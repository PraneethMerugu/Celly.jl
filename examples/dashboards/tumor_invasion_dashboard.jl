# tumor_invasion_dashboard.jl
# Tumor Invasion Dashboard built using PottsToolkit, MakiePotts, and SciML Callbacks

using GLMakie
using SciMLBase
using CommonSolve
using Random
using StructArrays
using CorePotts
using PottsToolkit
using MakiePotts
using CorePotts.KernelAbstractions

# ==========================================
# 1. Custom Callbacks and Kernels
# ==========================================

# 1.1 Custom Topology
struct PeriodicXNoFluxYTopology{N} <: CorePotts.AbstractTopology{N} end
CorePotts.offsets(::PeriodicXNoFluxYTopology{2}) = ((1, 0), (0, 1), (-1, 0), (0, -1))
function CorePotts.lottery_offsets(::PeriodicXNoFluxYTopology{2})
    CorePotts.offsets(PeriodicXNoFluxYTopology{2}())
end
CorePotts.num_dirs(::PeriodicXNoFluxYTopology{2}) = Val(4)
CorePotts.checkerboard_colors(::PeriodicXNoFluxYTopology{2}) = 2
function CorePotts.checkerboard_color(::PeriodicXNoFluxYTopology{2}, coords::NTuple{
        2, UInt32})
    UInt32((coords[1] + coords[2]) % 2)
end

@inline function CorePotts.get_lottery_neighbor_idx(topo::PeriodicXNoFluxYTopology{2},
        coords::NTuple{2, UInt32}, dir::Int, dims::NTuple{2, Int})
    offs = CorePotts.lottery_offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CorePotts.coord_to_idx((new_x, new_y), dims)
end

@inline function CorePotts.get_neighbor_by_coord(
        topo::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32},
        dir::UInt32, dims::NTuple{2, Int})
    offs = CorePotts.offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CorePotts.coord_to_idx((new_x, new_y), dims)
end

# 1.2 Stochastic Growth Event
struct StochasticGrowthEvent <: CorePotts.AbstractEvent
    prob::Float32
end

CorePotts.has_device_trigger(::StochasticGrowthEvent) = true
@inline function CorePotts.evaluate_trigger(evt::StochasticGrowthEvent, i, cd, t)
    if cd.volumes[i] > 0
        seed = UInt64(t) + UInt64(i)
        u = Float32(CorePotts.pcg_hash(seed) >> 32) * 2.3283064f-10
        return u < evt.prob
    end
    return false
end

@kernel function stochastic_growth_kernel!(mask, target_volumes)
    i = @index(Global, Linear)
    if mask[i]
        target_volumes[i] += 1
    end
end

CorePotts.get_event_kernel(::StochasticGrowthEvent, backend, block_size) = stochastic_growth_kernel!(backend, block_size)
CorePotts.get_event_args(::StochasticGrowthEvent, mask, u, p, cache, t) = (mask, u.cell_data.target_volumes)

# 1.3 Clock Advance Event
struct ClockAdvanceEvent <: CorePotts.AbstractEvent end

CorePotts.has_device_trigger(::ClockAdvanceEvent) = true
@inline function CorePotts.evaluate_trigger(::ClockAdvanceEvent, i, cd, t)
    return cd.volumes[i] > 0 && cd.is_proliferation_competent[i]
end

@kernel function clock_advance_kernel!(mask, mitotic_timers)
    i = @index(Global, Linear)
    if mask[i]
        mitotic_timers[i] += 1.0f0
    end
end

CorePotts.get_event_kernel(::ClockAdvanceEvent, backend, block_size) = clock_advance_kernel!(backend, block_size)
CorePotts.get_event_args(::ClockAdvanceEvent, mask, u, p, cache, t) = (mask, u.cell_data.mitotic_timers)

# 1.4 Tumor Mitosis Trigger and Post-Division Cleanup
function tumor_mitosis_trigger(cell_id, cell_data)
    # Type IDs: Medium=0, Leader=1, Follower=2 (Medium is forced to 0 by PottsProblem constructor)
    if cell_data.cell_types[cell_id] != 2 # Only Followers proliferate
        return false
    end
    if !cell_data.is_proliferation_competent[cell_id]
        return false
    end
    if cell_data.volumes[cell_id] < 20
        return false
    end
    if cell_data.mitotic_timers[cell_id] < cell_data.mitotic_thresholds[cell_id]
        return false
    end
    return true
end

