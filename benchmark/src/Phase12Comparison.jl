module Phase12Comparison

using Statistics
using TOML

export PHASE12_SCHEMA_VERSION, PHASE12_CONTRACT_VERSION
export load_record, validate_record, compatibility_issues
export aggregate_records, compare_record_groups, print_comparison

const PHASE12_SCHEMA_VERSION = "3.0.0"
const PHASE12_CONTRACT_VERSION = "1.0.0"

const COMPARISON_IDENTITY_KEYS = (
    "contract_version",
    "workload_set_version",
    "harness_tree_sha256",
    "backend",
    "hardware_id",
    "julia_version",
    "architecture",
    "os",
    "julia_threads",
    "precision",
    "profile",
    "tuning_policy",
)

const WORKLOAD_IDENTITY_KEYS = (
    "family",
    "algorithm",
    "semantic_fingerprint",
    "dimension_count",
    "dimensions",
    "sites",
    "timed_mcs",
    "declared_lifecycle_observation_per_mcs",
)

const REQUIRED_WORKLOAD_KEYS = (
    "steady_median_seconds_per_mcs",
    "first_mcs_seconds",
    "steady_median_host_allocated_bytes_per_mcs",
    "warm_execution_metrics",
    "residency",
)

const ZERO_WARM_METRICS = (
    "host_allocations",
    "device_allocations",
    "host_to_device_transfers",
)

function load_record(path::AbstractString)
    record = TOML.parsefile(path)
    issues = validate_record(record)
    isempty(issues) || throw(ArgumentError(
        "invalid Phase 12 record $(abspath(path)):\n- " * join(issues, "\n- ")))
    return record
end

function _table(record, key, issues, context)
    value = get(record, key, nothing)
    value isa AbstractDict || push!(issues, "$context requires table `$key`")
    return value isa AbstractDict ? value : Dict{String, Any}()
end

function _finite_nonnegative(value)
    return value isa Real && isfinite(value) && value >= 0
end

function validate_record(record::AbstractDict)
    issues = String[]
    get(record, "schema_version", nothing) == PHASE12_SCHEMA_VERSION || push!(issues,
        "schema_version must be $PHASE12_SCHEMA_VERSION")
    get(record, "record_kind", nothing) == "phase12-performance-run" || push!(issues,
        "record_kind must be phase12-performance-run")
    identity = _table(record, "comparison_identity", issues, "record")
    for key in COMPARISON_IDENTITY_KEYS
        haskey(identity, key) || push!(issues, "comparison_identity is missing `$key`")
    end
    get(identity, "contract_version", nothing) == PHASE12_CONTRACT_VERSION || push!(issues,
        "contract_version must be $PHASE12_CONTRACT_VERSION")
    run = _table(record, "run", issues, "record")
    haskey(run, "process_id") || push!(issues, "run is missing `process_id`")
    provenance = _table(record, "provenance", issues, "record")
    for key in ("implementation_commit", "implementation_tree_sha256", "harness_commit",
            "git_dirty")
        haskey(provenance, key) || push!(issues, "provenance is missing `$key`")
    end
    get(provenance, "git_dirty", true) === false || push!(issues,
        "authoritative Phase 12 records require a clean worktree")
    workloads = _table(record, "workloads", issues, "record")
    isempty(workloads) && push!(issues, "record contains no workloads")
    for (name, workload) in workloads
        workload isa AbstractDict || begin
            push!(issues, "workload `$name` must be a table")
            continue
        end
        for key in WORKLOAD_IDENTITY_KEYS
            haskey(workload, key) || push!(issues, "workload `$name` is missing `$key`")
        end
        for key in REQUIRED_WORKLOAD_KEYS
            haskey(workload, key) || push!(issues, "workload `$name` is missing `$key`")
        end
        for key in ("steady_median_seconds_per_mcs", "first_mcs_seconds",
                "steady_median_host_allocated_bytes_per_mcs")
            haskey(workload, key) && !_finite_nonnegative(workload[key]) && push!(issues,
                "workload `$name` metric `$key` must be finite and non-negative")
        end
        get(workload, "timed_mcs", 0) isa Integer && workload["timed_mcs"] > 0 ||
            push!(issues, "workload `$name` timed_mcs must be a positive integer")
        get(workload, "declared_lifecycle_observation_per_mcs", nothing) isa Bool ||
            push!(issues,
                "workload `$name` declared_lifecycle_observation_per_mcs must be Boolean")
        warm = get(workload, "warm_execution_metrics", Dict{String, Any}())
        warm isa AbstractDict || push!(issues,
            "workload `$name` warm_execution_metrics must be a table")
        residency = get(workload, "residency", Dict{String, Any}())
        residency isa AbstractDict || push!(issues,
            "workload `$name` residency must be a table")
        if residency isa AbstractDict
            bytes = get(residency, "backend_resident_bytes", nothing)
            _finite_nonnegative(bytes) || push!(issues,
                "workload `$name` residency requires non-negative backend_resident_bytes")
        end
    end
    return issues
