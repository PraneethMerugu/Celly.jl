# examples/dashboards/monolayer_benchmark_dashboard.jl

using GLMakie
using SciMLBase
using CommonSolve
using LinearAlgebra
using Random
using StructArrays
using CorePotts
using CorePotts.KernelAbstractions
using CorePotts.Atomix
using PottsToolkit
using MakiePotts

# ==========================================
# 1. Custom Monolayer Component & Penalty
# ==========================================

# A dummy penalty that costs 0.0, just to satisfy the Penalty tuple signature
struct MonolayerPenalty <: CorePotts.AbstractPenalty{CorePotts.Rigid} end
CorePotts.evaluate_penalty(::MonolayerPenalty, ctx) = 0.0f0

struct MonolayerGrowthComponent <: AbstractComponent
    initial_area::Float32
    initial_div_thresh::Int32
end

import PottsToolkit.Problem: compile_component, required_variables

# Declarative memory allocation hook!
required_variables(::MonolayerGrowthComponent) = (
    free_surfaces = Int32,
    inhibition_states = UInt8,
    target_volumes_float = Float32,
    division_threshold_volumes = Int32
)

function compile_component(comp::MonolayerGrowthComponent, type_to_id, num_types)
    trackers = [CorePotts.SurfaceAreaTracker()]
    
    props = Dict{UInt8, Dict{Symbol, Any}}()
    for (ct, id) in type_to_id
        if ct.name == :Tissue
            props[id] = Dict(
                :target_volumes_float => comp.initial_area,
                :target_volumes => floor(Int32, comp.initial_area),
                :target_surface_areas => floor(Int32, 4.0f0 * sqrt(comp.initial_area)),
                :division_threshold_volumes => comp.initial_div_thresh
            )
        end
    end
    
    return (MonolayerPenalty(), trackers, props)
end

# ==========================================
# 2. Custom Callbacks
# ==========================================

@kernel function _kernel_compute_free_surfaces!(free_surfaces, grid, topo, dims)
    i = @index(Global, Linear)
    cell_id = grid[i]
    if cell_id > 0
        coords = CorePotts.idx_to_coord(UInt32(i), dims)
        n_med = Int32(0)
        for d in 1:length(CorePotts.offsets(topo))
            n_idx = CorePotts.get_neighbor_by_coord(topo, coords, UInt32(d), dims)
            if grid[n_idx] == 0
                n_med += Int32(1)
            end
        end
        if n_med > 0
            Atomix.@atomic free_surfaces[cell_id] += n_med
        end
    end
end

@kernel function _kernel_monolayer_growth!(
        volumes, target_volumes, target_volumes_float,
        surface_areas, target_surface_areas, free_surfaces, inhibition_states,
        alpha, beta, gamma, dt, N_cells)
    i = @index(Global, Linear)
    if i <= N_cells
        v = volumes[i]
        if v > 0
            tv = target_volumes[i]
            # Type 1: inhibited if a_i = A_i / A_i^* < \beta (meaning it is too compressed)
            inhibited_type1 = (Float32(v) / Float32(tv)) < beta
            
            # Type 2: inhibited if f_i = free_surface / total_surface < \gamma
            fi = surface_areas[i] > 0 ? (Float32(free_surfaces[i]) / Float32(surface_areas[i])) : 0.0f0
            inhibited_type2 = fi < gamma
            
            state = UInt8(0)
            if inhibited_type1
                state += UInt8(1)
            end
            if inhibited_type2
                state += UInt8(2)
            end
            inhibition_states[i] = state
            
            if state == 0
                target_volumes_float[i] += alpha * dt
                target_volumes[i] = floor(Int32, target_volumes_float[i])
                target_surface_areas[i] = floor(Int32, 4.0f0 * sqrt(target_volumes_float[i]))
            end
        else
            inhibition_states[i] = UInt8(0)
        end
    end
end

struct MonolayerGrowthCallback
    alpha::Float32
    beta::Base.RefValue{Float32}
    gamma::Base.RefValue{Float32}
    dt::Float32
end

