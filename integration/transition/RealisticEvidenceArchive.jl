module RealisticEvidenceArchive

using SHA
using TOML
using CorePotts
using ..RealisticScaleRunner

export workload_fingerprint, build_realistic_evidence,
       validate_realistic_evidence, write_realistic_evidence

const REALISTIC_EVIDENCE_SCHEMA_VERSION = "1.0.0"

function _toml_digest(value)
    io = IOBuffer()
    TOML.print(io, value; sorted = true)
    return string("sha256:", bytes2hex(sha256(take!(io))))
end

workload_fingerprint(workload::AbstractDict, manifest::AbstractDict) = _toml_digest(
    Dict("workload" => workload, "model" => manifest["model"],
        "analysis" => manifest["analysis"], "margins" => manifest["margins"]))

function build_realistic_evidence(workload::AbstractDict, algorithm,
        summaries::AbstractVector; backend::AbstractString, profile::Symbol,
        manifest::AbstractDict = load_realistic_manifest(),
        source_revision::AbstractString, reproduction_command::AbstractString)
    profile in (:diagnostic, :qualification) || throw(ArgumentError(
        "profile must be :diagnostic or :qualification"))
    isempty(summaries) && throw(ArgumentError("realistic evidence requires replicas"))
    registered = Int(manifest["replicas_per_identity"])
    profile === :qualification && length(summaries) != registered && throw(ArgumentError(
        "qualification evidence requires exactly $registered replicas"))
    algorithm_name = String(algorithm)
    all(summary -> summary["workload"] == workload["id"] &&
            summary["algorithm"] == algorithm_name &&
            lowercase(summary["backend"]) == lowercase(backend), summaries) ||
        throw(ArgumentError("replica summaries do not share the declared identity"))
    versions = CorePotts.scientific_contract_versions()
    model_fingerprints = unique(getindex.(summaries, "model_fingerprint"))
    length(model_fingerprints) == 1 || throw(ArgumentError(
        "replicas do not share one compiled model fingerprint"))
    record = Dict{String, Any}(
        "schema" => Dict(
            "name" => "potts-realistic-scale-evidence",
            "version" => REALISTIC_EVIDENCE_SCHEMA_VERSION),
        "identity" => Dict(
            "study_version" => manifest["manifest_version"],
            "statistical_plan" => manifest["statistical_plan"],
            "workload" => workload["id"],
            "workload_fingerprint" => workload_fingerprint(workload, manifest),
            "model_fingerprint" => only(model_fingerprints),
            "algorithm" => algorithm_name,
            "algorithm_contract_version" => string(algorithm_name == "SequentialCPM" ?
                versions.sequential_algorithm : versions.checkerboard_scheduler),
            "scheduler" => algorithm_name == "SequentialCPM" ?
                "sequential_with_replacement" : "realized_graph_colored_sweep",
            "rng_contract_version" => string(versions.rng),
            "backend" => String(backend),
            "number_type" => manifest["number_type"],
            "source_revision" => String(source_revision)),
        "sampling" => Dict(
            "profile" => String(profile),
            "replicas" => length(summaries),
            "registered_replicas" => registered,
            "independent_replicas" => true,
            "paired_layout_identity" => true,
            "layout_seed_domain" => manifest["layout_seed_domain"],
            "simulation_seed_domain" => manifest["simulation_seed_domain"],
            "seed_base_hex" => manifest["seed_base_hex"],
            "first_seed_hex" => first(summaries)["seed_hex"],
            "last_seed_hex" => last(summaries)["seed_hex"]),
        "workload" => deepcopy(workload),
        "model" => deepcopy(manifest["model"]),
        "analysis" => deepcopy(manifest["analysis"]),
        "environment" => Dict(
            "julia_version" => string(VERSION),
            "operating_system" => string(Sys.KERNEL),
            "architecture" => string(Sys.ARCH),
            "threads" => Threads.nthreads()),
        "reproduction_command" => String(reproduction_command),
        "replica_primary_summaries" => collect(summaries),
        "result" => Dict(
            "status" => profile === :qualification ?
                "qualification-collected-analysis-required" : "diagnostic-collected",
            "qualification_passed" => false,
            "adjusted_confidence_results" => Any[]))
    return record
