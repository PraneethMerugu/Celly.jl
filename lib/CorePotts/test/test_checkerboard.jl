using Test
using CorePotts
import CorePotts: checkerboard_color, checkerboard_colors

using SciMLBase
@testset "Checkerboard Coloring Rules" begin
    @test checkerboard_colors(VonNeumannTopology{2}()) == 2
    @test checkerboard_colors(MooreTopology{2}()) == 4
    @test checkerboard_colors(ExtendedVonNeumannTopology{2, 3}()) == 8
    @test checkerboard_colors(ExtendedMooreTopology{2, 3}()) == 16

    @test checkerboard_color(VonNeumannTopology{2}(), (UInt32(0), UInt32(0))) == 0
    @test checkerboard_color(VonNeumannTopology{2}(), (UInt32(1), UInt32(0))) == 1
    @test checkerboard_color(VonNeumannTopology{2}(), (UInt32(0), UInt32(1))) == 1
    @test checkerboard_color(VonNeumannTopology{2}(), (UInt32(1), UInt32(1))) == 0

    @test checkerboard_color(MooreTopology{2}(), (UInt32(0), UInt32(0))) == 0
    @test checkerboard_color(MooreTopology{2}(), (UInt32(1), UInt32(0))) == 1
    @test checkerboard_color(MooreTopology{2}(), (UInt32(0), UInt32(1))) == 2
    @test checkerboard_color(MooreTopology{2}(), (UInt32(1), UInt32(1))) == 3
end

@testset "Checkerboard Metropolis Compilation" begin
    dims = (50, 50)
    grid = ones(Int32, dims)

    # Init 1 cell
    grid[25, 25] = 2

    topo = MooreTopology{2}()

    N_cells = 2

    trackers = (VolumeTracker(), SurfaceAreaTracker())
    penalties = (
        HSTVolumePenalty{Rigid}([0.0f0, 50.0f0, 50.0f0]),
        HSTSurfaceAreaPenalty{Rigid}([0.0f0, 2.0f0, 2.0f0])
    )

    cell_data = build_cell_data(grid, N_cells, penalties, trackers)

    u0 = PottsState(grid, cell_data, N_cells)
    p = PottsParameters(topo, penalties, trackers)

    alg = CheckerboardMetropolis(sweeps_per_step = 1, T = 10.0f0)

    prob = PottsProblem(u0, (0, 10), p)

    # Modify volume to avoid division by zero in HST
    prob.u0.cell_data.volumes[2] = 1
    prob.u0.cell_data.target_volumes[2] = 100
    prob.u0.cell_data.tensions[2] = 0.0f0
    prob.u0.cell_data.pressures[2] = 0.0f0
    prob.u0.cell_data.cell_types[2] = 1

    integrator = init(prob, alg)

    step!(integrator)
    @test integrator.t == 1
end

println("Done.")
