module RealisticEvidenceAnalysis

using Statistics
using TOML
using Distributions
using ..RealisticEvidenceArchive

export realistic_endpoint_specs, analyze_realistic_equivalence,
       analyze_realistic_family, write_realistic_analysis

const REALISTIC_ANALYSIS_SCHEMA_VERSION = "1.0.0"

function _require_match(left::AbstractDict, right::AbstractDict,
        table::AbstractString, field::AbstractString)
    get(left, field, nothing) == get(right, field, nothing) || throw(ArgumentError(
        "$table field '$field' differs between evidence records"))
end

function _require_registered_evidence(record::AbstractDict, manifest::AbstractDict)
    identity = record["identity"]
    sampling = record["sampling"]
    identity["study_version"] == manifest["manifest_version"] || throw(ArgumentError(
        "evidence study version does not match the analysis manifest"))
    identity["statistical_plan"] == manifest["statistical_plan"] || throw(ArgumentError(
        "evidence statistical plan does not match the analysis manifest"))
    identity["number_type"] == manifest["number_type"] || throw(ArgumentError(
        "evidence number type does not match the analysis manifest"))
    identity["algorithm"] in manifest["algorithms"] || throw(ArgumentError(
        "evidence algorithm is not registered by the analysis manifest"))
    identity["backend"] in manifest["backends"] || throw(ArgumentError(
        "evidence backend is not registered by the analysis manifest"))

    workload_id = identity["workload"]
    matches = filter(workload -> workload["id"] == workload_id, manifest["workloads"])
    length(matches) == 1 || throw(ArgumentError(
        "evidence workload is not uniquely registered by the analysis manifest"))
    registered_workload = only(matches)
    if sampling["profile"] == "qualification"
        record["workload"] == registered_workload || throw(ArgumentError(
            "qualification evidence workload differs from the registered workload"))
    end
    record["model"] == manifest["model"] || throw(ArgumentError(
        "evidence model table differs from the registered model"))
    record["analysis"] == manifest["analysis"] || throw(ArgumentError(
        "evidence analysis table differs from the registered analysis"))
    identity["workload_fingerprint"] ==
        workload_fingerprint(record["workload"], manifest) || throw(ArgumentError(
            "evidence workload fingerprint does not match the analysis manifest"))

    registered_sampling = (
        "registered_replicas" => manifest["replicas_per_identity"],
        "layout_seed_domain" => manifest["layout_seed_domain"],
        "simulation_seed_domain" => manifest["simulation_seed_domain"],
        "seed_base_hex" => manifest["seed_base_hex"],
    )
    for (field, expected) in registered_sampling
        get(sampling, field, nothing) == expected || throw(ArgumentError(
            "evidence sampling field '$field' does not match the analysis manifest"))
    end
    get(sampling, "independent_replicas", false) === true || throw(ArgumentError(
        "evidence does not declare independent replicas"))
    return nothing
end

function _require_comparable_pair(reference::AbstractDict, candidate::AbstractDict,
        comparison::Symbol, manifest::AbstractDict)
    _require_registered_evidence(reference, manifest)
    _require_registered_evidence(candidate, manifest)
    left_identity, right_identity = reference["identity"], candidate["identity"]
    for field in ("study_version", "statistical_plan", "workload",
            "workload_fingerprint", "model_fingerprint", "rng_contract_version",
            "number_type", "source_revision")
        _require_match(left_identity, right_identity, "identity", field)
    end
    left_sampling, right_sampling = reference["sampling"], candidate["sampling"]
    for field in ("profile", "registered_replicas", "layout_seed_domain",
            "simulation_seed_domain", "seed_base_hex")
        _require_match(left_sampling, right_sampling, "sampling", field)
    end
    if comparison === :paired_algorithm
        left_identity["backend"] == right_identity["backend"] || throw(ArgumentError(
            "paired algorithm comparison requires one backend"))
        left_identity["algorithm"] != right_identity["algorithm"] || throw(ArgumentError(
            "paired algorithm comparison requires distinct algorithms"))
    else
        for field in ("algorithm", "algorithm_contract_version", "scheduler")
            _require_match(left_identity, right_identity, "identity", field)
        end
        left_identity["backend"] != right_identity["backend"] || throw(ArgumentError(
            "independent backend comparison requires distinct backends"))
    end
    return nothing
