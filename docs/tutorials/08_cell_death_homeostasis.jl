using CairoMakie
CairoMakie.activate!()

# # Cell Death & Tissue Homeostasis
#
# Healthy tissues maintain a near-constant cell number through a precise
# balance between cell proliferation and programmed cell death (apoptosis).
# This *homeostatic steady state* is disrupted in cancer — where proliferation
# outpaces death — and in degenerative diseases where death exceeds renewal.
# The steady-state population N* satisfies a balance between the birth rate b
# and the death rate d: at equilibrium, b·N* = d·N*. Perturbations away from
# N* are restored by density-dependent feedback loops.
#
# In this tutorial we implement both sides of the balance:
# `MitosisEvent` drives division, while `ApoptosisEvent` applies
# stochastic apoptosis. We use `explore_potts` to watch the population stabilise
# around the homeostatic fixed point.

# ## Packages

using PottsToolkit
using MakiePotts
using SciMLBase
using Statistics: mean

# ## Cell Types

Epithelial = CellType(:Epithelial)
Medium = CellType(:Medium, is_background = true)

# ## Energy Model

sys = PottsSystem(
    cell_types = [Medium, Epithelial],
    penalties = [
        VolumeComponent(Epithelial => (λ = 5.0f0, target = 150)),
        AdhesionComponent(
            (Epithelial, Epithelial) => 2.0f0,
            (Epithelial, Medium) => 18.0f0
        )
    ],
    events = [
        MitosisEvent(Epithelial,
            trigger = VolumeRatioTrigger(2.0f0),
            orientation = MajorAxisOrientation(),
            inheritance = (;)
        ),
        ApoptosisEvent(Epithelial, trigger = ProbabilityTrigger(0.005f0)),
        PropertyUpdateEvent(Epithelial, (target_volumes = Add(1, ProbabilityTrigger(0.25f0)),))
    ]
)

# As in Tutorial 07, cells grow linearly via the `PropertyUpdateEvent`. 
# They divide when their physical volume reaches twice their target volume. 
# Since we do not split target volumes, each daughter cell inherits a target volume of 150, 
# but starts with a physical volume of ~75. They must then grow anew before their next division.
#
# ## Intrinsic Death Processing
#
# Any cell whose `target_volume <= 0` is automatically removed natively by the Potts engine.
# Since our `ApoptosisEvent` natively sets the target volume of triggered cells to zero, 
# the simulator will subsequently reap the cell ID to recycle memory safely at the end of the step.

# ## Problem
#
# We start with a tissue that completely fills the entire 150x150 grid
# using `RectangleLayout`. This allows us to observe mature tissue turnover
# immediately, rather than waiting for the simulation to grow to steady state.

prob = PottsProblem(
    sys,
    RectangleLayout(Epithelial, (1, 1), (150, 150)),
    (150, 150);
    tspan = (0, 2000),
    topology = VonNeumannTopology{2}(),
    max_cells = 1000
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

sol = solve(prob, alg; saveat = 10)

# ## Interactive Dashboard — Homeostatic Steady State
#
# The N Cells metric should show the population rising from 30, overshooting
# slightly due to the lag between birth and death stochasticity, and then
# settling into a noisy plateau. Increasing the temperature slider broadens
# the distribution of cell sizes, which modulates the effective mitosis rate
# and shifts the homeostatic setpoint slightly.

fig = explore_potts(
    prob, alg;
    metrics = [
        "N Cells" => u -> u.N_cells[],
        "Mean Volume" => u -> begin
            n = u.N_cells[]
            n > 0 ? mean(Array(u.cell_data.volumes)[1:n]) : 0.0
        end,
        "Birth - Death Flux" => u -> begin
            ## Approximates net population flux: positive = growing phase,
            ## near-zero = homeostatic plateau
            n = u.N_cells[]
            Float64(n) - 65.0   # 65 is the expected N* for these parameters
        end
    ],
    parameters = [
        "Temperature" => (
        range = 0.5f0:0.5f0:5.0f0,
        start = 2.0f0,
        action = (prob, alg, val) -> CheckerboardMetropolis(T = val, sweeps_per_step = 10)
    ),
    ]
)
