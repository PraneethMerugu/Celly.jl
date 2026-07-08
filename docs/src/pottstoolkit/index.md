# [PottsToolkit](@id pottstoolkit-overview)

**PottsToolkit** is the recommended entry point for all Potts simulations.
It provides a declarative, high-level DSL that compiles to CorePotts's internal
representation — you describe *what* biological rules apply to your cells;
PottsToolkit figures out *how* to implement them efficiently on the lattice.

```julia
using PottsToolkit   # this single import is all you need for most simulations
```

> [!IMPORTANT]
> `using PottsToolkit` re-exports **all public symbols from CorePotts**, including topology
> types, algorithm constructors, callback types, and backend types.
> You never need to separately `using CorePotts` in user code.

---

## The CellType / PottsSystem / Component Pattern

PottsToolkit uses a three-level declarative structure:

### 1. CellType

A `CellType` is a named token that labels a population of cells.
Cell types determine which penalty parameters apply to which cells.

```julia
A      = CellType(:A)
B      = CellType(:B)
Medium = CellType(:Medium)
```

There is always at least one `Medium` type representing the background lattice.
`CellType` objects are purely symbolic — they carry no state.

### 2. Components

Components attach biophysical rules to cell types.
Each component corresponds to one or more CorePotts penalty terms.

```julia
VolumeComponent(A => (λ = 5.0f0, target = 500), B => (λ = 5.0f0, target = 500))
HSTVolumeComponent(A => (λ = 5.0f0, target = 500); eta = 1.0)
SurfaceAreaComponent(A => (λ = 1.0f0, target = 200))
AdhesionComponent((A, Medium) => 15.0f0, (A, A) => 2.0f0, (A, B) => 10.0f0)
LengthComponent(A => (λ = 3.0f0, target = 20.0f0); eta = 1.0)
ChemotaxisComponent(A => 0.5f0, chemical_field = my_field)
```

See [Penalties](@ref corepotts-penalties) for the mathematical details behind each component.

### 3. PottsSystem

A `PottsSystem` bundles cell types and components into a complete model description:

```julia
sys = PottsSystem(
    [A, B, Medium],          # cell types
    [                        # components
        VolumeComponent(A => (λ=5.0f0, target=500), B => (λ=5.0f0, target=500)),
        AdhesionComponent((A, Medium) => 15.0f0, (A, B) => 10.0f0, (A, A) => 2.0f0,
                          (B, Medium) => 15.0f0, (B, B) => 2.0f0),
    ]
)
```

`PottsSystem` performs compile-time validation: it checks that all cell-type pairs
referenced in `AdhesionComponent` are declared, that parameter types are consistent,
and that conflicting components are not combined.

---

## PottsProblem: Compiling the System

`PottsProblem` takes a system description and concrete numerical parameters, then
compiles the system into CorePotts's internal representation (penalty objects, trackers,
and initial lattice configuration):

```julia
prob = PottsProblem(
    sys,                    # PottsSystem
    Dict(A => 20, B => 20), # initial cell counts per type
    (200, 200);             # lattice dimensions (width × height)
    tspan    = (0, 500),    # simulation time span in MCS
    topology = VonNeumannTopology{2}(),  # default
    trackers = ()           # optional extra trackers
)
```

**Under the hood**, `PottsProblem` does the following:

1. Allocates the lattice array and initialises it by seeding cells as compact circular
   blobs placed on a regular grid.
2. Instantiates each component's CorePotts penalty object with the compiled parameter
   arrays.
3. Registers the required trackers for each penalty (e.g. the volume tracker for
   `VolumeComponent`).
4. Wraps everything in a `SciMLBase.AbstractDEProblem`-compatible struct so that
   `solve`, `init`, and `step!` work as expected.

---

## Solving and the SciML Interface

PottsToolkit integrates with the SciML interface:

```julia
# One-shot solve
sol = solve(prob, alg; saveat = 10)

# Manual stepping (advanced)
integrator = init(prob, alg; saveat = 10)
for i in 1:100
    step!(integrator)
    # inspect integrator.u here
end
```

The solution object `sol` supports:
- `sol[t]` — access the saved state at time `t`.
- `sol.t` — vector of saved time points.
- Iteration over all saved frames.

---

## Cell-Event Callbacks

Growth, mitosis, and death are modelled as SciML callbacks composed with
`SciMLBase.CallbackSet`:

```julia
using SciMLBase

growth_cb = LinearGrowthCallback(0.5f0)    # +0.5 volume/MCS

trigger    = VolumeThresholdTrigger(2.0f0)
mitosis_cb = MitosisCallback(trigger;
    orientation       = RandomOrientation(),
    inheritance_rules = (target_volumes = Split(0.5f0),),
)

death_cb = DeathCallback((cell_id, cell_data) ->
    cell_data.cell_types[cell_id] == 3     # kill cells of type 3
)

cb = SciMLBase.CallbackSet(
    SciMLBase.DiscreteCallback((u, t, i) -> true, i -> growth_cb(i)),
    mitosis_cb,
    death_cb,
)

sol = solve(prob, alg; saveat = 10, callback = cb)
```

---

## Full Component Reference

| Component | Key parameters | HST variant? |
|-----------|---------------|-------------|
| `VolumeComponent` | `λ`, `target` | `HSTVolumeComponent` (+ `eta`) |
| `SurfaceAreaComponent` | `λ`, `target` | HST internally |
| `AdhesionComponent` | cell-type pair ⇒ energy | — |
| `LengthComponent` | `λ`, `target`, `eta` | Always HST |
| `ChemotaxisComponent` | sensitivity, `chemical_field` | — |
