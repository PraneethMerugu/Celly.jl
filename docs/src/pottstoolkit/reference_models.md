# [Reference Models](@id pottstoolkit-reference-models)

`PottsToolkit.ReferenceModels` provides small deterministic fixtures and paper-scalable constructors.
Every entry is an ordinary composition of public Level 2 declarations and returns either a
`PottsModel` or a concrete CorePotts problem. The family list follows the
[OpenVT Reference Models Working Group](https://www.openvt.org/pages/working-groups/reference-models-wg.html),
but PottsToolkit does not claim OpenVT schema compatibility or numerical equivalence to another
framework merely because the same family name is used.

| Required family | Public constructors | Primary interpretation |
|:--|:--|:--|
| Biased single-cell migration | `single_cell_biased_migration_problem` | Extension chemotaxis in a fixed linear gradient |
| Prescribed-gradient chemotaxis | `chemotaxis_model`, `chemotaxis_problem` | `:linear`, `:half_normal`, or `:exponential` field profile |
| Monolayer growth | `monolayer_growth_model`, `monolayer_growth_problem` | Target-volume growth, division, and contact repulsion |
| Differential adhesion | `differential_adhesion_model`, `differential_adhesion_problem` | Two-population sorting through unordered contact energies |
| Elongation-driven angiogenesis | `elongation_driven_angiogenesis_model`, `elongation_driven_angiogenesis_problem` | Exact major-axis RMS elongation with optional connectivity |

## Literature scope and parameter meaning

These constructors are reusable scientific starting points, not fitted biological parameter sets.
Their conventions are grounded in established CPM uses:

- differential contact energies and cell sorting follow the model family introduced by
  [Graner and Glazier (1992)](https://pubmed.ncbi.nlm.nih.gov/10046374/);
- prescribed-field chemotaxis and adhesion are standard CPM morphogenesis ingredients, as in
  [Savill and Hogeweg (1997)](https://pubmed.ncbi.nlm.nih.gov/31940735/);
- target-volume growth followed by division is a conventional CPM lifecycle construction and is
  also the mechanism described in the
  [parallel CPM formulation](https://pmc.ncbi.nlm.nih.gov/articles/PMC2139985/);
- the angiogenesis family is motivated by the finding that cell elongation can drive vascular
  network formation in [Merks et al. (2006)](https://pubmed.ncbi.nlm.nih.gov/16325173/).

`target_volume` is a lattice-site count, each `strength` is the coefficient of its documented
CorePotts Hamiltonian, contact values are unordered interface costs, chemotactic `sensitivity`
scales the declared nonconservative drive, and `target_elongation` is the exact major-axis RMS
length used by `QuadraticElongationHamiltonian`. All time values are integer MCS. The constructors
do not choose an update algorithm: `SequentialCPM` is the ordered literature-reference semantics,
while explicitly named parallel algorithms have their own accepted statistical contracts.

The biased-migration fixture realizes a positive horizontal stochastic bias through extension
chemotaxis in a fixed linear field. This is an operational CPM realization of the OpenVT biased
motility category, not a claim that chemotactic bias and every force-based motility law are
identical. Likewise, the three prescribed profiles are immutable fields; they do not imply
secretion, uptake, diffusion, or PDE coupling.

## Required observables

A paper experiment must define an ensemble procedure before interpreting emergent behavior. The
recommended family-level observables are:

| Family | Invariants checked per run | Statistical observables across seeds |
|:--|:--|:--|
| Biased migration | one active finite cell; valid ownership and volume | centroid displacement, mean-squared displacement, persistence, and directional index |
| Prescribed-gradient chemotaxis | field values and profile fingerprint remain fixed | displacement along the gradient, chemotactic index, speed, and response by profile |
| Monolayer growth | capacity is not exceeded; lifecycle transactions and cell identities remain valid | active-cell count, occupied area, density, division count, and radial growth versus MCS |
| Differential adhesion | both populations remain typed and all contact laws are present | unlike-contact measure, segregation index, domain-size distribution, and sorting kinetics |
| Elongation-driven angiogenesis | exact moment tracker remains valid; fragmentation follows the explicit connectivity choice | network span, connected components, cell-contact graph, branch/junction density, and shape anisotropy |

The current smoke suite proves construction, normalization, fingerprinting, lowering, invariant
preservation, actual proposal accounting, and CPU/Metal/ROCm execution. It does **not** yet claim
that a tiny fixture reproduces a published emergent distribution. Phase 15 paper qualification owns
ensemble sizes, statistical tests, literature parameterizations, and acceptance thresholds.

For example:

```julia
using PottsToolkit
import CorePotts

prob = ReferenceModels.elongation_driven_angiogenesis_problem(
    (48, 48); cells = 12, capacity = 64, tspan = (0, 100), seed = 2026)

alg = CorePotts.SequentialCPM(temperature = 2.0f0)
sol = CorePotts.solve(prob, alg)
```

A paper experiment must record its exact model fingerprint, execution fingerprint, backend,
algorithm, semantic seed set, numerical policy, observation procedure, and any units attached
during post-processing.
