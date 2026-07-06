using Metal
using CoreCPM
using StructArrays

function test_metal_cpm()
    println("Initializing Metal Arrays...")
    
    W, H = 256, 256
    N_cells = 10
    
    # 1. Initialize host grid
    host_grid = zeros(UInt32, W, H)
    for i in 1:10
        host_grid[i*10:i*10+4, i*10:i*10+4] .= i
    end
    
    # 2. Transfer grid to Apple Silicon GPU
    gpu_grid = MtlArray(host_grid)
    
    penalties = (HSTVolumePenalty{Rigid}(ones(Float32, 256)),)
    
    cell_data = build_cell_data(gpu_grid, N_cells)
    
    println("Setting up SciML Problem on Metal...")
    trackers = (VolumeTracker(), SurfaceAreaTracker())
    u0 = CPMState(gpu_grid, cell_data, N_cells)
    p = CPMParameters(VonNeumannTopology{2}(), penalties, trackers)
    prob = CPMProblem(u0, (0, 100), p)
    alg = CheckerboardMetropolis(; T=1.0f0, active_fraction=0.1f0, sweeps_per_step=10)
    integrator = SciMLBase.init(prob, alg)
    
    Metal.@allowscalar begin
        for i in 1:10
            integrator.u.cell_data.cell_types[i] = 1
        end
    end
    sync_cell_data!(integrator.u, integrator.p, integrator.cache, N_cells)
    
    println("Executing a warmup step...")
    Metal.@sync SciMLBase.step!(integrator)
    
    println("Benchmarking 100 steps on Metal...")
    @time Metal.@sync begin
        SciMLBase.solve!(integrator)
    end
end

test_metal_cpm()
