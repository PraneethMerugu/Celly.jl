using Printf
using TOML

VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

const RESULTS_ROOT = joinpath(@__DIR__, "results")
const WORKLOAD_ORDER = Dict(
    "volume_2d_small" => 1,
    "adhesion_2d_medium" => 2,
    "volume_3d_small" => 3,
    "adhesion_2d_publication" => 4
)
const ALGORITHM_ORDER = Dict("sequential" => 1, "lottery" => 2, "checkerboard" => 3,
    "intrinsic" => 4)

function latest_results()
    results = Dict{Tuple{String, String, String}, Tuple{String, Dict{String, Any}}}()
    isdir(RESULTS_ROOT) || return results
    for (directory, _, names) in walkdir(RESULTS_ROOT)
        for name in names
            endswith(name, ".toml") || continue
            path = joinpath(directory, name)
            result = TOML.parsefile(path)
            get(result["provenance"], "julia_version", "") == string(VERSION) || continue
            key = (result["provenance"]["backend"], result["workload"]["name"],
                result["algorithm"]["name"])
            recorded = result["recorded_at_utc"]
            if !haskey(results, key) || recorded > results[key][1]
                results[key] = (recorded, result)
            end
        end
    end
    return results
end

function main()
    results = latest_results()
    ordered_keys = sort!(collect(keys(results));
        by = key -> (key[1], WORKLOAD_ORDER[key[2]], ALGORITHM_ORDER[key[3]]))

    println("| Backend | Workload | Algorithm | Median MCS/s | First MCS (s) | Host bytes | Host allocs |")
    println("|---|---|---|---:|---:|---:|---:|")
    for key in ordered_keys
        result = results[key][2]
        metrics = result["metrics"]
        @printf("| %s | %s | %s | %.3f | %.6f | %d | %d |\n",
            key[1], key[2], key[3], metrics["median_mcs_per_second"],
            metrics["first_mcs_seconds"], metrics["benchmark_host_memory_bytes"],
            metrics["benchmark_host_allocations"])
    end
end

main()
