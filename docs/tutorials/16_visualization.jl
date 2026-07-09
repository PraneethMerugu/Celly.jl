# # Visualization with MakiePotts
#
# MakiePotts is the dedicated visualisation layer for Potts.jl.  It
# provides three complementary tools: `pottsplot` for quick static snapshots,
# `record_potts` for polished video output, and `explore_cpm` for fully
# interactive parameter exploration.  All three are backend-agnostic — they
# work with GLMakie (native window), CairoMakie (publication PDFs/PNGs), and
# WGLMakie (Pluto/Jupyter notebooks).

# ## Packages

using PottsToolkit
using MakiePotts
using Statistics

# Choose a Makie backend — only one may be loaded at a time.
# using GLMakie     # interactive window (default for desktop)
using CairoMakie
CairoMakie.activate!()  # vector/raster for docs

# ## Build a simple model to visualise

A = CellType(:A)
B = CellType(:B)
Medium = CellType(:Medium)

sys = PottsSystem(
    [A, B, Medium],
    [
        VolumeComponent(
            A => (λ = 5.0f0, target = 500),
            B => (λ = 5.0f0, target = 500)
        ),
        AdhesionComponent(
            (A, Medium) => 16.0f0,
            (B, Medium) => 16.0f0,
            (A, A) => 2.0f0,
            (B, B) => 2.0f0,
            (A, B) => 14.0f0
        )
    ]
)

prob = PottsProblem(
    sys,
    Dict(A => 20, B => 20),
    (200, 200);
    tspan = (0, 600),
    topology = VonNeumannTopology{2}()
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
sol = solve(prob, alg; saveat = 30)

# ## 1. Static snapshot with pottsplot
#
# `pottsplot(state)` accepts any lattice array or integrator state and returns
# a `(fig, ax, plot_object)` triple following the Makie recipe convention.
# Use `fig` to save or display; `ax` to adjust axes labels and limits.

fig, ax, p = pottsplot(sol.u[end])
ax.title[] = "Final state — cell sorting"
save("pottsplot_snapshot.png", fig)

# ## 2. pottsplot! with custom colours
#
# `pottsplot!` is the mutating recipe: it draws into an *existing* Axis.
# Use `type_colors` to override the default colour palette.  Keys are the
# integer cell-type indices (0 = Medium, 1 = first type, …).

fig2 = Figure(resolution = (900, 900))
ax2 = Axis(fig2[1, 1]; title = "Custom colours")
pottsplot!(ax2, sol.u[end];
    type_colors = [:white, :tomato, :dodgerblue]
)
save("pottsplot_custom_colors.png", fig2)

# ## 3. record_potts — full parameter tour
#
# `record_potts` iterates over all saved frames in `sol` and writes each as a
# video frame.  The `metrics` keyword adds a side panel of time-series plots
# that update in sync with the lattice view.
#
# **Signature:**
# ```julia
# record_potts(filename, sol; metrics, framerate, resolution)
# ```
#
# - `filename`   — output path; extension determines format (.mp4, .gif, .webm)
# - `sol`        — PottsSolution (from MemoryBackend)
# - `metrics`    — `Vector` of `"Label" => (u -> scalar)` pairs
# - `framerate`  — integer frames per second
# - `resolution` — `(width, height)` in pixels

record_potts(
    "cell_sorting.mp4", sol;
    metrics = [
        "Mean Volume" => u -> begin
            n = u.N_cells[]
            n == 0 ? 0.0 : mean(Array(u.cell_data.volumes)[1:n])
        end,
        "N Cells" => u -> u.N_cells[],
        "Sorting Index" =>
            u -> begin
                lat = Array(u.grid)
                types = Array(u.cell_data.cell_types)
                n_same = 0;
                n_total = 0
                for I in CartesianIndices(lat)
                    id = lat[I];
                    id == 0 && continue
                    for dI in (CartesianIndex(1, 0), CartesianIndex(0, 1))
                        J = I + dI
                        checkbounds(Bool, lat, J) || continue
                        jd = lat[J];
                        jd == 0 && continue
                        n_total += 1
                        types[id] == types[jd] && (n_same += 1)
                    end
                end
                n_total == 0 ? 0.5 : n_same / n_total
            end
    ],
    framerate = 20,
    resolution = (1400, 900)
)

# ```@raw html
# <video autoplay loop muted playsinline controls src="./cell_sorting.mp4" width="100%"></video>
# ```

# ## 4. explore_cpm — interactive dashboard
#
# `explore_cpm` launches a live window (requires a GPU-capable backend such
# as GLMakie or WGLMakie).  Sliders trigger automatic re-solves; metric plots
# update in real time.  Only works with MemoryBackend.
#
# ```julia
# using GLMakie
# fig = explore_cpm(
#     prob, alg;
#     metrics = [
#         "Mean Volume" => u -> mean(Array(u.cell_data.volumes)[2:end]),
#         "N Cells"     => u -> u.N_cells[],
#     ],
#     parameters = [
#         "Temperature" => (
#             range  = 0.5f0:0.5f0:5.0f0,
#             start  = 2.0f0,
#             action = (prob, alg, val) ->
#                 CheckerboardMetropolis(T = val, sweeps_per_step = 10),
#         ),
#     ],
# )
# ```

# ## Backend compatibility summary
#
# | Backend    | pottsplot | record_potts | explore_cpm |
# |------------|:-------:|:----------:|:-----------:|
# | GLMakie    |    ✓    |     ✓      |      ✓      |
# | CairoMakie |    ✓    |     ✓      |      ✗*     |
# | WGLMakie   |    ✓    |     ✓      |      ✓      |
#
# *CairoMakie does not support interactive Observables sliders.
