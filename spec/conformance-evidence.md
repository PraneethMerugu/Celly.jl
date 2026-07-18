# Specification-to-Conformance Evidence Index

Semantic status: Accepted index structure

Implementation maturity: Phase 3 foundation and Phase 4 reference slice complete

This index is the authoritative map from accepted semantics to executable evidence. A green
package-local regression suite does not satisfy a row by itself: evidence must exercise a stable
logical contract, a scalar reference, a validator, or a defined statistical procedure.

| Semantic contract | Reference or validator | Reference maturity | Production/backend maturity | Remaining gate |
| --- | --- | --- | --- | --- |
| [State Model](state-model.md) | `LogicalPottsState`, `state_invariant_errors`, canonical snapshots | Reference implemented | Historical production state not migrated | Compiled-state round trip and backend adapters |
| [Time and MCS](time-and-mcs.md) | `ReferenceMCSReport`, `AttemptAccounting`, normalized-round validators | Reference implemented for conventional `N`-attempt MCS | Historical optimized algorithms not migrated | Lottery calibration and named-algorithm reports |
| [Energy, Proposals, and Trackers](energy-proposals-and-trackers.md) | full/local volume and contact energy, proposal and acceptance oracles | Reference implemented for volume and contact | Historical optimized components not migrated | Further components and tracker lowering |
| [Lifecycle](lifecycle.md) | logical transactions plus reference-engine extinction/reuse | Reference implemented for copy extinction and core transactions | Historical event runtime not migrated | Event conflicts and compiled lifecycle adapters |
| [Randomness and Reproducibility](randomness-and-reproducibility.md) | semantic-address fixtures and versioned reference-engine draws | Temporary reference contract implemented | Backend RNG is deferred | Accepted generator and cross-backend known-answer qualification |
| [Numerical and Cross-Backend Semantics](numerical-and-cross-backend-semantics.md) | typed `ReferenceNumericalPolicy`, `ConformanceCase`, and statistical procedure tiers | `integration/conformance/test_harness.jl` | precision/backend matrix | Foundation present; adapters pending |
| [Topology and Spatial Relations](topology-and-spatial-relations.md) | canonical stencil oracle and reference periodic von Neumann execution | Reference implemented for the first 2D relation | Historical topology runtime remains | Role-specific compiled adapters |
| [Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md) | pending query/field oracle | — | field adapter matrix | Pending |
| [CorePotts Public Interfaces](corepotts-public-interface-semantics.md) | public logical state, proposal transactions, category validators | Protocol fixtures and complete reference-MCS consumer pass | Historical optimized components not migrated | Extend consumers as later component families land |
| [Sequential Reference Engine](reference-engine-semantics.md) | checked sequential CPU execution | Reference implemented for the 2D volume/contact slice | Deferred; it is not a production engine | Extend per later algorithm/component phases |
| [SciML Interface Semantics](sciml-interface-semantics.md) | pending problem/solution oracle | — | public SciML integration tests | Pending Phase 8 |
| [PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md) | volume-plus-contact authoring compilation | Reference implemented for one public spelling | Production compiler remains historical | Complete typed IR/compiler in Phases 10–11 |
| [PottsToolkit Authoring and API Semantics](pottstoolkit-authoring-composition-and-api-semantics.md) | public `CellType`/`PottsSystem`/component/layout path | Reference implemented for one vertical slice | Full DSL/API remains provisional | Complete DSL coverage in Phases 10–11 |

Legacy rows retain their Phase 3 wording until their executable slices are revised, but no
`Foundation present` entry claims that a shipping algorithm or backend conforms. New and revised
rows use the maturity vocabulary in `README.md`; rows assigned to later phases remain open
implementation obligations.

## Failure Reproduction Record

Every randomized conformance failure MUST report:

- semantic master seed and RNG contract version;
- model fingerprint;
- initial logical-state checksum;
- algorithm, numeric policy, dimension, and backend report; and
- one command that selects the failing suite or case.

The test-only `ReproductionContext` gives all Phase 3 cases a common record now. Final public
provenance is implemented through CorePotts and PottsToolkit interfaces in later phases.