@kernel function tumor_post_mitosis_kernel!(dev_parents, dev_children, mitotic_timers, mitotic_thresholds, step_val, num_divisions)
    i = @index(Global, Linear)
    if i <= num_divisions
        parent_id = dev_parents[i]
        child_id = dev_children[i]
        step = step_val

        # Reset parent
        s1_p = step + UInt64(parent_id) * UInt64(2)
        s2_p = step + UInt64(parent_id) * UInt64(2) + UInt64(1)
        mitotic_timers[parent_id] = Float32(CorePotts.pcg_hash(s1_p) >> 32) * 2.3283064f-10 * 75.0f0
        mitotic_thresholds[parent_id] = 25.0f0 + Float32(CorePotts.pcg_hash(s2_p) >> 32) * 2.3283064f-10 * 100.0f0

        # Reset child
        s1_c = step + UInt64(child_id) * UInt64(2)
        s2_c = step + UInt64(child_id) * UInt64(2) + UInt64(1)
        mitotic_timers[child_id] = Float32(CorePotts.pcg_hash(s1_c) >> 32) * 2.3283064f-10 * 75.0f0
        mitotic_thresholds[child_id] = 25.0f0 + Float32(CorePotts.pcg_hash(s2_c) >> 32) * 2.3283064f-10 * 100.0f0
    end
end

function tumor_post_division_action(u, p, cache, ws, num_divisions)
    vol_pen = p.penalties[1] # The HSTVolumePenalty
    CorePotts.reset_hst_fields_after_division!(u, cache, vol_pen)

    # Use native KernelAbstractions to update just the parent and child cells on VRAM
    # avoiding a global synchronization.
    backend = CorePotts.KernelAbstractions.get_backend(u.grid)
    k = tumor_post_mitosis_kernel!(backend, cache.block_size)
    ev = k(ws.dev_parents, ws.dev_children, u.cell_data.mitotic_timers, u.cell_data.mitotic_thresholds, cache.step_counter[1], num_divisions, ndrange=length(ws.dev_parents))
    return ev
end
# ==========================================
# 2. Main Dashboard Execution
# ==========================================
Leader = CellType(:Leader)
Follower = CellType(:Follower)
Medium = CellType(:Medium, is_background = true)

width, height = 500, 300
chem_field = Float32[Float32(y) for x in 1:width, y in 1:height]

sys = PottsSystem(
    cell_types = [Medium, Leader, Follower], # Medium=0, Leader=1, Follower=2 (IDs assigned by PottsProblem constructor)
    penalties = [
        HSTVolumeComponent(Leader => (λ = 2.0f0, target = 10.0),
            Follower => (λ = 2.0f0, target = 10.0); eta = 5.0f0),
        ChemotaxisComponent(Leader => 20.0f0, Follower => 0.0f0; chemical_field = chem_field),
        AdhesionComponent(
            (Leader, Leader) => 16.0f0,
            (Follower, Follower) => 5.0f0,
            (Leader, Follower) => 0.0f0,
            (Leader, Medium) => 2.0f0,
            (Follower, Medium) => 10.0f0
        )
    ],
    events = [
        StochasticGrowthEvent(0.015f0),
        ClockAdvanceEvent(),
        MitosisEvent(Follower,
            trigger = CustomTrigger(tumor_mitosis_trigger),
            orientation = CorePotts.RandomOrientation(),
            inheritance = (target_volumes = CorePotts.Split(0.5f0),),
            action = tumor_post_division_action
        )
    ],
    check_interval = 1 # We want to evaluate the mitosis trigger every step like the original script
)

# 1/4th Leaders, 3/4ths Followers
total_cells = length(1:3:width) * length(1:3:21)
num_leaders = round(Int, total_cells * 0.25)
num_followers = total_cells - num_leaders

# Max cells allocated 5000 directly.
prob = PottsProblem(
    sys, Dict(Leader => num_leaders, Follower => num_followers), (width, height);
    tspan = (0, 1000),
    topology = PeriodicXNoFluxYTopology{2}(),
    max_cells = 20000
)

# Initialize properties and position exactly like old script
grid = prob.u0.grid
fill!(grid, 0)
cell_id_counter = 1

# Setup types
import Random
for i in 1:num_leaders
    prob.u0.cell_data.cell_types[i] = 1
end
for i in (num_leaders + 1):total_cells
    prob.u0.cell_data.cell_types[i] = 2
end
Random.shuffle!(@view prob.u0.cell_data.cell_types[1:total_cells])

for x in 1:3:width
    for y in 1:3:21
        x_end = min(x + 2, width)
        y_end = min(y + 2, 21)
        grid[x:x_end, y:y_end] .= cell_id_counter

        global cell_id_counter
        # Override initial targets since grid injection might have set volumes differently
        prob.u0.cell_data.volumes[cell_id_counter] = 10
        prob.u0.cell_data.target_volumes[cell_id_counter] = 10
        cell_id_counter += 1
    end