end

function _require_one_registered_family(references::AbstractVector,
        candidates::AbstractVector, manifest::AbstractDict)
    records = vcat(collect(references), collect(candidates))
    first_identity, first_sampling = records[1]["identity"], records[1]["sampling"]
    for record in @view records[2:end]
        identity, sampling = record["identity"], record["sampling"]
        for field in ("study_version", "statistical_plan", "rng_contract_version",
                "number_type", "source_revision")
            _require_match(first_identity, identity, "family identity", field)
        end
        for field in ("profile", "registered_replicas", "layout_seed_domain",
                "simulation_seed_domain", "seed_base_hex")
            _require_match(first_sampling, sampling, "family sampling", field)
        end
    end
    for side in (references, candidates)
        first_side = side[1]["identity"]
        for record in @view side[2:end]
            identity = record["identity"]
            for field in ("algorithm", "algorithm_contract_version", "scheduler", "backend")
                _require_match(first_side, identity, "claim-family identity", field)
            end
        end
    end
    workload_ids = getindex.(getindex.(references, "identity"), "workload")
    length(unique(workload_ids)) == length(workload_ids) || throw(ArgumentError(
        "claim family contains duplicate workloads"))
    registered_ids = getindex.(manifest["workloads"], "id")
    Set(workload_ids) == Set(registered_ids) || throw(ArgumentError(
        "claim family must contain every registered workload exactly once"))
    return nothing
end

_raw(name, field; relative = nothing, absolute = nothing, standardized = nothing,
    quantile = nothing) = (; name, field, scale = :raw, relative, absolute,
        standardized, quantile, divisor = nothing, lower = nothing, upper = nothing)
_log(name, field, lower, upper; divisor = nothing) = (; name, field, scale = :log,
    relative = nothing, absolute = nothing, standardized = nothing, quantile = nothing,
    divisor, lower = log(lower), upper = log(upper))

function realistic_endpoint_specs(workload::AbstractDict, manifest::AbstractDict)
    id = workload["id"]
    base = [
        _raw("volume_cv_mean", "volume_coefficient_of_variation_mean";
            relative = 0.10, standardized = 0.25),
        _raw("boundary_mean", "boundary_measure_mean";
            relative = 0.10, standardized = 0.25),
        [_raw("volume_cv_q$(Int(100q))", "volume_coefficient_of_variation_mean";
            relative = 0.10, standardized = 0.25, quantile = q)
            for q in manifest["analysis"]["quantiles"]]...,
        [_raw("boundary_q$(Int(100q))", "boundary_measure_mean";
            relative = 0.10, standardized = 0.25, quantile = q)
            for q in manifest["analysis"]["quantiles"]]...,
    ]
    if id == "adhesion_volume_relaxation"
        return [
            _raw("energy_mean", "energy_per_mutable_site_mean";
                relative = 0.05, standardized = 0.25),
            base...,
            _log("energy_autocorrelation", "energy_integrated_autocorrelation_time",
                inv(1.15), 1.15),
            _log("morphology_autocorrelation",
                "morphology_integrated_autocorrelation_time", inv(1.15), 1.15),
            _log("mixing_time", "mixing_time_mcs", inv(1.20), 1.20),
            _log("energy_ess_per_mcs", "energy_effective_sample_size", 0.80, 1.25;
                divisor = "measured_mcs"),
            _log("morphology_ess_per_mcs", "morphology_effective_sample_size",
                0.80, 1.25; divisor = "measured_mcs")]
    elseif id == "differential_adhesion_sorting"
        return [
            _raw("energy_mean", "energy_per_mutable_site_mean";
                relative = 0.05, standardized = 0.25),
            _raw("heterotypic_contact_fraction", "heterotypic_contact_fraction_mean";
                absolute = 0.05, standardized = 0.25),
            _raw("segregation_index", "segregation_index_mean";
                absolute = 0.05, standardized = 0.25),
            base...,
            _log("sorting_autocorrelation", "sorting_integrated_autocorrelation_time",
                inv(1.15), 1.15),
            _log("mixing_time", "mixing_time_mcs", inv(1.20), 1.20),
            _log("sorting_ess_per_mcs", "sorting_effective_sample_size", 0.80, 1.25;
                divisor = "measured_mcs")]
    elseif id == "single_cell_migration"
        diameter = sqrt(Float64(manifest["model"]["target_volume"]))
        return [
            _raw("net_displacement", "net_displacement";
                absolute = 0.20diameter, standardized = 0.25),
            _raw("mean_squared_displacement", "mean_squared_displacement";
                absolute = 0.20diameter^2, standardized = 0.25),
            _raw("speed", "speed"; relative = 0.10, standardized = 0.25),
            _raw("persistence", "persistence"; relative = 0.10, standardized = 0.25),
            base...,
            _log("velocity_autocorrelation", "velocity_integrated_autocorrelation_time",
                inv(1.15), 1.15),
            _log("velocity_ess_per_mcs", "velocity_effective_sample_size", 0.80, 1.25;
                divisor = "measured_mcs")]
    end
    throw(ArgumentError("unsupported realistic workload: $id"))
