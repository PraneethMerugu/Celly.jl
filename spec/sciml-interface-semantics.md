# SciML Problem, Integrator, Solution, and Ensemble Semantics

Status: Accepted

## Purpose

This document defines genuine SciML integration for Potts.jl. It governs the relationship among
`PottsModel`, `PottsProblem`, algorithms, integrators, solutions, callbacks, saving, remaking, and
ensembles.

Using SciML names without their expected behavior is not conformance. Potts.jl participates in the
applicable SciMLBase interfaces while rejecting options whose meaning does not apply to Cellular
Potts dynamics.

## Model and Problem Ownership

### PottsModel

A `PottsModel` is an immutable reusable scientific description containing:

- Cell types and medium domains
- Properties and parameters
- Energy components
- Rules and biological events
- Scientific relations and boundary semantics
- Field coupling
- Capability requirements

It contains no realized initial lattice, live state, device arrays, run seed, or time span.

### PottsProblem

`PottsProblem` is an immutable subtype of the appropriate `SciMLBase.AbstractSciMLProblem`. It binds
one model to a concrete experiment:

- Initial state or typed initializer
- Concrete geometry, lattice dimensions, and spacing
- Integer-MCS time span
- Maximum cell capacity
- Master seed and RNG contract
- Problem-specific typed parameter values

Solving creates mutable execution state but does not alter the problem. Immutable internal data MAY
be shared; mutable initial data follows explicit copy and ownership rules.

The problem remains portable across qualified backends. Backend selection is not part of model
meaning.

### Parameters and initial state

`prob.p` is a typed parameter container with accepted parameter handles. It is not an untyped
dictionary and is not mutated directly; numerical changes use `remake`.

`prob.u0` MAY be a complete validated initial state or a typed initializer/layout description.
`init` realizes it deterministically. Initialization randomness uses a named semantic stream and
does not shift later dynamics draws.

Direct Level 3 construction MAY supply backend-resident initial state. Its backend must be
unambiguous and compatible with explicit solve selection. Mixed or contradictory storage is an
error.

## SciML Initialization and Solving

CorePotts implements the applicable `SciMLBase.__init` and `SciMLBase.__solve` extension points so
SciML's common checking and error handling remain available.

The governing relationship is:

```julia
solve(prob, alg; kwargs...) = solve!(init(prob, alg; kwargs...))
```

One-shot and interactive execution therefore share validation, compilation, initialization,
callbacks, saving, and result construction.

The Monte Carlo algorithm is an ordinary immutable value passed separately:

```julia
solve(prob, LotteryCPM(...))
```

The Phase 7 stable algorithm vocabulary is:

- `SequentialCPM`: conventional modified-Metropolis reference dynamics;
- `SequentialEquilibrium`: sequential Metropolis-Hastings equilibrium sampling when the complete
  model satisfies its capability requirements;
- `CheckerboardSweepCPM`: randomized-color, once-per-site parallel sweep dynamics; and
- `LotteryCPM`: topology-calibrated, conflict-resolved parallel dynamics.

Intrinsic or subgroup kernels are implementations of one of these algorithms when they preserve
the complete contract. If they change transactions, RNG identities, state freshness, or observable
results, they require another algorithm name and guarantee profile.

`solve(prob)` and `init(prob)` without an explicit algorithm select `SequentialCPM`. Backend choice
MUST NOT silently select different scientific dynamics. Selecting a GPU with this default emits one
informational message during integrator construction, before the first MCS, explaining that the
sequential process is intentional and naming compatible explicit parallel alternatives. The message
uses Julia's logging system, occurs once per integrator construction, and never changes the selected
algorithm.

Algorithm compatibility is checked during `init`, before device adaptation or expensive compilation
where possible. Diagnostics report all known incompatible components, topology, dimension,
reproducibility, numerical, and backend requirements together.

## Backend and Reproducibility Selection

Backend selection is an `init`/`solve` execution choice:

```julia
solve(prob, alg; backend = MetalBackend())
```

Host initial data is adapted during `init` only after model, problem, algorithm, numerical, RNG, and
backend validation.

The seed belongs to the problem:

```julia
prob = PottsProblem(model, initializer, geometry; seed = 42)
```

The requested reproducibility profile belongs to `init`/`solve`, allowing one problem to be examined
under different qualified profiles:

```julia
solve(prob, alg; reproducibility = StrictReproducibility())
```

Typed profile values are foundational. Symbols MAY be accepted as convenient aliases. Execution
never silently downgrades the requested profile.

## PottsIntegrator

