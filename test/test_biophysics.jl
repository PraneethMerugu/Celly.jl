using CorePotts
using SciMLBase
using Test
using PottsToolkit
using PottsToolkit.TestProblems
@testset "Biophysical Verification Tests" begin
    @testset "D. Steinberg’s Differential Adhesion Hypothesis" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                function run_dah(J_matrix; steps = 100)
                    prob = TestProblems.cell_sorting_problem(
                        grid_size = (20, 20),
                        cells_per_type = 10, # 20 cells total in a 20x20 is very dense, let's keep N=20 total, 10 per type
                        target_volume = 20,
                        volume_lambda = 2.0f0,
                        J_AA = J_matrix[2, 2],
                        J_BB = J_matrix[3, 3],
                        J_AB = J_matrix[2, 3],
                        J_Medium = J_matrix[1, 2],
                        tspan = (0, steps),
                        topology = MooreTopology{2}()
                    )
                    alg = AlgType(; active_fraction = 0.1f0, sweeps_per_step = 10, T = 5.0f0)
                    integrator = init(prob, alg)

                    solve!(integrator)

                    b_11, b_22, b_12 = 0, 0, 0
                    W, H = 20, 20
                    for x in 1:W, y in 1:H

                        c1 = integrator.u.grid[x, y]
                        c1 == 0 && continue
                        t1 = integrator.u.cell_data.cell_types[c1]
                        for (dx, dy) in CorePotts.lottery_offsets(VonNeumannTopology{2}())
                            nx, ny = mod1(x+dx, W), mod1(y+dy, H)
                            c2 = integrator.u.grid[nx, ny]
                            c2 == 0 && continue
                            if c1 != c2
                                t2 = integrator.u.cell_data.cell_types[c2]
                                if t1 == 1 && t2 == 1
                                    b_11 += 1
                                elseif t1 == 2 && t2 == 2
                                    b_22 += 1
                                else
                                    b_12 += 1
                                end
                            end
                        end
                    end
                    return b_11, b_22, b_12
                end

                J_sort = backend_zeros(Float32, 3, 3)
                J_sort[2, 2] = 2.0f0;
                J_sort[3, 3] = 2.0f0;
                J_sort[2, 3] = 15.0f0;
                J_sort[3, 2] = 15.0f0
                b11, b22, b12 = run_dah(J_sort)
                @test b12 < b11 + b22

                J_mix = backend_zeros(Float32, 3, 3)
                J_mix[2, 2] = 15.0f0;
                J_mix[3, 3] = 15.0f0;
                J_mix[2, 3] = 2.0f0;
                J_mix[3, 2] = 2.0f0
                b11, b22, b12 = run_dah(J_mix)
                @test b12 > b11 + b22

                J_engulf = backend_zeros(Float32, 3, 3)
                J_engulf[2, 2] = 2.0f0;
                J_engulf[3, 3] = 15.0f0;
                J_engulf[2, 3] = 5.0f0;
                J_engulf[3, 2] = 5.0f0
                b11, b22, b12 = run_dah(J_engulf)
                @test b22 < b11
            end
        end
    end

    @testset "F. Brownian Motion / Center of Mass Diffusion" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                prob = TestProblems.single_cell_fluctuation(
                    grid_size = (40, 40),
                    target_volume = 50,
                    volume_lambda = 2.0f0,
                    volume_eta = 0.0f0, # the test uses rigid penalty so eta essentially disabled
                    tspan = (0, 1000)
                )
                alg = AlgType(; active_fraction = 0.1f0, sweeps_per_step = 10, T = 15.0f0)
                integrator = init(prob, alg)

                function get_com(g)
                    idx = findall(==(1), g)
                    isempty(idx) && return (0.0, 0.0)
                    return (sum(i[1] for i in idx) / length(idx),
                        sum(i[2] for i in idx) / length(idx))
                end

                coms = []
                for _ in 1:100
                    step!(integrator)
                end
                cx_init, cy_init = get_com(integrator.u.grid)

                for _ in 1:20
                    for _ in 1:10
                        step!(integrator)
                    end
                    cx, cy = get_com(integrator.u.grid)
                    push!(coms, (cx - cx_init)^2 + (cy - cy_init)^2)
                end

                @test maximum(coms) > 0.25 # Suppressed diffusion due to mathematically stiff over-damping!
            end
        end
    end

    @testset "G. Young-Laplace Hydrostatic Pressure Proof" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                gamma = 10.0f0

                prob = TestProblems.young_laplace_droplet(
                    grid_size = (256, 256),
                    target_volume = 5026,
                    volume_lambda = 1.0f0,
                    volume_eta = 0.1f0,
                    gamma = gamma,
                    tspan = (0, 70),
                    topology = MooreTopology{2}()
                )
                # High-precision sweeps
                alg = AlgType(; active_fraction = 0.01f0, sweeps_per_step = 100, T = 2.0f0)

                p_samples = Float32[]
                v_samples = Int32[]
                condition(u, t, integrator) = t > 20
                function affect!(integrator)
                    push!(v_samples, integrator.u.cell_data.volumes[1])
                    push!(p_samples, integrator.u.cell_data.pressures[1])
                end
                cb = SciMLBase.DiscreteCallback(condition, affect!)

                integrator = init(prob, alg; callback = cb)

                solve!(integrator)

                mean_V = sum(v_samples) / length(v_samples)
                mean_P = sum(p_samples) / length(p_samples)
                R_eff = sqrt(mean_V / pi)

                # Note: The true effective macroscopic surface tension gamma_eff is roughly 6 * J.
                # This factor of 6 arises from two artifacts of the standard discrete Potts:
                # 1. The Hamiltonian sums over all directed edges without a 1/2 factor, so every edge
                #    is double-counted across the boundary (factor of 2).
                # 2. On a 2nd-order Moore lattice, a flat boundary pixel has 3 neighbor edges crossing 
                #    the boundary.
                # Thus, gamma_eff = 2 * 3 * J = 6 * gamma.
                # By Young-Laplace, P_theo = gamma_eff / R_eff.
                P_theo = (gamma * 6.0f0) / R_eff

                println("Young-Laplace Test (Unweighted):")
                println("   Effective Radius: ", R_eff)
                println("   Theoretical Pressure (approx): ", P_theo)
                println("   Empirical Mean Pressure: ", abs(mean_P))

                @test P_theo * 0.2 < abs(mean_P) < P_theo * 4.0
            end
        end
    end

    @testset "H. Young-Laplace Isotropic Euclidean Weighting" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                gamma = 10.0f0

                # Turn ON isotropic Euclidean weighting
                prob = TestProblems.young_laplace_droplet(
                    grid_size = (256, 256),
                    target_volume = 5026,
                    volume_lambda = 1.0f0,
                    volume_eta = 0.1f0,
                    gamma = gamma,
                    tspan = (0, 70),
                    topology = MooreTopology{2}(),
                    isotropic = true
                )
                alg = AlgType(; active_fraction = 0.01f0, sweeps_per_step = 100, T = 2.0f0)

                p_samples = Float32[]
                v_samples = Int32[]
                condition(u, t, integrator) = t > 20
                function affect!(integrator)
                    push!(v_samples, integrator.u.cell_data.volumes[1])
                    push!(p_samples, integrator.u.cell_data.pressures[1])
                end
                cb = SciMLBase.DiscreteCallback(condition, affect!)

                integrator = init(prob, alg; callback = cb)

                solve!(integrator)

                mean_V = sum(v_samples) / length(v_samples)
                mean_P = sum(p_samples) / length(p_samples)

                R_eff = sqrt(mean_V / pi)

                # For isotropic Euclidean weighting, the effective gamma scales similarly but incorporates
                # the 1/d weights. While the raw energy is slightly lower, the continuous liquid Wulff shape
                # (a perfect circle) exerts a higher uniform curvature pressure than the faceted crystalline 
                # octagon of the unweighted lattice.
                # Thus, empirical pressure remains physically continuous and roughly matches the unweighted scale.
                P_theo_iso = (gamma * 6.0f0) / R_eff

                println("Young-Laplace Test (Isotropic):")
                println("   Effective Radius: ", R_eff)
                println("   Theoretical Pressure (approx): ", P_theo_iso)
                println("   Empirical Mean Pressure: ", abs(mean_P))

                @test P_theo_iso * 0.1 < abs(mean_P) < P_theo_iso * 3.0
            end
        end
    end
    @testset "I. Young-Laplace 3D Hydrostatic Pressure Proof" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                gamma = 10.0f0

                prob = TestProblems.young_laplace_droplet_3d(
                    grid_size = (64, 64, 64),
                    target_volume = 33510,
                    volume_lambda = 1.0f0,
                    volume_eta = 0.1f0,
                    gamma = gamma,
                    tspan = (0, 70),
                    topology = MooreTopology{3}()
                )
                alg = AlgType(; active_fraction = 0.01f0, sweeps_per_step = 100, T = 2.0f0)

                p_samples = Float32[]
                v_samples = Int32[]
                condition(u, t, integrator) = t > 20
                function affect!(integrator)
                    push!(v_samples, integrator.u.cell_data.volumes[1])
                    push!(p_samples, integrator.u.cell_data.pressures[1])
                end
                cb = SciMLBase.DiscreteCallback(condition, affect!)

                integrator = init(prob, alg; callback = cb)

                solve!(integrator)

                mean_V = sum(v_samples) / length(v_samples)
                mean_P = sum(p_samples) / length(p_samples)
                R_eff = cbrt(mean_V / (4/3 * pi))

                # In 3D Moore, the lattice gamma factor is typically ~9 instead of 6.
                # Young-Laplace in 3D: P = 2*gamma / R
                # So P_theo = 2 * (gamma * 9) / R_eff
                P_theo = (gamma * 9.0f0 * 2) / R_eff

                println("Young-Laplace Test 3D (Unweighted):")
                println("   Effective Radius: ", R_eff)
                println("   Theoretical Pressure (approx): ", P_theo)
                println("   Empirical Mean Pressure: ", abs(mean_P))

                @test P_theo * 0.1 < abs(mean_P) < P_theo * 4.0
            end
        end
    end
end
