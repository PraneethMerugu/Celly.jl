# Phase 9 Current-Code and Gap Audit

Date: 2026-07-19

Status: Complete pre-interview audit

## Verdict

The replacement CorePotts engine is strong enough to receive a genuine SciML interface, but the
repository is not ready for that interface to be implemented as one large change. Phase 9 must
begin with a protocol-and-name cutover gate. Otherwise the final API would be built on closed
algorithm/backend/RNG seams and would collide with the SHA-frozen historical `PottsProblem`,
`PottsIntegrator`, and `PottsSolution` types.

This is a sequencing problem, not a reason to weaken the Phase 9 goals. The qualified Phase 7--8
engine already supplies the difficult scientific and GPU-resident machinery. Phase 9 should wrap
that engine, not rehabilitate the historical simulator and not create a third execution path.

## Audit scope

This audit inspected:

- the accepted Phase 9 requirements in `spec/sciml-interface-semantics.md`;
- the Phase 9 roadmap and the P1 findings in `design/audits/open-protocol-audit.md`;
- current CorePotts problem, algorithm, integrator, execution, persistence, and observation code;
- the PottsToolkit compiler and its public re-export behavior;
- legacy containment manifests and all frozen consumer signatures;
- SciML-related tests, tutorials, examples, integrations, and satellite consumers; and
- the root, benchmark, and documentation environments.

The root environment currently resolves SciMLBase 3.36.0, KernelAbstractions 0.9.42,
AcceleratedKernels 0.4.3, Adapt 4.7.0, StructArrays 0.7.3, StaticArrays 1.9.18, and the pinned
KernelIntrinsics 0.1.8 fork commit `b3a02b6e80f0839082a02f1838af7e10e992062c`. Julia 1.12.6 is
the sole current target.

## The two execution stacks

### Replacement scientific stack

The replacement path is centered on `ScientificPottsIntegrator` and has the following reusable
assets:

| Asset | Current implementation | Phase 9 value |
| --- | --- | --- |
| Logical state | `state/logical.jl` | Portable authoritative problem input and validation |
| Compiled state | `execution/contracts.jl`, `components/scientific_trackers.jl` | Concrete structure-of-arrays device state |
| Algorithms | `algorithms/sequential.jl`, `checkerboard.jl`, `lottery.jl` | Qualified one-MCS transition engines |
| Scientific components | `protocols/scientific.jl`, `components/scientific_*.jl` | Typed component laws and compiled evaluation |
| Lifecycle | `lifecycle/scientific.jl`, `lifecycle/compiled.jl` | Transactional completed-MCS biological effects |
| Execution accounting | `execution/contracts.jl` | Launch, synchronization, transfer, and allocation metrics |
| RNG | `rng/semantic.jl` | Addressed Philox contract and schedule-independent draws |
| Observation | `logical_snapshot`, `analysis_snapshot`, `current_mcs_report` | Explicit observation boundaries already instrumented |
| Persistence | `persistence/scientific.jl` | Canonical snapshots, exact checkpoints, restore, and logical import |

`step!(integrator)` already advances exactly one MCS for sequential, checkerboard, and lottery
algorithms. Phase 8 lifecycle executes after the completed proposal/mechanics MCS, and the
integrator's `mcs` advances only after that phase. This is the correct semantic foundation for
SciML time.

The replacement path does **not** yet define `PottsModel`, a final problem type, final solution
type, `__init`, `__solve`, `solve!`, `remake`, save scheduling, callbacks, or ensemble integration.
`init_scientific` starts from an already compiled backend-resident state, so it is an internal
engine constructor rather than the final SciML initialization boundary.

### Historical SciML stack

The historical stack lives primarily in `state/types.jl`, `state/backends.jl`, and
`sciml/simulator.jl`. It defines the public names currently re-exported by PottsToolkit:

- `PottsProblem` over `PottsState`, a `tspan`, `PottsParameters`, and untyped keyword storage;
- `MetropolisAlgorithm` aliases exposing `active_fraction` and `sweeps_per_step`;
- mutable `PottsIntegrator` with saving fields embedded directly in the type; and
- `PottsSolution` with a minimal time-series facade.

Its `step!` loops over user-visible `sweeps_per_step`, updates historical auxiliary components,
executes the old event engine, and then increments time by one. That is the MCS normalization defect
which motivated the semantics-first refactor. Its `solve!` also:

- deep-copies `u0` during initialization;
- evaluates arbitrary SciML callbacks after an unconditional device synchronization;
- saves by synchronizing and materializing historical backend state;
- records no explicit synchronization/transfer provenance;
- cannot distinguish a requested termination retcode from normal success; and
- always constructs a `Success` solution after its loop.