end

function _values(summaries, spec)
    values = Float64[]
    for summary in summaries
        haskey(summary, spec.field) || throw(ArgumentError(
            "replica summary is missing registered endpoint $(spec.field)"))
        value = Float64(summary[spec.field])
        spec.divisor === nothing || (value /= Float64(summary[spec.divisor]))
        isfinite(value) || throw(ArgumentError("endpoint $(spec.name) is not finite"))
        spec.scale === :log && value <= 0 && throw(ArgumentError(
            "log-scale endpoint $(spec.name) must be positive"))
        push!(values, spec.scale === :log ? log(value) : value)
    end
    return values
end

function _pooled_standard_deviation(reference, candidate)
    n1, n2 = length(reference), length(candidate)
    n1 >= 2 && n2 >= 2 || return 0.0
    return sqrt(((n1 - 1) * var(reference) + (n2 - 1) * var(candidate)) /
        (n1 + n2 - 2))
end

function _raw_margin(spec, reference, candidate)
    candidates = Float64[]
    spec.relative === nothing || push!(candidates,
        abs(mean(reference)) * Float64(spec.relative))
    spec.absolute === nothing || push!(candidates, Float64(spec.absolute))
    if spec.standardized !== nothing
        pooled = _pooled_standard_deviation(reference, candidate)
        if pooled > 0
            push!(candidates, Float64(spec.standardized) * pooled)
        elseif mean(reference) != mean(candidate)
            push!(candidates, 0.0)
        end
    end
    isempty(candidates) && throw(ArgumentError("endpoint $(spec.name) has no margin"))
    return minimum(candidates)
end

function _mean_statistics(reference, candidate, paired)
    if paired
        length(reference) == length(candidate) || throw(DimensionMismatch(
            "paired comparisons require equal replica counts"))
        differences = candidate .- reference
        estimate = mean(differences)
        standard_error = length(differences) < 2 ? 0.0 : std(differences) / sqrt(length(differences))
        return (; estimate, standard_error, degrees_of_freedom = length(differences) - 1)
    end
    n1, n2 = length(reference), length(candidate)
    n1 >= 2 && n2 >= 2 || throw(ArgumentError(
        "independent comparison requires at least two replicas per side"))
    v1, v2 = var(reference), var(candidate)
    terms = (v1 / n1, v2 / n2)
    standard_error = sqrt(sum(terms))
    denominator = terms[1]^2 / (n1 - 1) + terms[2]^2 / (n2 - 1)
    degrees = iszero(denominator) ? n1 + n2 - 2 : sum(terms)^2 / denominator
    return (; estimate = mean(candidate) - mean(reference), standard_error,
        degrees_of_freedom = degrees)
