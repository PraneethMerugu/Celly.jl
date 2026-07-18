# Phase 6 Legacy Quarantine

Status: Frozen for Phase 7 replacement

## Boundary

The Phase 6 scientific path consists of:

- `spatial/cartesian.jl`
- `protocols/scientific.jl`
- every `components/scientific_*.jl` source
- the logical/compiled state and Phase 5 execution contracts they consume
- `qualify_scientific_backend`, which exercises this path directly

These sources do not dispatch through the historical concrete penalties, topology presets,
`MetropolisSampler`, positional tracker tuples, or `evaluate_penalty` closures. The generic
`ScientificComponentSet` folds only the explicit semantic categories `AbstractEnergy`,
`AbstractDrive`, `AbstractHardConstraint`, and `AbstractKineticModifier` over one
`ScientificProposalContext`.

## Quarantined Inventory

The following sources remain executable only because Phase 7 must compare and replace the existing
algorithms atomically:

- `topology/topology.jl`
- `proposals/samplers.jl`
- `components/components.jl`, `components/energies/`, `components/constraints/`, and
  `components/trackers/`
- `kernels/metropolis.jl` and `kernels/intrinsics.jl`
- the historical `PottsState`, `PottsParameters`, `PottsCache`, and algorithm constructors
- legacy workload construction below the Phase 6 qualification code in
  `benchmark/src/PottsBenchmarks.jl`

No Phase 6 implementation may add a call from the scientific path into this inventory. Phase 7
must delete the corresponding legacy component, tracker, topology, sampler, and kernel route when
its final algorithm replacement becomes executable. Compatibility wrappers and migration guides
are not required before the paper API freeze.

## Enforcement

Review and completion audits search the Phase 6 sources for concrete historical names including
`VolumePenalty`, `AdhesionPenalty`, `ChemotaxisPenalty`, `FocalPointSpringPenalty`,
`MetropolisSampler`, `MooreTopology`, `SurfaceAreaTracker`, `evaluate_penalty`, `PottsParameters`,
and `PottsCache`. `OwnershipVolumeTracker` is a Phase 6 semantic tracker and is not the historical
`VolumeTracker`.

The quarantine is intentionally read-only. Bug fixes required only to preserve historical behavior
wait for replacement unless they block comparison evidence or repository safety.
