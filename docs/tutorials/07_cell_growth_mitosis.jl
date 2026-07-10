using CairoMakie
CairoMakie.activate!()

# # Cell Growth & Mitosis
#
# The cell cycle — a precisely orchestrated sequence of growth, DNA
# replication, and division — is the engine of tissue expansion. In the Potts,
# cell growth is modelled by continuously increasing the *target volume*
# parameter, so the volume penalty drives the cell to physically expand. When
# the actual volume reaches a threshold (typically 2× the initial target),
# mitosis is triggered: the cell is split into two daughters that inherit
# specified fractions of the parent's properties.
#
# This tutorial assembles a `CallbackSet` that couples linear growth to
# threshold-triggered mitosis, producing exponential population expansion
# from a small founder population.

# ## Packages

using PottsToolkit
using MakiePotts
using SciMLBase

# ## Cell Type

Progenitor = CellType(:Progenitor)
Medium = CellType(:Medium, is_background = true)

# ## Energy Model
#
# We keep the energy simple — VolumeComponent and AdhesionComponent are
# sufficient to produce compact, physically realistic daughter cells after
# division.

sys = PottsSystem(
    cell_types = [Medium, Progenitor],
    penalties = [
        VolumeComponent(Progenitor => (λ = 5.0f0, target = 150)),
        AdhesionComponent(
            (Progenitor, Progenitor) => 2.0f0,
            (Progenitor, Medium) => 18.0f0
        )
    ],
    events = [
        MitosisEvent(
        Progenitor,
        trigger = VolumeRatioTrigger(2.0f0),
        orientation = CorePotts.RandomOrientation(),
        inheritance = (target_volumes = CorePotts.Split(0.5f0),)
    )
    ]
)

# ## Growth Callback
#
# `LinearGrowthCallback(rate)` increments each cell's `target_volume` by
# `rate` lattice sites per MCS. A rate of 0.3 means it takes roughly
# 500 MCS for a cell to double from target 150 to 300 — a plausible
# *in vitro* doubling time when one MCS is calibrated to ~1 minute.

growth_cb = LinearGrowthCallback(0.3f0)

# ## Mitosis Trigger and Callback
#
# `VolumeRatioTrigger(factor)` fires when a cell's actual volume exceeds
# `factor × target_volume`. Using `factor = 2.0` means division is triggered
# when the cell has grown to twice its initial target — a standard G2/M
# checkpoint proxy.
#
# **Inheritance rules** determine how parent properties are distributed to
# daughters:
#
# - `Split(0.5f0)` — each daughter receives exactly half the parent value.
#   Use this for `target_volumes` so each daughter starts with the original
#   target and must grow again before the next division.
# - `Clone` (not used here) — both daughters receive the full parent value.
#   Useful for immutable identifiers such as lineage labels or receptor counts
#   that should be preserved, not divided.
#
# `MitosisEvent` also accepts an `orientation` argument controlling the
# division plane. `RandomOrientation()` chooses a uniformly random axis each
# time, producing isotropic growth. `MajorAxisOrientation()` aligns the
# division plane with the long axis of the mother cell, which is
# biologically realistic for many epithelial lineages.

cb = SciMLBase.CallbackSet(
    SciMLBase.DiscreteCallback((u, t, i) -> true, i -> growth_cb(i))
)

# ## Problem and Algorithm

prob = PottsProblem(
    sys,
    Dict(Progenitor => 5),
    (200, 200);
    tspan = (0, 800),
    topology = VonNeumannTopology{2}(),
    max_cells = 1000
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

sol = solve(prob, alg; saveat = 8, callback = cb)

# ## Interactive Dashboard
#
# `explore_cpm` lets you scrub through time while the N Cells metric
# demonstrates exponential population growth. The temperature slider lets
# you observe how thermal noise affects the regularity of division timing.

fig = explore_cpm(
    prob, alg;
    metrics = [
        "N Cells" => u -> u.N_cells[],
        "Mean Volume" => u -> begin
            n = u.N_cells[]
            n > 0 ? sum(Array(u.cell_data.volumes)[1:n]) / n : 0.0
        end,
        "Mean Target Vol" =>
            u -> begin
                n = u.N_cells[]
                n > 0 ? sum(Array(u.cell_data.target_volumes)[1:n]) / n : 0.0
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
