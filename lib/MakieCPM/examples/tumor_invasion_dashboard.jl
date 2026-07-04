# tumor_invasion_dashboard.jl
# Tumor Invasion Dashboard built using CPMToolkit, MakieCPM, and SciML Callbacks

using GLMakie
using SciMLBase
using CommonSolve
using Random
using StructArrays
using CoreCPM
using CPMToolkit
using MakieCPM
using CoreCPM.KernelAbstractions

# ==========================================
# 1. Custom Callbacks and Kernels
# ==========================================

# 1.1 Custom Topology
struct PeriodicXNoFluxYTopology{N} <: CoreCPM.AbstractTopology{N} end
CoreCPM.offsets(::PeriodicXNoFluxYTopology{2}) = ((1, 0), (0, 1), (-1, 0), (0, -1))
CoreCPM.lottery_offsets(::PeriodicXNoFluxYTopology{2}) = CoreCPM.offsets(PeriodicXNoFluxYTopology{2}())
CoreCPM.num_dirs(::PeriodicXNoFluxYTopology{2}) = Val(4)
CoreCPM.checkerboard_colors(::PeriodicXNoFluxYTopology{2}) = 2
CoreCPM.checkerboard_color(::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32}) = UInt32((coords[1] + coords[2]) % 2)

@inline function CoreCPM.get_lottery_neighbor_idx(topo::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32}, dir::Int, dims::NTuple{2, Int})
    offs = CoreCPM.lottery_offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CoreCPM.coord_to_idx((new_x, new_y), dims)
end

@inline function CoreCPM.get_neighbor_by_coord(topo::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32}, dir::UInt32, dims::NTuple{2, Int})
    offs = CoreCPM.offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CoreCPM.coord_to_idx((new_x, new_y), dims)
end

# 1.2 Stochastic Growth
struct StochasticGrowthCallback
    prob::Float32
end

@kernel function _kernel_stochastic_growth!(volumes, target_volumes, prob, step_counter, N_cells)
    i = @index(Global, Linear)
    if i <= N_cells
        if volumes[i] > 0
            seed = step_counter + UInt64(i)
            u = Float32(CoreCPM.pcg_hash(seed) >> 32) * 2.3283064f-10
            if u < prob
                target_volumes[i] += 1
            end
        end
    end
end

function (cb::StochasticGrowthCallback)(integrator)
    u = integrator.u
    cache = integrator.cache
    cache.step_counter[] += 1
    backend = KernelAbstractions.get_backend(u.grid)
    k = _kernel_stochastic_growth!(backend, cache.block_size)
    k(u.cell_data.volumes, u.cell_data.target_volumes, cb.prob, cache.step_counter[], UInt32(u.N_cells[]), ndrange=u.N_cells[])
    KernelAbstractions.synchronize(backend)
end

function sciml_stochastic_growth_callback(prob::Float32)
    cb = StochasticGrowthCallback(prob)
    condition(u, t, integrator) = true
    affect!(integrator) = cb(integrator)
    return SciMLBase.DiscreteCallback(condition, affect!)
end

# 1.3 Clock Advance
@kernel function _kernel_clock_advance!(volumes, is_proliferation_competent, mitotic_timers, N_cells)
    i = @index(Global, Linear)
    if i <= N_cells
        if volumes[i] > 0 && is_proliferation_competent[i]
            mitotic_timers[i] += 1.0f0
        end
    end
end

function sciml_clock_advance_callback()
    condition(u, t, integrator) = true
    function affect!(integrator)
        u = integrator.u
        cache = integrator.cache
        backend = KernelAbstractions.get_backend(u.grid)
        k = _kernel_clock_advance!(backend, cache.block_size)
        k(u.cell_data.volumes, u.cell_data.is_proliferation_competent, u.cell_data.mitotic_timers, UInt32(u.N_cells[]), ndrange=u.N_cells[])
        KernelAbstractions.synchronize(backend)
    end
    return SciMLBase.DiscreteCallback(condition, affect!)
end

# 1.4 Tumor Mitosis Trigger and Post-Division Cleanup
struct TumorMitosisTrigger end
CoreCPM.required_fields(::TumorMitosisTrigger) = (:cell_types, :volumes, :is_proliferation_competent, :mitotic_timers, :mitotic_thresholds)

function (trigger::TumorMitosisTrigger)(cell_id, cell_data)
    # Type IDs: Medium=0, Leader=1, Follower=2 (Medium is forced to 0 by CPMProblem constructor)
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

@kernel function _kernel_reset_mitotic_timers!(volumes, is_proliferation_competent, mitotic_timers, mitotic_thresholds, step_counter, N_cells)
    i = @index(Global, Linear)
    if i <= N_cells
        if volumes[i] > 0 && is_proliferation_competent[i]
            if mitotic_timers[i] >= mitotic_thresholds[i]
                seed1 = step_counter + UInt64(i) * UInt64(2)
                seed2 = step_counter + UInt64(i) * UInt64(2) + UInt64(1)
                
                u1 = Float32(CoreCPM.pcg_hash(seed1) >> 32) * 2.3283064f-10
                u2 = Float32(CoreCPM.pcg_hash(seed2) >> 32) * 2.3283064f-10
                
                mitotic_timers[i] = u1 * 75.0f0
                mitotic_thresholds[i] = 25.0f0 + u2 * 100.0f0
            end
        end
    end
