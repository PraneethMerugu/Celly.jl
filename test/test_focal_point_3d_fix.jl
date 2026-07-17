using CorePotts
using Test

@testset "3D Focal Point Spring Fix" begin
    grid = ones(Int, 10, 10, 10)
    grid[5, 5, 5] = 1
    grid[6, 5, 5] = 2

    # 1 and 2 are connected
    conn = [0 0 0; 0 0 1; 0 1 0]
    lambdas = Float32[0.0f0, 100.0f0, 100.0f0]
    target_lengths = Float32[0.0f0, 5.0f0, 5.0f0]
    fp_pen = FocalPointSpringPenalty(lambdas, target_lengths, conn)
    
    vol_pen = HSTVolumePenalty{Rigid}(Float32[0.0f0, 10.0f0, 10.0f0])
    vol_tracker = VolumeTracker()

    penalties = (vol_pen, fp_pen)
    trackers = (vol_tracker,)
    
    cell_data = CorePotts.build_cell_data(grid, 2, penalties, trackers)
    cell_data.volumes[1:2] .= 1
    cell_data.target_volumes[1:2] .= 1

    sys = PottsState(grid, cell_data)
    params = PottsParameters(CorePotts.MooreTopology{3}(), penalties, trackers, ())
    
    prob = PottsProblem(sys, (0, 100), params)
    sol = CorePotts.SciMLBase.solve(prob, SequentialMetropolis())
    
    # Run some sweeps and ensure they don't NaN or diverge
    @test !isnan(sol.u[end].cell_data.center_x[1])
end
