# [NeuralPotts](@id neuralpotts-overview)

**NeuralPotts** extends the Potts framework by replacing hand-crafted penalty functions with
a **neural energy-based model** (EBM) whose parameters are learned from data.
Instead of manually specifying $\lambda_V$, $J(\tau_1,\tau_2)$, etc., you provide example
simulation trajectories (or microscopy data) and NeuralPotts trains a Lux.jl neural network
to reproduce the observed cell dynamics.

```julia
using NeuralPotts
```

---

## Energy-Based Models in the Potts Context

An **Energy-Based Model** (EBM) is a probabilistic model that assigns a scalar energy
$E_\theta(\mathbf{x})$ to each configuration $\mathbf{x}$, with the Boltzmann
distribution as the generative model:

$$p_\theta(\mathbf{x}) = \frac{1}{Z(\theta)} \exp\!\bigl(-E_\theta(\mathbf{x})\bigr)$$

In the Potts context, $\mathbf{x}$ is a lattice configuration $\sigma$ and
$E_\theta(\sigma)$ is a neural network parameterised by weights $\theta$ that replaces
(or augments) the classical Hamiltonian.
The partition function $Z(\theta) = \sum_\sigma \exp(-E_\theta(\sigma))$ is intractable
for large lattices, which is why NeuralPotts uses **Contrastive Divergence** training
rather than maximum likelihood.

---

## LocalNeuralPenalty

The core building block is `LocalNeuralPenalty`, which wraps a Lux.jl neural network
and plugs it into the CorePotts penalty system.

```julia
using Lux, NeuralPotts

# Define a small MLP for the local energy
network = Lux.Chain(
    Lux.Dense(9, 32, tanh),
    Lux.Dense(32, 32, tanh),
    Lux.Dense(32, 1),
)

penalty = LocalNeuralPenalty(network)
```

### The 9-Element Feature Vector

The energy contribution of a copy attempt at site $\mathbf{x}$ is evaluated from a
**9-element local feature vector** describing the neighbourhood in a Moore (8-connected)
neighbourhood:

```
Feature vector f(x):
  [0]  cell type of the *source* site σ(x)   (centre)
  [1]  cell type of neighbour 1 (N)
  [2]  cell type of neighbour 2 (NE)
  [3]  cell type of neighbour 3 (E)
  [4]  cell type of neighbour 4 (SE)
  [5]  cell type of neighbour 5 (S)
  [6]  cell type of neighbour 6 (SW)
  [7]  cell type of neighbour 7 (W)
  [8]  cell type of neighbour 8 (NW)
```

Cell types are encoded as **type IDs** — integers `1, 2, …` assigned to non-background
`CellType`s in declaration order (background is excluded). They are
normalised before being passed to the network.
The network outputs a single scalar $\Delta E_\theta(\mathbf{f})$, which is added to
the total $\Delta H$ for the copy attempt.

**Why local?** The locality assumption keeps the feature vector fixed-size regardless of
grid dimensions and makes $\Delta H$ evaluation $O(1)$ per copy attempt — the same
complexity as classical penalties. It also means the trained penalty is translationally
invariant and can generalise to different grid sizes.

---

## Training: Persistent Contrastive Divergence

NeuralPotts trains the network via **Persistent Contrastive Divergence** (PCD), a
variant of Contrastive Divergence where the negative-phase Markov chain is not reset
between gradient steps but instead maintained as a persistent chain.

### PottsTrainingCache

```julia
cache = PottsTrainingCache(
    prob,
    alg;
    n_persistent_chains = 8,   # number of parallel negative-phase chains
    saveat              = 5,
)
```

`PottsTrainingCache` initialises `n_persistent_chains` independent simulation states that
will serve as the *negative phase* samples. They are updated by running the Potts forward
(using the current neural energy) between each gradient step.

### potts_loss

```julia
# Positive-phase data: real observed states (e.g. from microscopy)
positive_states = [data_state_1, data_state_2, ...]

θ, state = Lux.setup(rng, network)

# Training loop
opt   = Optimisers.Adam(1e-3)
opt_state = Optimisers.setup(opt, θ)

for epoch in 1:1000
    loss, grads = Zygote.withgradient(θ) do θ
        potts_loss(cache, positive_states, network, θ, state)
    end
    opt_state, θ = Optimisers.update(opt_state, θ, grads[1])
    println("Epoch $epoch  loss = $loss")
end
```

`potts_loss` computes:

$$\mathcal{L}(\theta) = \mathbb{E}_{p_\text{data}}[E_\theta(\mathbf{x})]
    - \mathbb{E}_{p_\theta}[E_\theta(\mathbf{x})]$$

The first term (positive phase) is the mean energy on real data.
The second term (negative phase) is the mean energy on the persistent chains.
Minimising $\mathcal{L}$ pushes the energy of real data down and the energy of
model samples up, shaping the energy landscape to match the data distribution.

---

## Differentiating Through the Energy: Zygote

All NeuralPotts operations are compatible with [Zygote.jl](https://fluxml.ai/Zygote.jl/),
Julia's source-to-source automatic differentiation engine.

The gradient $\nabla_\theta \mathcal{L}$ is computed by differentiating through the
neural network calls inside `potts_loss`. The Potts simulation steps themselves are treated
as *black boxes* for the negative phase (no backprop through the MCMC chain), which is
the standard PCD approximation.

> [!TIP]
> Because the Potts kernel calls inside `potts_loss` are not differentiated, you can use
> GPU-accelerated `CheckerboardMetropolis` inside the training loop without any
> compatibility issues with Zygote. The gradient flows only through the energy network
> evaluation on the cached positive- and negative-phase states.

---

## Putting It All Together

```julia
using PottsToolkit, NeuralPotts, Lux, Zygote, Optimisers

# 1. Define cell types and a system with a neural penalty
A      = CellType(:A)
Medium = CellType(:Medium, is_background=true)   # background must be marked explicitly

network = Lux.Chain(Lux.Dense(9, 64, tanh), Lux.Dense(64, 1))
penalty = LocalNeuralPenalty(network)

sys  = PottsSystem(cell_types = [Medium, A], penalties = [penalty])
prob = PottsProblem(sys, Dict(A => 30), (100, 100); tspan=(0, 200))
alg  = CheckerboardMetropolis(T=1.0f0, sweeps_per_step=5)

# 2. Prepare training cache and data
cache           = PottsTrainingCache(prob, alg; n_persistent_chains=4, saveat=5)
positive_states = load_training_data("microscopy_snapshots/")   # user-defined

# 3. Train
θ, st     = Lux.setup(Random.default_rng(), network)
opt_state = Optimisers.setup(Optimisers.Adam(1e-3), θ)

for epoch in 1:500
    loss, grads = Zygote.withgradient(
        θ -> potts_loss(cache, positive_states, network, θ, st), θ)
    opt_state, θ = Optimisers.update(opt_state, θ, grads[1])
end

# 4. Run inference with the trained network
sol = solve(prob, alg; saveat=10)
```

---

## Sub-pages

- [NeuralPotts API Reference](@ref neuralpotts-api) — Full docstring index.
