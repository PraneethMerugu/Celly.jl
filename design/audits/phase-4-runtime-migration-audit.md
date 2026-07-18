# Phase 4 Runtime Migration Audit

Status: Active

## Finding

The Phase 4 logical state is complete as a CPU scientific representation, but the historical
simulation path remains physically coupled to `PottsState.grid`, `PottsState.cell_data`, and
`PottsState.N_cells`. It cannot be described as migrated until those execution consumers operate on
an explicit compiled storage boundary rather than direct struct fields.

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

## Qualification rule

The final Phase 4 gate will not be marked complete merely because legacy names are deprecated. It
requires a CPU public integration path that creates, steps, observes, and snapshots a logical state
without direct legacy-state fields; available-GPU qualification then verifies the compiled storage
view rather than adapting the host logical representation directly.
