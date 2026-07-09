using CairoMakie
CairoMakie.activate!()

# # Directed Migration (Chemotaxis)
#
# Directed cell migration along chemical gradients — chemotaxis — is
# central to wound healing, immune surveillance, embryonic morphogenesis, and
# cancer metastasis. Neutrophils, for example, follow bacterial
# *N*-formylmethionine peptide gradients over millimetre distances to reach
# infection sites within minutes. In the Potts, chemotaxis is implemented as a
# bias on the Metropolis copy attempt: moves that advance a cell's centre of
# mass up the gradient receive an extra energy reduction proportional to χ
# (chi), the chemotactic sensitivity.

# ## Packages

using PottsToolkit
using MakiePotts

# ## Cell Type
#
# We model a single neutrophil-like cell type migrating through an inert
# medium toward a chemoattractant source at the right edge of the domain.

Neutrophil = CellType(:Neutrophil)
Medium = CellType(:Medium)

# ## Chemical Gradient Field
#
# The chemoattractant concentration is a static `Float32` matrix that lives
# on the same lattice as the cells. Here we construct a simple left-to-right
# linear gradient: concentration is 0 at x = 1 and 1 at x = W. In a more
# realistic scenario this field would be solved from a reaction-diffusion PDE,
# but a linear field suffices to demonstrate directed migration cleanly.
#
# The field array has dimensions (height, width) = (rows, cols) to match
# Julia's column-major layout and the Potts grid convention.

const W = 200   # grid width  (x direction — gradient direction)
const H = 100   # grid height (y direction)

gradient_field = Float32[j / W for i in 1:H, j in 1:W]

# ## Energy Model
#
# `ChemotaxisComponent` takes a per-cell-type sensitivity χ and the
# pre-computed field. Positive χ drives cells up the gradient (toward higher
# concentration). We combine it with a VolumeComponent so cells maintain a
# target area, and a modest AdhesionComponent so the cell boundary stays
# compact while migrating.

sys = PottsSystem(
    [Neutrophil, Medium],
    [
        VolumeComponent(Neutrophil => (λ = 8.0f0, target = 200)),
        AdhesionComponent(
            (Neutrophil, Medium) => 20.0f0,
            (Neutrophil, Neutrophil) => 2.0f0
        ),
        ChemotaxisComponent(Neutrophil => 10000.0f0, chemical_field = gradient_field)
    ]
)

# ## Problem
#
# We place 5 neutrophils near the left edge of a 200 × 100 grid and run for
# 600 MCS. `saveat = 5` gives smooth playback at 24 fps.

prob = PottsProblem(
    sys,
    Dict(Neutrophil => 5),
    (H, W);
    tspan = (0, 1500),
    topology = VonNeumannTopology{2}()
)

alg = CheckerboardMetropolis(T = 1.5f0, sweeps_per_step = 10)

sol = solve(prob, alg; saveat = 5)

# ## Visualisation
#
# The "Mean X Position" metric tracks the average x-coordinate of all
# neutrophil pixels. Over time it should shift rightward as cells migrate
# up the gradient, providing a quantitative readout of directional bias.

record_potts(
    "03_directed_migration.mp4",
    sol;
    metrics = [
        "N Cells" => u -> u.N_cells[],
        "Mean X Pos" => u -> begin
            grid = Array(u.grid)
            xs = [col for (row, col) in Tuple.(findall(>(0), grid))]
            isempty(xs) ? 0.0 : sum(xs) / length(xs)
        end
    ],
    framerate = 24,
    resolution = (1300, 700)
)

# ```@raw html
# <video autoplay loop muted playsinline controls src="../03_directed_migration.mp4" width="100%"></video>
# ```
