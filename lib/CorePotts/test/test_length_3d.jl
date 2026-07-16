using Test
using CorePotts

@testset "3D Length Penalty Validation" begin
    L = 32
    W = 32
    H = 32
    grid_dims = (L, W, H)
    N_cells = 1

    # Initialize a rod-shaped cell
    grid = backend_zeros(Int32, grid_dims)
    for x in 10:22
        for y in 14:18
            for z in 14:18
                grid[x, y, z] = 1
            end
        end
    end

    # Penalties: Volume + Length
    penalties = (
        HSTVolumePenalty{Rigid}(Float32[0.0, 50.0]),
        HSTLengthPenalty{Rigid}(Float32[0.0, 100.0], 1.0f0) # high length penalty
    )

    # Set up engine
    T_val = 15.0f0
    cell_data = build_cell_data(grid, N_cells, penalties, ())

    u0 = PottsState(grid, cell_data, N_cells)
    p = PottsParameters(VonNeumannTopology{3}(), penalties, ())
    cache = PottsCache(u0, p.topology)

    u0.cell_data.cell_types[1] = 1
    u0.cell_data.target_volumes[1] = 13 * 5 * 5

    # target length = 20
    u0.cell_data.target_lengths[1] = 20.0f0

    CorePotts.sync_cell_data!(grid, cell_data, N_cells)
    CorePotts.initialize_com_anchors!(u0, p, cache)

    # Pre-simulate update auxiliary fields to test 3D COM and Inertia logic
    CorePotts.update_sweep_auxiliary!(penalties[2], u0, p, cache, T_val, 1.0f0)

    L_initial = u0.cell_data.current_lengths[1]

    @test isapprox(L_initial, 3.74f0, atol = 0.1)
    println("3D Initial Length: $L_initial")
end