end

function _mean_tost(reference, candidate, lower, upper, paired)
    stats = _mean_statistics(reference, candidate, paired)
    if iszero(stats.standard_error)
        passed = lower <= stats.estimate <= upper
        return (; p_value = passed ? 0.0 : 1.0, stats...)
    end
    distribution = TDist(stats.degrees_of_freedom)
    lower_p = ccdf(distribution, (stats.estimate - lower) / stats.standard_error)
    upper_p = cdf(distribution, (stats.estimate - upper) / stats.standard_error)
    return (; p_value = max(lower_p, upper_p), stats...)
end

function _mean_interval(result, alpha)
    iszero(result.standard_error) && return (result.estimate, result.estimate)
    critical = quantile(TDist(result.degrees_of_freedom), 1 - alpha)
    return (result.estimate - critical * result.standard_error,
        result.estimate + critical * result.standard_error)
end

function _order_interval(values, probability, alpha)
    sorted = sort(values)
    n = length(sorted)
    distribution = Binomial(n, probability)
    lower = clamp(Int(quantile(distribution, alpha)) + 1, 1, n)
    upper = clamp(Int(quantile(distribution, 1 - alpha)) + 1, 1, n)
    return (sorted[lower], sorted[upper])
end

function _quantile_difference_interval(reference, candidate, probability, alpha)
    left = _order_interval(reference, probability, alpha / 2)
    right = _order_interval(candidate, probability, alpha / 2)
    return (right[1] - left[2], right[2] - left[1])
end

function _quantile_equivalence_p(reference, candidate, probability, lower, upper)
    inside(alpha) = begin
        interval = _quantile_difference_interval(reference, candidate, probability, alpha)
        lower <= interval[1] && interval[2] <= upper
    end
    inside(0.499999) || return 1.0
    low, high = 1.0e-12, 0.499999
    for _ in 1:60
        middle = (low + high) / 2
        inside(middle) ? (high = middle) : (low = middle)
    end
    return high
end

