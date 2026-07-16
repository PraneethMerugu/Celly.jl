using CorePotts
using SciMLBase
using Test
using StructArrays

@testset "Mass Conservation across Topologies" begin
    function run_mass_test(topo, grid_dims, steps = 100)
        N_cells = 1
        grid = backend_zeros(UInt32, grid_dims...)
        vol_penalty = HSTVolumePenalty{Rigid}(Float32[0.0f0, 50.0f0]) # cell_type 1 has lambda=50
        trackers = (VolumeTracker(), SurfaceAreaTracker())

        batch_size = prod(grid_dims) # 1 update attempt per pixel per MCS on average

        cell_data = build_cell_data(grid, N_cells, (vol_penalty,), trackers)

        # Initialize an N-dimensional sphere
        center = ntuple(i -> div(grid_dims[i], 2), length(grid_dims))
        spawn_hypersphere!(grid, grid_dims, center, 10, UInt32(1))

        T = 20.0f0

        u0 = PottsState(grid, cell_data)
        p_sys = PottsParameters(topo, (vol_penalty,), trackers)
        prob = PottsProblem(u0, (0, steps), p_sys)
        alg = ParallelMetropolis(; active_fraction = 0.1f0, sweeps_per_step = 10, T = T)

        integrator = SciMLBase.init(prob, alg)

        # Sync metrics and targets
        sync_cell_data!(integrator.u, integrator.p, integrator.cache, 1)

        # Run steps
        sol = solve!(integrator)

        # After execution, the total number of pixels belonging to cell 1
        # should exactly match sol.u.cell_data.volumes[1]
        actual_vol = count(==(1), sol.u.grid)
        tracked_vol = sol.u.cell_data.volumes[1]

        @test actual_vol == tracked_vol
    end

    @testset "2D Von Neumann" begin
        run_mass_test(VonNeumannTopology{2}(), (50, 50))
    end

    @testset "3D Von Neumann" begin
        run_mass_test(VonNeumannTopology{3}(), (30, 30, 30))
    end

    @testset "2D Moore" begin
        run_mass_test(MooreTopology{2}(), (50, 50))
    end

    @testset "3D Moore" begin
        run_mass_test(MooreTopology{3}(), (30, 30, 30))
    end
end
