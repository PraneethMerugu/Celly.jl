# [MakiePotts](@id makiepotts-overview)

**MakiePotts** provides visualization tools for Potts simulations built on top of
[Makie.jl](https://docs.makie.org).
It offers three main entry points:

| Function | Purpose |
|----------|---------|
| `pottsplot` / `pottsplot!` | Static plot of a single simulation state |
| `explore_cpm` | Interactive dashboard with live re-simulation |
| `record_potts` | Render a simulation solution to a video file |

```julia
using MakiePotts
```

> [!NOTE]
> MakiePotts uses Makie's backend-agnostic recipe system. Load a Makie backend
> (`using GLMakie`, `using CairoMakie`, or `using WGLMakie`) before calling MakiePotts
> functions. For interactive features (`explore_cpm`) you need `GLMakie` or `WGLMakie`.

---

## `pottsplot` — Static State Plot

`pottsplot` is a full Makie plot recipe that renders a single Potts lattice state as a
colour-coded image, where each cell type is assigned a distinct colour.

```julia
using GLMakie, MakiePotts

# Plot the final state of a solution
state = sol[end]
fig, ax, p = pottsplot(state)

# Plot with custom colormap and figure options
fig, ax, p = pottsplot(state;
    colormap  = :tab20,
    show_grid = false,
)
display(fig)
```

`pottsplot!` is the mutating variant for composing into an existing `Axis`:

```julia
fig = Figure(resolution = (800, 800))
ax  = Axis(fig[1, 1], aspect = DataAspect())
pottsplot!(ax, state)
display(fig)
```

Both functions return a `(Figure, Axis, Plot)` tuple compatible with all standard
Makie interactions (zooming, panning, saving with `save`).

---

## `record_potts` — Video Recording

`record_potts` iterates over all saved frames of a `solve` solution and renders them to
a video file (MP4, GIF, or any format supported by Makie's `record`).

```julia
record_potts("output.mp4", sol;
    framerate  = 30,
    resolution = (1400, 900),
    metrics    = [
        "Mean Volume" => u -> mean(Array(u.cell_data.volumes)[1:u.N_cells[]]),
        "N Cells"     => u -> u.N_cells[],
    ],
)
```

**Arguments:**

- `filename` — output path; extension determines format (`.mp4`, `.gif`, `.mov`).
- `sol` — the solution object from `solve`.
- `framerate` — frames per second in the output video.
- `resolution` — pixel resolution `(width, height)` of the video.
- `metrics` — optional list of `"Label" => function` pairs. Each function receives the
  current simulation state and returns a scalar. Metrics are plotted as time-series
  panels below the lattice animation.

**Metrics panel:**

When `metrics` is non-empty, the video is split into a top panel (the lattice) and one
sub-panel per metric showing its evolution over time, with the current frame highlighted.
This is useful for tracking cell count, mean volume, mean speed, or any other summary
statistic alongside the spatial view.

```julia
record_potts("growth.mp4", sol;
    framerate = 24,
    metrics   = [
        "N Cells"     => u -> u.N_cells[],
        "Mean Volume" => u -> mean(Array(u.cell_data.volumes)[1:u.N_cells[]]),
        "Max Volume"  => u -> maximum(Array(u.cell_data.volumes)[1:u.N_cells[]]),
    ],
)
```

---

## `explore_cpm` — Interactive Dashboard

`explore_cpm` launches a live interactive Makie window where you can adjust simulation
parameters with sliders or menus and immediately see the effect on the simulation,
all without leaving Julia.

```julia
using GLMakie, MakiePotts, Statistics

fig = explore_cpm(prob, alg;
    metrics = [
        "Mean Volume" => u -> mean(Array(u.cell_data.volumes)[1:u.N_cells[]]),
        "N Cells"     => u -> u.N_cells[],
    ],
    parameters = [
        "Temperature" => (
            range  = 0.5f0:0.5f0:5.0f0,
            start  = 2.0f0,
            action = (prob, alg, val) -> CheckerboardMetropolis(T=val, sweeps_per_step=10)
        ),
        "λ_volume" => (
            range  = 1.0f0:1.0f0:20.0f0,
            start  = 5.0f0,
            action = (prob, alg, val) -> begin
                # Rebuild the problem with updated λ
                # (user-defined action, full flexibility)
                prob
            end
        ),
    ],
)
```

**How it works:**

- Each `parameters` entry creates a slider or dropdown in the dashboard sidebar.
- When a slider is moved, the `action` function is called with `(prob, alg, new_value)`.
  It returns an updated `(prob, alg)` pair (or just one of them).
- The simulation is re-initialised from `t=0` with the new parameters and runs forward
  in the background, streaming frames to the display.
- Metrics panels update in real time.

> [!TIP]
> `explore_cpm` requires a GPU-compatible or multi-threaded Makie backend (`GLMakie`
> recommended). It is not available with `CairoMakie` (which is non-interactive).

> [!IMPORTANT]
> `explore_cpm` re-runs the simulation from scratch each time a parameter changes.
> For large grids or long `tspan` values this can be slow. Consider using a smaller
> grid (e.g. 100×100) and short `tspan` for interactive exploration, then running the
> full simulation with `solve` once you have settled on parameters.
