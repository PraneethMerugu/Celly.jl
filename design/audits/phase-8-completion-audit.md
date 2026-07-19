# Phase 8 Completion Audit

Date: 2026-07-19

Status: Candidate complete locally; authoritative ROCm and repository CI pending

This audit uses the Phase 8 deliverables and exit gate in `design/refactor-roadmap.md` as the
definition of completion. CPU and real Apple Metal evidence is complete. Phase 8 closes only after
the candidate commit passes the independent AMDGPU/ROCm runner and the required repository checks.

## Delivered scientific scope

Phase 8 replaces lifecycle, initialization, and persistence on the scientific path. It does not
revive the historical event engine or broaden the accepted paper scope. Dynamic focal-link events,
nonbinary division, remote checkpoint services, mandatory device-native initialization, and the
final PottsToolkit compiler remain in their owning later phases.

| Chunk | Executable result | Local verdict |
| --- | --- | --- |
| 8.1 scalar protocols | Typed open division/transition/retirement policies; schedules, targets, triggers, effects, conflict resolvers, and region-label geometry | Complete |
| 8.2 initialization | Stable provisional identities; generic claim emission; deterministic overlap and compaction; masks, labels, coordinates, shapes, site seeds, bounded rejection, periodic rasterization, and downstream layout | Complete |
| 8.3 scalar transactions | One pre-lifecycle snapshot; deterministic plan/resolve/validate/atomic commit; growth, transition, division, death, extinction, retirement, and bounded failures | Complete |
| 8.4 mechanics and derived state | Constitutive reset, intensive preservation, addressed stationary redraw, target split, tracker repair, death clear, and generation-safe reuse | Complete |
| 8.5 compiled CPU/integrator | Bounded concrete descriptors/workspaces and completed-MCS connection for sequential, checkerboard, and lottery | Complete |
| 8.6 GPU | Staged schedule-through-commit KernelAbstractions pipeline, device failure buffer, 2D/3D geometry and tracker repair | CPU and Metal complete; ROCm pending CI |
| 8.7 persistence | Canonical completed-MCS record, strict continuation profile, exact resume, logical import, memory/HDF5/Zarr adapters, integrity and publication faults | Complete locally and exact Metal continuation complete |
| 8.8 audit/performance | Machine-readable qualification and synchronized diagnostic measurements | Complete locally; authoritative CI pending |

## GPU execution contract

Lifecycle execution is a bounded staged device pipeline: clear, event detection, conflict
resolution, geometry validation, capacity preflight, commit, tracker reconstruction, derived repair,
mechanical repair, and report publication. Flexible host declarations lower to an isbits tuple and
fixed-capacity backend arrays before execution. No event is evaluated through a host callback.

Ordinary property-only lifecycle phases synchronize zero times inside an MCS. Identity-changing
transactions expose one failure-observation boundary for the whole atomic transaction, not one
synchronization per event or kernel. Conflict and capacity failures are written on device; all later
stages observe the same failure buffer and leave authoritative state unchanged before the error is
surfaced.

The local Metal matrix compiles and executes all three production algorithms in 2D and 3D with
vector, random, major-axis, minor-axis, and downstream-defined division geometry. It also covers
mechanical division policies, moment reconstruction, deterministic conflict/capacity failure,
generation advance, declaration permutation, and exact restored continuation. No host execution
fallback is present.

## Open-protocol proof

The benchmark module acts as a downstream package and defines, without a CorePotts source edit:

- a schedule and trigger with device methods;
- a custom effect;
- a custom compact region-label division geometry;
- a custom property division policy;
- a custom initialization claim emitter; and
- a custom maintained site-sum observable with compilation, array adaptation, copy-transaction,
  division, retirement, reconstruction, and checkpoint-restore methods.

One combined 2D/3D fixture compiles these values into CPU and Metal kernels, performs accepted copy
commits and division, independently reconstructs the observable, checks declaration permutation,
and resumes from an exact checkpoint. The same fixture is part of the ROCm matrix.

## Persistence proof

`CanonicalCheckpoint` stores backend-independent authoritative ownership, identity, generation,
property, RNG, ancestry, model, schema, and topology data. Its exact continuation profile binds the
algorithm, backend family and runtime, RNG contract, Julia/CorePotts versions, numerical mode,
scalar/index types, and core execution dependency identities. A mismatch cannot silently become an
exact resume; users must request a visibly downgraded logical import, which still requires the same
scientific model, schema, and topology.

Capture has one explicit observation synchronization. Restored execution rebuilds domain storage,
trackers, derived observables, algorithm workspaces, lifecycle descriptors, and backend arrays.
CPU and Metal uninterrupted-versus-restored trajectories agree for sequential, checkerboard, and
lottery in 2D/3D, including all property columns, stochastic mechanical state, reports, and RNG
continuation, with zero internal synchronization in the continued MCS path.

Memory, HDF5, and Zarr reconstruct the same canonical payload. Both file adapters stage and validate
before atomic local publication, write completion last, and preserve the previously published
checkpoint under injected failure. Unknown schema versions, incomplete records, checksum damage,
invalid ownership, wrong capacity, truncated property columns, model/schema/topology mismatches, and
changed exact profiles fail before a live integrator is mutated.

## Performance and resource evidence

The lifecycle qualifier reports 126 bytes for the built-in three-property fixture and 132 bytes for
the combined downstream fixture in both 2D and 3D. The synchronized diagnostic fixture reports a
128-byte lifecycle workspace and a 556-byte uncompressed canonical material payload.

After warm execution in the final local diagnostic process, adding one property-only lifecycle event
measured about 2.59x/1.34x/1.88x on CPU and 0.89x/1.38x/0.53x on Metal for
sequential/checkerboard/lottery on
the tiny 6-by-6 fixture. Ratios below one demonstrate timing noise and overlapping backend/JIT
effects, not a speedup claim. These measurements are therefore report-only until paper hardware,
sample sizes, cold-process order, and thresholds are frozen. Every timed MCS region synchronizes the
backend; historical Phase 1 workload records remain separate because their public-step semantics are
not normalized MCS semantics.

## Local evidence

- CorePotts package suite: 2,777 passes and one intentional broken test on Julia 1.12.6.
- PottsToolkit: 276 passes; MakiePotts: 3 passes; NeuralPotts: successful; complete
  cross-package integration: 152 passes.
- Complete CPU smoke matrix: green, including `LIFECYCLE_QUALIFICATION`,
  `PERSISTENCE_QUALIFICATION`, and `PHASE8_PERFORMANCE`.
- Complete real Apple Metal smoke matrix: lifecycle and persistence green; the combined downstream
  fixture and performance report also pass independently after the final protocol change.
- `scripts/check_structure.jl`, `scripts/check_legacy_containment.jl`, all package/integration
  suites, and `git diff --check`: green locally.

## Authoritative closure condition

This document becomes `Status: Complete` only after a pushed candidate commit passes:

1. the required Julia 1.12.6 repository CI, including structure and hard legacy containment;
2. the real Metal job; and
3. the independent real AMDGPU/ROCm job containing lifecycle, downstream-protocol, persistence, and
   performance records.

CUDA remains deferred under Decision 0013 and is not inferred from this phase.