No part of this implementation should be copied into the replacement interface without a fresh
semantic justification.

## The hard name and ownership collision

`PottsProblem`, `PottsIntegrator`, and `PottsSolution` are already concrete bindings in
`state/types.jl`. The accepted specification assigns those exact names to the final replacement
API. Julia cannot define a second type with the same binding in the same module.

The collision is protected by the Phase 7 hard-containment gate:

- 22 historical/consumer source files are frozen in full;
- 3 mixed files have frozen quarantined signatures; and
- 57 test, integration, benchmark, tutorial, and example consumers have frozen legacy signatures.

Approximately 50 repository consumer files currently spell at least one legacy problem,
integrator, solution, algorithm, or sweep-control name. PottsToolkit's `src/problems.jl` is itself
fully frozen and adds constructors directly to `CorePotts.PottsProblem`. PottsToolkit also broadly
re-exports CorePotts, so both future and historical names presently share one public namespace.

### Recommended resolution: one-time legacy name evacuation

Before introducing the final problem type:

1. Rename the three historical concrete types to explicitly internal legacy names.
2. Retarget the frozen historical simulator only to those renamed types.
3. Introduce the final `PottsProblem`, `PottsIntegrator`, and `PottsSolution` bindings once, in the
   replacement SciML source.
4. If the old PottsToolkit compiler must remain executable until Phase 10, allow its existing
   constructors to return the renamed legacy problem through a tightly inventoried transitional
   method. Do not let a replacement solve fall back to it.
5. Update the freeze manifest and quarantine audit in the same commit, documenting every changed
   historical line. Add no new legacy consumer.
6. Delete the transitional constructors when the Phase 10 compiler reaches its vertical-slice
   parity gate.

This is controlled removal work, not a compatibility promise. It preserves the hard containment
principle while giving the final types their permanent names. A provisional
`ScientificPottsProblem` followed by a later rename is not recommended: it would create needless
API churn and permit two replacement spellings to coexist.

## P1 open-protocol gate

The roadmap requires six findings to be resolved before the Level 3 API candidate. All remain open
or only partially implemented:

| P1 finding | Current evidence | Required Phase 9 precondition |
| --- | --- | --- |
| Algorithm openness | `ScientificPottsIntegrator` and multiple `step!`/report methods constrain algorithms with a central four-type `Union` | Dispatch through an open algorithm protocol; prove a downstream algorithm without a CorePotts edit |
| Proposal-law separation | `construct_copy_attempt` hardwires recipient/direction neighbor-copy construction and multiplicity calculation | Separate proposal scheduling/law, attempted transition representation, and copy-specific realization |
| Backend capability openness | `BackendFamily` is a closed enum and `require_capability` switches on `Symbol` values | Use typed capability traits/requirements; retain CPU, Metal, and ROCm as the only qualified production set |
| RNG namespace openness | `RNGStream` and `RNGEntityKind` are closed numeric enums embedded in `RNGAddress` | Add an extensible semantic namespace/identity layer which lowers to the closed versioned v1 address ABI |
| Compiled component lowering | Several trackers, fields, queries, and mechanics have good specialized lowering, but no uniform open compilation contract covers the complete set | Define the minimal dispatch-based compile/requirements protocol and exercise a combined downstream component fixture |
| Export curation | `CorePotts.jl` exports historical types, storage, workspace, and implementation details alongside scientific protocols | Classify and curate stable Level 3, experimental, and internal names before the final types are exported |

These changes should be a Phase 9.0 gate. They are small relative to Phases 7--8, but doing them
after `PottsProblem` and `PottsIntegrator` would force the public API to encode closed assumptions.

## Deliverable-by-deliverable gap matrix