function analyze_realistic_equivalence(reference::AbstractDict, candidate::AbstractDict;
        comparison::Symbol, manifest::AbstractDict, alpha::Real = 0.01)
    comparison in (:paired_algorithm, :independent_backend) || throw(ArgumentError(
        "comparison must be :paired_algorithm or :independent_backend"))
    validate_realistic_evidence(reference).valid || throw(ArgumentError(
        "reference evidence is invalid"))
    validate_realistic_evidence(candidate).valid || throw(ArgumentError(
        "candidate evidence is invalid"))
    _require_comparable_pair(reference, candidate, comparison, manifest)
    left_identity, right_identity = reference["identity"], candidate["identity"]
    reference_summaries = reference["replica_primary_summaries"]
    candidate_summaries = candidate["replica_primary_summaries"]
    paired = comparison === :paired_algorithm
    if paired
        getindex.(reference_summaries, "seed_hex") ==
            getindex.(candidate_summaries, "seed_hex") || throw(ArgumentError(
                "paired algorithm comparison requires identical semantic seeds"))
        getindex.(reference_summaries, "layout_seed_hex") ==
            getindex.(candidate_summaries, "layout_seed_hex") || throw(ArgumentError(
                "paired algorithm comparison requires identical layout identities"))
    end
    workload = reference["workload"]
    endpoints = Dict{String, Any}[]
    for spec in realistic_endpoint_specs(workload, manifest)
        left = _values(reference_summaries, spec)
        right = _values(candidate_summaries, spec)
        lower, upper = if spec.scale === :log
            (spec.lower, spec.upper)
        else
            margin = _raw_margin(spec, left, right)
            (-margin, margin)
        end
        if spec.quantile === nothing
            result = _mean_tost(left, right, lower, upper, paired)
            push!(endpoints, Dict{String, Any}(
                "endpoint" => spec.name, "kind" => "studentized-mean",
                "estimate" => result.estimate, "standard_error" => result.standard_error,
                "degrees_of_freedom" => result.degrees_of_freedom,
                "margin_lower" => lower, "margin_upper" => upper,
                "raw_equivalence_p" => result.p_value))
        else
            p = _quantile_equivalence_p(left, right, spec.quantile, lower, upper)
            push!(endpoints, Dict{String, Any}(
                "endpoint" => spec.name, "kind" => "exact-binomial-order-statistic",
                "probability" => spec.quantile,
                "estimate" => quantile(right, spec.quantile) - quantile(left, spec.quantile),
                "margin_lower" => lower, "margin_upper" => upper,
                "raw_equivalence_p" => p))
        end
    end
    order = sortperm(endpoints; by = endpoint -> endpoint["raw_equivalence_p"])
    running_adjusted = 0.0
    prior_passed = true
    total = length(endpoints)
    for (rank, index) in enumerate(order)
        endpoint = endpoints[index]
        multiplier = total - rank + 1
        running_adjusted = max(running_adjusted,
            min(1.0, multiplier * endpoint["raw_equivalence_p"]))
        endpoint["holm_rank"] = rank
        endpoint["holm_adjusted_p"] = running_adjusted
        endpoint["holm_local_alpha"] = Float64(alpha) / multiplier
        endpoint["passed"] = prior_passed &&
            endpoint["raw_equivalence_p"] <= endpoint["holm_local_alpha"]
        prior_passed &= endpoint["passed"]
        if endpoint["kind"] == "studentized-mean"
            left = _values(reference_summaries,
                only(filter(spec -> spec.name == endpoint["endpoint"],
                    realistic_endpoint_specs(workload, manifest))))
            right = _values(candidate_summaries,
                only(filter(spec -> spec.name == endpoint["endpoint"],
                    realistic_endpoint_specs(workload, manifest))))
            result = _mean_tost(left, right, endpoint["margin_lower"],
                endpoint["margin_upper"], paired)
            endpoint["adjusted_interval"] = collect(_mean_interval(result,
                endpoint["holm_local_alpha"]))
        else
            spec = only(filter(spec -> spec.name == endpoint["endpoint"],
                realistic_endpoint_specs(workload, manifest)))
            left = _values(reference_summaries, spec)
            right = _values(candidate_summaries, spec)
            endpoint["adjusted_interval"] = collect(_quantile_difference_interval(
                left, right, spec.quantile, endpoint["holm_local_alpha"]))
        end
    end
    passed = all(endpoint -> endpoint["passed"], endpoints)
    qualification_eligible = reference["sampling"]["profile"] == "qualification" &&
        candidate["sampling"]["profile"] == "qualification"
    return Dict{String, Any}(
        "schema" => Dict("name" => "potts-realistic-equivalence-analysis",
            "version" => REALISTIC_ANALYSIS_SCHEMA_VERSION),
        "identity" => Dict("comparison" => String(comparison),
            "workload_fingerprint" => left_identity["workload_fingerprint"],
            "reference_algorithm" => left_identity["algorithm"],
            "candidate_algorithm" => right_identity["algorithm"],
            "reference_backend" => left_identity["backend"],
            "candidate_backend" => right_identity["backend"]),
        "multiplicity" => Dict("method" => "Holm two-one-sided equivalence",
            "familywise_alpha" => Float64(alpha), "hypotheses" => total),
        "endpoints" => endpoints,
        "result" => Dict("status" => qualification_eligible ?
                (passed ? "equivalence-pass" : "equivalence-fail") :
                "diagnostic-analysis",
            "statistical_equivalence_passed" => passed,
            "qualification_eligible" => qualification_eligible,
            "qualification_passed" => qualification_eligible && passed))
end

