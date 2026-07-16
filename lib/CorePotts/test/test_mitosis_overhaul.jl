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
    trackers = (VolumeTracker(),)
    penalties = (HSTVolumePenalty{Rigid}(fill(1.0f0, 10)),)
    trigger = VolumeThresholdTrigger(1.0f0)
    cell_data = build_cell_data(grid, 10, penalties, trackers, trigger) # Max capacity 10
    u0 = PottsState(grid, cell_data, 0)
    p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
    cache = PottsCache(u0, p_sys.topology)
    ws = CorePotts.MitosisWorkspace(grid, 10)

    # Spawn 3 cells
    for i in 1:3
        u0.N_cells[1] += 1
        spawn_hypersphere!(u0.grid, cache.grid_dims, (10 + i*20, 10 + i*20), 8, UInt32(i))
        u0.cell_data.cell_types[i] = 1
    end
    CorePotts.sync_cell_data!(u0, p_sys, cache, u0.N_cells[1])

    # Artificially inflate their target volumes to trigger growth callback
    for i in 1:3
        u0.cell_data.target_volumes[i] = 10
    end

    # Apply Growth manually for the test (equivalent to rate=1.0)
    prob = PottsProblem(u0, (0, 10), p_sys)
    integrator = init(prob, ParallelMetropolis(T = 0.0f0))
    
    targets = Array(integrator.u.cell_data.target_volumes)
    for i in 1:length(targets)
        if targets[i] > 0
            targets[i] += 1
        end
    end
    copyto!(integrator.u.cell_data.target_volumes, targets)
    
    @test integrator.u.cell_data.target_volumes[1] == 11

    # Trigger mitosis, all 3 cells should divide. Total cells will become 6.
    process_mitosis_events!(
        integrator.u, p_sys, cache, ws; trigger = trigger,
        orientation = RandomOrientation())

    @test integrator.u.N_cells[1] == 6
    @test length(integrator.u.cell_data.volumes) >= 6
    @test integrator.u.cell_data.volumes[6] > 0

    # 2. Test Cell Death & ID Recycling
    # Kill cell 2
    integrator.u.cell_data.target_volumes[2] = 0
    integrator.u.cell_data.volumes[2] = 0

    process_death_events!(integrator.u, cache)
    @test integrator.u.cell_data.cell_types[2] == 0
    @test Array(integrator.u.free_list_count)[1] == 1
    @test Array(integrator.u.free_list)[1] == UInt32(2)

    # Set targets so ONLY cell 1 divides
    for i in 1:integrator.u.N_cells[1]
        integrator.u.cell_data.target_volumes[i] = 10000
    end
    integrator.u.cell_data.target_volumes[1] = 5

    # Trigger another division for cell 1
    process_mitosis_events!(
        integrator.u, p_sys, cache, ws; trigger = VolumeThresholdTrigger(1.0f0),
        orientation = RandomOrientation())

    # The child should reuse ID 2
    @test integrator.u.N_cells[1] == 6 # Still 6 max N_cells used!
    @test integrator.u.cell_data.volumes[2] > 0
    @test integrator.u.cell_data.cell_types[2] == 1
    @test Array(integrator.u.free_list_count)[1] == 0

    # 3. Test Oriented Mitosis (MajorAxisOrientation)
    # Reset grid and data
    fill!(integrator.u.grid, UInt32(0))
    integrator.u.N_cells[1] = 1
    fill!(integrator.u.free_list_count, Int32(0))

    # Spawn a highly elongated cell (Major Axis is Y axis)
    for x in 40:60
        for y in 20:80
            integrator.u.grid[x, y] = 1
        end
    end
    CorePotts.sync_cell_data!(integrator.u, p_sys, cache, 1)

    # Target volume small to force division
    integrator.u.cell_data.target_volumes[1] = 100

    process_mitosis_events!(
        integrator.u, p_sys, cache, ws; trigger = VolumeThresholdTrigger(1.0f0),
        orientation = MajorAxisOrientation())

    # If the cleavage plane normal is the minor axis (X), the cut goes through the major axis.
    # Therefore, the daughter cells should be split along X (Left vs Right).
    # Wait: MajorAxisOrientation means cleavage plane normal is MINOR axis.
    # So the cut plane is parallel to the MAJOR axis.
    # Thus, one child is on the left, one on the right.

    CorePotts.sync_cell_data!(integrator.u, p_sys, cache, 2)
    vol_1 = integrator.u.cell_data.volumes[1]
    vol_2 = integrator.u.cell_data.volumes[2]

    @test vol_1 > 0
    @test vol_2 > 0
    # 4. Test Trait Triggers and Inheritance Rules
    # Define a custom trigger that uses a custom field
    struct ProteinTrigger end
    CorePotts.required_variables(::ProteinTrigger) = (proteins = Float32, target_volumes = Int32)
    function (::ProteinTrigger)(cell_id, cell_data, step)
        return cell_data.proteins[cell_id] > 50
    end

    # Initialize engine with custom fields automatically allocated
    penalties2 = (HSTVolumePenalty{Rigid}(fill(1.0f0, 10)),)
    cell_data2 = build_cell_data(grid, 5, penalties2, trackers, ProteinTrigger())
    u0_2 = PottsState(grid, cell_data2, 0)
    p_sys_2 = PottsParameters(MooreTopology{2}(), penalties2, trackers)
    cache_2 = PottsCache(u0_2, p_sys_2.topology)
    ws_2 = CorePotts.MitosisWorkspace(grid, 10)

    u0_2.N_cells[1] = 1
    u0_2.cell_data.target_volumes[1] = 100
    u0_2.cell_data.proteins[1] = 100.0f0 # Triggers division
    u0_2.cell_data.cell_types[1] = 42

    # Define rules: Volumes split 50/50 (default), Proteins split 80/20, Cell Types clone
    rules = (proteins = Split(0.2f0),)

    process_mitosis_events!(u0_2, p_sys_2, cache_2, ws_2; trigger = ProteinTrigger(),
        inheritance_rules = rules, orientation = RandomOrientation())

    CorePotts.sync_cell_data!(u0_2, p_sys_2, cache_2, 2)
    @test u0_2.N_cells[1] == 2

    # Check inheritance
    vol_1 = u0_2.cell_data.volumes[1]
    vol_2 = u0_2.cell_data.volumes[2]

    @test u0_2.cell_data.proteins[1] == 80.0f0 # 1 - 0.2
    @test u0_2.cell_data.proteins[2] == 20.0f0 # 0.2
    @test u0_2.cell_data.cell_types[1] == 42
    @test u0_2.cell_data.cell_types[2] == 42
end