end

function _identity_issues(left, right, keys, context)
    issues = String[]
    for key in keys
        left_value = get(left, key, nothing)
        right_value = get(right, key, nothing)
        isequal(left_value, right_value) || push!(issues,
            "$context differs at `$key`: $(repr(left_value)) != $(repr(right_value))")
    end
    return issues
end

function compatibility_issues(baseline::AbstractDict, candidate::AbstractDict)
    issues = vcat(validate_record(baseline), validate_record(candidate))
    isempty(issues) || return unique!(issues)
    append!(issues, _identity_issues(
        baseline["comparison_identity"], candidate["comparison_identity"],
        COMPARISON_IDENTITY_KEYS, "comparison identity"))
    baseline_names = sort!(collect(keys(baseline["workloads"])))
    candidate_names = sort!(collect(keys(candidate["workloads"])))
    baseline_names == candidate_names || push!(issues,
        "workload sets differ: $(repr(baseline_names)) != $(repr(candidate_names))")
    for name in intersect(baseline_names, candidate_names)
        append!(issues, _identity_issues(
            baseline["workloads"][name], candidate["workloads"][name],
            WORKLOAD_IDENTITY_KEYS, "workload `$name` identity"))
    end
    return issues
end

function _group_issues(records::AbstractVector, label::String)
    issues = String[]
    isempty(records) && return ["$label group is empty"]
    for (index, record) in pairs(records)
        append!(issues, ("$label record $index: $issue" for issue in validate_record(record)))
    end
    isempty(issues) || return issues
    first_record = first(records)
    process_ids = String[]
    for (index, record) in pairs(records)
        append!(issues, ("$label record $index: $issue" for issue in
            compatibility_issues(first_record, record)))
        push!(process_ids, string(record["run"]["process_id"]))
    end
    length(unique(process_ids)) == length(process_ids) || push!(issues,
        "$label group contains repeated process_id values")
    return unique!(issues)
end

_median_metric(records, workload, key) =
    median(Float64(record["workloads"][workload][key]) for record in records)

_median_residency(records, workload) = median(Float64(
    record["workloads"][workload]["residency"]["backend_resident_bytes"])
    for record in records)

function aggregate_records(records::AbstractVector; minimum_processes::Int = 3)
    minimum_processes > 0 || throw(ArgumentError("minimum_processes must be positive"))
    issues = _group_issues(records, "aggregate")
    isempty(issues) || throw(ArgumentError(join(issues, "\n")))
    length(records) >= minimum_processes || throw(ArgumentError(
        "aggregate requires at least $minimum_processes independent processes; got $(length(records))"))
    workloads = Dict{String, Any}()
    for name in sort!(collect(keys(first(records)["workloads"])))
        workloads[name] = Dict(
            "algorithm" => first(records)["workloads"][name]["algorithm"],
            "process_steady_seconds_per_mcs" => [Float64(
                record["workloads"][name]["steady_median_seconds_per_mcs"])
                for record in records],
            "median_steady_seconds_per_mcs" =>
                _median_metric(records, name, "steady_median_seconds_per_mcs"),
            "median_first_mcs_seconds" =>
                _median_metric(records, name, "first_mcs_seconds"),
            "median_host_allocated_bytes_per_mcs" =>
                _median_metric(records, name, "steady_median_host_allocated_bytes_per_mcs"),
            "median_backend_resident_bytes" => _median_residency(records, name),
        )
    end
    return Dict(
        "processes" => length(records),
        "comparison_identity" => deepcopy(first(records)["comparison_identity"]),
        "implementation_commit" => first(records)["provenance"]["implementation_commit"],
        "workloads" => workloads,
    )
end

function _ratio(candidate, baseline)
    baseline == 0 && return candidate == 0 ? 1.0 : Inf
    return candidate / baseline
end

function _candidate_residency_issues(records)
    issues = String[]
    for (record_index, record) in pairs(records), (name, workload) in record["workloads"]
        warm = workload["warm_execution_metrics"]
        for key in ZERO_WARM_METRICS
            value = get(warm, key, nothing)
            value == 0 || push!(issues,
                "candidate record $record_index workload `$name` requires zero `$key`; got $(repr(value))")
        end
        timed_mcs = workload["timed_mcs"]
        declared_lifecycle = workload["declared_lifecycle_observation_per_mcs"]
        backend = record["comparison_identity"]["backend"]
        expected_synchronizations = declared_lifecycle ? timed_mcs : 0
        expected_device_to_host = declared_lifecycle && backend != "cpu" ? timed_mcs : 0
        for (key, expected) in (
                "host_synchronizations" => expected_synchronizations,
                "device_to_host_transfers" => expected_device_to_host)
            value = get(warm, key, nothing)
            value == expected || push!(issues,
                "candidate record $record_index workload `$name` expected `$key`=$expected; got $(repr(value))")
        end
    end
    return issues
end

