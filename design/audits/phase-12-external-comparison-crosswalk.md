# Phase 12 External CPM Comparison Crosswalk

Status: Semantics audited; execution fixtures deferred to the separate external suite

Date: 2026-07-21

## Purpose

This audit determines which of the five paper model families can support a semantically matched
external timing. It does not claim that similarly named examples implement the same stochastic
process. A missing match is recorded as incomparable rather than approximated to enlarge a
leaderboard.

The first execution suite pins:

- CompuCell3D 4.9.0;
- Morpheus 2.4.1; and
- Artistoo 1.2.0.

Phase 15 may advance a pin only by recording the new version and rerunning every affected fixture.

## Comparison identity

An external result enters a headline comparison only when all of the following are explicit:

1. lattice dimension, shape, spacing, boundary conditions, and copy neighborhood;
2. initial lattice labels and finite-cell identities;
3. Hamiltonian formula, contact counting convention, parameters, numerical precision, and
   acceptance temperature;
4. proposal process and MCS normalization;
5. field values, interpolation, source/recipient convention, and chemotaxis response;
6. lifecycle observation interval, trigger, division geometry, event order, and inherited state;
7. warmup, timed MCS count, output/observation work, synchronization, and setup/JIT boundaries;
8. hardware, process/thread count, software version, and seed policy.

Different random-number streams are acceptable for statistical validation, but they cannot support
trajectory-identity claims. A sequential external CPM is compared only with `SequentialCPM` (or
`SequentialEquilibrium` when its detailed-balance contract is established), never with the
transaction semantics of `CheckerboardSweepCPM` or `LotteryCPM` under one unlabeled algorithm name.

## Five-family audit

| Potts.jl paper family | CompuCell3D 4.9.0 | Morpheus 2.4.1 | Artistoo 1.2.0 | Phase 12 disposition |
|---|---|---|---|---|
| Single-cell biased migration | Candidate through a fixed field and Chemotaxis plugin; `ExternalPotential` is a different force model | Candidate through fixed-field Chemotaxis | Candidate through `ChemotaxisConstraint` | Match the prescribed-field Hamiltonian, not a visually similar motility example |
| Prescribed-gradient chemotaxis | Candidate; linear and saturating responses exist | Candidate; CPM/PDE and fixed-boundary chemotaxis examples exist | Candidate; a supplied `Grid2D` or coarse field is supported | Headline-eligible only after source/recipient sign, interpolation, and exact field samples agree |
| Growth/division monolayer | Expressible with target-volume growth and MCS-frequency mitosis, but built-in split and update order differ | Proliferation exists in 2D and 3D, but trigger/order/split equivalence is not established | `CPMEvol`/`Divider` and division examples exist, but the published example uses stochastic division | Attempt all three; report model-class throughput only until lifecycle semantics are matched |
| Differential-adhesion sorting | Direct candidate through Volume and Contact plugins and a documented cell-sorting model | Direct candidate through VolumeConstraint and Contact with a published cell-sorting model | Direct candidate through VolumeConstraint and Adhesion with the classic sorting example | Strongest initial external headline fixture after neighborhood and contact-count calibration |
| Elongation-driven angiogenesis | LengthConstraint and connectivity exist in 2D/3D, but their quadratic principal-length energy is not yet proven equal to Potts.jl's HST pressure update | Vascular-patterning examples use chemotaxis/PDE coupling rather than this elongation-only mechanism | No built-in principal-axis length constraint was found; a custom constraint would be required | Attempt and label incomparable; no speed ratio until the energy/update mechanism is demonstrated equivalent |

## Source-backed capability findings

- CompuCell3D documents quadratic volume/surface terms, per-type contact energies, fixed-field
  chemotaxis responses, MCS-frequency mitosis, and a principal-axis LengthConstraint. Its connectivity
  plugin can hard-reject fragmenting copies, which must not be silently enabled when the Potts.jl
  fixture permits fragmentation.
- Morpheus ships cell sorting, 2D/3D proliferation, chemotaxis, and vascular-patterning examples. Its
  vascular example couples CPM motion to a reaction-diffusion field, so it is not a substitute for
  Potts.jl's elongation-only angiogenesis reference.
- Artistoo exposes modular soft/hard constraints, including adhesion, volume, chemotaxis, perimeter,
  persistence, and connectivity, plus cell lineage/division support. This is enough for sorting and
  prescribed-field fixtures, but similarity of an example name is not lifecycle or elongation
  equivalence.

## Timing policy

External setup, import/JIT, initialization, first MCS, warm MCS, observation, rendering, and file
output are recorded separately wherever the tool exposes them. The headline boundary is warm
scientific execution with rendering and disk output disabled on every implementation. If a simulator
cannot expose an equivalent boundary, the result is descriptive and incomparable.

## Phase 12 conclusion

The external suite has a safe initial route: differential adhesion first, then prescribed-gradient
chemotaxis after formula calibration. The remaining three families are still attempted, but their
known lifecycle or Hamiltonian differences prohibit a headline ratio today. This satisfies the
semantic-validation requirement without weakening any existing scientific or GPU goal; actual
publication comparisons remain Phase 15 evidence.

## Primary references

- [CompuCell3D 4.9.0 release](https://compucell3d.org/)
- [CompuCell3D Volume and Surface constraints](https://compucell3dreferencemanual.readthedocs.io/en/latest/global_volume_and_surface_plugins.html)
- [CompuCell3D Chemotaxis](https://compucell3dreferencemanual.readthedocs.io/en/latest/chemotaxis_plugin.html)
- [CompuCell3D Mitosis](https://compucell3dreferencemanual.readthedocs.io/en/latest/mitosis.html)
- [CompuCell3D LengthConstraint](https://compucell3dreferencemanual.readthedocs.io/en/latest/length_constraint.html)
- [Morpheus 2.4.1 downloads](https://morpheus.gitlab.io/download/)
- [Morpheus built-in CPM examples](https://morpheus.gitlab.io/model/built-in-examples/)
- [Morpheus simplified cell sorting](https://morpheus.gitlab.io/model/m2007/)
- [Morpheus chemotaxis](https://morpheus.gitlab.io/model/m2010/)
- [Morpheus vascular patterning](https://morpheus.gitlab.io/model/m0032/)
- [Artistoo 1.2.0 release](https://github.com/ingewortel/artistoo/releases/tag/v1.2.0)
- [Artistoo constraint architecture](https://artistoo.net/manual/addConstraints.html)
- [Artistoo ChemotaxisConstraint](https://artistoo.net/class/src/hamiltonian/ChemotaxisConstraint.js~ChemotaxisConstraint.html)
- [Artistoo example gallery](https://artistoo.net/examples.html)
