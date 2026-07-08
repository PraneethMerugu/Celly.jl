# [Concepts](@id concepts)

This page provides the mathematical and algorithmic background for Potts.jl.
Understanding these ideas is not required to run simulations, but it will help you design
experiments, tune parameters, and interpret results.

---

## The Cellular Potts Model

### Lattice Representation

A Potts simulation lives on a discrete lattice $\Lambda \subset \mathbb{Z}^d$ (typically
$d = 2$ or $d = 3$). Each lattice site $\mathbf{x} \in \Lambda$ carries an integer **cell
ID** $\sigma(\mathbf{x}) \in \{0, 1, 2, \ldots, N_\text{cells}\}$.
The value $\sigma = 0$ denotes the background *medium*.
All sites with the same non-zero ID belong to the same cell — cells are therefore
*contiguous domains* of equal labels embedded in the lattice.

Each cell $i$ also has an associated **cell type** $\tau(i)$ drawn from a small discrete
set (e.g. `A`, `B`, `Medium`). Cell types determine which biological rules apply to a cell.

### Monte Carlo Dynamics

At each **Monte Carlo step** (MCS) the following procedure is repeated $|\Lambda|$ times
(one *sweep*):

1. Pick a source site $\mathbf{x}$ uniformly at random.
2. Pick a target (neighbour) site $\mathbf{x}'$ from the neighbourhood of $\mathbf{x}$.
3. Propose the copy $\sigma(\mathbf{x}) \leftarrow \sigma(\mathbf{x}')$.
4. Compute the energy change $\Delta H$ that this copy would cause.
5. Accept or reject according to the **Metropolis-Hastings criterion** (see below).

---

## The Hamiltonian

The total energy of a configuration is a sum of penalty terms:

$$H = H_\text{volume} + H_\text{surface} + H_\text{adhesion} + H_\text{length} + \cdots$$

Each penalty term encodes one biological constraint. The exact form of each term is
described in detail on the [Penalties](@ref corepotts-penalties) page. The key property
exploited by the engine is **locality**: because a copy attempt at site $\mathbf{x}$ only
changes cell IDs in a small neighbourhood, $\Delta H$ can be evaluated in $O(1)$ time
using pre-computed incremental statistics maintained by *trackers*.

---

## Metropolis-Hastings Acceptance

A copy proposal is accepted with probability

$$P_\text{accept}(\Delta H) = \begin{cases}
    1 & \text{if } \Delta H \leq 0 \\[4pt]
    \exp\!\left(-\dfrac{\Delta H}{T}\right) & \text{if } \Delta H > 0
\end{cases}$$

where $T$ is an effective temperature (the `T` parameter of the algorithm).
Low $T$ makes the simulation "stiffer" — it accepts few energy-increasing moves and the
system closely tracks local energy minima.
High $T$ allows large fluctuations.

### The Hastings Correction for Parallel Updates

When multiple sites are updated simultaneously (as in `CheckerboardMetropolis` or
`ParallelMetropolis`), a naive application of the Metropolis criterion is biased because the
proposal distribution is no longer symmetric.
CorePotts applies the **Hastings correction**: the acceptance probability is multiplied by the
ratio of the reverse-proposal probability to the forward-proposal probability,

$$P_\text{accept} = \min\!\left(1,\; \frac{q(\mathbf{x}' \to \mathbf{x})}{q(\mathbf{x} \to \mathbf{x}')}\, e^{-\Delta H / T}\right)$$

where $q(\mathbf{x} \to \mathbf{x}')$ is the probability that site $\mathbf{x}'$ was chosen
as the copy source given that $\mathbf{x}$ was the target.
For uniform neighbour sampling this ratio equals the ratio of neighbourhood sizes, which
equals 1 for regular (isotropic) topologies.

---

## HST Penalties (Hubbard-Stratonovich Transformation)

### Motivation

The classical volume penalty is

$$H_\text{vol}(i) = \lambda_V \bigl(v_i - V_i^{\rm target}\bigr)^2$$

This quadratic form is convenient but breaks *detailed balance* when the target volume
$V_i^{\rm target}$ is itself a stochastic variable (e.g. during growth or when it is
learned from data), because the energy landscape changes between the proposal and its
reverse.

### The HST Reformulation

The **Hubbard-Stratonovich transformation** introduces an auxiliary continuous variable
$\phi_i$ for each cell and rewrites the Boltzmann weight as a Gaussian integral:

$$e^{-\lambda_V (v_i - V_i)^2 / T} \propto \int d\phi_i \; e^{-\phi_i^2 / 2} \,
e^{-\lambda_V (v_i - \phi_i)^2 / T}$$

The auxiliary field $\phi_i$ evolves between MCS steps via a discrete
**Ornstein-Uhlenbeck SDE**:

$$\phi_i(t + \Delta t) = (1 - \eta \, \Delta t)\,\phi_i(t) + \eta \, v_i(t)\, \Delta t
+ \sqrt{2 \eta T}\; \xi(t)$$

where $\xi(t)$ is white noise and $\eta$ (the `eta` keyword argument) sets the relaxation
rate.

### Why HST Restores Detailed Balance

Because $\phi_i$ is now a genuine (auxiliary) degree of freedom that evolves independently,
the joint system $(\sigma, \phi)$ satisfies detailed balance with respect to the augmented
Hamiltonian.
This is particularly important for penalties coupled to dynamic targets (growth, division)
and for NeuralPotts, where the energy function is learned.

Use `HSTVolumeComponent`, `HSTLengthComponent`, or `HSTSurfaceAreaComponent` wherever
you need this guarantee.

> [!NOTE]
> HST components carry a small computational overhead per MCS compared to their classical
> counterparts because the auxiliary fields must be updated. For most simulations with static
> targets the classical quadratic penalties are sufficient.

---

## Trackers

Naively computing $H$ for the full lattice after every copy attempt would cost
$O(|\Lambda|)$ per step.
**Trackers** maintain running statistics — cell volume, surface area, centroid,
principal-axis length, etc. — and update them incrementally in $O(1)$ per copy attempt.

The internal update loop is:

```
1. Propose copy σ(x) ← σ(x′)
2. For each active tracker: compute the Δ-contribution to ΔH
3. Accept/reject
4. If accepted: apply tracker updates (increment/decrement counters)
```

No $O(N)$ scan of the lattice ever occurs during the hot loop; the lattice is only scanned
once at initialisation.

> [!TIP]
> Trackers are registered automatically when you add components to a `PottsSystem`. You do
> not need to manage them manually.

---

## GPU Parallelism: Checkerboard Graph Colouring

The key obstacle to parallelising the Metropolis update is **write conflicts**: if two
adjacent sites are updated simultaneously, they may interfere with each other's $\Delta H$
evaluation.

The `CheckerboardMetropolis` algorithm resolves this by partitioning the lattice into
*colour classes* such that no two sites of the same colour are neighbours.
For `VonNeumannTopology{2}` (4-connected) this is the standard 2-colouring
(black/white squares).
For `MooreTopology{2}` (8-connected) a 4-colouring is used.
For 3D topologies the colouring is extended analogously.

Within each colour class all sites are completely independent, so copy attempts can be
evaluated and committed in parallel on a GPU (via CUDA.jl or Metal.jl) or in parallel CPU
threads.
The algorithm cycles through all colour classes in one MCS, so one full sweep still visits
every site exactly once.

> [!IMPORTANT]
> For extended topologies (`ExtendedVonNeumannTopology`, `ExtendedMooreTopology`) the
> neighbourhood radius is larger than 1, which requires more colour classes.
> `ParallelMetropolis` with the lottery mechanism is often a better choice for those cases.
