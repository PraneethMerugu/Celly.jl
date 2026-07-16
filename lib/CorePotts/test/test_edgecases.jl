using CorePotts
using SciMLBase
using Test

@testset "Edge Case and Engineering Tests" begin
    @testset "G. Strict Zero-Temperature Quench" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                W, H = 20, 20
                N_cells = 5
                grid = rand(UInt32(1):UInt32(N_cells), W, H)
                J = Float32[0.0 5.0; 5.0 2.0]
                penalties = (VolumePenalty{Rigid}(Float32[0.0f0, 2.0f0]), AdhesionPenalty{Rigid}(J))
                trackers = (VolumeTracker(), SurfaceAreaTracker())
                
                cell_data = build_cell_data(grid, N_cells, penalties, trackers)
                for i in 1:N_cells
                    cell_data.cell_types[i] = 1
                    cell_data.target_volumes[i] = W*H/N_cells
                end

                u0 = PottsState(grid, cell_data)
                p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
                prob = PottsProblem(u0, (0, 100), p_sys)
                alg = AlgType(; T = 0.0f0, active_fraction = 0.1f0, sweeps_per_step = 10)
                integrator = init(prob, alg)
                CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, N_cells)

                function global_energy(u)
                    H_tot = 0.0
                    W, H_dim = size(u.grid)
                    for x in 1:W, y in 1:H_dim

                        c = u.grid[x, y]
                        t = c == 0 ? 0 : u.cell_data.cell_types[c]
                        for (dx, dy) in CorePotts.lottery_offsets(MooreTopology{2}())
                            nx, ny = mod1(x+dx, W), mod1(y+dy, H_dim)
                            nc = u.grid[nx, ny]
                            if c != nc
                                nt = nc == 0 ? 0 : u.cell_data.cell_types[nc]
                                H_tot += J[t + 1, nt + 1]
                            end
                        end
                    end
                    H_tot /= 2.0
                    for i in 1:length(u.cell_data.volumes)
                        v = u.cell_data.volumes[i]
                        tv = u.cell_data.target_volumes[i]
                        H_tot += 2.0f0 * (v - tv)^2
                    end
                    return H_tot
                end

                prev_E = global_energy(integrator.u)
                for _ in 1:50
                    step!(integrator)
                    CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, N_cells)
                    curr_E = global_energy(integrator.u)
                    @test curr_E <= prev_E + 1e-3
                    prev_E = curr_E
                end
            end
        end
    end

    @testset "H. Cell Fragmentation / Connectivity" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                W, H = 20, 20
                grid = zeros(UInt32, W, H)
                grid[5:15, 5:10] .= 1;
                grid[5:15, 11:15] .= 2
                J = Float32[0.0 5.0 5.0; 5.0 2.0 5.0; 5.0 5.0 2.0]

                penalties = (HSTVolumePenalty{Rigid}(Float32[0.0f0, 1.0f0, 1.0f0]),
                    AdhesionPenalty{Rigid}(J))
                trackers = (VolumeTracker(), SurfaceAreaTracker())
                
                cell_data = build_cell_data(grid, 2, penalties, trackers)
                cell_data.cell_types[1] = 1
                cell_data.cell_types[2] = 1
                cell_data.target_volumes[1] = 50
                cell_data.target_volumes[2] = 50

                u0 = PottsState(grid, cell_data)
                p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
                prob = PottsProblem(u0, (0, 100), p_sys)
                alg = AlgType(; T = 0.0f0)
                integrator = init(prob, alg)
                CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 2)
                solve!(integrator)

                function check_connectivity(g, c_id)
                    W, H = size(g)
                    visited = zeros(Bool, W, H)
                    start_x, start_y = 0, 0
                    for x in 1:W, y in 1:H

                        if g[x, y] == c_id
                            start_x, start_y = x, y;
                            break
                        end
                    end
                    if start_x == 0
                        return 0
                    end

                    queue = [(start_x, start_y)]
                    visited[start_x, start_y] = true
                    count = 0
                    while !isempty(queue)
                        x, y = popfirst!(queue)
                        count += 1
                        for (dx, dy) in CorePotts.lottery_offsets(VonNeumannTopology{2}())
                            nx, ny = mod1(x+dx, W), mod1(y+dy, H)
                            if g[nx, ny] == c_id && !visited[nx, ny]
                                visited[nx, ny] = true
                                push!(queue, (nx, ny))
                            end
                        end
                    end
                    return Base.count(==(c_id), g) - count
                end

                @test check_connectivity(integrator.u.grid, 1) < 5
                @test check_connectivity(integrator.u.grid, 2) < 5

                # Test boiling (fragmentation expected)
                alg_boil = AlgType(; T = 50.0f0)
                integrator_boil = init(prob, alg_boil)
                CorePotts.sync_cell_data!(integrator_boil.u, integrator_boil.p, integrator_boil.cache, 2)
                solve!(integrator_boil)
                @test check_connectivity(integrator_boil.u.grid, 1) > 0
            end
        end
    end

    @testset "I. Tracker Drift Validation" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                W, H = 30, 30
                N_cells = 10
                grid = rand(UInt32(1):UInt32(N_cells), W, H)
                penalties = (HSTVolumePenalty{Rigid}(Float32[0.0f0, 2.0f0]),)
                trackers = (VolumeTracker(),)
                
                cell_data = build_cell_data(grid, N_cells, penalties, trackers)
                for i in 1:N_cells
                    cell_data.cell_types[i] = 1
                    cell_data.target_volumes[i] = 90
                end

                u0 = PottsState(grid, cell_data)
                p_sys = PottsParameters(MooreTopology{2}(), penalties, trackers)
                prob = PottsProblem(u0, (0, 500), p_sys)
                alg = AlgType(; T = 10.0f0)
                integrator = init(prob, alg)
                CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, N_cells)

                solve!(integrator)

                actual_volumes = zeros(Int, N_cells)
                for v in integrator.u.grid
                    if v > 0
                        actual_volumes[v] += 1
                    end
                end

                for i in 1:N_cells
                    @test actual_volumes[i] == integrator.u.cell_data.volumes[i]
                end
            end
        end
    end
end
