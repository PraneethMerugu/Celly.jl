# [CPMToolkit](@id cpmtoolkit-overview)

**CPMToolkit** is the recommended entry point for all CPM simulations.
It provides a declarative, high-level DSL that compiles to CoreCPM's internal
representation — you describe *what* biological rules apply to your cells;
CPMToolkit figures out *how* to implement them efficiently on the lattice.

```julia
using CPMToolkit   # this single import is all you need for most simulations
```

> [!IMPORTANT]
> `using CPMToolkit` re-exports **all public symbols from CoreCPM**, including topology
> types, algorithm constructors, callback types, and backend types.
> You never need to separately `using CoreCPM` in user code.

---

## The CellType / CPMSystem / Component Pattern

CPMToolkit uses a three-level declarative structure:

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
Each component corresponds to one or more CoreCPM penalty terms.

```julia
VolumeComponent(A => (λ = 5.0f0, target = 500), B => (λ = 5.0f0, target = 500))
HSTVolumeComponent(A => (λ = 5.0f0, target = 500); eta = 1.0)
SurfaceAreaComponent(A => (λ = 1.0f0, target = 200))
AdhesionComponent((A, Medium) => 15.0f0, (A, A) => 2.0f0, (A, B) => 10.0f0)
LengthComponent(A => (λ = 3.0f0, target = 20.0f0); eta = 1.0)
ChemotaxisComponent(A => 0.5f0, chemical_field = my_field)
```

See [Penalties](@ref corecpm-penalties) for the mathematical details behind each component.

### 3. CPMSystem

A `CPMSystem` bundles cell types and components into a complete model description:

```julia
sys = CPMSystem(
    [A, B, Medium],          # cell types
    [                        # components
        VolumeComponent(A => (λ=5.0f0, target=500), B => (λ=5.0f0, target=500)),
        AdhesionComponent((A, Medium) => 15.0f0, (A, B) => 10.0f0, (A, A) => 2.0f0,
                          (B, Medium) => 15.0f0, (B, B) => 2.0f0),
    ]
)
```

`CPMSystem` performs compile-time validation: it checks that all cell-type pairs
referenced in `AdhesionComponent` are declared, that parameter types are consistent,
and that conflicting components are not combined.

---

## CPMProblem: Compiling the System

`CPMProblem` takes a system description and concrete numerical parameters, then
compiles the system into CoreCPM's internal representation (penalty objects, trackers,
and initial lattice configuration):

```julia
prob = CPMProblem(
    sys,                    # CPMSystem
    Dict(A => 20, B => 20), # initial cell counts per type
    (200, 200);             # lattice dimensions (width × height)
    tspan    = (0, 500),    # simulation time span in MCS
    topology = VonNeumannTopology{2}(),  # default
    trackers = ()           # optional extra trackers
)
```

**Under the hood**, `CPMProblem` does the following:

1. Allocates the lattice array and initialises it by seeding cells as compact circular
   blobs placed on a regular grid.
2. Instantiates each component's CoreCPM penalty object with the compiled parameter
   arrays.
3. Registers the required trackers for each penalty (e.g. the volume tracker for
   `VolumeComponent`).
4. Wraps everything in a `SciMLBase.AbstractDEProblem`-compatible struct so that
   `solve`, `init`, and `step!` work as expected.

---

## Solving and the SciML Interface

CPMToolkit integrates with the SciML interface:

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
