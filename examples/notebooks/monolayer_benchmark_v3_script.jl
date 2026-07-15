# ==========================================
# 0. Ephemeral GPU Library Setup
# ==========================================
using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

temp_env = mktempdir()
Pkg.activate(temp_env)

# Uncomment the GPU library you want to install for this session:
Pkg.add("Metal")           # --- Apple Silicon (Mac) ---
# Pkg.add("CUDA")          # --- NVIDIA GPUs ---
# Pkg.add("AMDGPU")        # --- AMD GPUs ---

push!(LOAD_PATH, temp_env)
Pkg.activate(@__DIR__)
println("\nGPU Library installed ephemerally! Environment is clean.")
# ==========================================
# Hardware Backend Selection
# ==========================================

# --- Apple Silicon (Mac) ---
using Metal
backend = MetalBackend()
ArrayType = MtlArray

# --- NVIDIA GPUs ---
# using CUDA
# backend = CUDABackend()
# ArrayType = CuArray

# --- AMD GPUs ---
# using AMDGPU
# backend = ROCBackend()
# ArrayType = ROCArray

using SciMLBase
using CommonSolve
using LinearAlgebra
using Random
using StructArrays
using CorePotts
using CorePotts.KernelAbstractions
using CorePotts.Atomix
using PottsToolkit
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

function compile_component(comp::MonolayerGrowthComponent, sys::PottsSystem,
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
        alpha, beta, gamma, dt, dev_N_cells)
    i = @index(Global, Linear)

    # ZERO SYNC FIX: Read N_cells natively on the GPU!
    if i <= dev_N_cells[1]
        v = volumes[i]
        if v > 0
            tv = target_volumes[i]
            inhibited_type1 = (Float32(v) / Float32(tv)) < beta

            fi = surface_areas[i] > 0 ?
                 (Float32(free_surfaces[i]) / Float32(surface_areas[i])) : 0.0f0
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
                target_surface_areas[i] = floor(Int32, 4.0f0 *
                                                       sqrt(target_volumes_float[i]))
            end
        else
            inhibition_states[i] = UInt8(0)
        end
    end
end

struct MonolayerGrowthCallback
    alpha::Float32
    beta::Float32
    gamma::Float32
    dt::Float32
    max_cells::Int  # Upper bound for kernel launch to avoid N_cells[] sync
end

function (cb::MonolayerGrowthCallback)(integrator)
    u = integrator.u
    cache = integrator.cache
    backend = KernelAbstractions.get_backend(u.grid)

    fill!(u.cell_data.free_surfaces, Int32(0))

    k1 = _kernel_compute_free_surfaces!(backend, cache.block_size)
    k1(u.cell_data.free_surfaces, u.grid, integrator.p.topology,
        cache.grid_dims, ndrange = length(u.grid))

    # ZERO SYNC FIX: Launch up to max_cells, avoid scalar indexing sync entirely
    k2 = _kernel_monolayer_growth!(backend, cache.block_size)
    k2(u.cell_data.volumes, u.cell_data.target_volumes, u.cell_data.target_volumes_float,
        u.cell_data.surface_areas, u.cell_data.target_surface_areas,
        u.cell_data.free_surfaces, u.cell_data.inhibition_states,
        cb.alpha, cb.beta, cb.gamma, cb.dt,
        u.N_cells, # Passing the GPU Array directly!
        ndrange = cb.max_cells)

    # No explicit synchronization needed here. It will run asynchronously on the GPU.
end

function sciml_monolayer_growth_callback(alpha, beta, gamma, dt, max_cells)
    cb = MonolayerGrowthCallback(alpha, beta, gamma, dt, max_cells)
    return SciMLBase.DiscreteCallback((u, t, integrator) -> true, cb)
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

