# Specification-to-Conformance Evidence Index

Status: In progress

This index is the authoritative map from accepted semantics to executable evidence. A green
package-local regression suite does not satisfy a row by itself: evidence must exercise a stable
logical contract, a scalar reference, a validator, or a defined statistical procedure.

| Semantic contract | Reference or validator | Initial executable home | Final adapter evidence | Status |
| --- | --- | --- | --- | --- |
| [State Model](state-model.md) | `ReferenceState`, `state_invariant_errors`, canonical snapshots | `integration/conformance/test_reference_semantics.jl` | CPU and backend state adapters | Foundation present |
| [Time and MCS](time-and-mcs.md) | `AttemptAccounting`, `reference_mcs_attempts` | `integration/conformance/test_reference_semantics.jl` | Named algorithm attempt reports | Foundation present |
| [Energy, Proposals, and Trackers](energy-proposals-and-trackers.md) | neighbor-copy forward/reverse multiplicities, named acceptance laws, exact volume tracker delta/reconstruction, quadratic-volume and unordered-contact Hamiltonians | `integration/conformance/test_reference_semantics.jl` | component reference implementations | Foundation present; further components pending their final scientific contracts |
| [Lifecycle](lifecycle.md) | atomic copy, deterministic division batch, capacity abort, retirement reset, and deferred slot reuse | `integration/conformance/test_reference_semantics.jl` | event and lifecycle adapters | Foundation present; conflict/event adapters pending |
| [Randomness and Reproducibility](randomness-and-reproducibility.md) | `SemanticAddress`, `ReproductionContext`, and failure report | `integration/conformance/test_reference_semantics.jl`, `integration/conformance/test_harness.jl` | addressed RNG known-answer suite | Foundation present; generator pending |
| [Numerical and Cross-Backend Semantics](numerical-and-cross-backend-semantics.md) | typed `ReferenceNumericalPolicy`, `ConformanceCase`, and statistical procedure tiers | `integration/conformance/test_harness.jl` | precision/backend matrix | Foundation present; adapters pending |
| [Topology and Spatial Relations](topology-and-spatial-relations.md) | canonical stencil and closed/periodic boundary oracle | `integration/conformance/test_reference_semantics.jl` | topology adapter matrix | Foundation present; role-specific adapters pending |
| [Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md) | pending query/field oracle | — | field adapter matrix | Pending |
| [CorePotts Public Interfaces](corepotts-public-interface-semantics.md) | test-only `AbstractConformanceAdapter` boundary | `integration/conformance/ConformanceHarness.jl` | public CorePotts protocols | Foundation present; production protocol pending Phase 4 |
| [SciML Interface Semantics](sciml-interface-semantics.md) | pending problem/solution oracle | — | public SciML integration tests | Pending Phase 8 |
| [PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md) | pending compiled-model oracle | — | DSL-to-typed-model equivalence | Pending Phases 10–11 |
| [PottsToolkit Authoring and API Semantics](pottstoolkit-authoring-composition-and-api-semantics.md) | pending authoring/provenance oracle | — | typed API and DSL cases | Pending Phases 10–11 |

The terms **Foundation present** and **Pending** are intentionally distinct from a claim that a
shipping algorithm or backend conforms. They identify whether the testable semantic home exists.

## Failure Reproduction Record

Every randomized conformance failure MUST report:

- semantic master seed and RNG contract version;
- model fingerprint;
- initial logical-state checksum;
- algorithm, numeric policy, dimension, and backend report; and
- one command that selects the failing suite or case.

The test-only `ReproductionContext` gives all Phase 3 cases a common record now. Final public
provenance is implemented through CorePotts and PottsToolkit interfaces in later phases.
