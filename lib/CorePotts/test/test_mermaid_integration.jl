using Test
using CorePotts
using Mermaid
using CommonSolve
using SciMLBase

@testset "Mermaid Integration" begin
    # 1. Setup a simple Potts simulation
    W, H = 20, 20
    N_cells = 3
    grid = zeros(UInt32, W, H)
    grid[5:10, 5:10] .= 1
    grid[12:17, 12:17] .= 2

    # Test collision handling with multiple penalties of the same type
    penalties = (VolumePenalty{Rigid}(Float32[1.0, 1.0, 1.0]),
        VolumePenalty{Rigid}(Float32[2.0, 2.0, 2.0]), AdhesionPenalty(ones(Float32, 3, 3)))
    trackers = (VolumeTracker(), SurfaceAreaTracker())

    cell_data = build_cell_data(grid, N_cells, penalties, trackers)
    cell_data.cell_types[1] = 1
    cell_data.cell_types[2] = 2
    cell_data.cell_types[3] = 1
    cell_data.volumes[3] = 0 # initially dead

    u0 = PottsState(grid, cell_data, N_cells)
    p = PottsParameters(MooreTopology{2}(), penalties, trackers)

    alg = SequentialMetropolis(; T = 1.0f0)
    prob = PottsProblem(u0, (0.0, 10.0), p)

    # 2. Create the Mermaid component
    cpm_comp = PottsComponent(prob, alg; name = "Tissue", timestep = 1.0)

    # 3. Test Initialization
    integrator = init(cpm_comp)

    # 4. Test Mermaid.variables
    vars = Mermaid.variables(cpm_comp)
    @test "#ids" in vars
    @test "#time" in vars
    @test "#state" in vars
    @test "#grid" in vars
    @test "target_volumes" in vars
    @test "VolumePenalty[1].lambdas" in vars
    @test "VolumePenalty[2].lambdas" in vars
    @test "AdhesionPenalty.J" in vars

    # 5. Test Mermaid.getstate
    @test Mermaid.getstate(integrator, Mermaid.ConnectedVariable("Tissue", "#time", nothing, nothing)) ==
          0.0
    @test Mermaid.getstate(integrator, Mermaid.ConnectedVariable("Tissue", "target_volumes", 1, nothing)) ==
          cell_data.target_volumes[1]

    # Test reading the collision penalty
    @test Mermaid.getstate(integrator,
        Mermaid.ConnectedVariable("Tissue", "VolumePenalty[2].lambdas", 2, nothing)) ==
          2.0f0

    # 6. Test Mermaid.setstate!
    # Update Cell 1's target volume to 50
    Mermaid.setstate!(integrator, Mermaid.ConnectedVariable("Tissue", "target_volumes", [1], nothing), [50.0])
    @test integrator.integrator.u.cell_data.target_volumes[1] == 50.0

    # Update Type 2's lambda to 2.0 (remember julia is 1-indexed, cell_types 1 is index 2 if type 0 exists, wait type is 1 so index 2 is for type 1)
    Mermaid.setstate!(integrator,
        Mermaid.ConnectedVariable("Tissue", "VolumePenalty[1].lambdas", [2], nothing),
        [2.0])
    @test integrator.integrator.p.penalties[1].lambdas[2] == 2.0

    # 7. Test sparse topology mapping (native dynamic topology)
    # Simulate cell 2 dying by setting its volume to 0
    integrator.integrator.u.cell_data.volumes[2] = 0
    # Simulate a new cell 3 being born
    integrator.integrator.u.cell_data.volumes[3] = 10
    integrator.integrator.u.N_cells[1] = 3

    # Now active cells are 1 and 3. "#ids" should return [1, 3]
    active_ids = Mermaid.getstate(integrator, Mermaid.ConnectedVariable("Tissue", "#ids", nothing, nothing))
    @test active_ids == [1, 3]

    # Bulk setstate! on target_volumes without variable index should map to active_ids [1, 3]
    Mermaid.setstate!(
        integrator, Mermaid.ConnectedVariable("Tissue", "target_volumes", nothing, nothing),
        [100.0, 300.0])
    @test integrator.integrator.u.cell_data.target_volumes[1] == 100.0
    @test integrator.integrator.u.cell_data.target_volumes[3] == 300.0
    # Cell 2 should remain unchanged

    # 8. Test step!
    step!(integrator)
    @test integrator.integrator.t == 1.0
end
