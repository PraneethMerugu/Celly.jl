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
import Adapt
# ==========================================
# 1. Custom Monolayer Component
# ==========================================
struct MonolayerPenalty <: CorePotts.AbstractPenalty{CorePotts.Rigid} end
CorePotts.evaluate_penalty(::MonolayerPenalty, ctx) = 0.0f0

struct MonolayerGrowthComponent <: AbstractComponent
    initial_area::Float32
    initial_div_thresh::Int32
end

import PottsToolkit.Problem: compile_component
import PottsToolkit.System: required_variables

function required_variables(::MonolayerGrowthComponent)
    (
        free_surfaces = Int32,
        inhibition_states = UInt8,
        target_volumes_float = Float32,
        division_threshold_volumes = Int32
    )
end

function compile_component(
        comp::MonolayerGrowthComponent, sys::PottsToolkit.System.PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int64)
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
# 2. 100% GPU Native Continuous Growth Callback
# ==========================================
struct MonolayerGrowthEvent <: CorePotts.AbstractMultiEvent
    alpha::Base.RefValue{Float32}
    beta::Base.RefValue{Float32}
    gamma::Base.RefValue{Float32}
    dt::Float32
    max_cells::Int
end

@kernel function monolayer_growth_kernel!(
        volumes, target_volumes, target_volumes_float, target_surface_areas, surface_areas,
        free_surfaces, inhibition_states, N_cells, evt_alpha, evt_beta, evt_gamma, evt_dt)
    i = @index(Global, Linear)
    if i <= N_cells[1]
        v = volumes[i]
        if v > 0
            tv = target_volumes[i]
            inhibited_type1 = (Float32(v) / Float32(tv)) < evt_beta

            fi = surface_areas[i] > 0 ?
                 (Float32(free_surfaces[i]) / Float32(surface_areas[i])) : 0.0f0
            inhibited_type2 = fi < evt_gamma

            state = UInt8(0)
            if inhibited_type1
                state += UInt8(1)
            end
            if inhibited_type2
                state += UInt8(2)
            end
            inhibition_states[i] = state

            if state == 0
                target_volumes_float[i] += evt_alpha * evt_dt
                target_volumes[i] = floor(Int32, target_volumes_float[i])
                target_surface_areas[i] = floor(
                    Int32, 4.0f0 * sqrt(target_volumes_float[i]))
            end
        else
            inhibition_states[i] = UInt8(0)
        end
    end
end

struct ApplyMonolayerGrowthEvent <: CorePotts.AbstractEvent
    alpha::Base.RefValue{Float32}
    beta::Base.RefValue{Float32}
    gamma::Base.RefValue{Float32}
    dt::Float32
end
function CorePotts.get_event_kernel(::ApplyMonolayerGrowthEvent, backend, block_size)
    monolayer_growth_kernel!(backend, block_size)
end
function CorePotts.get_event_args(evt::ApplyMonolayerGrowthEvent, mask, u, p, cache, t)
    (u.cell_data.volumes, u.cell_data.target_volumes, u.cell_data.target_volumes_float,
        u.cell_data.target_surface_areas, u.cell_data.surface_areas,
        u.cell_data.free_surfaces, u.cell_data.inhibition_states,
        u.N_cells, evt.alpha[], evt.beta[], evt.gamma[], evt.dt)
end
function CorePotts.get_event_ndrange(::ApplyMonolayerGrowthEvent, mask, u)
    length(u.cell_data.volumes)
end

function CorePotts.get_sub_events(evt::MonolayerGrowthEvent)
    (
        PropertyUpdateEvent(CellType(:Tissue, UInt8(1)), (free_surfaces = ContactArea(UInt8(0)),)),
        ApplyMonolayerGrowthEvent(evt.alpha, evt.beta, evt.gamma, evt.dt)
    )
end

# ==========================================
# 3. 100% GPU Native Mitosis Actions (PCG Noise)
# ==========================================
function monolayer_mitosis_trigger(cell_id, cell_data)
    if cell_data.volumes[cell_id] > 0 &&
       cell_data.volumes[cell_id] >= cell_data.division_threshold_volumes[cell_id]
        return true
    end
    return false
end

@kernel function monolayer_post_mitosis_kernel!(dev_parents, dev_children, target_volumes,
        division_threshold_volumes, current_seed, num_divisions)
    i = @index(Global, Linear)
    if i <= num_divisions
        parent_id = dev_parents[i]
        child_id = dev_children[i]

        p_seed = current_seed + UInt64(parent_id) * 0x0000000000000001
        c_seed = current_seed + UInt64(child_id) * 0x0000000000000001

        noise_parent = CorePotts.randn_pcg(p_seed, p_seed + UInt64(0x12345678))
        noise_child = CorePotts.randn_pcg(c_seed, c_seed + UInt64(0x87654321))

        X2 = 2.0f0 + 0.4f0 * noise_parent
        X3 = 2.0f0 + 0.4f0 * noise_child

        parent_new_target = Float32(target_volumes[parent_id])
        child_new_target = Float32(target_volumes[child_id])

        division_threshold_volumes[parent_id] = floor(Int32, parent_new_target * X2)
        division_threshold_volumes[child_id] = floor(Int32, child_new_target * X3)
    end
