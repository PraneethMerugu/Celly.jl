# Phase 9 Implementation Chunk Plan

Status: Accepted execution plan

Date: 2026-07-19

## Purpose

This plan turns the accepted Phase 9 semantics into reviewable vertical chunks. Every chunk must
leave the repository green, preserve the Phase 7--8 engine, and add conformance evidence with its
implementation. A later chunk may depend on an earlier one; none may weaken an earlier gate to make
progress appear complete.

The normative contract is
[SciML Problem, Integrator, Solution, and Ensemble Semantics](../../spec/sciml-interface-semantics.md)
and [Decision 0025](../../spec/decisions/0025-phase-9-sciml-and-gpu-interface.md).

## Phase 9.0: Legacy evacuation and open-protocol gate

Scope:

- Record direct-engine CPU, Metal, and ROCm structural and timing baselines before changing the call
  stack.
- Rename historical final-name types to explicit internal legacy names and update only the frozen
  containment boundary and its consumers.
- Remove central concrete algorithm unions and establish open algorithm, proposal-law,
  backend-requirement, RNG-namespace, and compiled-component protocol seams.
- Add a downstream extension fixture proving that a new conforming algorithm/component can lower
  without editing a central concrete-type switch.

Gate:

- Legacy containment, structure, direct-engine scientific tests, backend smoke tests, and baseline
  capture are green. No replacement final name is exported before this gate passes.

## Phase 9.1: Model, problem, ownership, and remake

Scope:

- Introduce final immutable `PottsModel`/`PottsProblem` ownership and canonical construction.
- Implement typed parameters, deterministic seed realization, integer `tspan`, fixed capacity,
  initial-state copy/alias policies, and staged aggregate validation.
- Implement scientific fingerprints, structural compilation keys, dependency-directed `remake`,
  and the explicit trajectory-free `PottsCompilationCache`.

Gate:

- Ownership/aliasing, concurrent initialization, capacity, seed, invalid construction, cache reuse,
  and invalidation matrices pass without running an MCS.

## Phase 9.2: Integrator and one authoritative MCS path

Scope:

- Implement applicable SciMLBase `__init`/`__solve` hooks and final `PottsIntegrator`.
- Route `step!`, `step!(integ,n)`, destructive iteration, and `solve!` through one complete MCS
  operation over the existing qualified engine.
- Implement terminal behavior, return codes, `maxiters`, strict keyword validation, CPU default,
  explicit backend selection, and the sequential-on-GPU notice.

Gate:

- One-shot, initialized, manually stepped, terminal, and partial execution are behaviorally
  equivalent where expected. A warm unobserved SciML MCS has zero extra launches, syncs, transfers,
  device allocations, state copies, and RNG draws over direct execution.

## Phase 9.3: Observation, saving, and solution

Scope:

- Compile and batch typed observation requirements by residency.
- Implement start/end/default saving, exact integer `saveat`, backend-resident independent snapshots,
  explicit host/observable/streaming policies, and no interpolation.
- Implement final `PottsSolution`, exact saved lookup, metadata, statistics, provenance, display, and
  hidden-boundary counters.

Gate:

- Save ordering, deduplication, residency, nonaliasing, unsaved-time errors, output failure, and
  display-without-sync pass on CPU, Metal, and ROCm.

## Phase 9.4: Callback and control boundary

Scope:

- Support standard host `DiscreteCallback`/`CallbackSet` with one shared snapshot and boundary per
  due MCS.
- Implement the typed device callback protocol, bounded lowering, declared observations/effects,
  deterministic ordering, conflict validation, termination, save requests, and typed parameter
  changes.
- Keep biological lifecycle effects in model protocols rather than callback mutation.

Gate:

- Host callbacks prove exactly one declared materialization boundary; device callbacks prove zero
  host boundaries. Ordering, conflicts, termination, final saving, and unsupported continuous
  callbacks have conformance fixtures.

## Phase 9.5: Checkpoint restore and logical import integration

Scope:

- Connect canonical Phase 8 persistence to the final problem/integrator/solution path.
- Implement exact compatibility validation, `restore_checkpoint`, separate checkpoint collections,
  persistence-failure behavior, and portable logical import with explicit ancestry.

Gate:

- Uninterrupted versus exact-restored continuation, incompatible restore, later-endpoint changes,
  output atomicity, cross-backend logical import, and no-false-exactness tests pass.

## Phase 9.6: Ensembles, symbolic indexing, and distribution

Scope:

- Add the thin SciMLBase ensemble adapter, `EnsembleSeedDerivationV1`, user-managed override,
  `prob_func` ordering, bounded reruns, failure collection, and output handling.
- Add typed parameter/observable symbolic indexing and reject unsupported generic AD.
- Qualify serial/threaded/distributed CPU ensembles and serial independent Metal/ROCm trajectories;
  preflight serialization and reject unqualified same-device threading.

Gate:

- Trajectory seeds and results are invariant to scheduler, worker assignment, batch size, completion
  order, and rerun execution. Ambiguous symbols, device dictionaries, unsupported AD, and unsafe
  serialization are absent or rejected.

## Phase 9.7: Qualification, benchmarks, and completion audit

Scope:

- Run the full Julia 1.12.6 CPU/Metal/ROCm, 2D/3D qualification matrix with scalar indexing
  disabled and representative paper workloads.
- Land layered cold/warm, direct/SciML, observation, callback, persistence, remake, and ensemble
  benchmarks with structural counters and dedicated-runner timing baselines.
- Migrate repository tests and the current developer-facing interface documentation needed by the
  new library path. Tutorial and paper-facing migration remains scheduled after Phase 10--11 API
  completion.
- Perform the final legacy-containment, open-protocol, GPU-residency, API-semantic, and performance
  audit.

Gate:

- All Phase 9 exit criteria in the roadmap and Decision 0025 are evidenced. No supported baseline
  regresses by more than 5% without an accepted reason. CUDA and evolving PDE-field execution remain
  explicitly deferred rather than partially implemented.

## Change discipline

Each pull request or review unit should implement one coherent vertical slice inside a chunk, add
its own tests and benchmark counters, and update the audit evidence. Mechanical renaming may be
separate from semantic behavior, but the repository must never expose two meanings under one final
name. Optimization follows measured bottlenecks and may not create a second scientific path.

Phase 9 is complete only when 9.0 through 9.7 gates pass. Code presence, compilation, or a green CPU
unit test alone is not completion evidence.
