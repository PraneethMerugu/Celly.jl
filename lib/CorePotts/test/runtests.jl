using Test
using Random
using StructArrays
using CorePotts
using SciMLBase
using CorePotts: pcg_hash, lottery_offsets, offsets, MooreTopology, VonNeumannTopology,
               ExtendedMooreTopology, ExtendedVonNeumannTopology, idx_to_coord, get_val,
               num_dirs
using KernelAbstractions

const TEST_ALGORITHMS = (ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis)

@testset "CorePotts.jl - Local Lotteries" begin
    @testset "1. Lottery Isolation Proof" begin
        # Generate tickets for a 100x100 grid
        grid_dims = (100, 100)
        global_seed = UInt64(12345)

        winners = zeros(Bool, grid_dims)
        moore_offs = lottery_offsets(MooreTopology{2}())

        for idx in 1:10000
            my_ticket = pcg_hash(global_seed + UInt64(idx))
            coords = idx_to_coord(UInt32(idx), grid_dims)

            won = true
            for dir in 1:length(moore_offs)
                # manual wrap
                dx, dy = moore_offs[dir]
                cx = mod1(Int(coords[1]) + 1 + dx, grid_dims[1])
                cy = mod1(Int(coords[2]) + 1 + dy, grid_dims[2])
                n_idx = (cy - 1) * grid_dims[1] + cx

                if n_idx != idx
                    n_ticket = pcg_hash(global_seed + UInt64(n_idx))
                    if n_ticket > my_ticket || (n_ticket == my_ticket && n_idx > idx)
                        won = false
                        break
                    end
                end
            end
            winners[idx] = won
        end

        # Verify isolation
        isolation_failed = false
        for x in 1:100, y in 1:100

            if winners[x, y]
                for (dx, dy) in moore_offs
                    nx, ny = mod1(x+dx, 100), mod1(y+dy, 100)
                    if winners[nx, ny]
                        isolation_failed = true
                    end
                end
            end
        end
        @test !isolation_failed
    end

    @testset "2. Maximum Volatility Race Condition Test" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                W, H = 100, 100
                N_cells = 100
                grid = rand(UInt32(1):UInt32(N_cells), W, H)
                cell_data = build_cell_data(grid, N_cells)

                for i in 1:N_cells
                    cell_data.cell_types[i] = 1
                end

                penalties = (HSTVolumePenalty{Rigid}(zeros(Float32, 256)),)
                trackers = (VolumeTracker(), SurfaceAreaTracker())

                u0 = PottsState(grid, cell_data, N_cells)
                p = PottsParameters(VonNeumannTopology{2}(), penalties, trackers)
                CorePotts.sync_cell_data!(u0, p, PottsCache(u0, p.topology), N_cells)

                u_test = u0
                prob = PottsProblem(u_test, (0, 100), p)
                alg = AlgType(; T = 1.0f0)

                integrator = init(
                    prob, alg, save_start = false, save_end = false, save_everystep = false)
                solve!(integrator)

                # Verify atomic tracking correctness
                actual_volumes = zeros(Int32, N_cells)
                for val in integrator.u.grid
                    if val > 0
                        actual_volumes[val] += 1
                    end
                end

                matched = true
                for i in 1:N_cells
                    if actual_volumes[i] != integrator.u.cell_data.volumes[i]
                        matched = false
                        break
                    end
                end
                @test matched
            end
        end
    end

    @testset "3. Topology Decoupling Security Test" begin
        @test length(lottery_offsets(VonNeumannTopology{2}())) == 8
        @test length(lottery_offsets(VonNeumannTopology{3}())) == 26
        @test length(offsets(ExtendedMooreTopology{2, 2}())) == 24
        @test length(offsets(ExtendedVonNeumannTopology{2, 2}())) == 8
        @test length(offsets(ExtendedMooreTopology{2, 3}())) == 48
    end

    @testset "4. Cell Sorting / Mixing Index Test" begin
        for AlgType in TEST_ALGORITHMS
            @testset "$(AlgType)" begin
                W, H = 50, 50
                N_cells = 50
                grid = rand(UInt32(1):UInt32(N_cells), W, H)
                cell_data = build_cell_data(grid, N_cells)

                for i in 1:N_cells
                    cell_data.cell_types[i] = i % 2 == 0 ? 1 : 2
                    cell_data.target_volumes[i] = 25
                end

                J = fill(10.0f0, 3, 3)
                J[2, 2] = 2.0f0 # A-A
                J[3, 3] = 2.0f0 # B-B
                J[2, 3] = 15.0f0 # A-B (repulsive)
                J[3, 2] = 15.0f0

                penalties = (
                    HSTVolumePenalty{Rigid}(fill(5.0f0, 256)), AdhesionPenalty{Rigid}(J))
                trackers = (VolumeTracker(), SurfaceAreaTracker())

                u0 = PottsState(grid, cell_data, N_cells)
                p = PottsParameters(MooreTopology{2}(), penalties, trackers)
                CorePotts.sync_cell_data!(u0, p, PottsCache(u0, p.topology), N_cells)

                u_test = u0
                prob = PottsProblem(u_test, (0, 20), p)
                alg = AlgType(; T = 10.0f0)

                integrator = init(
                    prob, alg, save_start = false, save_end = false, save_everystep = false)

                function calc_mixing_index(u, cell_types)
                    grid = u.grid
                    W, H = size(grid)
                    diffs = 0;
                    totals = 0
                    for x in 1:W, y in 1:H

                        cid = grid[x, y]
                        if cid > 0
                            for dx in -1:1, dy in -1:1

                                if dx == 0 && dy == 0
                                    ;
                                    continue;
                                end
                                ncid = grid[mod1(x+dx, W), mod1(y+dy, H)]
                                if ncid > 0 && ncid != cid
                                    totals += 1
                                    if cell_types[cid] != cell_types[ncid]
                                        diffs += 1
                                    end
                                end
                            end
                        end
                    end
                    return diffs / max(1, totals)
                end

                m_start = calc_mixing_index(integrator.u, integrator.u.cell_data.cell_types)
                solve!(integrator)
                m_end = calc_mixing_index(integrator.u, integrator.u.cell_data.cell_types)

                @test m_end < m_start
            end
        end
    end

    @testset "6. Zero-Allocation Test" begin
        W, H = 50, 50
        N_cells = 10
        grid = rand(UInt32(1):UInt32(N_cells), W, H)
        cell_data = build_cell_data(grid, N_cells)

        for i in 1:N_cells
            cell_data.cell_types[i] = 1
        end

        penalties = (HSTVolumePenalty{Rigid}(zeros(Float32, 256)),)
        trackers = (VolumeTracker(), SurfaceAreaTracker())

        u0 = PottsState(grid, cell_data, N_cells)
        p = PottsParameters(VonNeumannTopology{2}(), penalties, trackers)
        cache = PottsCache(u0, p.topology)

        CorePotts.sync_cell_data!(u0, p, cache, N_cells)
        alg = ParallelMetropolis(; sampler = MetropolisSampler(), T = 1.0f0)

        CorePotts.execute_step!(u0, p, cache, alg)

        allocs = @allocated CorePotts.execute_step!(u0, p, cache, alg)
        @test allocs < 500000
    end
end

include("test_edgecases.jl")
include("test_hst_detailed_balance.jl")
@testset "HST Focal Point Penalty Test" begin
    include("test_hst_focal_point.jl")
end

@testset "HST Length Penalty Test" begin
    include("test_hst_length.jl")
end

@testset "Chemotaxis Penalty Test" begin
    include("test_chemotaxis.jl")
end

include("test_topology_abstractions.jl")
include("test_event_gpu_sync.jl")
include("test_length_3d.jl")
include("test_mitosis_overhaul.jl")
include("test_ooc_backends.jl")
include("test_mermaid_integration.jl")

println("CorePotts tests passed")
