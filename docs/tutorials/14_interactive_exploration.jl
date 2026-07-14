using CairoMakie
CairoMakie.activate!()

# # Interactive Dashboard with explore_potts
#
# Writing code, re-running a simulation, and squinting at a static plot is a
# slow feedback loop for parameter tuning.  `explore_potts` replaces this cycle
# with a live, reactive dashboard: adjust a slider, and the full simulation
# re-runs automatically while metric plots update in real time.  This tutorial
# builds a cell-sorting model and walks through every feature of the dashboard.

# ## Packages

using PottsToolkit
using MakiePotts
using Statistics

# ## Model definition
#
# Two cell populations (A and B) with differential adhesion.  The sorting
# behaviour is exquisitely sensitive to temperature and the A–B adhesion
# energy — exactly the parameters we will expose as interactive sliders.

A = CellType(:A)
B = CellType(:B)
Medium = CellType(:Medium, is_background = true)

sys = PottsSystem(
    cell_types = [Medium, A, B],
    penalties = [
        VolumeComponent(
            A => (λ = 5.0f0, target = 500),
            B => (λ = 5.0f0, target = 500)
        ),
        AdhesionComponent(
            (A, Medium) => 16.0f0,
            (B, Medium) => 16.0f0,
            (A, A) => 2.0f0,
            (B, B) => 2.0f0,
            (A, B) => 14.0f0   # heterotypic — start high for sorting
        )
    ]
)

prob = PottsProblem(
    sys,
    Dict(A => 25, B => 25),
    (200, 200);
    tspan = (0, 600),
    topology = VonNeumannTopology{2}()
)

# ## Metric definitions
#
# A metric is a `"Label" => function` pair.  The function receives the
# current *integrator state* `u` — a mutable struct with fields:
# - `u.N_cells[]`          — current live cell count (RefValue)
# - `u.cell_data.volumes`  — GPU/CPU array of per-cell volumes
# - `u.cell_data.types`    — array of cell-type indices
# - `u.grid`               — the 2-D lattice (CuArray or Array)
#
# Metrics are plotted in a time-series panel beneath the lattice view.

metrics = [
    "Mean Volume" => u -> begin
        n = u.N_cells[]
        n == 0 ? 0.0 : mean(Array(u.cell_data.volumes)[1:n])
    end,
    "N Cells" => u -> u.N_cells[],
    "Sorting Index" => u -> begin
        ## Fraction of A-cell neighbours that are also A
        lat = Array(u.grid)
        types = Array(u.cell_data.cell_types)
        n_same = 0;
        n_total = 0
        for I in CartesianIndices(lat)
            id = lat[I]
            id == 0 && continue
            for dI in (CartesianIndex(1, 0), CartesianIndex(0, 1))
                J = I + dI
                checkbounds(Bool, lat, J) || continue
                jd = lat[J]
                jd == 0 && continue
                n_total += 1
                types[id] == types[jd] && (n_same += 1)
            end
        end
        n_total == 0 ? 0.5 : n_same / n_total
    end
]

# ## Parameter definitions
#
# A parameter is a `"Label" => NamedTuple` where:
# - `range`  — the slider step range (must be a StepRange of the correct type)
# - `start`  — initial slider value
# - `action` — a three-argument function `(prob, alg, val) -> new_alg_or_prob`
#              that returns a *new* algorithm (or modified problem) for each
#              slider position.  The dashboard re-solves from scratch.
#
# The adhesion J slider rebuilds the entire PottsSystem with the new J_AB value.
# This is intentional: the `action` closure has full Julia power available.

parameters = [
    "Temperature" => (
        range = 0.5f0:0.5f0:6.0f0,
        start = 2.0f0,
        action = (prob, alg, val) -> CheckerboardMetropolis(T = val, sweeps_per_step = 10)
    ),
    "Adhesion J_AB" => (
        range = 2.0f0:2.0f0:30.0f0,
        start = 14.0f0,
        action = (prob, alg, val) -> begin
            ## Rebuild the system with the new heterotypic adhesion energy
            new_sys = PottsSystem(
                cell_types = [Medium, A, B],
                penalties = [
                    VolumeComponent(
                        A => (λ = 5.0f0, target = 500),
                        B => (λ = 5.0f0, target = 500)
                    ),
                    AdhesionComponent(
                        (A, Medium) => 16.0f0,
                        (B, Medium) => 16.0f0,
                        (A, A) => 2.0f0,
                        (B, B) => 2.0f0,
                        (A, B) => val
                    )
                ]
            )
            ## Return the same algorithm; the dashboard detects the system change
            CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
        end
    )
]

# ## Dashboard layout
#
# The explore_potts window is organised as follows:
#
# ┌─────────────────────────────────┐
# │       Lattice (grid view)       │
# ├──────────────┬──────────────────┤
# │  Mean Volume │  Sorting Index   │  ← metric time-series
# ├──────────────┴──────────────────┤
# │  Temperature  [======●===]      │  ← sliders
# │  Adhesion J   [===●======]      │
# └─────────────────────────────────┘
#
# Note: explore_potts uses MemoryBackend internally.  Out-of-core backends
# (ZarrBackend, HDF5Backend) are not supported in interactive mode because
# the dashboard needs to replay saved frames in random order.

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

fig = explore_potts(
    prob, alg;
    metrics = metrics,
    parameters = parameters
)
