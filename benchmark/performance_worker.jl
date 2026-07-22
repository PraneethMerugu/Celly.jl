VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

function option(name, default)
    prefix = "--$name="
    argument = findfirst(value -> startswith(value, prefix), ARGS)
    return isnothing(argument) ? default : ARGS[argument][(length(prefix) + 1):end]
end

backend = option("backend", "cpu")
profile = option("profile", "smoke")
precision_name = option("precision", "Float32")
backend in ("cpu", "metal", "amdgpu") || error(
    "Phase 12 requires --backend=cpu, metal, or amdgpu")
profile in ("smoke", "full", "throughput") || error(
    "Expected --profile=smoke, full, or throughput")
precision_name in ("Float32", "Float64") || error(
    "Expected --precision=Float32 or Float64")
real_type = precision_name == "Float32" ? Float32 : Float64
backend != "cpu" && real_type !== Float32 && error(
    "GPU Float64 performance is optional and not qualified in Phase 12")

backend == "metal" && (@eval using Metal)
backend == "amdgpu" && (@eval using AMDGPU)

include(joinpath(@__DIR__, "src", "PottsBenchmarks.jl"))
using .PottsBenchmarks

reference_performance = PottsBenchmarks.measure_phase12_reference_backend(
    backend; profile, real_type)
_, device = PottsBenchmarks.load_backend(backend)
record = PottsBenchmarks.phase12_result(
    backend, profile, device;
    qualification = Dict(
        "status" => "qualified within every measured workload",
        "scope" => "scientific accounting, residency, and backend preflight"),
    direct_comparison = Dict(
        "status" => "not measured in the isolated Phase 12 warm worker"),
    reference_performance,
    checkpoint_performance = Dict(
        "status" => "not measured in the isolated Phase 12 warm worker"))
path = PottsBenchmarks.write_phase12_result(record)
println("PHASE12_RESULT=", path)
