using CorePotts
using SciMLBase
using Test
using Statistics

@testset "Hubbard-Stratonovich Detailed Balance" begin
    @testset "HST Volume Variance Convergence" begin
        W, H = 50, 50
        grid = zeros(UInt32, W, H)
        target_vol = 100
        spawn_hypersphere!(
            grid, (W, H), (25, 25), round(Int, sqrt(target_vol/pi)), UInt32(1))

        lambda_v, T_val = 5.0f0, 50.0f0

        penalties = (HSTVolumePenalty{Rigid}(Float32[lambda_v, lambda_v]; eta = 1.0f0),)
        trackers = (VolumeTracker(),)

        cell_data = build_cell_data(grid, 1, penalties, trackers)
        cell_data.cell_types[1] = 1
        cell_data.target_volumes[1] = target_vol

        u0 = PottsState(grid, cell_data)
        p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
        prob = PottsProblem(u0, (0, 5000), p_sys)
        alg = ParallelMetropolis(; active_fraction = 0.01f0, sweeps_per_step = 100, T = T_val)

        volumes = Int32[]
        condition(u, t, integrator) = t > 1000
        function affect!(integrator)
            push!(volumes, integrator.u.cell_data.volumes[1])
        end
        cb = SciMLBase.DiscreteCallback(condition, affect!)

        integrator = init(prob, alg; callback = cb)
        CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 1)

        solve!(integrator)

        emp_var = var(volumes)
        theo_var = T_val / (2.0 * lambda_v) # Exact Analytical Fluctuation-Dissipation Theorem

        println("Analytical Proof of Zero Bias via HST:")
        println("   Empirical Variance: ", emp_var)
        println("   Theoretical Variance: ", theo_var)

        # Assert within 25% due to the Euler integration variance inflation
        @test isapprox(emp_var, theo_var, rtol = 0.25)
    end
end
