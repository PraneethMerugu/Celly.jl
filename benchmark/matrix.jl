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
phase9_qualification = PottsBenchmarks.qualify_phase9_backend(backend)
println("PHASE9_QUALIFICATION=", phase9_qualification)
phase10_qualification = PottsBenchmarks.qualify_phase10_backend(backend)
println("PHASE10_QUALIFICATION=", phase10_qualification)
phase11_qualification = PottsBenchmarks.qualify_phase11_backend(backend)
println("PHASE11_QUALIFICATION=", phase11_qualification)
phase10_performance = PottsBenchmarks.measure_phase10_backend(backend)
println("PHASE10_PERFORMANCE=", phase10_performance)
phase10_reference_performance = PottsBenchmarks.measure_phase10_reference_backend(
    backend; profile)
println("PHASE10_REFERENCE_PERFORMANCE=", Dict(
    "profile" => profile,
    "workloads" => sort!(collect(keys(phase10_reference_performance["workloads"]))),
    "required_families" => phase10_reference_performance["required_families"]))
phase12_reference_performance = PottsBenchmarks.measure_phase12_reference_backend(
    backend; profile, sequential_reference = phase10_reference_performance)
println("PHASE12_REFERENCE_PERFORMANCE=", Dict(
    "profile" => profile,
    "workload_count" => length(phase12_reference_performance["workloads"]),
    "required_algorithms" => phase12_reference_performance["required_algorithms"]))
_, phase10_device = PottsBenchmarks.load_backend(backend)
phase10_record = PottsBenchmarks.phase10_result(
    backend, profile, phase10_device;
    qualification = phase10_qualification,
    direct_comparison = phase10_performance,
    reference_performance = phase12_reference_performance,
    checkpoint_performance = phase8_performance)
phase10_path = PottsBenchmarks.write_phase10_result(phase10_record)
println("PHASE10_RESULT=", phase10_path)
phase12_record = PottsBenchmarks.phase12_result(
    backend, profile, phase10_device;
    qualification = phase10_qualification,
    direct_comparison = phase10_performance,
    reference_performance = phase10_reference_performance,
    checkpoint_performance = phase8_performance)
phase12_path = PottsBenchmarks.write_phase12_result(phase12_record)
println("PHASE12_RESULT=", phase12_path)
phase9_performance = PottsBenchmarks.measure_phase9_backend(backend)
println("PHASE9_PERFORMANCE=", phase9_performance)

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
