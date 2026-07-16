using CairoMakie
CairoMakie.activate!()

# # Cell Elongation & Polarity
#
# Many cell types in living tissues adopt elongated morphologies rather than
# compact rounded shapes. Fibroblasts, myotubes, and epithelial cells under
# mechanical stress all exhibit well-defined long axes. In the Potts this is
# captured by the **LengthComponent**, which penalises deviations of the
# cell's major-axis length (derived from the inertia-tensor eigendecomposition)
# from a prescribed target. Combining elongation with realistic cell division
# along the long axis (MajorAxisOrientation) recapitulates the oriented
# proliferation patterns seen in growing epithelia.

# ## Packages

using PottsToolkit
using MakiePotts
using Statistics

# ## Cell-type definitions

# We model two populations: elongated stromal cells (Fib) and a surrounding
# Medium.  A single CellType call registers the label in the system.

Fib = CellType(:Fib)
Medium = CellType(:Medium, is_background = true)

# ## Energy components
#
# The **LengthComponent** computes the principal axis of each cell via its
# second-order central moments (inertia tensor).  The penalty is:
#
# ```
# H_length = λ · (L_major − target)²
# ```
#
# where `L_major` is the square-root of the larger eigenvalue of the moment
# matrix and `target` is the desired half-length.  The `eta` parameter
# controls a soft-floor that prevents numerical blow-up for very small cells.

components = [
    VolumeComponent(
        Fib => (λ = 5.0f0, target = 400),
        Medium => (λ = 0.0f0, target = 0)
    ),
    SurfaceAreaComponent(
        Fib => (λ = 1.0f0, target = 80),
    ),
    AdhesionComponent(
        (Fib, Medium) => 20.0f0,
        (Fib, Fib) => 4.0f0
    ),
    LengthComponent(
        Fib => (λ = 3.0f0, target = 20.0f0);
        eta = 1.0
    )
]

# ## System and problem
#
# We place 30 fibroblast-like cells on a 200×200 periodic grid and run for
# 800 MCS.  VonNeumannTopology{2}() gives the standard 4-connected neighbourhood.

sys = PottsSystem(
    cell_types = [Medium, Fib],
    penalties = components,
    events = [
        MitosisEvent(Fib,
            trigger = VolumeRatioTrigger(2.0f0),
            orientation = MajorAxisOrientation(),
            inheritance = (target_volumes = CorePotts.Split(0.5f0),)
        ),
        PropertyUpdateEvent(Fib, (target_volumes = Add(1, ProbabilityTrigger(0.3f0)),))
    ]
)

prob = PottsProblem(
    sys,
    Dict(Fib => 30),
    (200, 200);
    tspan = (0, 800),
    topology = VonNeumannTopology{2}(),
    trackers = ()
)

# ## Growth and Mitosis Native Event
#
# PropertyUpdateEvent slowly inflates the target volume (0.3 area units / MCS) dynamically on the GPU.
# Once a cell reaches twice its initial target volume, the native `MitosisEvent` fires.
# MajorAxisOrientation places the division plane *perpendicular* to the long
# axis, so each daughter inherits an elongated shape — exactly as seen in
# oriented cell divisions in vivo.

# ## Algorithm

alg = CheckerboardMetropolis(T = 2.5f0, sweeps_per_step = 10)

# ## Interactive exploration
#
# explore_potts opens a live dashboard.  The "Mean Major Length" metric is
# computed directly from the integrator state at every saved frame.  The
# Temperature slider triggers a full re-solve so you can observe how lower T
# freezes elongation while higher T disorders the tissue.

fig = explore_potts(
    prob, alg;
    metrics = [
        "Mean Major Length" =>
            u -> begin
                n = u.N_cells[]
                n == 0 ? 0.0 : mean(Array(u.cell_data.current_lengths)[1:n])
            end,
        "N Cells" => u -> u.N_cells[]
    ],
    parameters = [
        "Temperature" => (
        range = 0.5f0:0.5f0:6.0f0,
        start = 2.5f0,
        action = (prob, alg, val) -> CheckerboardMetropolis(T = val, sweeps_per_step = 10)
    ),
    ]
)