| Roadmap deliverable | Reusable foundation | Missing work and risk |
| --- | --- | --- |
| Final model/problem ownership | Logical/compiled descriptors, component identities, canonical fingerprints | No `PottsModel`; final `PottsProblem` name occupied; exact contents and `u0` ownership need implementation tests |
| `init` and solve family | `init_scientific`, one-MCS `step!`, execution plan | Need `__init`, `__solve`, `solve!`, default algorithm, option validation, termination, retcodes, mutation/alias rules |
| `remake` | Immutable logical values and fingerprints | No method or cache classification; must distinguish numerical, initialization, geometry/schema, and algorithm-dependent invalidation |
| Saving and observations | `analysis_snapshot`, checkpoint capture, explicit observation sync metrics | No save schedule, retained-output policy, immutable snapshot-handle abstraction, or observation compilation plan |
| Callbacks | Completed-MCS boundary and lifecycle ordering exist | No replacement callback contract; host/device callback classification and legal control operations remain interview decisions |
| `PottsSolution` | Canonical analysis snapshots and storage metadata | No replacement solution, exact-time lookup, interpolation rejection, stats/provenance, or no-sync display |
| Ensembles | Addressed RNG includes an ensemble stream; immutable problem intent accepted | No schedule-independent trajectory derivation wired to SciMLBase 3.36 `EnsembleContext`; default `EnsembleProblem` behavior needs explicit integration |
| Device residency | Backend arrays, asynchronous launch plan, explicit sync/transfer accounting | Observation requests are not yet compiled; saving/callback/display code could accidentally materialize state unless gated |

## Problem and model boundary

The accepted ownership split is implementable and should remain unchanged:

- `PottsModel` is immutable scientific meaning: component values, relations, topology/boundary
  meaning, lifecycle declarations, field couplings, schemas, and capability requirements.
- `PottsProblem` binds that model to one concrete experiment: portable `u0` or initializer,
  geometry, integer `tspan`, capacity, typed `p`, master seed, and problem keywords.
- `PottsIntegrator` owns all mutable compiled state, backend arrays, workspaces, execution metrics,
  callback/save state, status, and current completed MCS.

The problem should not contain an `ExecutionPlan` or backend arrays in ordinary construction.
Expert Level 3 construction from backend-resident state may be supported, but its storage backend
must be unambiguous and validated against the requested solve backend.

## Saving, observation, and persistence gaps

Phase 8 deliberately distinguished an `ScientificAnalysisSnapshot` from a
`CanonicalCheckpoint`. Phase 9 should preserve that distinction:

- saving a state for analysis does not imply exact continuation;
- a checkpoint is not an ordinary `sol.u` element unless the user explicitly requests checkpoint
  storage;
- device-resident observable outputs should remain device resident;
- a host observation should produce exactly one declared observation boundary for the requested
  data, not one synchronization per observable; and
- displays use cached metadata only.

`analysis_snapshot` currently materializes a logical snapshot, while `current_mcs_report` copies a
small report buffer. Phase 9 needs an observation plan capable of fusing or batching requests and
classifying each request as cached metadata, device reduction, selected transfer, full logical
snapshot, or checkpoint. Without that plan, `saveat` and callbacks would regress the zero-sync GPU
contract even if the solver loop itself remained asynchronous.

## Callback gap

The historical simulator treats every standard `DiscreteCallback` as a host callback and
unconditionally synchronizes before calling it. That is safe from races but neither explicit nor
efficient, and it permits arbitrary mutation of state.

The replacement contract needs two paths:

- a standard host callback path at completed-MCS boundaries, with an explicit observation request
  and one recorded synchronization/materialization boundary; and
- a typed device-compatible observation/control path which lowers to concrete kernels and remains
  resident.

Neither path may perform biological division, death, transition, or arbitrary lattice mutation.
Those remain lifecycle effects. The interview must decide the exact standard `DiscreteCallback`
adapter, especially what value it receives as `u` and which mutation operations are legal.

## Ensemble gap exposed by SciMLBase 3.36

SciMLBase 3.36 passes an `EnsembleContext` containing trajectory ID, rerun count, worker ID,
optional generated seed, and per-trajectory RNG to `prob_func` and `output_func`. Its generic solve
path forwards an RNG directly only when `supports_solve_rng(prob, alg)` is true. The raw generated
`sim_seed` is not generically forwarded to ordinary non-jump solvers.

That does not automatically satisfy the accepted Potts contract. Potts trajectories require a
versioned semantic seed derived from ensemble master seed, stable trajectory identity, and rerun
identity, independent of scheduling and batching. We must choose and test one explicit adapter
rather than accidentally deriving semantic seeds from mutable task RNG state.

The recommended direction is a Potts-owned ensemble adapter which still uses
`SciMLBase.EnsembleProblem`, `EnsembleContext`, `prob_func`, `output_func`, and standard ensemble
algorithms, but remakes each trajectory with a Potts versioned seed derivation before inner solve.
The interview must settle how the ensemble master seed is supplied and how a user `prob_func` composes
with that automatic remake.

## PDE and evolving-field scope

Current scientific field support covers aligned field storage, sampling, static external-field
Hamiltonians, chemotactic drives, and response laws. There is no replacement PDE evolution,
secretion, uptake, or operator-splitting implementation.

