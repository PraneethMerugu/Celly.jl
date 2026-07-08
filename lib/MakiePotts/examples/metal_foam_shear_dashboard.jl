using GLMakie
using PottsToolkit
using MakiePotts
using CorePotts
using Metal
using Adapt

# ------------------------------------------------------------------
# 1. Custom Shear Penalty
# ------------------------------------------------------------------
struct BulkShearPenalty{T} <: CorePotts.AbstractPenalty
    shear_rate::T
end

CorePotts.compute_global_energy(p::BulkShearPenalty, u, params) = 0.0f0

function CorePotts.evaluate_penalty(p::BulkShearPenalty, ctx)
    # The current boundary pixel being updated
    y = ctx.spatial_coords[2]

    # Delta x: direction of the boundary movement
    dx = Int(ctx.spatial_coords[1]) - Int(ctx.source_coords[1])

    # Handle periodic boundary conditions for the displacement
    w = ctx.grid_dims[1]
    if dx > w ÷ 2
        dx -= w
    elseif dx < -(w ÷ 2)
        dx += w
    end

    # Calculate shear relative to the vertical middle of the grid
    h = ctx.grid_dims[2]
    y_rel = Float32(y) - Float32(h) / 2.0f0

    # Gamma is the strain field (read from GPU array)
    gamma = p.shear_rate[1] * y_rel

    # Bias the Hamiltonian: favors moves in the direction of shear
    return -gamma * Float32(dx)
end

# ------------------------------------------------------------------
# 2. Custom Topology
# ------------------------------------------------------------------
struct PeriodicXNoFluxYExtendedMooreTopology{N, R} <: CorePotts.AbstractTopology{N} end

function CorePotts.offsets(::PeriodicXNoFluxYExtendedMooreTopology{2, 2})
    CorePotts.offsets(CorePotts.ExtendedMooreTopology{2, 2}())
end
function CorePotts.lottery_offsets(::PeriodicXNoFluxYExtendedMooreTopology{2, 2})
    CorePotts.offsets(CorePotts.ExtendedMooreTopology{2, 2}())
end
function CorePotts.num_dirs(::PeriodicXNoFluxYExtendedMooreTopology{2, 2})
    Val(length(CorePotts.offsets(CorePotts.ExtendedMooreTopology{2, 2}())))
end

function CorePotts.checkerboard_colors(::PeriodicXNoFluxYExtendedMooreTopology{2, 2})
    CorePotts.checkerboard_colors(CorePotts.ExtendedMooreTopology{2, 2}())
end
@inline CorePotts.checkerboard_color(::PeriodicXNoFluxYExtendedMooreTopology{2, 2},
    coords::NTuple{2, UInt32}) = CorePotts.checkerboard_color(
    CorePotts.ExtendedMooreTopology{
        2, 2}(), coords)

@inline function CorePotts.get_lottery_neighbor_idx(
        topo::PeriodicXNoFluxYExtendedMooreTopology{2, 2},
        coords::NTuple{2, UInt32}, dir::Int, dims::NTuple{2, Int})
    offs = CorePotts.lottery_offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CorePotts.coord_to_idx((new_x, new_y), dims)
end

@inline function CorePotts.get_neighbor_by_coord(
        topo::PeriodicXNoFluxYExtendedMooreTopology{2, 2},
        coords::NTuple{2, UInt32}, dir::UInt32, dims::NTuple{2, Int})
    offs = CorePotts.offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CorePotts.coord_to_idx((new_x, new_y), dims)
end

# ------------------------------------------------------------------
# 3. System Definition
# ------------------------------------------------------------------
Foam = CellType(:Foam)
Medium = CellType(:Medium)

shear_rate_mtl = MtlArray(Float32[0.0f0])
shear_penalty = BulkShearPenalty(shear_rate_mtl)

sys = PottsSystem(
    cell_types = [Foam, Medium],
    penalties = [
        VolumeComponent(Foam => (λ = 2.0f0, target = 250)),
        AdhesionComponent(
            (Foam, Foam) => 2.0f0,
            (Foam, Medium) => 15.0f0
        ),
        shear_penalty
    ]
)

# ------------------------------------------------------------------
# 4. Custom Initialization (Brick-Wall) & Problem Setup
# ------------------------------------------------------------------
function brick_wall_init!(grid::AbstractMatrix, n_cols::Int, n_rows::Int, dims::NTuple{
        2, Int})
    w, h = dims
    cell_w = w / n_cols
    cell_h = h / n_rows

    for y in 1:h
        row = Int(floor((y - 1) / cell_h))
        x_offset = (row % 2 == 1) ? (cell_w / 2) : 0.0

        for x in 1:w
            shifted_x = (x - 1 + x_offset) % w
            col = Int(floor(shifted_x / cell_w))

            cell_id = row * n_cols + col + 1
            grid[x, y] = eltype(grid)(cell_id)
        end
    end
end

println("Generating Brick-Wall partition for 500x500...")
# Create CPU problem first to compile penalties and allocate cell data
prob_cpu = PottsProblem(
    sys,
    Dict(Foam => 1000),
    (500, 500);
    tspan = (0, 500),
    topology = PeriodicXNoFluxYExtendedMooreTopology{2, 2}()
)

cpu_grid = zeros(UInt32, 500, 500)
brick_wall_init!(cpu_grid, 40, 25, (500, 500))
prob_cpu.u0.grid .= cpu_grid

