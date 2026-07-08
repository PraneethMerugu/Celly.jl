using CairoMakie
CairoMakie.activate!()

# # The PottsToolkit DSL
#
# PottsToolkit provides a **declarative domain-specific language** for building
# Cellular Potts Models.  Rather than subclassing types or overriding methods,
# you compose named *components* into a `PottsSystem`, and the toolkit compiles
# them into an efficient energy-evaluation kernel.  This tutorial is the
# authoritative reference for every built-in component, every topology, and
# the advanced escape hatch for injecting raw CorePotts penalties.

# ## Packages
#
# `using PottsToolkit` automatically re-exports all public CorePotts symbols, so
# there is never a need to `using CorePotts` directly in user code.

using PottsToolkit
using MakiePotts
using Statistics

# ## Step 1: Register cell types
#
# `CellType(:name)` creates a named label.  The special name `:Medium`
# conventionally marks the background (cell ID 0).  Order here has no effect
# on the simulation — the system sorts and validates internally.

A = CellType(:A)
B = CellType(:B)
Medium = CellType(:Medium)

# ## Step 2: Build components
#
# ### VolumeComponent
#
# Penalises deviations from a target area (2-D) / volume (3-D):
# `H = λ · (V − V_target)²`.  Every non-Medium cell type must receive
# parameters; Medium is conventionally given λ = 0.

vol = VolumeComponent(
    A => (λ = 5.0f0, target = 500),
    B => (λ = 5.0f0, target = 400),
    Medium => (λ = 0.0f0, target = 0)
)

# ### HSTVolumeComponent
#
# The *hard-soft threshold* variant applies a steep penalty only below a
# minimum area, mimicking the mechanical incompressibility of cytoplasm while
# allowing gentle expansion above the target.  Useful for crowded tissues.

hst_vol = HSTVolumeComponent(
    A => (λ = 5.0f0, target = 500);
    eta = 1.0    # controls steepness of the lower threshold
)

# ### SurfaceAreaComponent
#
# Penalises excess perimeter (2-D) or surface area (3-D):
# `H = λ · (P − P_target)²`.  Drives cells toward compact shapes.

surf = SurfaceAreaComponent(
    A => (λ = 1.0f0, target = 100),
    B => (λ = 1.0f0, target = 80)
)

# ### AdhesionComponent
#
# Contact energy between pairs of cell types:
# `H = Σ_{neighbours} J(τ_i, τ_j)`.  The system is symmetric — you only
# need to specify each unordered pair once.

adh = AdhesionComponent(
    (A, Medium) => 16.0f0,
    (B, Medium) => 16.0f0,
    (A, A) => 2.0f0,
    (B, B) => 2.0f0,
    (A, B) => 14.0f0
)

# ### LengthComponent
#
# Penalises deviations of the cell's *major-axis length* from a target,
# computed via the inertia-tensor eigendecomposition.  The `eta` parameter
# regularises the tensor for very small cells.

len = LengthComponent(
    A => (λ = 3.0f0, target = 20.0f0);
    eta = 1.0
)

# ### ChemotaxisComponent
#
# Biases copy attempts toward regions of high chemical concentration.
# The penalty change is: `ΔH_chem = −μ · ΔC`, where `μ` is the
# chemotactic sensitivity and `ΔC` is the concentration difference between
# source and target sites.  Provide a pre-computed field array.

chemical_field = rand(Float32, 200, 200)   # replace with your field

chem = ChemotaxisComponent(
    A => 0.5f0;
    chemical_field = chemical_field
)

# ## Step 3: Assemble the system
#
# `PottsSystem` validates that every cell type referenced in a component has
# been registered, checks for duplicate components, and pre-compiles the
# energy kernel.

sys = PottsSystem(
    [A, B, Medium],
    [vol, surf, adh, len]
)

# ## Step 4: Build the problem
#
# `PottsProblem` places the initial cell configuration, sets the grid size,
# time span, topology, and optional trackers.
#
# ### Topology options
#
# | Type                           | Connectivity | Boundaries |
# |--------------------------------|:------------:|:----------:|
# | `VonNeumannTopology{2}()`      | 4-connected  | periodic   |
# | `MooreTopology{2}()`           | 8-connected  | periodic   |
# | `NoFluxVonNeumannTopology{2}()`| 4-connected  | rigid      |
# | `NoFluxMooreTopology{2}()`     | 8-connected  | rigid      |
# | `ExtendedVonNeumannTopology{2,2}()` | 12-conn | periodic   |
# | `VonNeumannTopology{3}()`      | 6-connected  | periodic 3D|

prob = PottsProblem(
    sys,
    Dict(A => 20, B => 20),
    (200, 200);
    tspan = (0, 600),
    topology = VonNeumannTopology{2}(),
    trackers = ()
)

# ## Step 5: Algorithm selection

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
# alg = ParallelMetropolis(T = 2.0f0, sweeps_per_step = 10)
# alg = SequentialMetropolis(T = 2.0f0, sweeps_per_step = 10)

# ## Advanced: raw CorePotts penalty escape hatch
#
# If you need a penalty not (yet) wrapped in a PottsToolkit component, you can
# subtype `CorePotts.AbstractPenalty` directly and pass it inside a component
# list.  PottsSystem treats any AbstractPenalty as a first-class component.
# This keeps bespoke physics self-contained without forking the library.
#
# ```julia
# import CorePotts: AbstractPenalty, delta_H
# struct MyCustomPenalty <: AbstractPenalty end
# CorePotts.delta_H(p::MyCustomPenalty, src, dst, state) = 0.0f0  # your logic
# sys = PottsSystem([A, Medium], [vol, adh, MyCustomPenalty()])
# ```

# ## Solve and visualise

sol = solve(prob, alg; saveat = 20)

record_potts(
    "pottstoolkit_dsl_demo.mp4", sol;
    metrics = [
        "Mean Volume A" => u -> begin
        types = Array(u.cell_data.cell_types)
        vols = Array(u.cell_data.volumes)
        n = u.N_cells[]
        idx = findall(==(1), types[1:n])
        isempty(idx) ? 0.0 : mean(vols[idx])
    end,
    ],
    framerate = 20,
    resolution = (1200, 800)
)
