# [Scientific contract identities and algorithm guarantees](@id scientific-contract-identities)

Scientific contract versions are independent of the package version. Inspect the complete set with:

```julia
using CorePotts

scientific_contract_versions()
```

The returned `ScientificContractVersions` value records the RNG, PottsToolkit authoring DSL,
normalized IR, checkpoint schema, semantic and execution fingerprints, Phase 13 result/evidence
schema, and algorithm/scheduler identities. Its `freeze_status` is `:phase13_frozen`: the project
owner approved these exact paper API identities after reviewing the final Phase 13 evidence packet.

| Contract | Frozen identity |
|:--|:--|
| Semantic RNG | `RNG_CONTRACT_VERSION` |
| PottsToolkit authoring DSL | `AUTHORING_DSL_CONTRACT_VERSION` |
| Normalized authoring IR | `NORMALIZED_IR_CONTRACT_VERSION` |
| Canonical checkpoint schema | `CHECKPOINT_SCHEMA_VERSION` |
| Semantic fingerprint | `SEMANTIC_FINGERPRINT_VERSION` |
| Execution fingerprint | `EXECUTION_FINGERPRINT_VERSION` |
| Phase 13 result/evidence schema | `PHASE13_RESULT_EVIDENCE_SCHEMA_VERSION` |
| Sequential algorithm | `SEQUENTIAL_ALGORITHM_CONTRACT_VERSION` |
| Checkerboard scheduler | `CHECKERBOARD_SCHEDULER_CONTRACT_VERSION` |
| Lottery algorithm | `LOTTERY_ALGORITHM_CONTRACT_VERSION` |
| Experimental tiled checkerboard | `TILED_CHECKERBOARD_EXPERIMENTAL_CONTRACT_VERSION` |

## Guarantee metadata

`algorithm_guarantees(algorithm)` returns an `AlgorithmGuaranteeProfile`. The Phase 13 fields are:

- `guarantee_label`: one value from `algorithm_guarantee_taxonomy()`;
- `qualified_domain`: the exact admitted model and parameter domain;
- `maximum_observed_discrepancy`: the largest retained comparison discrepancy;
- `tested_backends`: backends represented by applicable current evidence;
- `evidence_version`: the retained evidence record version;
- `api_status` and `paper_scope`: API stability and paper-admission decisions.

Empty evidence fields are meaningful. They say that qualification has not yet been established; they
must not be populated from intended support, successful compilation, or unrelated performance
tests. In particular, `backend_contract` declares intended execution support, while
`tested_backends` records only applicable Phase 13 evidence.

The production sequential and ordinary checkerboard algorithm APIs are stable and retain the
scientifically conservative `:unqualified` label. Their profiles name the exact transition and
realistic evidence domains, tested backends, retained maximum discrepancy, and evidence version.
This API stability does not claim equilibrium, sequential--checkerboard equivalence, cross-backend
realistic equivalence, or physical-time semantics. `LotteryCPM` is a limited later protocol
consumer, not part of the initial Phase 13 matrix. `SequentialEquilibrium` and
`TiledCheckerboardCPM` are explicitly experimental and outside the paper scope.

Downstream algorithms may continue constructing `AlgorithmGuaranteeProfile` with the original
required keywords. New evidence fields default conservatively to unqualified, provisional, no
paper scope, no tested backend, and no evidence version.

`compatibility_report` and PottsToolkit's `backend_report` include the same profile in their
`guarantee` field. A report's `qualified` Boolean means that the selected combination passes the
execution preflight; it does not itself assert a transition-kernel guarantee.
