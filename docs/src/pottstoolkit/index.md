# [PottsToolkit](@id pottstoolkit-overview)

**PottsToolkit** is the recommended entry point for all Potts simulations.
It provides a declarative, high-level modeling API that compiles to CorePotts's internal
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
Medium = CellType(:Medium, is_background=true)   # background must be marked explicitly
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
    cell_types = [Medium, A, B],     # background type listed first by convention
    penalties  = [
        VolumeComponent(A => (λ=5.0f0, target=500), B => (λ=5.0f0, target=500)),
        AdhesionComponent((A, Medium) => 15.0f0, (A, B) => 10.0f0, (A, A) => 2.0f0,
                          (B, Medium) => 15.0f0, (B, B) => 2.0f0),
    ],
    events = [
        # See the Biological Events API guide for details on how to configure
        # Apoptosis, Mitosis, and Transitions!
    ],
    check_interval = 10
)
```

`PottsSystem` performs compile-time validation: it checks that all cell-type pairs
referenced in `AdhesionComponent` are declared, that parameter types are consistent,
and that conflicting components are not combined.

For more information on the new declarative event system for modeling discrete topological changes like death and division, see the [Biological Events API](events.md) guide.

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

1. Converts `Dict(CellType => count)` into a `RandomLayout` — which uniformly scatters
   the requested number of cells across the grid randomly.
2. Calls `build_initial_state` to populate the lattice from the layout, assigning
   cell IDs sequentially from `1`.
3. Calls `initialize_metrics!` to perform a single O(|Λ|) scan that syncs all
   tracker arrays (volume, surface area, etc.) from the actual lattice contents.
4. Instantiates each component's CorePotts penalty object with the compiled parameter
   arrays, keyed by type ID.
5. Wraps everything in a `SciMLBase.AbstractDEProblem`-compatible struct so that
   `solve`, `init`, and `step!` work as expected.

### Custom Layouts

By default `PottsProblem` places cells via `RandomLayout`, which distributes
them randomly. For structured initialization (like spheroids or confluent sheets), pass an explicit layout:

```julia
using PottsToolkit: HypersphereLayout

# Explicit layout — override the default radius computation
layout = HypersphereLayout(
    Dict(A => 20, B => 20),
    (200, 200);
    radius = 8.0f0    # each cell is a disc of radius 8 lattice sites
)

prob = PottsProblem(sys, layout, (200, 200); tspan = (0, 500))
```

Any `AbstractLayout` subtype can be passed here, making it straightforward to implement
e.g. stripe initializations, confined geometries, or data-driven initial conditions.

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

# Type IDs are 1-based and assigned to non-background types in declaration order.
# With `cell_types = [Medium, A, B]`: A has type ID 1, B has type ID 2.
death_cb = DeathCallback((cell_id, cell_data) ->
    cell_data.cell_types[cell_id] == 2     # kill cells of type B (type ID = 2)
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