# Sync the target volumes to match the exact brick-wall calculated sizes
dummy_cache = CorePotts.PottsCache(prob_cpu.u0, prob_cpu.p.topology, 128)
CorePotts.sync_cell_data!(prob_cpu.u0, prob_cpu.p, dummy_cache, 1000; set_targets = true)

# Convert to GPU State
println("Transferring state to Metal GPU...")
prob = Adapt.adapt(MtlArray, prob_cpu)

# ------------------------------------------------------------------
# 5. Burn-in Phase
# ------------------------------------------------------------------
# Configure CheckerboardMetropolis for Metal
alg = CheckerboardMetropolis(T = 1.5f0, sweeps_per_step = 5, active_fraction = 1.0f0 /
                                                                               5.0f0)

println("Starting burn-in phase: Equilibrating foam without shear...")
integrator = CorePotts.init(prob, alg)

# Run first 400 steps at finite temperature
for i in 1:400
    if i % 100 == 0
        println("  Burn-in step $i/500")
    end
    CorePotts.step!(integrator)
end

# Cool down to T = 0.0f0 for the final 100 steps
println("  Cooling down to T = 0.0...")
integrator.alg = CheckerboardMetropolis(
    sampler = integrator.alg.sampler,
    sweeps_per_step = integrator.alg.sweeps_per_step,
    active_fraction = integrator.alg.active_fraction,
    T = 0.0f0
)

for i in 401:500
    if i % 100 == 0
        println("  Burn-in step $i/500")
    end
    CorePotts.step!(integrator)
end
println("Burn-in complete.")

# Create a new problem starting from the equilibrated state
prob_burned = CorePotts.PottsProblem(integrator.u, prob.tspan, prob.p)

# ------------------------------------------------------------------
# 5.5 T1 Adjacency Tracker
# ------------------------------------------------------------------
function compute_adjacency(grid)
    edges = Set{Tuple{Int, Int}}()
    w, h = size(grid)
    for y in 1:h
        for x in 1:w
            id1 = grid[x, y]
            if id1 == 0
                continue
            end

            # Check right (periodic)
            nx = x == w ? 1 : x + 1
            id2 = grid[nx, y]
            if id2 != 0 && id1 != id2
                push!(edges, (min(id1, id2), max(id1, id2)))
            end

            # Check down (no-flux)
            if y < h
                id3 = grid[x, y + 1]
                if id3 != 0 && id1 != id3
                    push!(edges, (min(id1, id3), max(id1, id3)))
                end
            end
        end
    end
    return edges
end

function compute_t1s(sol, current_step; bin_size = 50)
    prev_step = max(1, current_step - bin_size)

    # Download GPU grids to CPU memory before iteration to avoid scalar indexing
    curr_grid_cpu = Array(sol.u[current_step].grid)
    prev_grid_cpu = Array(sol.u[prev_step].grid)

    curr_adj = compute_adjacency(curr_grid_cpu)
    prev_adj = compute_adjacency(prev_grid_cpu)

    new_edges = setdiff(curr_adj, prev_adj)
    return Float32(length(new_edges))
end

# ------------------------------------------------------------------
# 6. Interactive Dashboard
# ------------------------------------------------------------------
if !isdefined(Main, :TESTING)
    println("Launching interactive dashboard...")
    GLMakie.activate!()

    fig = explore_cpm(
        prob_burned, alg;
        draw_boundaries = true,
        metrics = [
            "Energy (Φ)" =>
                (sol, i) -> CorePotts.compute_global_energy(prob_burned.p.penalties, sol.u[i], prob_burned.p),
            "Number of T1s (50 MCS bin)" => (sol, i) -> compute_t1s(sol, i; bin_size = 50)
        ],
        parameters = [
            "Shear Rate" => (
                range = -0.1f0:0.005f0:0.1f0,
                start = 0.0f0,
                action = (p, a, val) -> begin
                    # The 3rd penalty in our tuple is the BulkShearPenalty
                    # Since prob_burned is on the GPU, we must allow scalar indexing to mutate its scalar property
                    Metal.@allowscalar prob_burned.p.penalties[3].shear_rate[1] = val
                    return a
                end
            ),
            "Sweeps Per Step" => (
                range = 1:20,
                start = 5,
                action = (p, a, val) -> begin
                    return CorePotts.CheckerboardMetropolis(
                        sampler = a.sampler,
                        T = a.T,
                        sweeps_per_step = val,
                        active_fraction = 1.0f0 / Float32(val)
                    )
                end
            ),
            "Temperature" => (
                range = 0.0f0:0.1f0:5.0f0,
                start = 0.0f0, # Start at 0 since we cooled down during burn-in
                action = (p, a, val) -> begin
                    return CorePotts.CheckerboardMetropolis(
                        sampler = a.sampler,
                        sweeps_per_step = a.sweeps_per_step,
                        active_fraction = a.active_fraction,
                        T = val
                    )
                end
            ),
            "Coupling Strength" => (
                range = 1.0f0:0.5f0:10.0f0,
                start = 2.0f0,
                action = (p, a, val) -> begin
                    # Foam is index 2, Medium is index 1
                    Metal.@allowscalar p.p.penalties[2].J[2, 2] = val
                    return a
                end
            )
        ]
    )

    display(fig)

    println("Press Enter to close...")
    readline()
end
