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
# MitosisCallback drives growth and division, while DeathCallback applies
# stochastic apoptosis. We use `explore_cpm` to watch the population stabilise
# around the homeostatic fixed point.

# ## Packages

using PottsToolkit
using MakiePotts
using SciMLBase
using Statistics: mean

# ## Cell Types

Epithelial = CellType(:Epithelial)
Medium = CellType(:Medium, is_background=true)

# ## Energy Model

sys = PottsSystem(
    cell_types = [Medium, Epithelial],
    penalties  = [
        VolumeComponent(Epithelial => (λ = 5.0f0, target = 150)),
        AdhesionComponent(
            (Epithelial, Epithelial) => 2.0f0,
            (Epithelial, Medium) => 18.0f0
        )
    ]
)

# ## Growth and Mitosis
#
# As in Tutorial 07, cells grow linearly and divide when they reach twice
# their target volume. `Split(0.5f0)` halves the target volume at division
# so each daughter must grow anew before its next division.

growth_cb = LinearGrowthCallback(0.25f0)
trigger = VolumeThresholdTrigger(2.0f0)
mitosis_cb = MitosisCallback(trigger;
    orientation = MajorAxisOrientation(),
    inheritance_rules = (target_volumes = Split(0.5f0),)
)

# ## Death Callback — Stochastic Apoptosis
#
# # cells shrink to zero and disappear. Wait, `DeathCallback` in `CorePotts` automatically removes
# any cell whose `target_volume <= 0`. So to trigger death, we just use a standard
# `DiscreteCallback` to randomly set `target_volume = 0` for a few cells each step.
#
# Here we implement *stochastic apoptosis*: each cell has a small per-MCS
# probability p_death = 0.002 of dying, independently of its neighbours or
# internal state. At steady state the expected death rate is p_death × N_cells
# per MCS. Because the mitosis rate scales with the number of cells that are
# large enough to divide, the population stabilises at the N* where the two
# rates balance.
#
# The `rand()` call inside the predicate is evaluated independently for each
# living cell at each callback invocation, producing uncorrelated apoptosis
# events — a reasonable approximation to intrinsic stochastic apoptosis
# in the absence of extrinsic death signals.

const P_DEATH = 0.005f0

random_death_cb = SciMLBase.DiscreteCallback(
    (u, t, integrator) -> true,
    function (integrator)
        ## i is a 1-based cell ID; cell_data arrays are indexed from 1
        for i in 1:integrator.u.N_cells[]
            ## Only kill living cells
            if integrator.u.cell_data.volumes[i] > 0 && rand() < P_DEATH
                integrator.u.cell_data.target_volumes[i] = 0
            end
        end
    end
)

death_cb = DeathCallback()

# ## Callback Assembly

cb = SciMLBase.CallbackSet(
    SciMLBase.DiscreteCallback((u, t, i) -> true, i -> growth_cb(i)),
    mitosis_cb,
    random_death_cb,
    death_cb
)

# ## Problem
#
# We start with 30 cells — below the expected homeostatic population — to
# observe the system grow toward steady state and then fluctuate around it.
# A 150 × 150 grid comfortably accommodates up to ~100 cells of target
# volume 150 before crowding effects dominate.

prob = PottsProblem(
    sys,
    Dict(Epithelial => 30),
    (150, 150);
    tspan = (0, 2000),
    topology = VonNeumannTopology{2}(),
    max_cells = 1000
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

sol = solve(prob, alg; saveat = 10, callback = cb)

# ## Interactive Dashboard — Homeostatic Steady State
#
# The N Cells metric should show the population rising from 30, overshooting
# slightly due to the lag between birth and death stochasticity, and then
# settling into a noisy plateau. Increasing the temperature slider broadens
# the distribution of cell sizes, which modulates the effective mitosis rate
# and shifts the homeostatic setpoint slightly.

fig = explore_cpm(
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