@kernel function _kernel_monolayer_post_mitosis!(
        target_volumes, division_threshold_volumes,
        dev_parents, dev_children, seed_base)
    i = @index(Global, Linear)

    parent_id = dev_parents[i]
    child_id = dev_children[i]

    # Combine time (seed_base) and space (i) into a globally unique seed
    p_seed = seed_base + UInt64(parent_id) * 0x0000000000000001
    c_seed = seed_base + UInt64(child_id) * 0x0000000000000001

    # Generate unique normally distributed noise entirely on the GPU
    noise_parent = CorePotts.randn_pcg(p_seed, p_seed + UInt64(0x12345678))
    noise_child = CorePotts.randn_pcg(c_seed, c_seed + UInt64(0x87654321))

    X2 = max(1.1f0, 2.0f0 + 0.4f0 * noise_parent)
    X3 = max(1.1f0, 2.0f0 + 0.4f0 * noise_child)

    parent_new_target = Float32(target_volumes[parent_id])
    child_new_target = Float32(target_volumes[child_id])

    # Assign the new thresholds directly in VRAM
    division_threshold_volumes[parent_id] = floor(Int32, parent_new_target * X2)
    division_threshold_volumes[child_id] = floor(Int32, child_new_target * X3)
end

function monolayer_post_mitosis_action(u, p, cache, ws, num_divisions)
    backend = KernelAbstractions.get_backend(u.grid)

    # Generate a unique seed on the CPU based on the current system time
    current_seed = UInt64(time_ns())

    # Launch the kernel: everything stays in VRAM!
    k = _kernel_monolayer_post_mitosis!(backend, cache.block_size)
    k(u.cell_data.target_volumes, u.cell_data.division_threshold_volumes,
        ws.dev_parents, ws.dev_children, current_seed,
        ndrange = num_divisions)
end
# ==========================================
# 4. Setup and Run (1200x1200 grid)
# ==========================================
println("Setting up the Monolayer Benchmark Model on GPU...")

grid_size = (1200, 1200)
max_cells = 20_000
R = 5.0f0
initial_area = Float32(pi * R^2)
alpha = initial_area / 20.0f0
import Random;
Random.seed!(42)
X1 = max(1.1f0, 2.0f0 + 0.4f0 * randn(Float32))
initial_div_thresh = floor(Int32, initial_area * X1)

medium = CellType(:Medium, is_background = true)
tissue = CellType(:Tissue)

sys = PottsSystem(
    cell_types = [medium, tissue],
    penalties = [
        VolumeComponent(tissue => (λ = 5.0f0, target = initial_area)),
        SurfaceAreaComponent(tissue => (λ = 0.5f0, target = 4.0f0*sqrt(initial_area))),
        AdhesionComponent(
            (medium, tissue) => 0.0f0,
            (tissue, tissue) => 0.0f0
        ),
        ConnectivityConstraint(),
        MonolayerGrowthComponent(initial_area, initial_div_thresh)
    ],
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
    )
)

layout = HypersphereLayout(tissue, (600, 600), Int(round(R)))

prob = PottsProblem(sys, layout, grid_size;
    max_cells = max_cells,
    tspan = (0, 1200),
    topology = CorePotts.NoFluxMooreTopology{2}())

import Adapt
prob = Adapt.adapt(ArrayType, prob)
alg = CheckerboardMetropolis(T = 20.0f0, active_fraction = 1.0f0)

beta_val = 0.8f0
gamma_val = 0.2f0

println("Starting Simulation for 1,200 steps (Zero-Sync Mode)...")
growth_cb = sciml_monolayer_growth_callback(alpha, beta_val, gamma_val, 1.0f0, max_cells)

@time sol = CommonSolve.solve(prob, alg; callback = growth_cb, saveat = 5)

println("Simulation Complete! Final cell count: ", sol.u[end].N_cells[])
import Pkg;
Pkg.add("CairoMakie")
# ==========================================
# 5. Record the Simulation Video
# ==========================================
using MakiePotts
using CairoMakie

println("Rendering video to monolayer_benchmark_v3.mp4...")

colors = ["#FFFFFF", "#00FF00", "#FF0000", "#0000FF", "#800080"]

metrics = [
    "Cell Population" => u -> u.N_cells[],
    "Total Tissue Area" => u -> begin
        n = u.N_cells[]
        sum(Array(@view u.cell_data.volumes[1:n]))
    end,
    "Fraction Growing" => u -> begin
        n = u.N_cells[]
        states = Array(@view u.cell_data.inhibition_states[1:n])
        count(==(0), states) / max(1, n)
    end
]

record_potts("monolayer_benchmark_v3.mp4", sol;
    framerate = 10,
    metrics = metrics,
    type_colors = colors,
    color_property = :inhibition_states,
    color_offset = 1,
    draw_boundaries = true,
    boundary_color = "#000000"
)

println("Video saved successfully!")