`init` returns a mutable `PottsIntegrator` owning:

- Current compiled state
- Current integer MCS
- Algorithm and scientific guarantee profile
- Source problem or sufficient immutable provenance
- Compiled model and execution plan
- Backend, workspaces, and execution policy
- RNG contract and current semantic position
- Callback and saving state
- Diagnostics and current return code

Mutable execution cannot alter the source model or problem.

### Stepping

```julia
step!(integrator)
```

advances exactly one MCS and returns the integrator.

```julia
step!(integrator, n)
```

accepts a nonnegative integer and advances exactly `n` MCS. Floating durations are rejected.

Internal checkerboard colors, lottery rounds, proposal batches, field substeps, and kernel launches
are not public steps. They never change the meaning of `step!`.

`reinit!` MAY later support efficient repeated execution, but it requires explicit behavior for new
initial state, seed, parameters, caches, callbacks, and output. It does not block the first stable
refactor.

## Time and Solver Options

Public time is integer MCS. `integrator.t`, problem `tspan`, schedules, callback boundaries, and
`saveat` use integer MCS values.

A floating endpoint MAY be accepted only when exactly integral and converted without ambiguity.
Otherwise construction fails with an informative error.

Public `dt` is one MCS. Auxiliary physics MAY have accepted internal substeps but those do not
redefine CPM time.

Options such as adaptive stepping, `abstol`, and `reltol` are rejected rather than accepted and
ignored. Potts.jl does not pretend to have continuous adaptive local-error control.

`maxiters` is a safety limit distinct from `tspan`. Reaching it before the requested final MCS
returns a solution with `SciMLBase.ReturnCode.MaxIters`.

## Remaking Problems

`SciMLBase.remake(prob; ...)` returns a new immutable problem and MAY replace:

- Model
- Initial state or initializer
- Typed parameters
- Geometry
- Time span
- Capacity
- Seed

It does not mutate shared arrays implicitly.

Numerical changes, including compatible parameter or seed changes, reuse compilation when safe.
Structural changes to schemas, topology, dimension, rule/effect graph, components, query set, or
algorithm structure invalidate the affected plan.

The compiler MAY report the classification and cache consequence. Normal use does not expose cache
internals.

Explicit integrator-time parameter changes use documented operations at accepted MCS phase
boundaries; direct mutation of `prob.p` is not their implementation.

## Saving

SciML `saveat` is supported at integer MCS values. A positive scalar integer denotes a regular MCS
interval. Nonintegral save times are rejected until a corresponding state meaning exists.

`save_start` and `save_end` follow normal SciML expectations. `save_everystep = true` saves every
MCS, not every internal algorithm round.

Dense interpolation is not advertised. Cellular ownership has no accepted state between integer MCS
snapshots, so Potts solutions do not fabricate linear interpolation between cell labels.

`sol(t)` returns an exact available saved state at integer MCS `t`, or follows explicitly documented
snapshot retrieval behavior. It never silently interpolates ownership.

Saving does not require every full state to be copied to host memory. A policy MAY:

- Keep qualified device snapshots
- Transfer full or selected state
- Save only scientific observables
- Stream frames to an output backend
- Use out-of-core storage

The solution reports what was retained and where. Saved entries are immutable snapshots or stable
snapshot handles, not aliases to live integrator storage.

## PottsSolution

A Potts solution subtypes the appropriate `SciMLBase.AbstractSciMLSolution` and exposes as
applicable:

- `t`
- `u`
- `prob`
- `alg`
- `retcode`
- Diagnostics and statistics
- Reproducibility and model provenance
- Storage metadata

Every completed solution has a meaningful return code. It does not remain at `ReturnCode.Default`.

- Normal completion: `ReturnCode.Success`
- Deliberate user termination: `ReturnCode.Terminated`
- Safety limit reached: `ReturnCode.MaxIters`

`SciMLBase.successful_retcode(sol)` works through the standard trait. `Success` and deliberate
`Terminated` are successful outcomes.

### Throwing versus returning

The following throw before or during execution rather than returning a misleading solution:

- Invalid model, problem, algorithm, backend, or solver option
- Structured cell-capacity exhaustion
- Broken state or transaction invariants
- Unsupported required capability
- Device execution or compilation failure

Expected deliberate termination returns a valid solution with `Terminated`. Reaching `maxiters`
returns a partial solution with `MaxIters`.

## Biological Events and SciML Callbacks

Division, death, transition, growth, property updates, and field coupling are model components with
accepted snapshot, effect, and transaction semantics. They are not implemented as generic SciML
callbacks.

