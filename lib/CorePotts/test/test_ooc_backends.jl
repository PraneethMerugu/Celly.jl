using Test
using CorePotts
using StructArrays
using Zarr
using HDF5

@testset "Out-Of-Core Backend Mechanics & Extensions" begin
    # 1. Setup a dummy simulation
    grid = backend_zeros(Int32, 50, 50)
    grid[20:30, 20:30] .= 1

    cell_data = build_cell_data(grid, 1)
    cell_data.volumes[1] = 100
    cell_data.target_volumes[1] = 100

    u0 = PottsState(grid, cell_data, 1)
    topo = VonNeumannTopology{2}()
    penalties = (VolumePenalty{Rigid}([1.0f0]),)
    trackers = (VolumeTracker(),)

    p = PottsParameters(topo, penalties, trackers)

    # 10 steps
    # 10 steps
    tspan = (0, 10)

    # We must deepcopy u0 for each solve because solve! modifies it in-place!
    prob_mem = LegacyPottsProblem(deepcopy(u0), tspan, p)
    alg = ParallelMetropolis(; T = 10.0f0, sweeps_per_step = 1)

    # 2. Run with MemoryBackend (In-memory)
    sol_mem = solve(prob_mem, alg; backend = MemoryBackend())

    @test length(sol_mem) == 11 # 0 to 10 is 11 steps

    # 3. Run with ZarrBackend
    zarr_path = tempname() * ".zarr"
    prob_zarr = LegacyPottsProblem(deepcopy(u0), tspan, p)
    sol_zarr = solve(prob_zarr, alg; backend = ZarrBackend(zarr_path))

    @test isdir(zarr_path)
    @test length(sol_zarr) == length(sol_mem)

    # Verify Zarr content lazy loads and matches perfectly
    mem_final = sol_mem[end]
    zarr_final = sol_zarr[end]

    @test mem_final.grid == zarr_final.grid
    @test mem_final.cell_data.volumes == zarr_final.cell_data.volumes
    @test mem_final.cell_data.target_volumes == zarr_final.cell_data.target_volumes
    @test mem_final.cell_data.cell_types == zarr_final.cell_data.cell_types

    # 4. Run with HDF5Backend
    h5_path = tempname() * ".h5"
    prob_h5 = LegacyPottsProblem(deepcopy(u0), tspan, p)
    sol_h5 = solve(prob_h5, alg; backend = HDF5Backend(h5_path))

    @test isfile(h5_path)
    @test length(sol_h5) == length(sol_mem)

    h5_final = sol_h5[end]

    @test mem_final.grid == h5_final.grid
    @test mem_final.cell_data.volumes == h5_final.cell_data.volumes
    @test mem_final.cell_data.target_volumes == h5_final.cell_data.target_volumes
    @test mem_final.cell_data.cell_types == h5_final.cell_data.cell_types

    # Cleanup
    rm(zarr_path, force = true, recursive = true)
    rm(h5_path, force = true)
end
