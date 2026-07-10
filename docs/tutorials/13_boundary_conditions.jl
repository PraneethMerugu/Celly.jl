# # Boundary Conditions
#
# The default periodic boundary conditions let cells wrap around the grid
# edges, which is appropriate for modelling bulk tissue but unsuitable for
# confined geometries such as a cell monolayer growing in a well or a tissue
# slice pressed against a rigid substrate.  PottsToolkit exposes the boundary
# condition through the `topology` keyword of `PottsProblem`.  Swapping a single
# type changes the behaviour of every attempted copy event at the boundary —
# no other code needs to change.

# ## Packages

using PottsToolkit
using MakiePotts
using Statistics

# ## Shared model components
#
# Both simulations use an identical energy landscape; only the topology differs.

Cell = CellType(:Cell)
Medium = CellType(:Medium, is_background = true)

sys = PottsSystem(
    cell_types = [Medium, Cell],
    penalties = [
        VolumeComponent(
            Cell => (λ = 5.0f0, target = 300),
            Medium => (λ = 0.0f0, target = 0)
        ),
        SurfaceAreaComponent(
            Cell => (λ = 1.5f0, target = 70),
        ),
        AdhesionComponent(
            (Cell, Medium) => 20.0f0,
            (Cell, Cell) => 4.0f0
        )
    ]
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

# ## Periodic topology (VonNeumannTopology{2})
#
# The 4-connected periodic neighbourhood is the standard Potts topology.  Cells
# that reach the right edge reappear on the left; top wraps to bottom.
# This is ideal for bulk tissue models where edge effects should not matter.

prob_periodic = PottsProblem(
    sys,
    Dict(Cell => 20),
    (200, 200);
    tspan = (0, 600),
    topology = VonNeumannTopology{2}()
)

sol_periodic = solve(prob_periodic, alg; saveat = 20)

# ## No-flux (rigid wall) topology (NoFluxVonNeumannTopology{2})
#
# The no-flux topology reflects copy attempts at boundaries: a lattice site at
# the edge cannot copy from a site outside the grid, and copy attempts that
# would move a cell across the boundary are rejected.  This mimics cells
# growing against a rigid substrate or the walls of a culture dish.
# Cells therefore pile up, elongate, and crowd near the walls rather than
# smoothly wrapping.

prob_noflux = PottsProblem(
    sys,
    Dict(Cell => 20),
    (200, 200);
    tspan = (0, 600),
    topology = NoFluxVonNeumannTopology{2}()
)

sol_noflux = solve(prob_noflux, alg; saveat = 20)

# ## Extended neighbourhoods
#
# `ExtendedVonNeumannTopology{2,2}()` uses a radius-2 neighbourhood (up to 12
# neighbours in 2-D) instead of the standard 4.  Longer-range interactions
# smooth the lattice artefacts, relevant when modelling signalling molecules
# that diffuse a few pixels before acting.  The extended topology is also
# available in no-flux form:
#
# ```julia
# ExtendedVonNeumannTopology{2,2}()
# ExtendedMooreTopology{2,2}()
# NoFluxVonNeumannTopology{2}()
# NoFluxMooreTopology{2}()
# ```

# ## Side-by-side visualisation
#
# We record both simulations, then assemble them into a single figure for
# comparison using the Makie layout system.

record_potts("periodic_boundary.mp4", sol_periodic; framerate = 15, resolution = (800, 800))
record_potts("noflux_boundary.mp4", sol_noflux; framerate = 15, resolution = (800, 800))

# Build a static side-by-side comparison from the final frames

using CairoMakie
CairoMakie.activate!()

fig = Figure(resolution = (1400, 700))

ax1 = Axis(fig[1, 1]; title = "Periodic (VonNeumann)")
ax2 = Axis(fig[1, 2]; title = "Rigid Walls (NoFlux)")

pottsplot!(ax1, sol_periodic.u[end])
pottsplot!(ax2, sol_noflux.u[end])

save("boundary_conditions_comparison.png", fig)
fig

# ```@raw html
# <video autoplay loop muted playsinline controls src="../periodic_boundary.mp4" width="100%"></video>
# <br>
# <video autoplay loop muted playsinline controls src="../noflux_boundary.mp4" width="100%"></video>
# ```
