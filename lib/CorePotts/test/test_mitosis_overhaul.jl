using Test
using StructArrays
using StaticArrays

# Add CorePotts to LOAD_PATH to allow importing
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using CorePotts
using SciMLBase

@testset "Cell Life-Cycle Overhaul" begin
    dims = (100, 100)
    grid = fill(UInt32(0), dims)

    # 1. Test Dynamic Memory and Resizing
    cell_data = build_cell_data(grid, 10) # Max capacity 10
    trackers = (VolumeTracker(),)
    u0 = PottsState(grid, cell_data, 0)
    p_sys = PottsParameters(MooreTopology{2}(), (HSTVolumePenalty{Rigid}(fill(1.0f0, 10)),), trackers)
    cache = PottsCache(u0, p_sys.topology)
    ws = CorePotts.MitosisWorkspace(grid, 10)

    # Spawn 3 cells
    for i in 1:3
        u0.N_cells[] += 1
        spawn_hypersphere!(u0.grid, cache.grid_dims, (10 + i*20, 10 + i*20), 8, UInt32(i))
        u0.cell_data.cell_types[i] = 1
    end
    sync_cell_data!(u0, p_sys, cache, u0.N_cells[])

    # Artificially inflate their target volumes to trigger growth callback
    for i in 1:3
        u0.cell_data.target_volumes[i] = 10
    end

    # Apply Growth — rate=1.0f0 means probability=1.0, so every live cell always gets +1 target volume
    growth = LinearGrowthCallback(1.0f0)
    prob = PottsProblem(u0, (0, 10), p_sys)
    integrator = init(prob, ParallelMetropolis(T = 0.0f0))
    growth(integrator)
    @test u0.cell_data.target_volumes[1] == 11

    # Trigger mitosis, all 3 cells should divide. Total cells will become 6.
    process_mitosis_events!(u0, p_sys, cache, ws; trigger = VolumeThresholdTrigger(1.0f0),
        orientation = RandomOrientation())

    @test u0.N_cells[] == 6
    @test length(u0.cell_data.volumes) >= 6
    @test u0.cell_data.volumes[6] > 0

    # 2. Test Cell Death & ID Recycling
    # Kill cell 2
    u0.cell_data.target_volumes[2] = 0
    u0.cell_data.volumes[2] = 0

    process_death_events!(u0, cache, ws)
    @test u0.cell_data.cell_types[2] == 0
    @test u0.free_list[1] == UInt32(2)

    # Set targets so ONLY cell 1 divides
    for i in 1:u0.N_cells[]
        u0.cell_data.target_volumes[i] = 10000
    end
    u0.cell_data.target_volumes[1] = 5

    # Trigger another division for cell 1
    process_mitosis_events!(u0, p_sys, cache, ws; trigger = VolumeThresholdTrigger(1.0f0),
        orientation = RandomOrientation())

    # The child should reuse ID 2
    @test u0.N_cells[] == 6 # Still 6 max N_cells used!
    @test u0.cell_data.volumes[2] > 0
    @test u0.cell_data.cell_types[2] == 1
    @test isempty(u0.free_list)

    # 3. Test Oriented Mitosis (MajorAxisOrientation)
    # Reset grid and data
    fill!(u0.grid, UInt32(0))
    u0.N_cells[] = 1
    empty!(u0.free_list)

    # Spawn a highly elongated cell (Major Axis is Y axis)
    for x in 40:60
        for y in 20:80
            u0.grid[x, y] = 1
        end
    end
    sync_cell_data!(u0, p_sys, cache, 1)

    # Target volume small to force division
    u0.cell_data.target_volumes[1] = 100

    process_mitosis_events!(u0, p_sys, cache, ws; trigger = VolumeThresholdTrigger(1.0f0),
        orientation = MajorAxisOrientation())

    # If the cleavage plane normal is the minor axis (X), the cut goes through the major axis.
    # Therefore, the daughter cells should be split along X (Left vs Right).
    # Wait: MajorAxisOrientation means cleavage plane normal is MINOR axis.
    # So the cut plane is parallel to the MAJOR axis.
    # Thus, one child is on the left, one on the right.

    sync_cell_data!(u0, p_sys, cache, 2)
    vol_1 = u0.cell_data.volumes[1]
    vol_2 = u0.cell_data.volumes[2]

    @test vol_1 > 0
    @test vol_2 > 0
    # 4. Test Trait Triggers and Inheritance Rules
    # Define a custom trigger that uses a custom field
    struct ProteinTrigger end
    CorePotts.required_fields(::ProteinTrigger) = (:proteins, :target_volumes)
    function (::ProteinTrigger)(cell_id, cell_data)
        return cell_data.proteins[cell_id] > 50
    end

    # Initialize engine with custom fields
    cell_data2 = build_cell_data(grid, 5; proteins = fill!(similar(grid, Float32, 5), 0.0f0))
    u0_2 = PottsState(grid, cell_data2, 0)
    p_sys_2 = PottsParameters(MooreTopology{2}(), (HSTVolumePenalty{Rigid}(fill(1.0f0, 10)),), trackers)
    cache_2 = PottsCache(u0_2, p_sys_2.topology)
    ws_2 = CorePotts.MitosisWorkspace(grid, 10)

    u0_2.N_cells[] = 1
    u0_2.cell_data.target_volumes[1] = 100
    u0_2.cell_data.proteins[1] = 100.0f0 # Triggers division
    u0_2.cell_data.cell_types[1] = 42

    # Define rules: Volumes split 50/50 (default), Proteins split 80/20, Cell Types clone
    rules = (proteins = Split(0.2f0),)

    process_mitosis_events!(u0_2, p_sys_2, cache_2, ws_2; trigger = ProteinTrigger(),
        inheritance_rules = rules, orientation = RandomOrientation())

    sync_cell_data!(u0_2, p_sys_2, cache_2, 2)
    @test u0_2.N_cells[] == 2

    # Check inheritance
    vol_1 = u0_2.cell_data.volumes[1]
    vol_2 = u0_2.cell_data.volumes[2]

    @test u0_2.cell_data.proteins[1] == 80.0f0 # 1 - 0.2
    @test u0_2.cell_data.proteins[2] == 20.0f0 # 0.2
    @test u0_2.cell_data.cell_types[1] == 42
    @test u0_2.cell_data.cell_types[2] == 42
end
