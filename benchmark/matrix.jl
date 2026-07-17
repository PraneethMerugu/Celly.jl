VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

function option(name, default)
    prefix = "--$name="
    argument = findfirst(arg -> startswith(arg, prefix), ARGS)
    return isnothing(argument) ? default : ARGS[argument][(length(prefix) + 1):end]
end

backend = option("backend", "cpu")
profile = option("profile", "smoke")
profile in ("smoke", "full") || error("Expected --profile=smoke or --profile=full")

backend == "metal" && (@eval using Metal)
backend == "cuda" && (@eval using CUDA)
backend == "amdgpu" && (@eval using AMDGPU)

include(joinpath(@__DIR__, "src", "PottsBenchmarks.jl"))
using .PottsBenchmarks

workloads = profile == "smoke" ? ("volume_2d_small",) :
            ("volume_2d_small", "adhesion_2d_medium", "volume_3d_small",
    "adhesion_2d_publication")
algorithms = backend == "cpu" ? ("sequential", "lottery", "checkerboard") :
             ("lottery", "checkerboard")
samples, seconds, warmup = profile == "smoke" ? (2, 5.0, 1) : (10, 30.0, 2)

for workload in workloads, algorithm in algorithms

    @info "Benchmarking" backend workload algorithm profile
    result = PottsBenchmarks.benchmark_case(
        workload, algorithm, backend; samples, seconds, warmup_steps = warmup)
    for stage in ("initial_invariants", "final_invariants")
        invariants = result[stage]
        failures = sort!([name for (name, value) in invariants if value === false])
        isempty(failures) || error("$stage failed for $workload/$algorithm: $failures")
    end
    path = PottsBenchmarks.write_result(result)
    println("BASELINE_RESULT=", path)
end
