using Test
using CoreCPM

@testset "GPU Death Event Sync" begin
    W, H = 100, 100
    grid = zeros(UInt32, W, H)
    
    # Two cells
    grid[10:20, 10:20] .= 1
    grid[50:60, 50:60] .= 2
    
    cell_data = CoreCPM.build_cell_data(grid, 2)
    cell_data.volumes[1] = 121
    cell_data.volumes[2] = 0 # Dead cell
    cell_data.target_volumes[1] = 121
    cell_data.target_volumes[2] = 0 # Target 0
    cell_data.cell_types[1] = 1
    cell_data.cell_types[2] = 1
    
    penalty = HSTVolumePenalty(Float32[0.0f0, 50.0f0])
    
    u0 = CPMState(grid, cell_data, 2)
    cache = CPMCache(u0, VonNeumannTopology{2}())
    ws = CoreCPM.MitosisWorkspace(grid, 2)
    
    # Process death events
    CoreCPM.process_death_events!(u0, cache, ws)
    
    # Check that cell 2 is in free list
    @test 2 in u0.free_list
    
    # Check type is zeroed
    types_cpu = Array(u0.cell_data.cell_types)
    @test types_cpu[2] == 0
    @test types_cpu[1] == 1
    
    # Count should be 1
    @test length(u0.free_list) == 1
end
