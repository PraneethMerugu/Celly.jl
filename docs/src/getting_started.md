# [Getting Started](@id getting-started)

This page walks you through installing the Potts.jl packages, running your first
simulation, and choosing the right Monte Carlo algorithm for your use case.

---

## Installation

The four packages are registered in the Julia General registry (or a local registry if you are
working from source). Open the Julia REPL and enter Pkg mode with `]`:

```julia-repl
pkg> add PottsToolkit
pkg> add MakiePotts
pkg> add NeuralPotts
pkg> add CorePotts        # usually pulled in automatically as a dependency
```

Or equivalently from Julia code:

```julia
import Pkg
Pkg.add("PottsToolkit")
Pkg.add("MakiePotts")
Pkg.add("NeuralPotts")
```

### Working from Source (Dev Mode)

If you have cloned the monorepo and want to use the local packages directly, run this
bootstrap one-liner from the repo root:

```julia
import Pkg
for pkg in ["CorePotts", "PottsToolkit", "MakiePotts", "NeuralPotts"]
    Pkg.develop(path = joinpath("lib", pkg))
end
```

This registers each package in dev-mode so that edits you make to the source are immediately
reflected without re-adding.

---

## A Complete Minimal Example: Cell Sorting

The classic Steinberg cell-sorting experiment — two cell populations with different adhesion
energies spontaneously segregate — is the Hello World of Potts simulations.

```julia
using PottsToolkit
using MakiePotts

# ── 1. Cell types ──────────────────────────────────────────────────────────────
A      = CellType(:A)
B      = CellType(:B)
Medium = CellType(:Medium, is_background=true)   # background must be marked explicitly

# ── 2. System: biological components ──────────────────────────────────────────
sys = PottsSystem(
    cell_types = [Medium, A, B],         # background type listed first by convention
    penalties  = [
        # Volume constraint keeps cells at a target area
        VolumeComponent(
            A => (λ = 5.0f0, target = 500),
            B => (λ = 5.0f0, target = 500),
        ),
        # Adhesion drives sorting: A-B contacts are costly, same-type contacts cheap
        AdhesionComponent(
            (A,      Medium) => 15.0f0,
            (B,      Medium) => 15.0f0,
            (A,      A)      => 2.0f0,
            (B,      B)      => 2.0f0,
            (A,      B)      => 10.0f0,
        ),
    ]
)

# ── 3. Problem: cells, grid size, time span ────────────────────────────────────
prob = PottsProblem(
    sys,
    Dict(A => 20, B => 20),  # 20 cells of each type
    (200, 200);               # 200×200 lattice
    tspan = (0, 500),
)

# ── 4. Algorithm and solve ─────────────────────────────────────────────────────
alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
sol = solve(prob, alg; saveat = 10)

# ── 5. Record a video ─────────────────────────────────────────────────────────
record_potts("cell_sorting.mp4", sol;
    metrics   = ["N Cells" => u -> u.N_cells[]],
    framerate = 30,
)
```

After running this you will find `cell_sorting.mp4` in your working directory showing the
two populations progressively clustering together.

---

## Choosing a Monte Carlo Algorithm

PottsToolkit (via CorePotts) ships three Metropolis algorithms. They differ in how lattice-site
copy attempts are parallelised and in the strict guarantees they provide.

| Algorithm | Parallelism | Conflicts | When to use |
|-----------|-------------|-----------|-------------|
| `CheckerboardMetropolis` | Full GPU/CPU parallel | None by construction (graph colouring) | **Default — always try this first** |
| `ParallelMetropolis` | Parallel with lottery | Resolved stochastically | Fallback when checkerboard colouring is unavailable (e.g. extended topologies) |
| `SequentialMetropolis` | Single thread | N/A | Debugging, unit tests, exact reproducibility |

### CheckerboardMetropolis (recommended)

```julia
alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
```

The lattice is coloured like a checkerboard (or a higher-order analogue for Moore
neighbourhoods). All sites of the same colour are independent — they share no neighbours —
so copy attempts can be evaluated in parallel without write conflicts.
This is the fastest algorithm and is fully correct for `VonNeumannTopology` and
`MooreTopology`.

### ParallelMetropolis

```julia
alg = ParallelMetropolis(T = 2.0f0, sweeps_per_step = 10)
```

All sites attempt a copy simultaneously, but a *lottery* mechanism resolves conflicts:
only the winning site in each conflicting neighbourhood actually commits its update.
This introduces a small stochastic bias compared to sequential sampling, but is
appropriate when you need parallelism and the topology does not admit a clean checkerboard
colouring (e.g. `ExtendedVonNeumannTopology`).

### SequentialMetropolis

```julia
alg = SequentialMetropolis(T = 2.0f0, sweeps_per_step = 10)
```

Sites are updated one at a time in a random order. This is the textbook Potts algorithm and
produces statistically exact samples from the Gibbs distribution, but is much slower than
the parallel variants. Use it to validate parallel implementations or to reproduce published
results from the literature.

> [!TIP]
> For most biological simulations on 200×200 or larger grids, `CheckerboardMetropolis` with
> `sweeps_per_step = 10` is a good starting point. Increase `sweeps_per_step` if you want
> each saved frame to correspond to more Monte Carlo sweeps (i.e. more "biological time").

---

## Next Steps

- Read [Concepts](@ref concepts) for the mathematical details behind the Hamiltonian and
  acceptance criterion.
- Browse the **Tutorials** for worked examples covering growth, mitosis, chemotaxis,
  and more.
- See [PottsToolkit](@ref pottstoolkit-overview) for the full component reference.