SciML callbacks provide external observation and control, including:

- Custom observation and saving
- Termination
- Declared parameter changes at MCS boundaries
- Coupling to another accepted solver
- User-requested monitoring

Callback conditions observe a consistent documented integer-MCS boundary after the MCS and accepted
event phases.

A host callback that requires device data creates a declared synchronization boundary. A qualified
device-compatible callback MAY remain resident. Callback synchronization and residency appear in
the execution report.

Callbacks do not mutate lattice or cell state arbitrarily. Scientific changes use typed effects or
documented integrator operations so trackers, RNG, provenance, and invariants remain consistent.

`terminate!(integrator)` is supported and yields `ReturnCode.Terminated` with final saving governed
by the selected options.

Scientifically interacting callback effects use explicit priority or dependency semantics, or are
rejected when conflicting. Accidental vector order is not a conflict law. Pure observations use a
documented deterministic order.

## Snapshots and Checkpoints

An analysis snapshot and continuation checkpoint are distinct APIs.

A snapshot represents observable state at a named MCS. A checkpoint promises continuation and
therefore includes all required model, scientific state, algorithm, RNG, identity, and semantic
counter state under its checkpoint contract. Stable capture occurs only at finalized MCS `0` or a
completed positive integer MCS; replaceable caches and execution workspaces are rebuilt.

They MAY share storage infrastructure but neither silently claims the other's guarantees.

Canonical storage, exact resume, logical import, and compatibility follow
[Snapshots, Checkpoints, Restore, and Logical Storage](persistence.md).

## Ensembles

Potts problems participate in `SciMLBase.EnsembleProblem`. Potts.jl does not invent a separate
parameter-sweep framework for cases covered by the SciML ensemble interface.

`prob_func` uses `remake` to vary seeds, parameters, initial conditions, geometry, or models across
trajectories.

Every trajectory receives independent mutable execution state and workspaces. Immutable model and
problem data MAY be shared safely across threads or processes.

### Ensemble RNG

Trajectory seeds are derived from:

- Ensemble master seed
- Stable trajectory identity
- Rerun identity
- Versioned derivation contract

They do not depend on worker, thread, device, batch size, completion order, or ensemble scheduling.

Serial, threaded, distributed, and GPU ensemble execution preserve each trajectory's selected
scientific algorithm and semantic seed identity. Ensemble scheduling does not alter within-trajectory
semantics.

## Observation Interface

Ordinary observation functions receive scientific state or snapshot interfaces rather than raw
backend arrays. Explicit expert operations MAY request backend storage.

Observation requests declare whether they require device reduction, host materialization, full
state, or only cached metadata. The compiler can then report transfers and synchronization before
execution.

## Display

`show(prob)` concisely reports model identity, geometry, time span, seed, capacity, and unresolved
requirements without printing the lattice.

`show(integrator)` does not synchronize the device. It uses cached host metadata such as current
completed MCS, backend, algorithm, status, and available diagnostics. State inspection is explicit.

`show(sol)` includes return code, saved interval, backend, algorithm guarantee, seed, RNG version,
model-fingerprint prefix, and storage mode.

## Conformance Requirements

- `PottsProblem` and `PottsSolution` participate in the appropriate SciMLBase abstractions.
- CorePotts uses the applicable `__init` and `__solve` hooks.
- One-shot solving is behaviorally `solve!(init(...))`.
- Problems are immutable and separate from mutable integrators.
- `step!` advances integer MCS, never internal rounds.
- Inapplicable adaptive-solver options are rejected rather than ignored.
- `remake` preserves ownership and distinguishes numerical from structural changes.
- Saving occurs at exact MCS states without fabricated dense interpolation.
- Saved states do not alias live mutable integrator storage.
- Every completed solution has a meaningful return code.
- Capacity and invariant failures follow their structured error contracts.
- Biological events remain model effects rather than generic callbacks.
- Host callback synchronization is declared and reported.
- Snapshots and continuation checkpoints remain distinct.
- Ensemble seeds are independent of scheduling and batching.
- Displays do not cause hidden GPU synchronization.

## Primary Interface References

- [SciMLBase initialization and solving](https://docs.sciml.ai/SciMLBase/dev/interfaces/Init_Solve/)
- [SciMLBase solutions and return codes](https://docs.sciml.ai/SciMLBase/stable/interfaces/Solutions/)
- [SciMLBase ensemble interface](https://docs.sciml.ai/SciMLBase/stable/interfaces/Ensembles/)
