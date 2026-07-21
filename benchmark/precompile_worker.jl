VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

function option(name, default)
    prefix = "--$name="
    argument = findfirst(value -> startswith(value, prefix), ARGS)
    return isnothing(argument) ? default : ARGS[argument][(length(prefix) + 1):end]
end

function directory_bytes(root)
    bytes = Int64(0)
    for (directory, _, names) in walkdir(root), name in names
        bytes += filesize(joinpath(directory, name))
    end
    return bytes
end

backend_name = option("backend", "cpu")
backend_name in ("cpu", "metal", "amdgpu") || error(
    "Phase 12 precompile measurement requires cpu, metal, or amdgpu")

repository_root = normpath(joinpath(@__DIR__, ".."))
base_project = joinpath(@__DIR__, "Project.toml")
backend_project = backend_name == "metal" ?
    joinpath(@__DIR__, "backends", "metal", "Project.toml") :
    joinpath(@__DIR__, "backends", "amdgpu", "Project.toml")
separator = Sys.iswindows() ? ';' : ':'

isolated_cache_bytes = Int64(0)
base_precompile_seconds = 0.0
backend_precompile_seconds = 0.0
mktempdir() do isolated_depot
    stacked_depot = join((isolated_depot, Base.DEPOT_PATH...), separator)
    common_environment = (
        "JULIA_DEPOT_PATH" => stacked_depot,
        "JULIA_PKG_OFFLINE" => "true",
        "JULIA_PKG_PRECOMPILE_AUTO" => "0",
    )
    base_command = `$(Base.julia_cmd()) --project=$base_project --startup-file=no -e 'using Pkg; Pkg.precompile(; strict=true)'`
    base_precompile_seconds = @elapsed run(addenv(base_command, common_environment...))
    if backend_name != "cpu"
        backend_command = `$(Base.julia_cmd()) --project=$backend_project --startup-file=no -e 'using Pkg; Pkg.precompile(; strict=true)'`
        backend_precompile_seconds = @elapsed run(addenv(
            backend_command, common_environment...))
    end
    isolated_cache_bytes = directory_bytes(isolated_depot)
end

# Provenance and serialization occur only after isolated precompilation has completed.
include(joinpath(@__DIR__, "src", "PottsBenchmarks.jl"))
using .PottsBenchmarks
using Dates
using TOML

provenance = PottsBenchmarks.provenance(backend_name, "isolated-precompile")
precompile_harness_checksum = PottsBenchmarks.file_set_checksum(
    [joinpath(@__DIR__, "precompile_worker.jl")])
process_id = get(ENV, "POTTS_BENCHMARK_PROCESS_ID",
    string(Dates.format(now(UTC), dateformat"yyyymmddTHHMMSS.sss"), "-", getpid()))
record = Dict(
    "schema_version" => PottsBenchmarks.Phase12Comparison.PHASE12_SCHEMA_VERSION,
    "record_kind" => "phase12-precompile-run",
    "recorded_at_utc" => string(now(UTC)),
    "comparison_identity" => Dict(
        "contract_version" => PottsBenchmarks.Phase12Comparison.PHASE12_CONTRACT_VERSION,
        "precompile_workload_version" => "isolated-environment-1.0.0",
        "precompile_harness_tree_sha256" => precompile_harness_checksum,
        "backend" => backend_name,
        "hardware_id" => provenance["hardware_id"],
        "julia_version" => string(VERSION),
        "architecture" => string(Sys.ARCH),
        "os" => string(Sys.KERNEL),
        "julia_threads" => Threads.nthreads(),
    ),
    "run" => Dict(
        "process_id" => process_id,
        "independence_unit" => "fresh isolated writable depot",
        "network_policy" => "offline",
    ),
    "provenance" => provenance,
    "metrics" => Dict(
        "base_environment_precompile_seconds" => base_precompile_seconds,
        "backend_environment_precompile_seconds" => backend_precompile_seconds,
        "total_precompile_seconds" =>
            base_precompile_seconds + backend_precompile_seconds,
        "isolated_depot_bytes" => isolated_cache_bytes,
    ),
)

issues = PottsBenchmarks.Phase12Comparison.validate_precompile_record(record)
isempty(issues) || error("refusing to write invalid Phase 12 precompile result:\n- " *
                         join(issues, "\n- "))
directory = joinpath(PottsBenchmarks.RESULTS_ROOT, provenance["subject_id"],
    "precompile", backend_name)
mkpath(directory)
timestamp = Dates.format(now(UTC), dateformat"yyyymmddTHHMMSS")
path = joinpath(directory, "$(timestamp)-phase12-precompile-$process_id.toml")
open(path, "w") do io
    TOML.print(io, record; sorted = true)
end
println("PHASE12_PRECOMPILE_RESULT=", path)