end
prob.u0.N_cells[] = total_cells

# Pre-allocate extra tracking arrays directly to cell_data
components_nt = StructArrays.components(prob.u0.cell_data)
new_components = Base.merge(
    components_nt,
    (;
        is_proliferation_competent = zeros(Bool, 20000),
        mitotic_timers = zeros(Float32, 20000),
        mitotic_thresholds = zeros(Float32, 20000)
    )
)
new_cell_data = StructArray(new_components)
new_u0 = PottsState(prob.u0.grid, new_cell_data, prob.u0.N_cells, prob.u0.free_list)
prob = PottsProblem(new_u0, prob.tspan, prob.p)

# Initialize proliferation competent flags based on PP = 0.5f0
for i in 1:prob.u0.N_cells[]
    if prob.u0.cell_data.cell_types[i] == 2 && rand() < 0.5f0 # Follower is ID 2
        prob.u0.cell_data.is_proliferation_competent[i] = true
        prob.u0.cell_data.mitotic_timers[i] = rand() * 75.0f0
        prob.u0.cell_data.mitotic_thresholds[i] = 25.0f0 + rand() * 100.0f0
    end
end

# No cb_set needed anymore!

alg = CheckerboardMetropolis(sweeps_per_step = 10, active_fraction = 0.1f0, T = 10.0f0)

# Build parameter sliders mapping exactly to original interactive_app.jl parameters
parameters = [
    "Noise Decay (eta)" => (
        range = 0.0f0:0.5f0:20.0f0,
        start = 5.0f0,
        action = (p, a, val) -> begin
            old_vol = p.p.penalties[1]
            new_vol = CorePotts.HSTVolumePenalty{Rigid}(old_vol.lambdas, Float32(val))
            new_pens = (new_vol, p.p.penalties[2], p.p.penalties[3])
            new_p = CorePotts.PottsParameters(p.p.topology, new_pens, p.p.trackers)
            return CorePotts.PottsProblem(p.u0, p.tspan, new_p)
        end
    ),
    "Migration Bias (λ)" => (
        range = 0.0f0:1.0f0:30.0f0,
        start = 20.0f0,
        action = (p, a, val) -> begin
            # Chemotaxis is index 2, Leader is index 2
            p.p.penalties[2].lambdas[2] = val
            return a
        end
    ),
    "Contact Energy (J_lf)" => (
        range = -5.0f0:0.5f0:20.0f0,
        start = 0.0f0,
        action = (p, a, val) -> begin
            p.p.penalties[3].J[2, 3] = val
            p.p.penalties[3].J[3, 2] = val
            return a
        end
    ),
    "Proliferation Prob (PP)" => (
        range = 0.0f0:0.05f0:1.0f0,
        start = 0.5f0,
        action = (p, a, val) -> begin
            for id in 1:p.u0.N_cells[]
                if p.u0.cell_data.cell_types[id] == 2 && rand() < val # Follower is ID 2
                    p.u0.cell_data.is_proliferation_competent[id] = true
                    p.u0.cell_data.mitotic_timers[id] = rand() * 75.0f0
                    p.u0.cell_data.mitotic_thresholds[id] = 25.0f0 + rand() * 100.0f0
                else
                    p.u0.cell_data.is_proliferation_competent[id] = false
                end
            end
            return a
        end
    ),
    "Contact Energy (J_ll)" => (
        range = 0.0f0:0.5f0:20.0f0,
        start = 16.0f0,
        action = (p, a, val) -> begin
            p.p.penalties[3].J[2, 2] = val
            return a
        end
    ),
    "Contact Energy (J_ff)" => (
        range = 0.0f0:0.5f0:20.0f0,
        start = 5.0f0,
        action = (p, a, val) -> begin
            p.p.penalties[3].J[3, 3] = val
            return a
        end
    ),
    "Sweeps per Step" => (
        range = 1:1:20,
        start = 10,
        action = (p, a, val) -> begin
            return CorePotts.CheckerboardMetropolis(
                sampler = a.sampler,
                sweeps_per_step = val,
                active_fraction = 1.0f0 / Float32(val), # Maintain 1.0 sweep
                T = a.T
            )
        end
    )
]

if !haskey(ENV, "TESTING")
    println("Launching Tumor Invasion Dashboard...")
    fig = explore_potts(prob, alg;
        parameters = parameters,
        type_colors = ["#1C1C1E", "blue", "green"],
        draw_boundaries = false)
    display(fig)

    println("Press Enter to close...")
    readline()
else
    println("TESTING=true, running headless pre-solve...")
    sol = CommonSolve.solve(prob, alg)
    println("Successfully finished headless solve!")
end
