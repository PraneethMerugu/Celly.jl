using CoreCPM
using SciMLBase
using BenchmarkTools
using StructArrays

function setup_benchmark()
    W, H = 256, 256
    N_cells = 100

    grid = zeros(UInt32, W, H)
    grid_dims = size(grid)

    penalties = (HSTVolumePenalty{Rigid}(ones(Float32, 256) .* 1.0f0),)
    trackers = (VolumeTracker(), SurfaceAreaTracker())

    cell_data = build_cell_data(grid, N_cells)

    for i in 1:10
        for j in 1:10
            cell_id = (i - 1) * 10 + j
            spawn_hypersphere!(grid, grid_dims, (i * 20, j * 20), 5, UInt32(cell_id))
            cell_data.cell_types[cell_id] = UInt8(1)
            cell_data.target_volumes[cell_id] = 100
        end
    end

    u0 = CPMState(grid, cell_data, N_cells)
    p = CPMParameters(VonNeumannTopology{2}(), penalties, trackers)
    prob = CPMProblem(u0, (0, 100), p)

    return prob
end

function run_benchmark()
    prob = setup_benchmark()

    println("Benchmarking SequentialMetropolis (Deterministic CPU)...")
    alg_seq = SequentialMetropolis(; T = 1.0f0, active_fraction = 0.1f0, sweeps_per_step = 1)
    # Warmup
    integrator_seq = SciMLBase.init(prob, alg_seq)
    SciMLBase.solve!(integrator_seq)

    @btime begin
        integrator = SciMLBase.init($prob, $alg_seq)
        SciMLBase.solve!(integrator)
    end

    println("\nBenchmarking ParallelMetropolis (Stochastic GPU Lottery)...")
    alg_par = ParallelMetropolis(; T = 1.0f0, active_fraction = 0.1f0, sweeps_per_step = 1)
    # Warmup
    integrator_par = SciMLBase.init(prob, alg_par)
    SciMLBase.solve!(integrator_par)

    @btime begin
        integrator = SciMLBase.init($prob, $alg_par)
        SciMLBase.solve!(integrator)
    end

    println("\nBenchmarking CheckerboardMetropolis (Optimal L1 Dense GPU)...")
    alg_chk = CheckerboardMetropolis(; T = 1.0f0, active_fraction = 0.1f0, sweeps_per_step = 1)
    # Warmup
    integrator_chk = SciMLBase.init(prob, alg_chk)
    SciMLBase.solve!(integrator_chk)

    @btime begin
        integrator = SciMLBase.init($prob, $alg_chk)
        SciMLBase.solve!(integrator)
    end
end

run_benchmark()
