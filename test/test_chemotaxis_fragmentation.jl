using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
Pkg.instantiate()

using Test
using Potts.CorePotts
using Potts.CorePotts.SciMLBase

@testset "Chemotaxis Fragmentation" begin
    # 100x100 grid
    W, H = 100, 100
    grid = zeros(UInt32, W, H)

    # 10x10 square cell near the left edge
    grid[10:19, 45:54] .= 1

    # Strong linear chemical gradient C(x, y) = x
    chem_field = zeros(Float32, W, H)
    for x in 1:W
        for y in 1:H
            chem_field[x, y] = Float32(x)
        end
    end

    vol_tracker = VolumeTracker()
    vol_pen = HSTVolumePenalty{Rigid}(Float32[0.0f0, 10.0f0])

    # Positive lambda means it wants to move UP the gradient
    # Since lambda is very high and there's no volume/adhesion penalty,
    # the cell will stretch/fragment heavily if unbounded. With saturation, it should be limited.
    chem_pen = ChemotaxisPenalty(Float32[0.0f0, 500.0f0], chem_field; saturation=0.5f0)

    penalties = (vol_pen, chem_pen)
    trackers = (vol_tracker,)
    cell_data = CorePotts.build_cell_data(grid, 1, penalties, trackers)
    cell_data.volumes[1] = 100
    cell_data.target_volumes[1] = 100
    cell_data.cell_types[1] = 1

    u0 = PottsState(grid, cell_data)
    p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
    problem = PottsProblem(u0, (0, 200), p_sys)

    alg = SequentialMetropolis(; sweeps_per_step = 1, T = 1.0f0)
    integrator = CorePotts.SciMLBase.init(problem, alg)

    CorePotts.SciMLBase.solve!(integrator)
    CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 1)

    min_x, max_x = 100, 1
    count = 0
    for x in 1:W
        for y in 1:H
            if integrator.u.grid[x, y] == 1
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                count += 1
            end
        end
    end

    width = max_x - min_x + 1
    println("Final volume: ", count, ", Width: ", width)

    # We assert that the cell width is bounded (it will fail because it fragments and stretches)
    @test width < 30
end