Multiple accepted documents defer those semantics to a “SciML coupling phase,” but the Phase 9
roadmap does not explicitly list them. Broad PDE implementation should not be smuggled into the
problem/solution refactor. Phase 9 should either:

- define only the future coupling boundary and leave evolving fields to a separately scoped phase;
  or
- explicitly add a later Phase 9 chunk with its own semantics interview and reference fixture.

The first option is recommended for efficient completion of the core SciML interface.

## Tests and benchmarks required before implementation

Phase 8 performance evidence is a synchronized 6-by-6 diagnostic, not a paper-quality normalized
MCS baseline. Before Phase 9 changes the call stack, record replacement-path baselines for:

- construction without compilation;
- `init` including validation, lowering, adaptation, compilation, and first kernel compile;
- first MCS and warmed MCS separately;
- direct `step!` overhead relative to the internal one-MCS engine;
- metadata-only, device-observable, selected-host, and full-state saving;
- callback condition/effect overhead by residency class;
- checkpoint capture and restore;
- numerical-only and structural `remake`; and
- serial/threaded ensemble throughput and memory per trajectory.

Every GPU sample must warm compilation separately and synchronize at the measured sample boundary.
The hot MCS must not synchronize internally unless the selected observation policy requires it.
The same semantic fixture should run on CPU, Metal, and ROCm; backend-specific profilers may provide
additional evidence without changing the common benchmark definition.

## Recommended Phase 9 chunks

1. **9.0 — Preflight gate.** Resolve the six P1 protocol findings, curate exports, record the
   baseline, and perform the one-time legacy name evacuation.
2. **9.1 — Immutable model and problem.** Implement final ownership, constructors, validation,
   portable `u0`, typed `p`, integer time, seed, fingerprints, and `remake` classification.
3. **9.2 — Integrator and solve core.** Implement `__init`, `__solve`, `solve!`, integer `step!`,
   default algorithm, option rejection, termination, retcodes, and solve-equivalence tests.
4. **9.3 — Observation and saving.** Implement observation planning, saved-state policies,
   `saveat`, snapshot handles, statistics, and no-hidden-sync assertions.
5. **9.4 — Solution interface.** Implement collection/index behavior, exact saved-time lookup,
   interpolation rejection, metadata/provenance, and no-sync display.
6. **9.5 — Callbacks and control.** Implement host and device-compatible callback paths with
   declared observation needs and restricted mutation.
7. **9.6 — Ensembles.** Implement versioned trajectory seeds, standard `EnsembleProblem`
   composition, output/reduction behavior, failure handling, and schedule-invariance tests.
8. **9.7 — Qualification and closure.** Run complete CPU/Metal/ROCm conformance, performance,
   legacy containment, documentation API checks, and a Phase 9 completion audit.

## Hard implementation rules

- There is one replacement integrator and one solve loop.
- `solve(prob, alg)` remains behaviorally `solve!(init(prob, alg))`.
- No public step represents a color, round, batch, kernel, or PDE substep.
- Inapplicable adaptive/tolerance options throw; they are not accepted and ignored.
- Initialization, saving, callbacks, display, and ensembles may not hide device synchronization.
- `remake` never mutates the source problem or silently aliases mutable initial state.
- Saved values never alias live integrator storage.
- Exact checkpoint restoration continues through the same final problem/integrator path.
- No replacement API invokes the historical simulator as a fallback.
- CPU, Metal, and ROCm remain the only required qualified production backends until the backend
  contract changes; CUDA remains deferred.

## Interview gates

The code audit leaves the following questions for the interview because they materially affect the
public contract:

1. approval of the one-time legacy name evacuation and its temporary PottsToolkit constructor
   boundary;
2. the exact `u0` ownership/aliasing choices for host and expert device input;
3. the `remake` cache ownership and whether explicit cache objects are user-visible;
4. saved-output defaults and the exact value returned by `sol(t)`;
5. the standard SciML callback adapter and legal integrator controls;
6. the Potts/SciML ensemble-master-seed bridge; and
7. whether evolving PDE fields are a later separately named phase or a scoped Phase 9 extension.

Everything else in the accepted semantics is sufficiently specified to turn into conformance tests
before implementation.

## Interview resolution

All seven gates above were accepted on 2026-07-19. The normative resolutions are recorded in
[Decision 0025](../../spec/decisions/0025-phase-9-sciml-and-gpu-interface.md), and the executable
sequence is the [Phase 9 chunk plan](phase-9-chunk-plan.md). In particular, evolving PDE fields are
a separately scoped post-paper-core phase unless a required paper experiment explicitly promotes
them; they are not part of Phase 9 implementation.
