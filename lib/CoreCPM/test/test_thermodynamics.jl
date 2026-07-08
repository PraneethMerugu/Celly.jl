using CoreCPM
using SciMLBase
using Test
using Random
using Statistics

@testset "Thermodynamic Verification Tests" begin
    @testset "A. Single-Cell Volume Fluctuation Test" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                # Concept: Measure variance of single cell volume
                # V_var = T / (2 * lambda_V)

                W, H = 50, 50
                grid_dims = (W, H)
                N_cells = 1
                grid = zeros(UInt32, W, H)

                lambda_v = 5.0f0
                T_val = 50.0f0
                target_vol = 100

                # Initialize cell 1
                center = (W ÷ 2, H ÷ 2)
                spawn_hypersphere!(
                    grid, grid_dims, center, round(Int, sqrt(target_vol/pi)), UInt32(1))

                cell_data = build_cell_data(grid, N_cells)
                cell_data.cell_types[1] = 1
                cell_data.target_volumes[1] = target_vol

                penalties = (HSTVolumePenalty{Rigid}(Float32[lambda_v, lambda_v]; eta = 1.0f0),) # index 1 is cell type 1
                trackers = (VolumeTracker(),)

                CoreCPM.sync_cell_data!(grid, cell_data, N_cells)
                u0 = CPMState(grid, cell_data)
                p_sys = CPMParameters(MooreTopology{2}(), penalties, trackers)
                prob = CPMProblem(u0, (0, 11_000), p_sys)
                alg = AlgType(; active_fraction = 0.01f0, sweeps_per_step = 100, T = T_val)

                volumes = Int32[]
                condition(u, t, integrator) = t > 1000
                function affect!(integrator)
                    push!(volumes, integrator.u.cell_data.volumes[1])
                end
                cb = SciMLBase.DiscreteCallback(condition, affect!)

                integrator = init(prob, alg; callback = cb)
                CoreCPM.sync_cell_data!(integrator.u, integrator.p, integrator.cache, N_cells)

                solve!(integrator)

                emp_var = var(volumes)
                theo_var = T_val / (2 * lambda_v)

                println("A. Volume Fluctuation Test")
                println("   Empirical Variance: ", emp_var)
                println("   Theoretical Variance: ", theo_var)
                println("   Ratio (Emp/Theo): ", emp_var / theo_var)

                # Assert within 25% due to the Euler integration variance inflation
                @test isapprox(emp_var, theo_var, rtol = 0.25)
            end
        end
    end

    @testset "B. 2D Ising Model Critical Phase Transition" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                W, H = 50, 50
                N_cells = 2
                grid = zeros(UInt32, W, H)
                cell_data = build_cell_data(grid, N_cells)

                cell_data.cell_types[1] = 1
                cell_data.cell_types[2] = 2

                J = zeros(Float32, 3, 3)
                J[2, 3] = 1.0f0
                J[3, 2] = 1.0f0

                penalties = (AdhesionPenalty{Rigid}(J),)
                trackers = ()

                T_vals = Float32[0.5, 1.1, 1.5, 2.5]

                println("B. Ising Model Magnetization")
                for T in T_vals
                    Random.seed!(Int(T*100))
                    for i in 1:length(grid)
                        grid[i] = rand() < 0.95 ? 1 : 2
                    end

                    CoreCPM.sync_cell_data!(grid, cell_data, N_cells)
                    u0 = CPMState(grid, cell_data)

                    p_sys = CPMParameters(VonNeumannTopology{2}(), penalties, trackers)
                    prob = CPMProblem(u0, (0, 6000), p_sys)
                    alg = AlgType(; T = T, active_fraction = 0.1f0, sweeps_per_step = 10)

                    mag_acc = 0.0
                    condition(u, t, integrator) = t > 5000
                    function affect!(integrator)
                        u = integrator.u
                        c1, c2 = 0, 0
                        for v in u.grid
                            type = u.cell_data.cell_types[v]
                            if type == 1
                                c1 += 1
                            elseif type == 2
                                c2 += 1
                            end
                        end
                        mag_acc += abs(c1 - c2) / (W * H)
                    end
                    cb = SciMLBase.DiscreteCallback(condition, affect!)

                    integrator = init(prob, alg; callback = cb)
                    CoreCPM.sync_cell_data!(integrator.u, integrator.p, integrator.cache, N_cells)

                    solve!(integrator)

                    samples = 1000
                    mag = mag_acc / samples
                    println("   T = $T, Mag = $mag")

                    if T < 1.0
                        @test mag > 0.6
                    elseif T > 1.5
                        @test mag < 0.4
                    end
                end
            end
        end
    end
end
