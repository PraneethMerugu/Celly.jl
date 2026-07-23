"""
    ScientificContractVersions

Inspectable identities for the scientific contracts frozen at Phase 13. The versions are
independent of package versions. `freeze_status == :phase13_frozen` records explicit project-owner
approval of these exact paper-release identities.
"""
struct ScientificContractVersions
    freeze_status::Symbol
    rng::VersionNumber
    authoring_dsl::VersionNumber
    normalized_ir::VersionNumber
    checkpoint_schema::VersionNumber
    semantic_fingerprint::VersionNumber
    execution_fingerprint::VersionNumber
    result_evidence_schema::VersionNumber
    sequential_algorithm::VersionNumber
    checkerboard_scheduler::VersionNumber
    lottery_algorithm::VersionNumber
    tiled_checkerboard_experimental::VersionNumber
end

const RNG_CONTRACT_VERSION = v"1.0.0"
const AUTHORING_DSL_CONTRACT_VERSION = v"1.0.0"
const NORMALIZED_IR_CONTRACT_VERSION = v"1.0.0"
const CHECKPOINT_SCHEMA_VERSION = v"1.0.0"
const SEMANTIC_FINGERPRINT_VERSION = v"1.0.0"
const EXECUTION_FINGERPRINT_VERSION = v"1.0.0"
const PHASE13_RESULT_EVIDENCE_SCHEMA_VERSION = v"1.0.0"
const SEQUENTIAL_ALGORITHM_CONTRACT_VERSION = v"1.0.0"
const CHECKERBOARD_SCHEDULER_CONTRACT_VERSION = v"1.0.0"
const LOTTERY_ALGORITHM_CONTRACT_VERSION = v"1.0.0"
const TILED_CHECKERBOARD_EXPERIMENTAL_CONTRACT_VERSION = v"1.0.0"

const SCIENTIFIC_CONTRACT_VERSIONS = ScientificContractVersions(
    :phase13_frozen,
    RNG_CONTRACT_VERSION,
    AUTHORING_DSL_CONTRACT_VERSION,
    NORMALIZED_IR_CONTRACT_VERSION,
    CHECKPOINT_SCHEMA_VERSION,
    SEMANTIC_FINGERPRINT_VERSION,
    EXECUTION_FINGERPRINT_VERSION,
    PHASE13_RESULT_EVIDENCE_SCHEMA_VERSION,
    SEQUENTIAL_ALGORITHM_CONTRACT_VERSION,
    CHECKERBOARD_SCHEDULER_CONTRACT_VERSION,
    LOTTERY_ALGORITHM_CONTRACT_VERSION,
    TILED_CHECKERBOARD_EXPERIMENTAL_CONTRACT_VERSION,
)

"""Return the immutable Phase 13 frozen scientific-contract version report."""
scientific_contract_versions() = SCIENTIFIC_CONTRACT_VERSIONS

function Base.show(io::IO, versions::ScientificContractVersions)
    print(io, "ScientificContractVersions(", versions.freeze_status,
        ", rng=", versions.rng, ", dsl=", versions.authoring_dsl,
        ", ir=", versions.normalized_ir, ", evidence=",
        versions.result_evidence_schema, ')')
end
