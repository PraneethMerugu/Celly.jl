using CorePotts
using SciMLBase
using Test

@testset "HST Focal Point Penalty Test" begin
    for AlgType in TEST_ALGORITHMS
        @testset "$(AlgType)" begin
            grid_dims = (40, 40)
            grid = backend_zeros(UInt32, grid_dims...)
            # Spawn two cells
            spawn_hypersphere!(grid, grid_dims, (15, 20), 4, UInt32(1))
            spawn_hypersphere!(grid, grid_dims, (25, 20), 4, UInt32(2))

            conn = backend_zeros(Int32, 2, 2)
            conn[1, 2] = 1
            conn[2, 1] = 1
            lambdas = Float32[2.0, 2.0]
            target_lengths = Float32[20.0, 20.0]

            penalties = (
                HSTVolumePenalty{Rigid}(Float32[0.0, 2.0, 2.0]),
                HSTFocalPointPenalty(lambdas, target_lengths, conn)
            )
            trackers = (VolumeTracker(),)

            cell_data = build_cell_data(grid, 2, penalties, trackers)
            cell_data.cell_types[1] = 1
            cell_data.cell_types[2] = 1
            cell_data.target_volumes[1] = 50
            cell_data.target_volumes[2] = 50

            u0 = PottsState(grid, cell_data)
            p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
            prob = LegacyPottsProblem(u0, (0, 100), p_sys)
            alg = AlgType(; active_fraction = 0.1f0, sweeps_per_step = 10, T = 5.0f0)
            integrator = init(prob, alg)

            CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 2)

            # Step integrator
            for _ in 1:10
                step!(integrator)
            end

            # Assert forces evolved
            # Both forces shouldn't be exactly zero due to OU noise and spring restoring
            Fx1 = integrator.u.cell_data.force_x[1]
            Fy1 = integrator.u.cell_data.force_y[1]
            Fx2 = integrator.u.cell_data.force_x[2]
            Fy2 = integrator.u.cell_data.force_y[2]

            @test (abs(Fx1) + abs(Fy1)) > 0.0f0
            @test (abs(Fx2) + abs(Fy2)) > 0.0f0
        end
    end
end
