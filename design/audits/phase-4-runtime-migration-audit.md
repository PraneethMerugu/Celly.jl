# Phase 4 Runtime Migration Audit

Status: Deferred to Phases 5–7 by ADR 0012

## Finding

The Phase 4 logical state is complete as a CPU scientific representation. The historical simulation
path remains physically coupled to `PottsState.grid`, `PottsState.cell_data`, and
`PottsState.N_cells`; this is acknowledged production migration debt, not the revised Phase 4 exit
gate. Those consumers must move to explicit compiled state during the execution, component, and
algorithm phases before the old runtime can be removed.

## First migrated boundary

`PottsCache` now obtains its lattice through public `lattice_storage(state)`. Both `PottsState` and
`LogicalPottsState` implement that accessor, and a logical 2D state constructs a normal topology
cache in CorePotts tests. This is the pattern for remaining execution-only storage access: a small
documented boundary, not a compatibility property pretending that the logical state has legacy
fields.

## Remaining direct-field consumers

| Migration tranche | Current owners | Required boundary |
| --- | --- | --- |
| Proposal/intrinsics | `kernels/metropolis.jl`, `kernels/intrinsics.jl` | Compiled lattice/property execution view and proposal commit API |
| Tracker runtime | `components/trackers/trackers.jl` | Tracker workspace and rebuilt/incremental tracker view |
| Scientific components | energy files, `components/components.jl` | Semantic proposal/property access, then isolated backend lowering |
| Lifecycle/events | `kernels/events/*`, `lifecycle/*` | Compiled lifecycle workspace over fixed logical slots |
| SciML/output | `sciml/simulator.jl`, `state/backends.jl` | Snapshot and observation interface with explicit host transfer |
| Legacy construction | `initialization/initialization.jl`, `state/types.jl` | Final `PottsProblem` construction from `InitializedLogicalState` |

## Revised qualification rule

Phase 4 requires a CPU reference integration path that creates, steps, observes, and snapshots a
logical state without direct legacy-state fields. Available-GPU qualification verifies the compiled
storage view in later phases rather than adapting the host logical representation directly. This
audit remains the migration inventory for that work and does not claim the historical runtime has
already migrated.
