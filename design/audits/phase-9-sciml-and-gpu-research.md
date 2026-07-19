# Phase 9 SciML and JuliaGPU Research Audit

Date: 2026-07-19

Status: Complete pre-interview research audit

## Verdict

The accepted Potts semantics are compatible with current SciML and JuliaGPU practice. The most
Julian design is not to imitate an ODE internally. It is to implement the common SciML problem,
algorithm, initialization, solve, solution, remake, callback, and ensemble interfaces where their
meaning applies, while making integer MCS and discrete ownership explicit where ODE concepts do
not apply.

The GPU design should likewise expose an ordinary Julia host API but lower once into concrete,
bounded, backend-resident state and workspaces. Solver orchestration stays on the host; scientific
MCS work, qualified observations, and device callbacks stay in kernels. Synchronization belongs
only at declared observation, failure, persistence, or benchmark boundaries.

## Research basis

This audit used the source of the repository's resolved SciMLBase 3.36.0 as the implementation
authority and cross-checked it against current official documentation. JuliaGPU conclusions use
official KernelAbstractions, GPUArrays, CUDA, AMDGPU, StructArrays, StaticArrays, and
AcceleratedKernels documentation. Comparable scientific-library patterns use official SciML,
JumpProcesses, Catalyst, and DiffEqGPU documentation.

Primary references:

