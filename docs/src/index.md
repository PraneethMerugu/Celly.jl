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
| **CorePotts** | The hardware-agnostic scientific engine: state, algorithms, components, trackers, lifecycle, persistence, and SciML execution. |
| **PottsToolkit** | The curated Level 2 authoring API: biological identities, components, composition, validation, reports, reference models, and public lowering to CorePotts. |
| **MakiePotts** | Visualization layer built on Makie.jl — static plots, interactive dashboards (`explore_potts`), and video recording (`record_potts`). |
| **NeuralPotts** | Energy-based model training: replace hand-crafted penalties with a Lux.jl neural network trained via Persistent Contrastive Divergence. |

---

## Quick Start

```julia
using PottsToolkit
import CorePotts

# 1. Construct and inspect a reusable Level 2 model
model = ReferenceModels.differential_adhesion_model(
    target_volume=20, between=15, medium_contact=8)
report = explain(model)

# 2. Build and solve a deterministic instance
prob = ReferenceModels.differential_adhesion_problem(
    (64, 64); cells_per_population=12, capacity=32,
    target_volume=20, between=15, medium_contact=8,
    tspan=(0, 500), seed=2026)
alg = CorePotts.CheckerboardSweepCPM(temperature=2.0f0)
sol = CorePotts.solve(prob, alg; saveat=10)
```

---

## Where to Go Next

- **[Getting Started](@ref getting-started)** — installation, first simulation, algorithm selection.
- **[Concepts](@ref concepts)** — the mathematical background: Hamiltonian, Metropolis acceptance, HST penalties.
- **[PottsToolkit](@ref pottstoolkit-overview)** — the modeling API in depth.
- **[MakiePotts](@ref makiepotts-overview)** — visualization, dashboards, and video recording.
- **[NeuralPotts](@ref neuralpotts-overview)** — neural energy-based models.
- **Tutorials** — step-by-step worked examples.
