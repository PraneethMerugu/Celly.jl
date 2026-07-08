# Test environment is automatically activated by Pkg.test()

using CoreCPM, NeuralCPM, Lux, Optimization, OptimizationOptimisers, ComponentArrays, Zygote
using Random, Statistics

grid_dims = (50, 50)
N_cells = 40
grid = zeros(UInt32, grid_dims...)

for i in 1:N_cells
    spawn_hypersphere!(grid, grid_dims, (25, 25), 15, UInt32(i))
end

cell_types = UInt8[rand() > 0.5 ? 1 : 2 for _ in 1:N_cells]
target_volumes = Int32[25 for _ in 1:N_cells]

cell_data = build_cell_data(grid, N_cells, target_volumes = target_volumes, cell_types = cell_types)
state = CPMState(grid, cell_data)

topology = MooreTopology{2}()
J_matrix = Float32[0 10 10; 10 2 20; 10 20 2]
penalties = (
    VolumePenalty{Rigid}(Float32[0.0f0, 50.0f0, 50.0f0]),
    AdhesionPenalty{Rigid}(J_matrix)
)
params = CPMParameters(topology, penalties, (VolumeTracker(),))
alg = ParallelMetropolis(T = 10.0f0, active_fraction = 0.1f0)
prob = CPMProblem(state, (0, 10), params)
cache = CPMCache(state, topology)

for i in 1:10
    execute_step!(state, params, cache, alg)
end

data_batch = [deepcopy(state)]

rng = Xoshiro(0)
model = Chain(
    Dense(9 => 16, tanh),
    Dense(16 => 1)
)
ps, st = Lux.setup(rng, model)
ps_flat = ComponentArray(ps)

theta = ComponentArray(
    neural_weights = ps_flat,
    volume_lambdas = Float32[0.0f0, 50.0f0, 50.0f0]
)

function update_fn(p_old::CPMParameters, θ)
    new_vol = VolumePenalty{Rigid}(θ.volume_lambdas)
    new_nn = LocalNeuralPenalty(model, θ.neural_weights, st)
    return CPMParameters(p_old.topology, (new_vol, new_nn), p_old.trackers)
end

initial_grid = deepcopy(grid)
shuffle!(initial_grid)
initial_state = CPMState(initial_grid, deepcopy(cell_data))
base_prob = CPMProblem(initial_state, (0, 0), params)

train_cache = CPMTrainingCache(base_prob, 2, ParallelMetropolis(T = 10.0f0, active_fraction = 0.1f0))

p_context = (
    train_cache = train_cache,
    data_batch = data_batch,
    update_fn = update_fn
)

function mcmc_callback(state, loss_val)
    θ = state.u
    p_new = update_fn(train_cache.p, θ)
    for i in 1:length(train_cache.persistent_states)
        CoreCPM.execute_step!(train_cache.persistent_states[i], p_new, train_cache.caches[i], train_cache.alg)
    end
    println("Current Loss: ", loss_val)
    return false
end

optf = OptimizationFunction(
    (θ, p) -> cpm_loss(θ, p.train_cache, p.data_batch, p.update_fn),
    AutoZygote()
)
opt_prob = OptimizationProblem(optf, theta, p_context)

println("Training Neural CPM...")
result = solve(opt_prob, Adam(0.01), maxiters = 2, callback = mcmc_callback)
println("Success!")
