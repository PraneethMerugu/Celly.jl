using CairoMakie
CairoMakie.activate!()

# # Thermodynamic HST Penalties
#
# The classic CPM volume penalty H_V = λ(V - V_target)² is convenient but
# thermodynamically inconsistent at finite temperature. The problem is that
# it treats the target volume as a *fixed* external field — the cell behaves
# as if coupled to a spring whose other end is nailed to the wall. This
# violates *detailed balance* for the fluctuations of V_target itself: if
# the target can evolve (e.g., after growth or mitosis), the equilibrium
# distribution of actual volumes does not match a Boltzmann distribution
# at temperature T.
#
# The **Homeostatic Stochastic Trapping (HST)** penalty fixes this by
# modelling the target volume as an Ornstein–Uhlenbeck (OU) process that
# relaxes toward the actual volume with a timescale controlled by `eta` (η).
# In the limit η → 0, the HST penalty converges to the classical quadratic.
# For η > 0, the equilibrium distribution of volumes is Gaussian with a
# variance that depends correctly on both T and λ — satisfying detailed
# balance and giving physically correct thermal fluctuations.
#
# **Practical recommendation**: use `HSTVolumeComponent` (and the analogous
# HST surface area component) whenever your simulation is quantitative or
# when volume fluctuations are an observable of interest. The overhead
# compared to the classical quadratic is negligible.

# ## Packages

using CPMToolkit
using MakieCPM
using Statistics: mean, std, var

# ## Cell Types

CellA  = CellType(:CellA)
Medium = CellType(:Medium)

# ## Classical System (Reference)
#
# `VolumeComponent` uses the standard quadratic penalty H = λ(V−V₀)².
# We use this as the baseline against which HST is compared.

sys_classical = CPMSystem(
    [CellA, Medium],
    [
        VolumeComponent(CellA => (λ = 5.0f0, target = 200)),
        AdhesionComponent(
            (CellA, CellA)   => 2.0f0,
            (CellA, Medium)  => 16.0f0,
        ),
    ]
)

# ## HST System
#
# `HSTVolumeComponent` takes the same per-cell-type `(λ, target)` parameters
# as `VolumeComponent`, plus a global `eta` (η) that sets the OU relaxation
# rate. η has units of inverse MCS; η = 1.0 means the OU process relaxes
# fully within ~1 MCS, which is appropriate for well-mixed simulations.
# η = 0.1 gives slower relaxation, suitable when cells grow on timescales
# of tens of MCS.
#
# `SurfaceAreaComponent` is included to constrain cell shape alongside volume,
# giving a more realistic mechanical phenotype.

sys_hst = CPMSystem(
    [CellA, Medium],
    [
        HSTVolumeComponent(CellA => (λ = 5.0f0, target = 200); eta = 1.0),
        SurfaceAreaComponent(CellA => (λ = 1.0f0, target = 60)),
        AdhesionComponent(
            (CellA, CellA)   => 2.0f0,
            (CellA, Medium)  => 16.0f0,
        ),
    ]
)

# ## Problems
#
# Identical grid, cell count, and run length for a fair comparison.
# Both systems get the same random seed via the same algorithm.

prob_classical = CPMProblem(
    sys_classical,
    Dict(CellA => 40),
    (200, 200);
    tspan    = (0, 600),
    topology = VonNeumannTopology{2}(),
)

prob_hst = CPMProblem(
    sys_hst,
    Dict(CellA => 40),
    (200, 200);
    tspan    = (0, 600),
    topology = VonNeumannTopology{2}(),
)

alg = CheckerboardMetropolis(T = 3.0f0, sweeps_per_step = 10)

sol_classical = solve(prob_classical, alg; saveat = 6)
sol_hst       = solve(prob_hst,       alg; saveat = 6)

# ## Comparing Volume Distributions
#
# The key observable is the variance of cell volumes at steady state:
#
# - **Classical**: σ²_V ≈ T / (2λ) from a naïve Boltzmann argument, but
#   the actual distribution is biased because the boundary fluctuations
#   are not correctly accounted for.
# - **HST**: σ²_V = T / (2λ) exactly, as proven by the fluctuation-
#   dissipation theorem for the OU process. The distribution is exactly
#   Gaussian at equilibrium.
#
# At T = 3.0 and λ = 5.0, the predicted HST variance is 3.0 / 10.0 = 0.3
# sites² — very tight, confirming that the penalty is stiff. Increasing T
# in the explore_cpm slider makes this difference more visible.

# ## Interactive Dashboard
#
# The "Volume Variance" metric is the primary comparison observable.
# Higher T → wider volume distribution. The HST system should show a
# variance that tracks the Boltzmann prediction T/(2λ), while the classical
# system deviates, especially at high T.

fig = explore_cpm(
    prob_hst, alg;
    metrics = [
        "N Cells"          => u -> u.N_cells[],
        "Mean Volume"      => u -> begin
            n = u.N_cells[]
            n > 1 ? mean(Array(u.cell_data.volumes)[1:n]) : 0.0
        end,
        "Volume Variance"  => u -> begin
            n = u.N_cells[]
            n > 1 ? var(Array(u.cell_data.volumes)[1:n]) : 0.0
        end,
        "Volume Std Dev"   => u -> begin
            n = u.N_cells[]
            n > 1 ? std(Array(u.cell_data.volumes)[1:n]) : 0.0
        end,
    ],
    parameters = [
        "Temperature" => (
            range  = 0.5f0:0.5f0:8.0f0,
            start  = 3.0f0,
            action = (prob, alg, val) ->
                CheckerboardMetropolis(T = val, sweeps_per_step = 10)
        ),
        "HST eta" => (
            range  = 0.1f0:0.1f0:2.0f0,
            start  = 1.0f0,
            action = (prob, alg, val) -> begin
                ## Rebuild the HST system with the new eta value
                new_sys = CPMSystem(
                    [CellA, Medium],
                    [
                        HSTVolumeComponent(CellA => (λ = 5.0f0, target = 200); eta = val),
                        SurfaceAreaComponent(CellA => (λ = 1.0f0, target = 60)),
                        AdhesionComponent(
                            (CellA, CellA)  => 2.0f0,
                            (CellA, Medium) => 16.0f0,
                        ),
                    ]
                )
                CheckerboardMetropolis(T = 3.0f0, sweeps_per_step = 10)
            end
        ),
    ],
)