end

function _seed_value(text)
    value = String(text)
    startswith(value, "0x") || return nothing
    return tryparse(UInt64, value[3:end]; base = 16)
end

function validate_realistic_evidence(record::AbstractDict)
    errors = String[]
    get(get(record, "schema", Dict()), "name", "") ==
        "potts-realistic-scale-evidence" || push!(errors, "invalid schema name")
    get(get(record, "schema", Dict()), "version", "") ==
        REALISTIC_EVIDENCE_SCHEMA_VERSION || push!(errors, "invalid schema version")
    for table in ("identity", "sampling", "workload", "model", "analysis",
            "environment", "result")
        get(record, table, nothing) isa AbstractDict || push!(errors, "missing table '$table'")
    end
    identity = get(record, "identity", Dict())
    for field in ("study_version", "statistical_plan", "workload",
            "workload_fingerprint", "model_fingerprint", "algorithm",
            "algorithm_contract_version", "scheduler", "rng_contract_version",
            "backend", "number_type", "source_revision")
        isempty(string(get(identity, field, ""))) && push!(errors,
            "missing identity field '$field'")
    end
    summaries = get(record, "replica_primary_summaries", nothing)
    summaries isa AbstractVector || push!(errors, "missing replica primary summaries")
    sampling = get(record, "sampling", Dict())
    if summaries isa AbstractVector
        length(summaries) == get(sampling, "replicas", -1) || push!(errors,
            "replica summary count does not match sampling record")
        seeds = [_seed_value(get(summary, "seed_hex", "")) for summary in summaries]
        all(!isnothing, seeds) || push!(errors, "malformed replica seed")
        if all(!isnothing, seeds) && length(seeds) > 1
            all(seeds[index] == seeds[1] + index - 1 for index in eachindex(seeds)) ||
                push!(errors, "replica seeds are not the registered contiguous sequence")
        end
        required = ("model_fingerprint", "initial_state_fingerprint",
            "layout_seed_hex", "dynamics_seed_hex", "observation_count",
            "observation_synchronizations", "elapsed_measured_seconds")
        for (index, summary) in enumerate(summaries), field in required
            haskey(summary, field) || push!(errors,
                "replica $index is missing '$field'")
        end
        for (index, summary) in enumerate(summaries)
            if get(summary, "observation_count", -1) !=
                    get(summary, "observation_synchronizations", -2)
                push!(errors, "replica $index violated observation synchronization accounting")
            end
            get(summary, "layout_seed_hex", "") !=
                get(summary, "dynamics_seed_hex", "") || push!(errors,
                    "replica $index did not domain-separate layout and dynamics seeds")
        end
    end
    profile = get(sampling, "profile", "")
    if profile == "qualification"
        get(sampling, "replicas", 0) == get(sampling, "registered_replicas", -1) ||
            push!(errors, "qualification record is not complete")
        if summaries isa AbstractVector && !isempty(summaries)
            base = _seed_value(get(sampling, "seed_base_hex", ""))
            first_seed = _seed_value(get(first(summaries), "seed_hex", ""))
            if base === nothing || first_seed != base
                push!(errors, "qualification record does not start at the registered seed base")
            end
            last_seed = _seed_value(get(last(summaries), "seed_hex", ""))
            registered_count = get(sampling, "registered_replicas", 0)
            expected_last = base === nothing || registered_count < 1 ? nothing :
                base + UInt64(registered_count - 1)
            last_seed == expected_last || push!(errors,
                "qualification record does not end at the registered seed limit")
        end
    elseif profile != "diagnostic"
        push!(errors, "invalid sampling profile")
    end
    return (; valid = isempty(errors), errors)
end

function write_realistic_evidence(path::AbstractString, record::AbstractDict;
        force::Bool = false)
    report = validate_realistic_evidence(record)
    report.valid || throw(ArgumentError(
        "refusing to write invalid realistic evidence: $(join(report.errors, "; "))"))
    isfile(path) && !force && throw(ArgumentError(
        "realistic evidence already exists; pass force=true to replace it"))
    mkpath(dirname(path))
    open(path, "w") do io
        TOML.print(io, record; sorted = true)
    end
    return path
end

end