end

function sciml_tumor_mitosis_callback(vol_pen)
    ws_ref = Ref{CoreCPM.MitosisWorkspace}()
    trigger = TumorMitosisTrigger()
    
    condition(u, t, integrator) = true
    function affect!(integrator)
        u = integrator.u
        cache = integrator.cache
        
        if !isassigned(ws_ref)
            max_c = length(u.cell_data.volumes)
            ws_ref[] = CoreCPM.MitosisWorkspace(u.grid, max_c)
        end
        
        CoreCPM.process_mitosis_events!(u, integrator.p, cache, ws_ref[]; trigger=trigger, orientation=CoreCPM.RandomOrientation(), inheritance_rules=(target_volumes=CoreCPM.Split(0.5f0),))
        CoreCPM.reset_hst_pressures_after_division!(u, cache, vol_pen)
        
        cache.step_counter[] += 1
        backend = KernelAbstractions.get_backend(u.grid)
        k = _kernel_reset_mitotic_timers!(backend, cache.block_size)
        k(u.cell_data.volumes, u.cell_data.is_proliferation_competent, u.cell_data.mitotic_timers, u.cell_data.mitotic_thresholds, cache.step_counter[], UInt32(u.N_cells[]), ndrange=u.N_cells[])
        KernelAbstractions.synchronize(backend)
    end
    return SciMLBase.DiscreteCallback(condition, affect!)
end


# ==========================================
# 2. Main Dashboard Execution
# ==========================================
Leader = CellType(:Leader)
Follower = CellType(:Follower)
Medium = CellType(:Medium)

width, height = 500, 300
chem_field = Float32[Float32(y) for x in 1:width, y in 1:height]

sys = CPMSystem(
    [Medium, Leader, Follower], # Medium=0, Leader=1, Follower=2 (IDs assigned by CPMProblem constructor)
    [
        HSTVolumeComponent(Leader => (λ=2.0f0, target=10.0), Follower => (λ=2.0f0, target=10.0); eta=5.0f0),
        ChemotaxisComponent(Leader => 20.0f0, Follower => 0.0f0; chemical_field=chem_field),
        AdhesionComponent(
            (Leader, Leader) => 16.0f0,
            (Follower, Follower) => 5.0f0,
            (Leader, Follower) => 0.0f0,
            (Leader, Medium) => 2.0f0,
            (Follower, Medium) => 10.0f0
        )
    ]
)

# 1/4th Leaders, 3/4ths Followers
total_cells = length(1:3:width) * length(1:3:21)
num_leaders = round(Int, total_cells * 0.25)
num_followers = total_cells - num_leaders

# Max cells allocated 5000 directly.
prob = CPMProblem(
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
for i in (num_leaders+1):total_cells
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
new_u0 = CPMState(prob.u0.grid, new_cell_data, prob.u0.N_cells, prob.u0.free_list)
prob = CPMProblem(new_u0, prob.tspan, prob.p)

# Initialize proliferation competent flags based on PP = 0.5f0
for i in 1:prob.u0.N_cells[]
    if prob.u0.cell_data.cell_types[i] == 2 && rand() < 0.5f0 # Follower is ID 2
        prob.u0.cell_data.is_proliferation_competent[i] = true
        prob.u0.cell_data.mitotic_timers[i] = rand() * 75.0f0
        prob.u0.cell_data.mitotic_thresholds[i] = 25.0f0 + rand() * 100.0f0
    end
end

# Assemble callbacks
vol_pen = prob.p.penalties[1] # The HSTVolumePenalty
cb_set = SciMLBase.CallbackSet(
    sciml_stochastic_growth_callback(0.015f0),
    sciml_clock_advance_callback(),
    sciml_tumor_mitosis_callback(vol_pen),
    CoreCPM.DeathCallback(max_cells=20000)
)

alg = CheckerboardMetropolis(sweeps_per_step=10, active_fraction=0.1f0, T=10.0f0)

# Build parameter sliders mapping exactly to original interactive_app.jl parameters
parameters = [
    "Noise Decay (eta)" => (
        range = 0.0f0:0.5f0:20.0f0,
        start = 5.0f0,
        action = (p, a, val) -> begin
            old_vol = p.p.penalties[1]
            new_vol = CoreCPM.HSTVolumePenalty(old_vol.lambdas, Float32(val))
            new_pens = (new_vol, p.p.penalties[2], p.p.penalties[3])
            new_p = CoreCPM.CPMParameters(p.p.topology, new_pens, p.p.trackers)
            return CoreCPM.CPMProblem(p.u0, p.tspan, new_p)
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
            return CoreCPM.CheckerboardMetropolis(
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
    fig = explore_cpm(prob, alg; 
                      parameters=parameters, 
                      solve_kwargs=(; callback=cb_set),
                      type_colors=["#1C1C1E", "blue", "green"],
                      draw_boundaries=false)
    display(fig)

    println("Press Enter to close...")
    readline()
else
    println("TESTING=true, running headless pre-solve...")
    sol = CommonSolve.solve(prob, alg; callback=cb_set)
    println("Successfully finished headless solve!")
end
