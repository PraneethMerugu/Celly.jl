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

rng_qualification = PottsBenchmarks.qualify_rng_backend(backend)
println("RNG_QUALIFICATION=", rng_qualification)
execution_qualification = PottsBenchmarks.qualify_execution_backend(backend)
println("EXECUTION_QUALIFICATION=", execution_qualification)
scientific_qualification = PottsBenchmarks.qualify_scientific_backend(backend)
println("SCIENTIFIC_QUALIFICATION=", scientific_qualification)
sequential_qualification = PottsBenchmarks.qualify_sequential_backend(backend)
println("SEQUENTIAL_QUALIFICATION=", sequential_qualification)
checkerboard_qualification = PottsBenchmarks.qualify_checkerboard_backend(backend)
println("CHECKERBOARD_QUALIFICATION=", checkerboard_qualification)
lottery_qualification = PottsBenchmarks.qualify_lottery_backend(backend)
println("LOTTERY_QUALIFICATION=", lottery_qualification)
mechanics_qualification = PottsBenchmarks.qualify_mechanics_backend(backend)
println("MECHANICS_QUALIFICATION=", mechanics_qualification)
lifecycle_qualification = PottsBenchmarks.qualify_lifecycle_backend(backend)
println("LIFECYCLE_QUALIFICATION=", lifecycle_qualification)
persistence_qualification = PottsBenchmarks.qualify_persistence_backend(backend)
println("PERSISTENCE_QUALIFICATION=", persistence_qualification)
phase8_performance = PottsBenchmarks.measure_phase8_backend(backend)
println("PHASE8_PERFORMANCE=", phase8_performance)

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