end

function monolayer_post_mitosis_action(u, p, cache, ws, num_divisions)
    current_seed = UInt64(time_ns())
    backend = CorePotts.KernelAbstractions.get_backend(u.grid)
    k = monolayer_post_mitosis_kernel!(backend, cache.block_size)
    ev = k(ws.dev_parents, ws.dev_children, u.cell_data.target_volumes,
        u.cell_data.division_threshold_volumes, current_seed,
        num_divisions, ndrange = length(ws.dev_parents))
    return ev
end

# ==========================================
# 4. Setup and Run
# ==========================================
function run_dashboard()
    println("Setting up the Monolayer Benchmark Model...")

    grid_size = (800, 800)
    R = 5.0f0
    initial_area = Float32(pi * R^2)
    alpha_ref = Ref(initial_area / 26520.0f0) # Calibrated alpha!
    beta_ref = Ref(0.8f0)
    gamma_ref = Ref(0.2f0)
    X1 = max(1.1f0, 2.0f0 + 0.4f0 * randn(Float32))
    initial_div_thresh = floor(Int32, initial_area * X1)

    max_cells = 250_000

    medium = CellType(:Medium, is_background = true)
    tissue = CellType(:Tissue)

    sys = PottsSystem(
        cell_types = [medium, tissue],
        penalties = [
            VolumeComponent(tissue => (λ = 5.0f0, target = initial_area)),
            SurfaceAreaComponent(tissue =>
                (λ = 0.5f0, target = 4.0f0 * sqrt(initial_area))),
            AdhesionComponent(
                (medium, tissue) => 0.0f0,
                (tissue, tissue) => 0.0f0
            ),
            ConnectivityConstraint(),
            MonolayerGrowthComponent(initial_area, initial_div_thresh)
        ],
        check_interval = 1,
        events = (
            MitosisEvent(tissue,
                trigger = CustomTrigger(monolayer_mitosis_trigger),
                inheritance = (
                    target_volumes = CorePotts.Split(0.5f0),
                    target_volumes_float = CorePotts.Split(0.5f0),
                    division_threshold_volumes = CorePotts.Split(0.5f0)
                ),
                action = monolayer_post_mitosis_action
            ),
            MonolayerGrowthEvent(alpha_ref, beta_ref, gamma_ref, 1.0f0, max_cells)
        )
    )

    layout = HypersphereLayout(tissue, (400, 400), Int(round(R)))

    # Using the new extended PottsProblem with MTK-style declarative initialization!
    prob = PottsProblem(sys, layout, grid_size;
        max_cells = max_cells,
        tspan = (0, 2000),
        topology = CorePotts.NoFluxMooreTopology{2}())

    # We leave ArrayType adaptation out here so the user can just use CPU arrays for explore_potts
    # since explore_potts requires CPU arrays. Wait, they might want GPU. 
    # Let's check how MakiePotts handles it. Usually `explore_potts` expects a CPU array 
    # or you can adapt it to GPU if MakiePotts supports GPU arrays.
    # Actually, let's keep it as is, or let the user decide. MakiePotts does not support GPU arrays out of the box yet?
    # Actually, in the old file, they had `prob = Adapt.adapt(Array, prob)` before explore_potts!
    prob = Adapt.adapt(Array, prob)

    alg = CheckerboardMetropolis(T = 20.0f0, active_fraction = 1.0f0)

    parameters = [
        "Sweeps per Step" => (
            range = 1:1:20,
            start = 1,
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
        "Growth Rate (α)" => (
            range = 0.0:0.2:1.0,
            start = alpha_ref[],
            action = (p, a, val) -> begin
                alpha_ref[] = Float32(val)
                return nothing
            end
        ),
        "Type 1 Thresh (β)" => (
            range = 0.0:0.05:1.0,
            start = beta_ref[],
            action = (p, a, val) -> begin
                beta_ref[] = Float32(val)
                return nothing
            end
        ),
        "Perimeter Constraint (λp)" => (
            range = 0.0:0.5:10.0,
            start = 0.5,
            action = (p, a, val) -> begin
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
        fig = explore_potts(prob, alg;
            parameters = parameters,
            metrics = metrics,
            solve_kwargs = (; saveat = 5),
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
        sol = CommonSolve.solve(prob, alg)
        println("Successfully finished headless solve!")
    end
end

run_dashboard()
