using Test
using CorePotts
using StructArrays
using KernelAbstractions

@testset "Property Updates & Spatial Buffers" begin
    # Setup cell data mock
    N_cells = 3
    cell_data = StructArray(
        cell_types = UInt8[1, 2, 1],
        volumes = Int32[10, 20, 30],
        target_volumes = Int32[20, 20, 20],
        inhibition_states = UInt8[0, 0, 0],
        anchor_x = Float32[0, 0, 0],
        anchor_y = Float32[0, 0, 0]
    )

    # 1. Test basic closure evaluation
    ctx = (t = 0, step_counter = UInt64(0), spatial_buffer = nothing)
    rule_vol = CompiledRule((c, i, ctx, current_val) -> current_val + Int32(5))
    rule_inh = CompiledRule((c, i, ctx, current_val) -> UInt8(1))

    rules = (
        volumes = rule_vol,
        inhibition_states = rule_inh
    )

    CorePotts.evaluate_and_assign_rules!(cell_data, UInt32(1), ctx, rules)
    @test cell_data.volumes[1] == 15
    @test cell_data.inhibition_states[1] == 1

    # 2. Test spatial map-reduce extraction
    # We will simulate a small grid to test populate_spatial_buffer!
    W, H = 5, 5
    grid = zeros(UInt32, W, H)
    # Cell 1 (type 1) in top left 2x2
    grid[1:2, 1:2] .= 1
    # Cell 2 (type 2) in bottom right 2x2
    grid[4:5, 4:5] .= 2
    # Cell 3 (type 1) touching Cell 1 and Cell 2
    grid[3, 3:4] .= 3
    grid[3:4, 3] .= 3

    u = PottsState(grid, cell_data, N_cells)
    topology = MooreTopology{2}()
    cache = PottsCache(u, topology)

    # Spatial rules: 
    # 1. NeighborCount of Type 2 (should be 1 for cell 3)
    # 2. NeighborSum of :volumes of Type 1 (Cell 3 touches Cell 1, so it should sum Cell 1's volume)
    sr_1 = CorePotts.NeighborCount(2, 1)
    sr_2 = CorePotts.NeighborSum{:volumes}(1, 2)
    spatial_rules = (sr_1, sr_2)

    spatial_buffer, ev = CorePotts.populate_spatial_buffer!(
        u, topology, cache, spatial_rules, nothing)
    KernelAbstractions.synchronize(KernelAbstractions.get_backend(grid))

    # Convert to CPU for testing
    cpu_buf = Array(spatial_buffer)

    # spatial_buffer layout: buf_idx = (rule.buffer_index - 1) * N_cells + cell_id
    # Rule 1 (buffer_index = 1): NeighborCount of Type 2
    # Cell 3 touches Cell 2. Cell 2 is type 2. So Cell 3 should have count 1.
    @test cpu_buf[(1 - 1) * N_cells + 3] == 1.0f0

    # Rule 2 (buffer_index = 2): NeighborSum of :volumes of Type 1
    # Cell 3 touches Cell 1. Cell 1 is type 1. Cell 1's volume is 15 (after previous test).
    @test cpu_buf[(2 - 1) * N_cells + 3] == 15.0f0

    # Test ContactArea in map phase
    sr_3 = CorePotts.ContactArea(0, 1) # count contact with medium (id 0)
    spatial_buffer2, ev2 = CorePotts.populate_spatial_buffer!(
        u, topology, cache, (sr_3,), nothing)
    KernelAbstractions.synchronize(KernelAbstractions.get_backend(grid))
    cpu_buf2 = Array(spatial_buffer2)

    # Cell 1 (2x2 = 4 pixels) touches the medium on its outer edges.
    # We can just check it's > 0 for now.
    @test cpu_buf2[1] > 0
end