function (cb::MonolayerGrowthCallback)(integrator)
    u = integrator.u
    cache = integrator.cache
    backend = KernelAbstractions.get_backend(u.grid)
    
    # 1. Reset free_surfaces
    fill!(u.cell_data.free_surfaces, Int32(0))
    KernelAbstractions.synchronize(backend)
    
    # 2. Compute free surfaces
    k1 = _kernel_compute_free_surfaces!(backend, cache.block_size)
    k1(u.cell_data.free_surfaces, u.grid, integrator.p.topology, cache.grid_dims, ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)
    
    # 3. Apply growth and compute inhibition states
    k2 = _kernel_monolayer_growth!(backend, cache.block_size)
    k2(u.cell_data.volumes, u.cell_data.target_volumes, u.cell_data.target_volumes_float,
       u.cell_data.surface_areas, u.cell_data.target_surface_areas, u.cell_data.free_surfaces, u.cell_data.inhibition_states,
       cb.alpha, cb.beta[], cb.gamma[], cb.dt, UInt32(u.N_cells[]), ndrange = u.N_cells[])
    KernelAbstractions.synchronize(backend)
end

function sciml_monolayer_growth_callback(alpha, beta_ref, gamma_ref, dt)
    cb = MonolayerGrowthCallback(alpha, beta_ref, gamma_ref, dt)
    condition(u, t, integrator) = true
    affect!(integrator) = cb(integrator)
    return SciMLBase.DiscreteCallback(condition, affect!)
end

# ==========================================
# 3. Custom Mitosis Trigger & Callback
# ==========================================

struct MonolayerMitosisTrigger end

CorePotts.required_fields(::MonolayerMitosisTrigger) = (:volumes, :division_threshold_volumes)

function (trigger::MonolayerMitosisTrigger)(cell_id, cell_data)
    if cell_data.volumes[cell_id] > 0 && cell_data.volumes[cell_id] >= cell_data.division_threshold_volumes[cell_id]
        return true
    end
    return false
end

function sciml_monolayer_mitosis_callback()
    ws_ref = Ref{CorePotts.MitosisWorkspace}()
    trigger = MonolayerMitosisTrigger()
    
    function perform_mitosis!(integrator)
        u = integrator.u
        p = integrator.p
        cache = integrator.cache
        
        if !isassigned(ws_ref)
            max_c = length(u.cell_data.volumes)
            ws_ref[] = CorePotts.MitosisWorkspace(u.grid, max_c)
        end
        
        num_divisions = CorePotts.populate_dividing_parents!(u, cache, trigger, ws_ref[])
        if num_divisions == 0
            return
        end
        
        CorePotts.process_mitosis_events!(
            u, p, cache, ws_ref[]; trigger = trigger,
            orientation = CorePotts.RandomOrientation(),
            inheritance_rules = (
                target_volumes = CorePotts.Split(0.5f0),
                target_volumes_float = CorePotts.Split(0.5f0)
            ))
            
        parents = @view ws_ref[].dev_parents[1:num_divisions]
        children = @view ws_ref[].dev_children[1:num_divisions]
        
        for i in 1:num_divisions
            p_id = parents[i]
            c_id = children[i]
            
            # Reset inhibition states
            u.cell_data.inhibition_states[p_id] = 0
            u.cell_data.inhibition_states[c_id] = 0
            
            # Draw new division thresholds: X_i ~ N(2, 0.4)
            p_area = u.cell_data.target_volumes_float[p_id]
            X1 = max(1.1f0, 2.0f0 + 0.4f0 * randn(Float32))
            X2 = max(1.1f0, 2.0f0 + 0.4f0 * randn(Float32))
            
            u.cell_data.division_threshold_volumes[p_id] = floor(Int32, p_area * X1)
            u.cell_data.division_threshold_volumes[c_id] = floor(Int32, p_area * X2)
            
            u.cell_data.target_surface_areas[p_id] = floor(Int32, 4.0f0 * sqrt(p_area))
            u.cell_data.target_surface_areas[c_id] = floor(Int32, 4.0f0 * sqrt(p_area))
        end
        
        # Reset tracker values physically
        fill!(u.cell_data.volumes, Int32(0))
        fill!(u.cell_data.surface_areas, Int32(0))
        CorePotts.initialize_metrics!(p.trackers[1], u.cell_data, u.grid, p.topology, cache.grid_dims)
        CorePotts.initialize_metrics!(p.trackers[2], u.cell_data, u.grid, p.topology, cache.grid_dims)
    end
    
    return SciMLBase.DiscreteCallback((u, t, integrator) -> true, perform_mitosis!)
end

# ==========================================
# 4. Setup and Dashboard
# ==========================================

