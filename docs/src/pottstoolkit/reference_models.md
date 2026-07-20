# [Reference Models](@id pottstoolkit-reference-models)

`PottsToolkit.ReferenceModels` provides small deterministic fixtures and paper-scalable constructors.
Every entry is an ordinary composition of public Level 2 declarations and returns either a
`PottsModel` or a concrete CorePotts problem.

| Required family | Public constructors | Primary interpretation |
|:--|:--|:--|
| Biased single-cell migration | `single_cell_biased_migration_problem` | Extension chemotaxis in a fixed linear gradient |
| Prescribed-gradient chemotaxis | `chemotaxis_model`, `chemotaxis_problem` | `:linear`, `:half_normal`, or `:exponential` field profile |
| Monolayer growth | `monolayer_growth_model`, `monolayer_growth_problem` | Target-volume growth, division, and contact repulsion |
| Differential adhesion | `differential_adhesion_model`, `differential_adhesion_problem` | Two-population sorting through unordered contact energies |
| Elongation-driven angiogenesis | `elongation_driven_angiogenesis_model`, `elongation_driven_angiogenesis_problem` | Exact major-axis RMS elongation with optional connectivity |

For example:

```julia
using PottsToolkit
import CorePotts

prob = ReferenceModels.elongation_driven_angiogenesis_problem(
    (48, 48); cells = 12, capacity = 64, tspan = (0, 100), seed = 2026)

alg = CorePotts.SequentialCPM(temperature = 2.0f0)
sol = CorePotts.solve(prob, alg)
```

The current prescribed fields are immutable snapshots. Coupled secretion, uptake, diffusion, and
operator splitting are intentionally outside this reference family until their own semantics are
specified. Parameter values are model inputs rather than universal biological calibrations; a paper
experiment must record its exact model fingerprint, execution fingerprint, units supplied during
post-processing, backend, algorithm, and seed.