- [SciMLBase init and solve interface](https://docs.sciml.ai/SciMLBase/dev/interfaces/Init_Solve/)
- [SciMLBase problem and remake interface](https://docs.sciml.ai/SciMLBase/dev/interfaces/Problems/)
- [SciMLBase solution and return-code interface](https://docs.sciml.ai/SciMLBase/stable/interfaces/Solutions/)
- [SciMLBase ensemble interface](https://docs.sciml.ai/SciMLBase/stable/interfaces/Ensembles/)
- [SciML callback documentation](https://docs.sciml.ai/DiffEqDocs/stable/features/callback_functions/)
- [KernelAbstractions quick start and synchronization](https://juliagpu.github.io/KernelAbstractions.jl/stable/quickstart/)
- [KernelAbstractions kernel language](https://juliagpu.github.io/KernelAbstractions.jl/stable/kernels/)
- [GPUArrays test interface](https://juliagpu.github.io/GPUArrays.jl/dev/testsuite/)
- [AcceleratedKernels overview](https://juliagpu.github.io/AcceleratedKernels.jl/stable/)
- [AcceleratedKernels map-reduce API](https://juliagpu.github.io/AcceleratedKernels.jl/stable/api/mapreduce/)
- [StructArrays GPU usage](https://juliaarrays.github.io/StructArrays.jl/stable/advanced/)
- [CUDA custom-structure adaptation](https://cuda.juliagpu.org/stable/tutorials/custom_structs/)
- [AMDGPU custom-structure adaptation](https://amdgpu.juliagpu.org/stable/tutorials/custom_structs)
- [DiffEqGPU GPU execution modes](https://docs.sciml.ai/DiffEqGPU/stable/getting_started/)
- [JumpProcesses](https://docs.sciml.ai/JumpProcesses/stable/)
- [Catalyst spatial jump simulations](https://docs.sciml.ai/Catalyst/stable/spatial_modelling/spatial_jump_simulations/)

## What genuine SciML integration requires

### Define the owned dispatch points, not broad generic methods

SciMLBase's current guidance is:

```julia
init(::ProblemType, args...; kwargs...)::IntegratorType
solve!(::IntegratorType)::SolutionType
solve(args...; kwargs...) = solve!(init(args...; kwargs...))
```

Solver packages normally extend `SciMLBase.__init` and `SciMLBase.__solve` so SciML's common
high-level handling remains in force. The first dispatched argument must be a type owned by the
package to avoid ambiguity. CorePotts should therefore define narrow methods on the final
`PottsProblem` and `PottsIntegrator`, not `solve(::AbstractSciMLProblem, ::AbstractPottsAlgorithm)`
or other broad signatures.

The historical simulator directly defines both `init`/`solve` and `__init`/`__solve`. The
replacement should use the recommended internal extension points unless an observed SciMLBase
limitation requires a narrowly documented exception.

### A Potts problem should be a real problem, not an execution cache

SciML describes an `AbstractSciMLProblem` as the immutable encoding of a mathematical/numerical
problem. Problem values determine their concrete field types, may carry solver keywords, and are
expected to participate in `remake`.

That supports the accepted split:

- `PottsModel`: reusable scientific meaning;
- `PottsProblem`: a concrete portable experiment; and
- `PottsIntegrator`: mutable backend execution.

Backend arrays, compiled kernels, mutable RNG position, workspaces, pending callbacks, and save
buffers should not live in the ordinary problem. Keeping them in the integrator makes repeated
`solve(prob, ...)` calls independent and thread-safe, matching SciMLBase's explicit expectation
that solve calls be thread- and parallel-safe.

### `remake` should reconstruct semantics, then classify reuse

SciMLBase 3.36's generic `remake` reconstructs a problem from its fields and keyword constructor,
with special handling for `u0`, `p`, and stored `kwargs`. CorePotts can participate idiomatically by
giving `PottsProblem` a complete keyword constructor and, where Potts-specific validation or cache
classification is required, a narrow `SciMLBase.remake(::PottsProblem; ...)` method.

Compiled products should not be hidden mutable fields inside the immutable source problem merely
to make `remake` cheap. A separate compilation cache keyed by semantic fingerprints is safer:

- seed, `tspan`, and compatible numerical parameter changes may reuse structural products;
- `u0` changes require state realization and tracker rebuild but may reuse model compilation;
- geometry, topology, schema, component/effect graph, observation plan, numerical type, algorithm
  structure, or backend-capability changes invalidate their dependent products; and
- reuse must be an optimization with tests proving identical semantics, never an observable
  requirement for correctness.

### Integer MCS is a valid SciML time domain

SciML's common interface does not require every problem to use adaptive floating time. Potts can
use integer `tspan`, integer `t`, and one-MCS `step!`. Algorithm-specific options belong on the
algorithm value; common solve options belong on `solve`.

Consequences:

- `step!(integrator)` advances one complete MCS;
- `step!(integrator, n)` accepts only nonnegative integers;
- `saveat` contains integer MCS values or a positive integer interval;
- `adaptive`, `abstol`, `reltol`, floating `dt`, and continuous root-finding callbacks are rejected;
- `maxiters` is a separate safety bound and returns `ReturnCode.MaxIters`; and
- internal color passes, lottery rounds, kernel launches, mechanics half-steps, and lifecycle
  phases remain invisible to public time.

### Return codes must remain meaningful

SciMLBase distinguishes an in-progress `Default` code from completed outcomes. `Success` and
requested `Terminated` are both successful under `successful_retcode`; `MaxIters` is not.

The Potts solve loop should hold `Default` while active, set `Terminated` only through the accepted
termination operation, set `MaxIters` when the safety budget stops an otherwise valid trajectory,
and set `Success` only after reaching the requested final MCS. Invalid models, unsupported
capabilities, capacity exhaustion, invariant failures, and device errors should throw their
structured errors rather than return a misleading partial success.

## Solution interface recommendation

SciMLBase's `AbstractTimeseriesSolution` is an array-like view over saved `u` values with matching
`t` values and expects applicable `prob`, `alg`, interpolation, density, retcode, and statistics
metadata. A Potts solution can conform as a one-dimensional collection of immutable snapshots or
stable snapshot handles, provided it implements the complete collection behavior it claims.

Recommended behavior:

- `sol[j]` returns the saved entry at `sol.t[j]`;
- `length(sol.t)` is the number of saved times;
- `sol(t)` performs exact integer saved-time lookup only;
- requesting an unsaved time throws an informative error or returns an explicitly documented
  storage lookup result, never a fabricated ownership interpolation;
- `dense == false` and interpolation calls that imply a between-MCS state are rejected;
- `u`, `t`, `prob`, `alg`, `retcode`, `stats`, provenance, and storage metadata are ordinary fields
  or documented properties; and
- `show` prints cached metadata without inspecting device arrays or loading out-of-core snapshots.

Subclassing `AbstractTimeseriesSolution` only for branding while omitting its indexing semantics
would not be genuine integration. Conformance tests should exercise Base collection behavior and
SciML's `successful_retcode`, not only field presence.

## Callback findings

SciML callbacks are designed around solver-specific time semantics. Continuous callbacks use
interpolation and root finding, so they have no valid meaning for atomic integer-MCS ownership
states and should be rejected.

`DiscreteCallback` and `CallbackSet` are applicable at completed-MCS boundaries, but their ordinary
ODE contract allows `affect!` to mutate `integrator.u` and their `save_positions` behavior can add
saves independently of `saveat`. Potts cannot permit arbitrary state mutation because ownership,
trackers, generations, RNG identity, lifecycle provenance, and fixed-capacity invariants must be
updated transactionally.

Recommended adapter:

1. Evaluate callbacks after proposal/mechanics and lifecycle have completed for the MCS.
2. Support standard discrete callback condition/effect shape through a Potts boundary adapter.
3. Expose only documented controls such as `terminate!`, declared parameter updates, and explicit
   observation/save requests; reject direct authoritative-state mutation.
4. Interpret callback save positions only at the same integer boundary and deduplicate equal MCS
   entries according to an explicit policy.
5. Treat an ordinary closure callback as host-resident unless it implements a typed Potts device
   protocol.
6. Compile all callback observation requirements together so a host callback causes one declared
   synchronization/materialization boundary and a qualified device callback causes none.

This is stricter than an ODE callback but still genuine SciML behavior for a discrete structured
state whose safe mutations differ from an ODE array.

## Ensemble findings

SciMLBase's `EnsembleProblem` is the correct user-facing abstraction. It separates:

- `prob_func(prob, ctx)` for trajectory-specific remake;
- `output_func(sol, ctx)` for retained output and rerun requests;
- `reduction` and `u_init` for batched aggregation; and
- serial, threaded, and distributed scheduling from the inner scientific algorithm.

SciMLBase 3.36 uses `EnsembleContext` rather than the older positional index/repeat convention. The
context includes `sim_id`, `repeat`, `worker_id`, optional `sim_seed`, per-trajectory `rng`, and
master RNG. Its generic ensemble solver pre-generates trajectory seeds before scheduling when
`seed` or `rng` is supplied, which is schedule independent. However, for an ordinary non-jump
problem it does not pass the raw `sim_seed` to inner `solve`; it only passes an RNG when
`supports_solve_rng(prob, alg)` is true.

Potts must not silently substitute mutable Julia RNG consumption for its addressed Philox semantic
seed. The recommended integration is:

- keep `SciMLBase.EnsembleProblem` and its standard output/reduction/scheduling algorithms;
- use a Potts-owned, versioned trajectory seed derivation from master seed, `ctx.sim_id`, and
  `ctx.repeat`;
- apply the derived seed through `remake(prob; seed=...)` before the inner solve;
- compose automatic seed remaking with user `prob_func` in a documented order;
- allocate independent mutable integrator state and workspaces for every trajectory;
- never use worker ID, task ID, completion order, batch size, or backend launch geometry in the
  derivation; and
- test serial, threaded, distributed where practical, and qualified GPU scheduling for identical
  trajectory identities and statistically correct outputs.

Whether this is supplied by a Potts-specific `EnsembleProblem` constructor method, a narrow solve
adapter, or an explicit Potts ensemble wrapper is an API decision for the interview. Reimplementing
SciML's scheduling engine is the least desirable option.

## What comparable SciML libraries teach us

### JumpProcesses

[JumpProcesses](https://docs.sciml.ai/JumpProcesses/stable/) keeps stochastic scientific meaning
separate from execution choice: jump definitions are assembled into a `JumpProblem`, an aggregator
selects the exact stochastic simulation method, and an appropriate stepper performs the solve.
Exact methods may save extremely frequently, so its documentation explicitly separates algorithm
execution from output selection.

The lesson for Potts is to keep `SequentialCPM`, `SequentialEquilibrium`,
`CheckerboardSweepCPM`, and `LotteryCPM` as explicit scientific algorithms with guarantee profiles.
Backend kernels implement those algorithms; backend choice does not silently select one.

### Catalyst

[Catalyst's spatial jump interface](https://docs.sciml.ai/Catalyst/stable/spatial_modelling/spatial_jump_simulations/)
layers a high-level lattice reaction model over `DiscreteProblem`, `JumpProblem`, an explicit
spatial aggregator, and ordinary `solve`. The modeling layer does not absorb every solver concern.

The Potts analogue is `PottsToolkit` authoring -> immutable `PottsModel` -> concrete
`PottsProblem` -> explicit algorithm/backend solve. This supports the planned multilevel API and
argues against putting DSL declarations, compiled kernels, or backend arrays in the final problem.

### DiffEqGPU

[DiffEqGPU](https://docs.sciml.ai/DiffEqGPU/stable/getting_started/) distinguishes within-method
GPU acceleration of one large problem from GPU parallelism across many small trajectories. Its
lower-overhead whole-solver kernel mode accepts stricter GPU-compatible functions and static data;
its more flexible array mode has different overheads and restrictions.

Potts likewise needs two independently benchmarked axes:

- one large lattice whose MCS is executed on a GPU; and
- ensembles of independent Potts trajectories, which may use multiple devices or batched
  execution later.

Phase 9 should not claim that standard `EnsembleThreads` or a backend-resident single trajectory is
already an optimized whole-ensemble GPU kernel. That is a separate algorithm and benchmark result.

## JuliaGPU execution contract

### KernelAbstractions is the portability boundary

KernelAbstractions 0.9 launches kernels asynchronously and orders launches implicitly on a backend.
Host `synchronize(backend)` waits for outstanding work. Phase 9 should therefore preserve the
current execution-plan rule: launch normally, synchronize only when the host must observe results.

Kernels should receive the smallest concrete storage/descriptors required for execution, not the
host `PottsModel`, `PottsProblem`, callback closures, solution objects, or dictionaries. Workgroup
barriers must be encountered convergently, and `@Const` should be used only when non-aliasing and
read-only assumptions are true.

### Adapt owns structural movement, not semantic compilation

Adapt is appropriate for recursively changing array storage while preserving a custom struct's
shape. It should continue to operate at explicit compiled storage boundaries. It should not decide
scientific validation, construct missing workspaces, change numerical policy, or infer backend
semantics. Those happen before adaptation.

### StructArrays is appropriate for heterogeneous cell properties

StructArrays provides a structure-of-arrays representation and supports GPU storage through its
Adapt/GPU extensions. This matches coalesced per-property access and the fixed-capacity property
schema. The compiled schema must remain concrete; a `StructArray` does not make `Any`, abstract
field arrays, or runtime dictionary lookup GPU valid.

### StaticArrays is for genuinely small fixed values

StaticArrays is useful for fixed dimension-dependent coordinates, offsets, local tensors, and small
per-lane values. It should not hold lattice-sized state or large capacity-dependent workspaces,
because excessive static size increases compile time, register pressure, and code size. Static size
must encode a stable algorithmic constant, not arbitrary user problem size.

### AcceleratedKernels should supply standard parallel primitives

AcceleratedKernels offers backend-unified operations and exposes temporary arrays for reuse. Use it
for supported scan, reduction, sort, permutation, and map-reduce operations when their semantics
match the required operation. Supply explicit neutral/init values and respect associativity;
parallel floating reductions do not become deterministic merely because a library primitive is
used. Preallocate documented `temp` storage in the integrator rather than allocating it on every
save or callback.

### KernelIntrinsics is an implementation layer

KernelIntrinsics should be used for subgroup operations only behind a typed, qualified capability
and an algorithm whose transaction/RNG semantics remain unchanged. A subgroup implementation is
not a new public scientific algorithm when it preserves the same transition law. It must never be
called on an unqualified backend or used to make an approximate reduction appear exact.

The pinned fork is appropriate while its Metal support is under review, but checkpoint provenance
and CI must continue to record its exact commit. Qualification remains CPU, Metal, and ROCm; CUDA
support is not inferred from portable source alone.

### GPUArrays rules should be test gates

GPUArrays recommends disabling scalar indexing in tests. Phase 9 GPU tests should make scalar
iteration an error and verify that:

- `init` adaptation produces one-backend array trees;
- stepping, device observations, and device callbacks do not scalar-index backend arrays;
- host materialization appears in transfer/synchronization metrics;
- no per-MCS device allocations occur after warm initialization for the stable path; and
- all backend-specific functionality is isolated in package extensions or typed capability
  methods.

## Observation and performance recommendations

An observation request should lower during `init` into a concrete plan. Useful categories are:

| Category | Example | Required boundary |
| --- | --- | --- |
| Cached host metadata | MCS, algorithm name, backend, status | None |
| Device-resident value | per-cell observable array retained on device | None |
| Device reduction | count, energy, aggregate statistic | Kernel launch; no host sync until host consumes it |
| Selected host value | small report or reduction result | One sync and selected transfer |
| Full analysis snapshot | ownership and requested properties | One sync and materialization |
| Checkpoint | exact continuation record | One explicit persistence boundary |

All observations due at one MCS should be batched before the host boundary. `show`, logging, progress,
and callback bookkeeping must not call `Array(device_state)`, `only(device_array)`, or similar
implicit observations.

GPU performance measurements must separate compile latency, initialization, launch overhead, and
steady-state execution. Official CUDA guidance likewise requires synchronization around measured
asynchronous work; the same principle applies through KernelAbstractions on Metal and ROCm. A warm
MCS benchmark synchronizes after the measured MCS for timing validity but asserts that the MCS
implementation itself added no semantic observation synchronization.

## Required conformance evidence

Phase 9 should not close without:

- SciMLBase-owned dispatch tests for `__init`, `__solve`, `solve!`, `step!`, `terminate!`, `remake`,
  return codes, and `successful_retcode`;
- collection/index/display tests for the final solution;
- exact integer-time and unsupported-option tests;
- behavioral-equivalence tests for `solve(prob, alg)` and `solve!(init(prob, alg))` under all
  qualified algorithms/backends;
- problem immutability and independent repeated/threaded solve tests;
- remake equivalence plus structural/numerical cache reuse instrumentation;
- no-alias saved-state tests;
- host/device observation and callback synchronization budgets;
- ensemble seed identity invariance under serial/threaded scheduling, batching, and reruns;
- GPU scalar-indexing-disabled tests;
- zero steady-state per-MCS device allocation tests for stable configurations;
- CPU, Metal, and ROCm backend qualification using the same semantic fixtures; and
- performance comparisons against the direct replacement one-MCS engine, so the SciML layer's
  overhead is measured rather than assumed.

## Research-backed recommendations for the interview

1. Keep the accepted model/problem/integrator separation.
2. Extend `__init` and `__solve`; do not duplicate high-level solve dispatch without evidence.
3. Use exact integer MCS and reject continuous/adaptive concepts.
4. Use `AbstractTimeseriesSolution` only with its real collection contract and exact saved-time
   lookup.
5. Reject continuous callbacks; adapt discrete callbacks through restricted Potts controls.
6. Compile observations by residency and batch host boundaries.
7. Keep standard `EnsembleProblem`, but add an explicit Potts semantic-seed bridge rather than
   consuming task RNG incidentally.
8. Treat within-lattice GPU execution and GPU ensemble execution as separate capabilities.
9. Keep KernelAbstractions as the common kernel layer, AcceleratedKernels for matching reusable
   primitives, Adapt for storage movement, StructArrays for fixed-schema SoA data, StaticArrays for
   small fixed values, and KernelIntrinsics behind typed qualified subgroup capabilities.
10. Define the evolving-PDE coupling boundary now, but implement PDE evolution in a separately
    scoped semantics/implementation phase unless it is added explicitly to Phase 9.

These recommendations preserve all existing priorities: literature-correct named algorithms,
hardware agnosticism, full qualified GPU execution, reproducibility, extensibility, API polish, and
paper-quality performance evidence.
