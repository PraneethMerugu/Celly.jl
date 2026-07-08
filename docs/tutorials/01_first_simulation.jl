using CairoMakie
CairoMakie.activate!()

# # First Simulation
#
# Welcome to the Potts.jl tutorials. This first tutorial walks through
# every step of a complete Cellular Potts Model (Potts) simulation — from
# defining cell types to recording a movie — so you have a working mental
# model before diving into more specialised topics.

# ## Packages
#
# `PottsToolkit` is the single entry point for users. It re-exports the physics
# engine (`CorePotts`) automatically, so you never need to import `CorePotts`
# directly. `MakiePotts` adds visualisation and recording utilities.

using PottsToolkit
using MakiePotts

# ## Defining Cell Types
#
# A Potts universe is partitioned into named cell types. Every lattice site
# belongs to exactly one cell (or to the special `Medium` background). We
# represent this with `CellType` objects that carry a symbolic name.

TypeA = CellType(:TypeA)
Medium = CellType(:Medium)

# ## Building the Energy Model
#
# The Potts Hamiltonian is a sum of penalty terms. Here we use two:
#
# **VolumeComponent** — penalises deviation from a target volume.
# The parameter `λ` (lambda) is the stiffness: large λ means cells resist
# volume changes strongly. `target` is the preferred area in lattice sites.
#
# **AdhesionComponent** — sets the interfacial contact energy J between
# pairs of cell types. Lower J means the interface is energetically
# *favoured*, so cells of that pair tend to stick together.
# J(TypeA, Medium) is deliberately high so TypeA cells round up rather
# than spreading into the medium.

sys = PottsSystem(
    [TypeA, Medium],
    [
        VolumeComponent(TypeA => (λ = 5.0f0, target = 100)),
        AdhesionComponent(
            (TypeA, Medium) => 20.0f0,
            (TypeA, TypeA) => 2.0f0
        )
    ]
)

# ## Constructing the Problem
#
# `PottsProblem` binds a system to an initial cell count, a grid geometry, and
# a time span. The grid is 100 × 100 lattice sites. `tspan = (0, 300)` means
# we will run for 300 Monte Carlo Steps (MCS); one MCS is one full sweep of
# the lattice. We seed 10 TypeA cells placed randomly at t = 0.

prob = PottsProblem(
    sys,
    Dict(TypeA => 10),
    (100, 100);
    tspan = (0, 300),
    topology = VonNeumannTopology{2}()
)

# ## Choosing an Algorithm
#
# `CheckerboardMetropolis` divides the lattice into two interleaved
# checkerboard sub-lattices and updates them in alternating half-sweeps.
# This is the recommended default: it is GPU-compatible, embarrassingly
# parallel, and satisfies detailed balance. `T` is the Boltzmann temperature;
# `sweeps_per_step` controls how many full sweeps constitute one saved MCS.

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

# ## Solving
#
# `solve` runs the simulation and returns a `PottsSolution`. `saveat = 5` saves
# a snapshot every 5 MCS, giving us 60 frames over the 300-step run.

sol = solve(prob, alg; saveat = 5)

# ## Visualising the Result
#
# `record_potts` writes an MP4 using every saved snapshot as a frame. The
# `metrics` keyword overlays live scalar quantities on the side panel —
# here we track the total number of living cells and the mean cell volume.

record_potts(
    "01_first_simulation.mp4",
    sol;
    metrics = [
        "N Cells" => u -> u.N_cells[],
        "Mean Volume" => u -> begin
            vols = Array(u.cell_data.volumes)
            n = u.N_cells[]
            n > 0 ? sum(vols[1:n]) / n : 0.0
        end
    ],
    framerate = 20,
    resolution = (1200, 700)
)