function run_dashboard()
    println("Setting up the Monolayer Benchmark Model...")
    
    grid_size = (800, 800)
    R = 5.0f0
    initial_area = Float32(pi * R^2)
    alpha = initial_area / 20.0f0 # cell area growth rate (doubles in 20 units)
    X1 = max(1.1f0, 2.0f0 + 0.4f0 * randn(Float32))
    initial_div_thresh = floor(Int32, initial_area * X1)

    # Declarative PottsSystem for physics compilation!
    medium = CellType(:Medium)
    tissue = CellType(:Tissue)
    
    sys = PottsSystem([medium, tissue],
        [
            VolumeComponent(tissue => (λ = 5.0f0, target = initial_area)),
            SurfaceAreaComponent(tissue => (λ = 2.0f0, target = 4.0f0*sqrt(initial_area))),
            AdhesionComponent(
                (medium, tissue) => 0.0f0, 
                (tissue, tissue) => 0.0f0
            ),
            ConnectivityConstraint(),     # Prevent fragmentation topologically!
            MonolayerGrowthComponent(initial_area, initial_div_thresh)    # Custom plugin API for allocating required properties!
        ]
    )
    
    # Declarative explicit layout primitive!
    layout = HypersphereLayout(tissue, (400, 400), Int(round(R)))

    # Using the new extended PottsProblem with MTK-style declarative initialization!
    prob = PottsProblem(sys, layout, grid_size; 
                        max_cells = 250_000, 
                        tspan=(0, 2000),
                        topology = CorePotts.NoFluxMooreTopology{2}())
    alg = CheckerboardMetropolis(T=20.0f0, active_fraction=1.0f0/10.0f0)
    
    # Dynamic controls
    beta_ref = Ref(0.8f0)
    gamma_ref = Ref(0.2f0)
    
    # Callbacks
    growth_cb = sciml_monolayer_growth_callback(alpha, beta_ref, gamma_ref, 1.0f0)
    mitosis_cb = sciml_monolayer_mitosis_callback()
    callbacks = SciMLBase.CallbackSet(growth_cb, mitosis_cb)
    
    # Dashboard parameter controls
    parameters = [
        "Type 1 Thresh (β)" => (
            range = 0.0:0.05:1.0,
            start = 0.8,
            action = (p, a, val) -> begin
                beta_ref[] = Float32(val)
                return nothing
            end
        ),
        "Type 2 Thresh (γ)" => (
            range = 0.0:0.05:1.0,
            start = 0.2,
            action = (p, a, val) -> begin
                gamma_ref[] = Float32(val)
                return nothing
            end
        ),
        "Sweeps per Step" => (
            range = 1:1:20,
            start = 10,
            action = (p, a, val) -> begin
                return CorePotts.CheckerboardMetropolis(
                    sampler = a.sampler,
                    sweeps_per_step = val,
                    active_fraction = 1.0f0 / Float32(val),
                    T = a.T
                )
            end
        ),
        "Temperature (T)" => (
            range = 1.0:1.0:50.0,
            start = 20.0,
            action = (p, a, val) -> begin
                return CorePotts.CheckerboardMetropolis(
                    sampler = a.sampler,
                    sweeps_per_step = a.sweeps_per_step,
                    active_fraction = a.active_fraction,
                    T = Float32(val)
                )
            end
        ),
        "Perimeter Constraint (λp)" => (
            range = 0.0:0.5:10.0,
            start = 2.0,
            action = (p, a, val) -> begin
                # Look for the HSTSurfaceAreaPenalty in the penalty tuple
                for pen in p.p.penalties
                    if pen isa CorePotts.HSTSurfaceAreaPenalty
                        pen.lambdas[2] = Float32(val)
                    end
                end
                return nothing
            end
        )
    ]
    
    metrics = [
        "Cell Population" => u -> Int(u.N_cells[])
    ]
    
    # Dynamic colormap: White(Medium), Green(Growing), Red(Type1), Blue(Type2), Purple(Both)
    colors = ["#FFFFFF", "#00FF00", "#FF0000", "#0000FF", "#800080"]

    if !haskey(ENV, "TESTING")
        println("Launching Monolayer Dashboard...")
        fig = explore_cpm(prob, alg;
            parameters = parameters,
            metrics = metrics,
            solve_kwargs = (; callback = callbacks, saveat = 5),
            type_colors = colors,
            color_property = :inhibition_states,
            color_offset = 1,
            draw_boundaries = true,
            boundary_color = "#000000"
        )
        display(fig)

        println("Press Enter to close...")
        readline()
    else
        println("TESTING=true, running headless pre-solve...")
        sol = CommonSolve.solve(prob, alg; callback = callbacks)
        println("Successfully finished headless solve!")
    end
end

run_dashboard()