function analyze_realistic_family(references::AbstractVector,
        candidates::AbstractVector; comparison::Symbol, manifest::AbstractDict,
        alpha::Real = 0.01)
    length(references) == length(candidates) > 0 || throw(ArgumentError(
        "family analysis requires equally many nonempty reference and candidate records"))
    _require_one_registered_family(references, candidates, manifest)
    pair_analyses = [analyze_realistic_equivalence(references[index], candidates[index];
        comparison, manifest, alpha) for index in eachindex(references)]
    endpoints = Dict{String, Any}[]
    endpoint_pairs = Int[]
    for (pair_index, analysis) in enumerate(pair_analyses)
        workload = references[pair_index]["workload"]["id"]
        for source in analysis["endpoints"]
            endpoint = deepcopy(source)
            endpoint["workload"] = workload
            push!(endpoints, endpoint)
            push!(endpoint_pairs, pair_index)
        end
    end
    order = sortperm(endpoints; by = endpoint -> endpoint["raw_equivalence_p"])
    running_adjusted = 0.0
    prior_passed = true
    total = length(endpoints)
    paired = comparison === :paired_algorithm
    for (rank, index) in enumerate(order)
        endpoint = endpoints[index]
        pair_index = endpoint_pairs[index]
        multiplier = total - rank + 1
        local_alpha = Float64(alpha) / multiplier
        running_adjusted = max(running_adjusted,
            min(1.0, multiplier * endpoint["raw_equivalence_p"]))
        endpoint["holm_rank"] = rank
        endpoint["holm_adjusted_p"] = running_adjusted
        endpoint["holm_local_alpha"] = local_alpha
        endpoint["passed"] = prior_passed && endpoint["raw_equivalence_p"] <= local_alpha
        prior_passed &= endpoint["passed"]
        if endpoint["kind"] == "studentized-mean"
            result = (; estimate = endpoint["estimate"],
                standard_error = endpoint["standard_error"],
                degrees_of_freedom = endpoint["degrees_of_freedom"])
            endpoint["adjusted_interval"] = collect(_mean_interval(result, local_alpha))
        else
            workload = references[pair_index]["workload"]
            spec = only(filter(spec -> spec.name == endpoint["endpoint"],
                realistic_endpoint_specs(workload, manifest)))
            left = _values(references[pair_index]["replica_primary_summaries"], spec)
            right = _values(candidates[pair_index]["replica_primary_summaries"], spec)
            endpoint["adjusted_interval"] = collect(_quantile_difference_interval(
                left, right, spec.quantile, local_alpha))
        end
    end
    passed = all(endpoint -> endpoint["passed"], endpoints)
    eligible = all(index ->
        references[index]["sampling"]["profile"] == "qualification" &&
        candidates[index]["sampling"]["profile"] == "qualification",
        eachindex(references))
    return Dict{String, Any}(
        "schema" => Dict("name" => "potts-realistic-equivalence-family-analysis",
            "version" => REALISTIC_ANALYSIS_SCHEMA_VERSION),
        "identity" => Dict("comparison" => String(comparison),
            "workloads" => getindex.(getindex.(references, "workload"), "id"),
            "reference_algorithms" => unique(getindex.(getindex.(references, "identity"),
                "algorithm")),
            "candidate_algorithms" => unique(getindex.(getindex.(candidates, "identity"),
                "algorithm")),
            "reference_backends" => unique(getindex.(getindex.(references, "identity"),
                "backend")),
            "candidate_backends" => unique(getindex.(getindex.(candidates, "identity"),
                "backend"))),
        "multiplicity" => Dict("method" => "Holm two-one-sided equivalence",
            "scope" => "all applicable primary endpoints in the claim family",
            "familywise_alpha" => Float64(alpha), "hypotheses" => total),
        "endpoints" => endpoints,
        "result" => Dict("status" => eligible ?
                (passed ? "equivalence-pass" : "equivalence-fail") :
                "diagnostic-analysis",
            "statistical_equivalence_passed" => passed,
            "qualification_eligible" => eligible,
            "qualification_passed" => eligible && passed))
end

function write_realistic_analysis(path::AbstractString, analysis::AbstractDict;
        force::Bool = false)
    isfile(path) && !force && throw(ArgumentError(
        "analysis already exists; pass force=true to replace it"))
    mkpath(dirname(path))
    open(path, "w") do io
        TOML.print(io, analysis; sorted = true)
    end
    return path
end

end
