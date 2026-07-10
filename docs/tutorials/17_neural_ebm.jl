using CairoMakie
CairoMakie.activate!()

# # Neural Energy-Based Model (NeuralPotts)
#
# Hand-crafting penalty functions requires biological intuition and careful
# parameter fitting.  **NeuralPotts** offers an alternative: replace (or
# augment) the explicit energy terms with a neural network trained to
# reproduce observed cell configurations.  The network is an
# *energy-based model* (EBM) — it assigns a scalar energy to every lattice
# configuration, and training minimises the energy of observed data while
# maximising it for MCMC-generated "fantasy" configurations (*Persistent
# Contrastive Divergence*).
#
# A critical architectural constraint: MCMC sampling must run **outside** the
# loss function so that Zygote's AD does not trace through the stochastic
# lattice updates.  The `PottsTrainingCache` struct owns the persistent Markov
# chains and is mutated in-place during the training loop.

# ## Packages

using PottsToolkit      # re-exports CorePotts
using NeuralPotts       # extends CorePotts with neural penalty types + training utilities
using MakiePotts
using Lux
using Optimisers
using Statistics
using Random

rng = Random.default_rng()

# ## Step 1: Define a Lux MLP
#
# The neural penalty receives a *local patch descriptor* — a flattened vector
# of cell-type labels in a small neighbourhood around each candidate copy
# event.  Here we use a 3×3 patch (9 pixels × n_types one-hot) = 9·3 = 27
# input features for three cell types.

n_types = 3    # A, B, Medium
patch_size = 9    # 3×3 neighbourhood, flattened

model = Chain(
    Dense(9 => 64, tanh),
    Dense(64 => 32, tanh),
    Dense(32 => 1)             # scalar energy contribution
)

ps, st = Lux.setup(rng, model)

# ## Step 2: Wrap in LocalNeuralPenalty
#
# `LocalNeuralPenalty` is defined in NeuralPotts.  It implements the
# `CorePotts.AbstractPenalty` interface so it can be dropped into any
# `PottsSystem` component list alongside standard components.
# The `radius` controls the neighbourhood patch fed to the network.

neural_penalty = LocalNeuralPenalty(model, ps, st)

# ## Step 3: Build the Potts system and problem
#
# The neural penalty is listed alongside standard Potts components.  The
# standard components provide a stable prior that keeps cells well-behaved;
# the neural penalty learns residual structure from data.

A = CellType(:A)
B = CellType(:B)
Medium = CellType(:Medium, is_background = true)

sys = PottsSystem(
    cell_types = [Medium, A, B],
    penalties = [
        VolumeComponent(
            A => (λ = 3.0f0, target = 400),
            B => (λ = 3.0f0, target = 400)
        ),
        AdhesionComponent(
            (A, Medium) => 10.0f0,
            (B, Medium) => 10.0f0,
            (A, A) => 2.0f0,
            (B, B) => 2.0f0,
            (A, B) => 8.0f0
        ),
        neural_penalty    # learned energy term
    ]
)

prob = PottsProblem(
    sys,
    Dict(A => 15, B => 15),
    (150, 150);
    tspan = (0, 400),
    topology = MooreTopology{2}()
)

alg = CheckerboardMetropolis(T = 1.5f0, sweeps_per_step = 10)

# ## Step 4: Create a training cache
#
# `PottsTrainingCache` owns K *persistent Markov chains* — independent Potts
# integrators initialised from random states.  During training their states
# are updated (MCMC steps) *before* the loss is evaluated, so Zygote never
# needs to differentiate through the stochastic update kernel.

# ```julia
# n_chains = 4
# cache    = PottsTrainingCache(prob, n_chains, alg)
#
# opt_state = Optimisers.setup(Optimisers.Adam(1e-3), ps)
# 
# n_data = 8
# data_sols = [solve(prob, alg; saveat = 400) for _ in 1:n_data]
# observed_lattices = [sol.u[end] for sol in data_sols]
# 
# n_epochs = 50
# 
# for epoch in 1:n_epochs
#     advance_chains!(cache, alg; n_steps = 20)
# 
#     loss_val, grads = Lux.withgradient(ps) do params
#         NeuralPotts.potts_loss(
#             neural_penalty,
#             params, st,
#             observed_lattices,
#             cache;
#             alpha = 1.0f0,
#         )
#     end
# 
#     opt_state, ps = Optimisers.update(opt_state, ps, grads[1])
#     neural_penalty = LocalNeuralPenalty(model, ps, st)
#     epoch % 10 == 0 && println("Epoch $epoch — loss: $(round(loss_val; digits=4))")
# end
# ```

# ## Step 6: Run the trained model and visualise
#
# Rebuild the system with the trained parameters, solve, and record.

# ```julia
# trained_sys = PottsSystem(
#     cell_types = [Medium, A, B],
#     penalties  = [
#         VolumeComponent(
#             A => (λ = 3.0f0, target = 400),
#             B => (λ = 3.0f0, target = 400),
#         ),
#         AdhesionComponent(
#             (A, Medium) => 10.0f0,
#             (B, Medium) => 10.0f0,
#             (A, A)      =>  2.0f0,
#             (B, B)      =>  2.0f0,
#             (A, B)      =>  8.0f0,
#         ),
#         neural_penalty,
#     ],
# )
# 
# trained_prob = PottsProblem(
#     trained_sys,
#     Dict(A => 15, B => 15),
#     (150, 150);
#     tspan    = (0, 600),
#     topology = MooreTopology{2}(),
# )
# 
# trained_sol = solve(trained_prob, alg; saveat = 20)
# 
# record_potts(
#     "neural_ebm_trained.mp4", trained_sol;
#     metrics = [
#         "Mean Volume" => u -> begin
#             n = u.N_cells[]
#             n == 0 ? 0.0 : mean(Array(u.cell_data.volumes)[1:n])
#         end,
#     ],
#     framerate  = 20,
#     resolution = (1000, 800),
# )
# ```

# ```@raw html
# <video autoplay loop muted playsinline controls src="../neural_ebm_trained.mp4" width="100%"></video>
# ```