function compare_record_groups(baseline::AbstractVector, candidate::AbstractVector;
        minimum_processes::Int = 3, regression_threshold::Real = 0.05,
        memory_threshold::Real = 0.05)
    0 <= regression_threshold < 1 || throw(ArgumentError(
        "regression_threshold must lie in [0, 1)"))
    0 <= memory_threshold < 1 || throw(ArgumentError(
        "memory_threshold must lie in [0, 1)"))
    issues = vcat(_group_issues(baseline, "baseline"),
        _group_issues(candidate, "candidate"))
    if isempty(issues) && !isempty(baseline) && !isempty(candidate)
        append!(issues, compatibility_issues(first(baseline), first(candidate)))
    end
    length(baseline) >= minimum_processes || push!(issues,
        "baseline requires at least $minimum_processes independent processes")
    length(candidate) >= minimum_processes || push!(issues,
        "candidate requires at least $minimum_processes independent processes")
    isempty(issues) || return Dict(
        "comparable" => false, "passed" => false, "issues" => unique!(issues))

    baseline_aggregate = aggregate_records(baseline; minimum_processes)
    candidate_aggregate = aggregate_records(candidate; minimum_processes)
    residency_issues = _candidate_residency_issues(candidate)
    comparisons = Dict{String, Any}()
    steady_ratios = Dict{String, Vector{Float64}}()
    passed = isempty(residency_issues)
    for name in sort!(collect(keys(baseline_aggregate["workloads"])))
        before = baseline_aggregate["workloads"][name]
        after = candidate_aggregate["workloads"][name]
        steady_ratio = _ratio(after["median_steady_seconds_per_mcs"],
            before["median_steady_seconds_per_mcs"])
        first_ratio = _ratio(after["median_first_mcs_seconds"],
            before["median_first_mcs_seconds"])
        memory_ratio = _ratio(after["median_backend_resident_bytes"],
            before["median_backend_resident_bytes"])
        workload_passed = steady_ratio <= 1 + regression_threshold &&
                          first_ratio <= 1 + regression_threshold &&
                          memory_ratio <= 1 + memory_threshold
        passed &= workload_passed
        algorithm = before["algorithm"]
        push!(get!(steady_ratios, algorithm, Float64[]), steady_ratio)
        comparisons[name] = Dict(
            "passed" => workload_passed,
            "steady_seconds_ratio" => steady_ratio,
            "steady_throughput_ratio" => inv(steady_ratio),
            "first_mcs_seconds_ratio" => first_ratio,
            "backend_resident_bytes_ratio" => memory_ratio,
        )
    end
    algorithm_geometric_means = Dict(
        algorithm => exp(mean(log, ratios)) for (algorithm, ratios) in steady_ratios)
    geometric_mean_passed = all(<=(1), values(algorithm_geometric_means))
    passed &= geometric_mean_passed
    return Dict(
        "schema_version" => PHASE12_SCHEMA_VERSION,
        "contract_version" => PHASE12_CONTRACT_VERSION,
        "comparable" => true,
        "passed" => passed,
        "regression_threshold" => Float64(regression_threshold),
        "memory_threshold" => Float64(memory_threshold),
        "algorithm_geometric_mean_steady_seconds_ratios" => algorithm_geometric_means,
        "geometric_mean_passed" => geometric_mean_passed,
        "residency_issues" => residency_issues,
        "baseline" => baseline_aggregate,
        "candidate" => candidate_aggregate,
        "workloads" => comparisons,
    )
end

function print_comparison(io::IO, comparison::AbstractDict)
    if !get(comparison, "comparable", false)
        println(io, "Phase 12 comparison: INCOMPARABLE")
        for issue in get(comparison, "issues", String[])
            println(io, "- ", issue)
        end
        return comparison
    end
    println(io, "Phase 12 comparison: ", comparison["passed"] ? "PASS" : "FAIL")
    for algorithm in sort!(collect(keys(
            comparison["algorithm_geometric_mean_steady_seconds_ratios"])))
        println(io, algorithm, " geometric mean steady-time ratio: ", round(
            comparison["algorithm_geometric_mean_steady_seconds_ratios"][algorithm];
            digits = 6))
    end
    println(io, "| Workload | Steady time | Throughput | First MCS | Memory | Gate |")
    println(io, "|---|---:|---:|---:|---:|---:|")
    for name in sort!(collect(keys(comparison["workloads"])))
        result = comparison["workloads"][name]
        println(io, "| ", name, " | ",
            round(result["steady_seconds_ratio"]; digits = 6), " | ",
            round(result["steady_throughput_ratio"]; digits = 6), " | ",
            round(result["first_mcs_seconds_ratio"]; digits = 6), " | ",
            round(result["backend_resident_bytes_ratio"]; digits = 6), " | ",
            result["passed"] ? "pass" : "fail", " |")
    end
    for issue in comparison["residency_issues"]
        println(io, "- ", issue)
    end
    return comparison
end

print_comparison(comparison::AbstractDict) = print_comparison(stdout, comparison)

end
