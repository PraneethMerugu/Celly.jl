using CorePotts
using SciMLBase
using Test

@testset "3D Focal Point Penalty Test" begin
    for AlgType in TEST_ALGORITHMS
        @testset "$(AlgType)" begin
            grid_dims = (20, 20, 20)
            grid = backend_zeros(UInt32, grid_dims...)
            # Spawn two cells
            spawn_hypersphere!(grid, grid_dims, (10, 10, 5), 3, UInt32(1))
            spawn_hypersphere!(grid, grid_dims, (10, 10, 15), 3, UInt32(2))

            conn = backend_zeros(Int32, 2, 2)
            conn[1, 2] = 1
            conn[2, 1] = 1
            lambdas = Float32[2.0, 2.0]
            target_lengths = Float32[5.0, 5.0]

            penalties = (
                HSTVolumePenalty{Rigid}(Float32[0.0, 2.0, 2.0]),
                FocalPointSpringPenalty(lambdas, target_lengths, conn)
            )
            trackers = (VolumeTracker(),)

            cell_data = build_cell_data(grid, 2, penalties, trackers)
            cell_data.cell_types[1] = 1
            cell_data.cell_types[2] = 1
            cell_data.target_volumes[1] = 20
            cell_data.target_volumes[2] = 20

            u0 = PottsState(grid, cell_data)
            p_sys = PottsParameters(MooreTopology{3}(), penalties, trackers)
            prob = LegacyPottsProblem(u0, (0, 100), p_sys)
            alg = AlgType(; active_fraction = 1.0f0 / 30.0f0, sweeps_per_step = 30, T = 5.0f0)
            integrator = init(prob, alg)

            CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 2)

            # Step integrator
            for _ in 1:10
                step!(integrator)
            end

            # Assert forces evolved
            Fz1 = integrator.u.cell_data.force_z[1]
            Fz2 = integrator.u.cell_data.force_z[2]

            @test abs(Fz1) > 0.0f0
            @test abs(Fz2) > 0.0f0
        end
    end
end

@testset "3D HST Focal Point Penalty Test" begin
    for AlgType in TEST_ALGORITHMS
        @testset "$(AlgType)" begin
            grid_dims = (20, 20, 20)
            grid = backend_zeros(UInt32, grid_dims...)
            # Spawn two cells
            spawn_hypersphere!(grid, grid_dims, (10, 10, 5), 3, UInt32(1))
            spawn_hypersphere!(grid, grid_dims, (10, 10, 15), 3, UInt32(2))

            conn = backend_zeros(Int32, 2, 2)
            conn[1, 2] = 1
            conn[2, 1] = 1
            lambdas = Float32[2.0, 2.0]
            target_lengths = Float32[5.0, 5.0]

            penalties = (
                HSTVolumePenalty{Rigid}(Float32[0.0, 2.0, 2.0]),
                HSTFocalPointPenalty(lambdas, target_lengths, conn)
            )
            trackers = (VolumeTracker(),)

            cell_data = build_cell_data(grid, 2, penalties, trackers)
            cell_data.cell_types[1] = 1
            cell_data.cell_types[2] = 1
            cell_data.target_volumes[1] = 20
            cell_data.target_volumes[2] = 20

            u0 = PottsState(grid, cell_data)
            p_sys = PottsParameters(MooreTopology{3}(), penalties, trackers)
            prob = LegacyPottsProblem(u0, (0, 100), p_sys)
            alg = AlgType(; active_fraction = 1.0f0 / 30.0f0, sweeps_per_step = 30, T = 5.0f0)
            integrator = init(prob, alg)

            CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 2)

            # Step integrator
            for _ in 1:10
                step!(integrator)
            end

            # Assert forces evolved
            Fz1 = integrator.u.cell_data.force_z[1]
            Fz2 = integrator.u.cell_data.force_z[2]

            @test abs(Fz1) > 0.0f0
            @test abs(Fz2) > 0.0f0
        end
    end
end
