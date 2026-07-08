using CairoMakie
CairoMakie.activate!()

# # Epithelial Sheet & Tissue Mechanics
#
# Epithelial monolayers are the fundamental structural unit of organs such as
# the gut, skin, and lung. Their mechanical properties — stiffness, cohesion,
# and resistance to shear — emerge from the interplay between cell-cell
# adhesion and cytoskeletal tension. A widely used theoretical framework for
# epithelial mechanics is the *vertex model*, but the Potts captures similar
# physics at the level of individual lattice sites, making it straightforward
# to model irregular cell shapes and topological rearrangements (T1/T2
# transitions) without explicit bookkeeping.
#
# In this tutorial we tile a 150 × 150 grid with epithelial cells and
# demonstrate how SurfaceAreaComponent combined with VolumeComponent produces
# a mechanically stable sheet where cells resist both compression and
# stretching.

# ## Packages

using PottsToolkit
using MakiePotts
using Statistics: mean, std

# ## Cell Types
#
# A single epithelial cell type plus the background medium.

Epithelial = CellType(:Epithelial)
Medium = CellType(:Medium)

# ## Energy Model — Volume, Surface Area, and Adhesion
#
# Three components define the mechanical energy of an epithelial sheet:
#
# **VolumeComponent**: incompressibility — cells resist area changes with
# stiffness λ_V = 5.0. Target volume ≈ 100 sites ≈ a 10×10 pixel cell.
#
# **SurfaceAreaComponent**: cortical tension — penalises deviation of the
# cell perimeter from the target value. λ_S = 1.0 is kept lower than λ_V
# to allow cell shape fluctuations while maintaining overall area. A target
# perimeter of 40 corresponds to a roughly circular cell of area 100.
#
# **AdhesionComponent**: cell-cell stickiness. Low J(Epithelial,Epithelial)
# relative to J(Epithelial,Medium) ensures that cells prefer to be in
# contact with each other, forming the coherent sheet. If J(cell,cell) were
# made larger, the sheet would fragment into isolated rounded-up cells.

sys = PottsSystem(
    [Epithelial, Medium],
    [
        VolumeComponent(
            Epithelial => (λ = 5.0f0, target = 100),
        ),
        SurfaceAreaComponent(
            Epithelial => (λ = 1.0f0, target = 40),
        ),
        AdhesionComponent(
            (Epithelial, Epithelial) => 3.0f0,
            (Epithelial, Medium) => 18.0f0
        )
    ]
)

# ## Problem — Dense Monolayer
#
# 180 cells on a 150 × 150 grid gives an average spacing consistent with a
# confluent monolayer (coverage fraction ≈ 180 × 100 / 22500 ≈ 0.8). We run
# for 800 MCS to allow the initial random seed to relax to a tessellation.

prob = PottsProblem(
    sys,
    Dict(Epithelial => 180),
    (150, 150);
    tspan = (0, 800),
    topology = VonNeumannTopology{2}()
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

sol = solve(prob, alg; saveat = 8)

# ## Interactive Exploration
#
# `explore_cpm` launches a live dashboard where you can scrub through
# simulation time and watch metrics update in real time. The volume standard
# deviation is a useful mechanical readout: a small σ_V indicates a
# mechanically homogeneous sheet, while large σ_V suggests force
# heterogeneity or cell-size polydispersity — both biologically relevant
# in diseased epithelia.

fig = explore_cpm(
    prob, alg;
    metrics = [
        "N Cells" => u -> u.N_cells[],
        "Mean Volume" => u -> mean(Array(u.cell_data.volumes)[1:u.N_cells[]]),
        "σ Volume" => u -> std(Array(u.cell_data.volumes)[1:u.N_cells[]]),
        "Mean Perimeter" =>
            u -> begin
                n = u.N_cells[]
                n > 0 ? mean(Array(u.cell_data.surface_areas)[1:n]) : 0.0
            end
    ],
    parameters = [
        "Temperature" => (
        range = 0.5f0:0.5f0:6.0f0,
        start = 2.0f0,
        action = (prob, alg, val) -> CheckerboardMetropolis(T = val, sweeps_per_step = 10)
    ),
    ]
)
