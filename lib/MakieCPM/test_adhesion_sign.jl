using CoreCPM
using Test

function test_sign()
    W, H = 10, 10
    N_cells = 2
    grid = zeros(UInt32, W, H)
    cell_data = build_cell_data(grid, N_cells)

    cell_data.cell_types[1] = 1
    cell_data.cell_types[2] = 2

    J = zeros(Float32, 3, 3)
    J[2, 3] = 1.0f0
    J[3, 2] = 1.0f0

    # Grid is all 1s except one 2 in the middle
    fill!(grid, 1)
    grid[5, 5] = 2

    u0 = CPMState(grid, cell_data)
    p_sys = CPMParameters(VonNeumannTopology{2}(), (AdhesionPenalty{Rigid}(J),), ())

    # Let's manually evaluate dH for flipping (5,6) from 1 to 2
    ctx = CoreCPM.UpdateContext(
        src = UInt32(2), tgt = UInt32(1),
        source_coords = (UInt32(4), UInt32(4)), spatial_coords = (UInt32(4), UInt32(5)),
        neighbors = UInt32[1, 1, 1, 2], # Top, Bottom, Right are 1; Left is 2
        neighbor_pixels = CartesianIndex{2}[],
        cell_data = cell_data, topology = VonNeumannTopology{2}()
    )

    # E_old = tgt is 1, surrounded by three 1s and one 2.
    # Energy of 1-1 is 0. Energy of 1-2 is 1.0. So E_old = 1.0.
    # E_new = src is 2, surrounded by three 1s and one 2.
    # Energy of 2-1 is 1.0. Energy of 2-2 is 0. So E_new = 3.0.
    # True delta H = 3.0 - 1.0 = 2.0.

    dH_computed = CoreCPM.evaluate_penalty(p_sys.penalties[1], ctx)
    println("Computed dH: ", dH_computed)
end

test_sign()
