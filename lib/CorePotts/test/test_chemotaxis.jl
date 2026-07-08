using Test
using CorePotts

@testset "ChemotaxisPenalty Directional Migration" begin
    # 100x100 grid
    W, H = 100, 100
    grid = zeros(UInt32, W, H)

    # 20x20 square cell near the left edge (x = 10:29, y = 40:59)
    grid[10:29, 40:59] .= 1

    # Simple linear chemical gradient C(x, y) = x
    chem_field = zeros(Float32, W, H)
    for x in 1:W
        for y in 1:H
            chem_field[x, y] = Float32(x)
        end
    end

    cell_data = CorePotts.build_cell_data(grid, 1)
    cell_data.volumes[1] = 400
    cell_data.target_volumes[1] = 400
    cell_data.cell_types[1] = 1

    vol_tracker = VolumeTracker()

    vol_pen = HSTVolumePenalty{Rigid}(Float32[0.0f0, 50.0f0])

    # Positive lambda means it wants to move UP the gradient (towards +x)
    chem_pen = ChemotaxisPenalty(Float32[0.0f0, 200.0f0], chem_field)

    # Add Adhesion to keep the cell cohesive
    # J[cell, medium] = 20.0, J[cell, cell] = 0.0
    J = zeros(Float32, 2, 2)
    J[2, 1] = 20.0f0;
    J[1, 2] = 20.0f0
    adh_pen = AdhesionPenalty{Rigid}(J)

    function compute_com_x(grid)
        sum_x = 0.0f0
        count = 0
        for idx in 1:length(grid)
            if grid[idx] == 1
                c_x = (idx - 1) % W
                sum_x += c_x
                count += 1
            end
        end
        return sum_x / count
    end

    initial_x = compute_com_x(grid)

    u0 = PottsState(grid, cell_data)
    p_sys = PottsParameters(MooreTopology{2}(), (vol_pen, chem_pen, adh_pen), (vol_tracker,))
    problem = PottsProblem(u0, (0, 1000), p_sys)
    integrator = init(problem, ParallelMetropolis(; T = 10.0f0, active_fraction = 0.1f0, sweeps_per_step = 1))

    solve!(integrator)
    CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 1)

    final_x = compute_com_x(grid)

    # It should have migrated significantly rightward (+x)
    @test final_x > initial_x + 1.0f0

    # The volume should not have exploded despite constant positive Delta H from moving right
    # Because Chemotaxis uses Delta H = lambda * (C_target - C_source)
    @test abs(cell_data.volumes[1] - 400) < 50
end
