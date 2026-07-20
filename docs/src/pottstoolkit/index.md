# [PottsToolkit](@id pottstoolkit-overview)

PottsToolkit is the high-level, typed modeling interface for Potts.jl. A model is an immutable
scientific value: declare biological identities and components, inspect or validate the normalized
meaning, then lower it to a concrete [`CorePotts.PottsProblem`](@ref).

PottsToolkit deliberately does not re-export CorePotts. This keeps the API levels visible:

- Level 1 will provide the concise DSL syntax.
- Level 2 is the public PottsToolkit authoring API documented here.
- Level 3 is direct composition with public CorePotts scientific components.
- Level 4 is CorePotts protocol extension and engine development.

## A complete model

```julia
using PottsToolkit
import CorePotts

medium = Medium(:Medium)
cell = CellType(:Cell)

volume = VolumeConstraint(cell => (target = 16.0, strength = 2.0))
adhesion = Adhesion(
    (medium, medium) => 0.0,
    (medium, cell) => 8.0,
    (cell, cell) => 3.0,
)
model = PottsModel(medium, cell, volume, adhesion)

mask = falses(24, 24)
mask[10:13, 10:13] .= true
prob = problem(model, (24, 24), CellLayout(cell, 1, mask);
    capacity = 8, tspan = (0, 20), seed = 2026)
sol = CorePotts.solve(prob, CorePotts.SequentialCPM(temperature = 2.0f0))
```

`problem` returns CorePotts's problem directly. PottsToolkit introduces no runtime problem wrapper,
backend branch, or second execution engine.

## Scientific components

The preferred Level 2 spellings are ordinary immutable Julia values:

| Family | Declaration | Meaning |
|:--|:--|:--|
| Finite-cell volume | `VolumeConstraint` | Exact quadratic volume Hamiltonian |
| Fluctuating volume | `FluctuatingVolumeConstraint` | Named mechanical pressure process |
| Cell boundary | `BoundaryConstraint` | Exact quadratic edge-count or physical boundary measure |
| Fluctuating boundary | `FluctuatingBoundaryConstraint` | Named mechanical surface-tension process |
| Elongation | `Elongation` | Exact major-axis RMS Hamiltonian using unwrapped first and second moments |
| Contact | `Adhesion` | Symmetric unordered contact-energy law |
| Connectivity | `PreserveConnectivity` | Optional exact rejection of fragmenting copies |
| Prescribed field | `PrescribedField` | Immutable field snapshot with explicit interpolation and boundary semantics |
| Chemotaxis | `Chemotaxis` | Nonconservative drive with explicit response and responding-owner mode |

Fragmentation is valid unless `PreserveConnectivity()` is present. Elongation automatically requests
the required all-active moment tracker; it does not imply connectivity, so network models normally
declare both independently.

## Lifecycle declarations

`Growth`, `PropertyUpdate`, `StochasticPropertyUpdate`, `Transition`, `Division`, `ShrinkDeath`, and
`ImmediateDeath` lower to the compiled CorePotts lifecycle. Schedules use integer MCS boundaries and
all rules due at one boundary read the same pre-event snapshot.

Division inheritance is explicit. For example, an elongation target can declare
`target_division = CorePotts.CloneOnDivision()`. The default unsupported policy prevents a model
from silently inventing a daughter-cell law.

## Inspection before execution

```julia
validation = validate(model)
normalized = normalize(model)
report = explain(normalized)
deps = dependencies(normalized)
identity = semantic_fingerprint(normalized)
lowered = lower(model; dimensions = 2)
```

These operations are host-only. Reports, dependency edges, provenance, and semantic fingerprints
are derived from the same normalized model that is lowered, avoiding a separate documentation or
compiler interpretation.

Before allocating a backend integrator, inspect the complete execution combination:

```julia
using KernelAbstractions

algorithm = CorePotts.SequentialCPM(temperature = 2.0f0)
backend_report(prob, algorithm, KernelAbstractions.CPU())
```

Backend preflight checks the algorithm, component capabilities, lifecycle, dimensionality, and
tracker requirements as one contract.

## Open Level 3 composition

Any conforming `CorePotts.AbstractEnergy`, `AbstractDrive`, `AbstractHardConstraint`,
`AbstractKineticModifier`, or `AbstractMechanicalComponent` may be placed directly in `PottsModel`.
Its public CorePotts metadata participates in validation, reports, fingerprints, property-schema
merging, and lowering without a PottsToolkit compiler edit. Use `NamedCoreComponent` only when
multiple semantic instances need distinct Level 2 identities.

See [Reference Models](@ref pottstoolkit-reference-models) for reusable workloads and the
[API Reference](@ref pottstoolkit-api) for the complete surface.
