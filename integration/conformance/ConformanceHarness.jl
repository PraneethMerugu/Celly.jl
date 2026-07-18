module ConformanceHarness

using ..ReferenceSemantics: ReferenceState, AttemptAccounting, canonical_checksum,
    assert_valid_state, assert_reference_mcs

export ConformanceCase, conformance_case_matrix, AbstractConformanceAdapter, reference_state,
       attempt_accounting, validate_adapter, ReproductionContext, ConformanceFailure,
       require_conformance, reproduction_report, StatisticalProcedure, statistical_procedure,
       assess_bernoulli, require_logical_match

"""One logical conformance point, independent of an implementation's storage layout."""
struct ConformanceCase
    algorithm::Symbol
    numeric_type::DataType
    dimension::Int
    backend::Symbol
end

function ConformanceCase(; algorithm::Symbol, numeric_type::DataType, dimension::Integer,
        backend::Symbol)
    dimension in (2, 3) || throw(ArgumentError("Phase 3 conformance currently covers dimensions 2 and 3"))
    return ConformanceCase(algorithm, numeric_type, Int(dimension), backend)
end

function conformance_case_matrix(; algorithms = (:sequential, :checkerboard, :lottery),
        numeric_types = (Float32, Float64), dimensions = (2, 3), backends = (:cpu,))
    return [ConformanceCase(algorithm = algorithm, numeric_type = numeric_type,
        dimension = dimension, backend = backend)
        for algorithm in algorithms, numeric_type in numeric_types,
            dimension in dimensions, backend in backends]
end

"""
    AbstractConformanceAdapter

Test-only boundary through which a future CPU or GPU implementation exposes logical state and its
algorithm report. It intentionally accepts no physical arrays, workspace, or kernel detail.
"""
abstract type AbstractConformanceAdapter end

function reference_state(adapter::AbstractConformanceAdapter)
    throw(MethodError(reference_state, (adapter,)))
end

function attempt_accounting(adapter::AbstractConformanceAdapter)
    throw(MethodError(attempt_accounting, (adapter,)))
end

function validate_adapter(adapter::AbstractConformanceAdapter)
    state = reference_state(adapter)
    accounting = attempt_accounting(adapter)
    state isa ReferenceState || throw(ArgumentError("reference_state(adapter) must return ReferenceState"))
    accounting isa AttemptAccounting || throw(ArgumentError(
        "attempt_accounting(adapter) must return AttemptAccounting"))
    assert_valid_state(state)
    assert_reference_mcs(accounting)
    return (state_checksum = canonical_checksum(state), accounting = accounting)
end

struct ReproductionContext
    semantic_seed::UInt64
    rng_version::String
    model_fingerprint::String
    initial_state_checksum::String
    algorithm::Symbol
    numeric_type::DataType
    dimension::Int
    backend_report::String
    command::String
end

function ReproductionContext(; semantic_seed::Integer, rng_version::AbstractString,
        model_fingerprint::AbstractString, initial_state,
        algorithm::Symbol, numeric_type::DataType, dimension::Integer,
        backend_report::AbstractString, command::AbstractString)
    semantic_seed >= 0 || throw(ArgumentError("semantic_seed must be non-negative"))
    isempty(rng_version) && throw(ArgumentError("rng_version must not be empty"))
    isempty(model_fingerprint) && throw(ArgumentError("model_fingerprint must not be empty"))
    isempty(backend_report) && throw(ArgumentError("backend_report must not be empty"))
    isempty(command) && throw(ArgumentError("reproduction command must not be empty"))
    dimension in (2, 3) || throw(ArgumentError("dimension must be 2 or 3"))
    return ReproductionContext(UInt64(semantic_seed), String(rng_version), String(model_fingerprint),
        canonical_checksum(initial_state), algorithm, numeric_type, Int(dimension),
        String(backend_report), String(command))
end

function reproduction_report(context::ReproductionContext)
    return join((
        "semantic_seed=0x$(string(context.semantic_seed; base = 16, pad = 16))",
        "rng_version=$(context.rng_version)",
        "model_fingerprint=$(context.model_fingerprint)",
        "initial_state_checksum=$(context.initial_state_checksum)",
        "algorithm=$(context.algorithm)",
        "numeric_type=$(context.numeric_type)",
        "dimension=$(context.dimension)",
        "backend=$(context.backend_report)",
        "reproduce=$(context.command)",
    ), '\n')
end

struct ConformanceFailure <: Exception
    message::String
    context::ReproductionContext
    details::NamedTuple
end

function Base.showerror(io::IO, failure::ConformanceFailure)
    print(io, failure.message, '\n', reproduction_report(failure.context))
    isempty(failure.details) || print(io, '\n', "details=", failure.details)
end

function require_conformance(condition::Bool, message::AbstractString, context::ReproductionContext;
        details::NamedTuple = NamedTuple())
    condition || throw(ConformanceFailure(String(message), context, details))
    return nothing
end

function require_logical_match(actual::ReferenceState, expected::ReferenceState,
        context::ReproductionContext)
    actual_checksum = canonical_checksum(actual)
    expected_checksum = canonical_checksum(expected)
    require_conformance(actual_checksum == expected_checksum, "logical state differs from reference",
        context; details = (actual_checksum = actual_checksum, expected_checksum = expected_checksum))
    return nothing
end

"""Fixed statistical procedure metadata; actual draws are supplied by an algorithm adapter."""
struct StatisticalProcedure
    tier::Symbol
    minimum_trials::Int
    z_tolerance::Float64
end

function statistical_procedure(tier::Symbol)
    tier === :deterministic && return StatisticalProcedure(tier, 0, 0.0)
    tier === :ci && return StatisticalProcedure(tier, 10_000, 5.0)
    tier === :scheduled && return StatisticalProcedure(tier, 1_000_000, 5.5)
    throw(ArgumentError("tier must be :deterministic, :ci, or :scheduled"))
end

function assess_bernoulli(successes::Integer, trials::Integer, probability::Real,
        procedure::StatisticalProcedure)
    0 <= successes <= trials || throw(ArgumentError("successes must lie in 0:trials"))
    0 <= probability <= 1 || throw(ArgumentError("probability must lie in [0, 1]"))
    trials >= procedure.minimum_trials || return (
        pass = false, reason = :insufficient_trials, z_score = Inf,
        expected = trials * probability, observed = successes,
    )
    if probability == 0 || probability == 1
        expected = probability == 0 ? 0 : trials
        return (pass = successes == expected, reason = :exact_boundary, z_score = 0.0,
            expected = expected, observed = successes)
    end
    expected = trials * probability
    z_score = abs(successes - expected) / sqrt(trials * probability * (1 - probability))
    return (pass = z_score <= procedure.z_tolerance, reason = :z_score, z_score = z_score,
        expected = expected, observed = successes)
end

end
