using CorePotts
using SciMLBase
using Makie
using StructArrays

function run_sim()
    W, H = 256, 256
    N_cells = 2

    grid = zeros(UInt32, W, H)
    grid_dims = size(grid)

    # Large penalty parameter to keep circle intact
    penalties = (HSTVolumePenalty{Rigid}(ones(Float32, 256) .* 1.0f0),)
    trackers = (VolumeTracker(), SurfaceAreaTracker())

    cell_data = build_cell_data(grid, N_cells)

    spawn_hypersphere!(grid, grid_dims, (128, 128), 30, UInt32(1))

    # Just to show multi-cell spawning
    spawn_hypersphere!(grid, grid_dims, (180, 180), 20, UInt32(2))
    cell_data.cell_types[1:2] .= [UInt8(1), UInt8(2)]

    println("Grid initialized. Setting up LegacyPottsProblem...")

    u0 = PottsState(grid, cell_data, N_cells)
    p = PottsParameters(VonNeumannTopology{2}(), penalties, trackers)
    prob = CorePotts.LegacyPottsProblem(u0, (0, 5000), p)
    alg = CheckerboardMetropolis(; T = 1.0f0, active_fraction = 0.1f0, sweeps_per_step = 10)

    integrator = SciMLBase.init(prob, alg)

    # Fully sync volumes and targets based on the physically painted grid
    sync_cell_data!(integrator.u, integrator.p, integrator.cache, 2)

    fig = Figure(size = (800, 800))
    ax = Axis(fig[1, 1], title = "Potts Simulation (SciML Integrator)", aspect = DataAspect())

    # Observable for updating the heatmap efficiently
    grid_obs = Observable(integrator.u.grid)
    heatmap!(ax, grid_obs, colormap = :viridis, colorrange = (0, 1))

    stream = VideoStream(fig, framerate = 10)

    # Define a custom condition to trigger the animation frame render
    condition(u, t, integrator) = t % 100 == 0 && t > 0
    function affect!(integrator)
        notify(grid_obs)
        recordframe!(stream)
    end
    cb = SciMLBase.DiscreteCallback(condition, affect!)

    # Re-initialize with the callback
    integrator = SciMLBase.init(prob, alg; callback = cb)
    sync_cell_data!(integrator.u, integrator.p, integrator.cache, 2)

    # Just solve! The callback will automatically record frames
    solve!(integrator)
    save("cpm_simulation.mp4", stream)

    # Finally call solve to get the full solution if we want to run to the end of tspan
    # sol = solve(prob, alg)

    println("Simulation finished. Saved to cpm_simulation.mp4")
end

run_sim()
