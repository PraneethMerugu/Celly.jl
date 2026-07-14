# Potts.jl

The **Cellular Potts Model** (Potts) is a lattice-based computational framework for simulating
the collective behaviour of biological cells. Each lattice site carries an integer *cell ID*;
cells are contiguous domains of equal IDs embedded in a background medium.
A Monte Carlo dynamics drives the system: at each step a lattice site is chosen, its ID is
proposed to be overwritten by a neighbouring ID, and the proposal is accepted or rejected
according to a Boltzmann factor derived from a Hamiltonian that encodes biological rules such
as cell volume, surface area, adhesion, and chemotaxis.
The Potts has been used to model cell sorting, tissue morphogenesis, tumour invasion,
wound healing, and developmental patterning.

---

## The Potts.jl Packages

| Package | Role |
|---------|------|
| **CorePotts** | The physics engine — lattice representation, Monte Carlo algorithms, penalty evaluation, trackers, and I/O backends. Intended as an internal library; end users rarely import it directly. |
| **PottsToolkit** | A declarative, user-facing modeling API that lets you define cell types, attach biological components, build a [`PottsProblem`](@ref), and `solve` it in a few lines of Julia. Re-exports everything from CorePotts. |
| **MakiePotts** | Visualization layer built on Makie.jl — static plots, interactive dashboards (`explore_potts`), and video recording (`record_potts`). |
| **NeuralPotts** | Energy-based model training: replace hand-crafted penalties with a Lux.jl neural network trained via Persistent Contrastive Divergence. |

---

## Quick Start

```julia
using PottsToolkit    # re-exports CorePotts automatically
using MakiePotts

# 1. Define cell types
A      = CellType(:A)
B      = CellType(:B)
Medium = CellType(:Medium, is_background=true)   # background must be marked explicitly

# 2. Assemble the model
sys = PottsSystem(
    cell_types = [Medium, A, B],                  # background type listed first by convention
    penalties  = [
        VolumeComponent(A => (λ=5.0f0, target=500), B => (λ=5.0f0, target=500)),
        AdhesionComponent(
            (A, Medium) => 15.0f0,
            (B, Medium) => 15.0f0,
            (A, A)      => 2.0f0,
            (B, B)      => 2.0f0,
            (A, B)      => 10.0f0,
        ),
    ]
)

# 3. Build and solve the problem
prob = PottsProblem(sys, Dict(A => 20, B => 20), (200, 200); tspan=(0, 500))
alg  = CheckerboardMetropolis(T=2.0f0, sweeps_per_step=10)
sol  = solve(prob, alg; saveat=10)

# 4. Record a video
record_potts("cell_sorting.mp4", sol; framerate=30)
```

---

## Where to Go Next

- **[Getting Started](@ref getting-started)** — installation, first simulation, algorithm selection.
- **[Concepts](@ref concepts)** — the mathematical background: Hamiltonian, Metropolis acceptance, HST penalties.
- **[PottsToolkit](@ref pottstoolkit-overview)** — the modeling API in depth.
- **[MakiePotts](@ref makiepotts-overview)** — visualization, dashboards, and video recording.
- **[NeuralPotts](@ref neuralpotts-overview)** — neural energy-based models.
- **Tutorials** — step-by-step worked examples.
