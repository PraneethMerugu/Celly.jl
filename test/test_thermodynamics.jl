using CorePotts
using SciMLBase
using Test
using Random
using Statistics
using PottsToolkit
using PottsToolkit.TestProblems
@testset "Thermodynamic Verification Tests" begin
    @testset "A. Single-Cell Volume Fluctuation Test" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                # Concept: Measure variance of single cell volume
                # V_var = T / (2 * lambda_V)

                lambda_v = 5.0f0
                T_val = 50.0f0

                prob = TestProblems.single_cell_fluctuation(
                    grid_size = (50, 50),
                    target_volume = 100,
                    volume_lambda = lambda_v,
                    volume_eta = 1.0f0,
                    tspan = (0, 11_000)
                )
                alg = AlgType(; active_fraction = 0.01f0, sweeps_per_step = 100, T = T_val)

                volumes = Int32[]
                condition(u, t, integrator) = t > 1000
                function affect!(integrator)
                    push!(volumes, integrator.u.cell_data.volumes[2])
                end
                cb = SciMLBase.DiscreteCallback(condition, affect!)

                integrator = init(prob, alg; callback = cb)

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
                T_vals = Float32[0.5, 1.1, 1.5, 2.5]

                println("B. Ising Model Magnetization")
                for T in T_vals
                    prob = TestProblems.ising_model(grid_size=(W, H), J=1.0f0, tspan=(0, 6000))

                    Random.seed!(Int(T*100))
                    for i in 1:length(prob.u0.grid)
                        prob.u0.grid[i] = rand() < 0.95 ? 2 : 3
                    end
                    prob.u0.cell_data.volumes[2] = sum(prob.u0.grid .== 2)
                    prob.u0.cell_data.volumes[3] = sum(prob.u0.grid .== 3)
                    prob.u0.cell_data.volumes[1] = 0
                    alg = AlgType(; T = T, active_fraction = 0.1f0, sweeps_per_step = 10)

                    mag_acc = 0.0
                    condition(u, t, integrator) = t > 5000
                    function affect!(integrator)
                        u = integrator.u
                        c1, c2 = 0, 0
                        for v in u.grid
                            if v == 2
                                c1 += 1
                            elseif v == 3
                                c2 += 1
                            end
                        end
                        mag_acc += abs(c1 - c2) / (c1 + c2)
                    end
                    cb = SciMLBase.DiscreteCallback(condition, affect!)

                    integrator = init(prob, alg; callback = cb)

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
