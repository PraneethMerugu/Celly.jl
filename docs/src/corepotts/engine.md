# [Monte Carlo Algorithms](@id corepotts-engine)

CorePotts provides four Monte Carlo update algorithms. They all implement the same
Metropolis-Hastings acceptance criterion (see [Concepts](@ref concepts)) but differ in
*how* lattice-site copy attempts are parallelised.

An algorithm is selected when constructing the integrator:

```julia
alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
sol = solve(prob, alg; saveat = 10)
```

---

## CheckerboardMetropolis *(recommended)*

```julia
alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
```

**How it works:**

The lattice is partitioned into *colour classes* (the checkerboard decomposition) such
that no two sites of the same colour are neighbours. All sites of the same colour are
therefore independent — evaluating $\Delta H$ at one site does not affect any other site
in the same class. This means all sites in a colour class can be processed simultaneously
without any conflict-resolution logic.

One MCS consists of cycling through all colour classes in sequence; within each class all
sites are updated in parallel.

**Properties:**
- ✅ No write conflicts — no lottery or retry logic needed.
- ✅ Fastest algorithm for standard topologies.
- ✅ Compatible with GPU execution via KernelAbstractions.jl.
- ✅ Satisfies detailed balance (with Hastings correction).
- ⚠️ Only works out-of-the-box for topologies that admit a finite colouring:
  `VonNeumannTopology` (2 colours), `MooreTopology` (4 colours in 2D, 8 in 3D),
  and `VonNeumannTopology{3}` (2 colours).

**When to use:** Almost always. This is the default algorithm.

---

## ParallelMetropolis

```julia
alg = ParallelMetropolis(T = 2.0f0, sweeps_per_step = 10)
```

**How it works:**

All sites simultaneously draw a random copy proposal and evaluate $\Delta H$.
When two adjacent sites both want to commit an update that would affect the same
cell statistics, a **lottery** mechanism selects one winner and discards the other.
The winning site commits its update; the losing site is treated as a rejection.

**Properties:**
- ✅ Fully parallel — no colouring step.
- ✅ Works for any topology, including extended-radius topologies.
- ⚠️ The lottery introduces a small bias relative to the exact sequential sampler.
- ⚠️ Acceptance rate is slightly lower than `CheckerboardMetropolis` because of
  lottery losses.

**When to use:** When you are using `ExtendedVonNeumannTopology` or
`ExtendedMooreTopology` where a clean checkerboard colouring does not exist.

---

## SequentialMetropolis

```julia
alg = SequentialMetropolis(T = 2.0f0, sweeps_per_step = 10)
```

**How it works:**

Sites are visited one at a time in a uniformly random order (random permutation per
sweep). Each copy proposal is evaluated and accepted/rejected before the next site is
visited. This is the textbook Potts algorithm.

**Properties:**
- ✅ Statistically exact — produces the true Gibbs distribution.
- ✅ No conflict-resolution required.
- ✅ Fully reproducible with a fixed random seed.
- ❌ Single-threaded — cannot be parallelised without breaking the sequential guarantee.
- ❌ Much slower than parallel variants for large grids.

**When to use:**
- Debugging a new penalty: compare against `CheckerboardMetropolis` to verify
  correctness.
- Reproducing published results that specify sequential sampling.
- Unit tests that require exact, seed-reproducible trajectories.

---

## SparseLotteryMetropolis

```julia
alg = SparseLotteryMetropolis(T = 2.0f0, sweeps_per_step = 10, active_fraction = 0.1f0)
```

**How it works:**

A sparse variant of `ParallelMetropolis`. Instead of considering every lattice site each
sweep, only a random fraction `active_fraction` of sites participate in each pass.
This dramatically reduces memory bandwidth for simulations with large grids and few
active cells.

**Properties:**
- ✅ Efficient for sparse configurations (many medium sites, few cells).
- ✅ Works for any topology.
- ⚠️ Introduces additional sparsity-induced bias.

**When to use:** Large lattices with low cell occupancy — e.g. a few cells in a vast
medium, or during initialisation before many cells are seeded.

---

## Parameter Reference

| Parameter | Applies to | Description | Typical range |
|-----------|-----------|-------------|---------------|
| `T` | all | Effective temperature. Controls acceptance of energy-increasing moves. | 0.5 – 10.0 |
| `sweeps_per_step` | all | Number of full lattice sweeps per saved time step. Governs how much "biological time" passes per frame. | 1 – 100 |
| `active_fraction` | `SparseLotteryMetropolis` | Fraction of sites sampled per pass. | 0.01 – 1.0 |
| `block_size` | `CheckerboardMetropolis` | GPU thread-block size (advanced). Tune for hardware. | 32, 64, 128, 256 |

> [!TIP]
> Temperature `T` does not have units in the strict physical sense — it is measured in
> the same units as the Hamiltonian. If you double all $\lambda$ values, you should also
> double `T` to keep the same effective dynamics. A good heuristic is to set
> `T ≈ 0.1 × λ_V × V_{\rm target}^{2/3}`.

> [!NOTE]
> All four algorithms natively evaluate and execute `AbstractEvent`s registered on the 
> `PottsSystem` inside their inner loops using zero-allocation mask-driven GPU kernels. 
> Standard continuous SciML callbacks (e.g. `LinearGrowthCallback`) can also be passed via 
> the `callback` keyword in `solve`.
