VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

using AMDGPU

include(joinpath(@__DIR__, "profile_common.jl"))
using .Phase12BackendProfile

backend_name = "amdgpu"
probe = AMDGPU.ROCArray(zeros(UInt8, 1))
backend = Phase12BackendProfile.KernelAbstractions.get_backend(probe)
directory, provenance = Phase12BackendProfile.profile_directory(
    backend_name, string(backend))
profiles = Dict{String, Any}()

for algorithm_name in Phase12BackendProfile.PROFILE_ALGORITHMS
    integrator = Phase12BackendProfile.prepare_integrator(
        backend_name, backend, algorithm_name)
    code_directory = joinpath(directory, algorithm_name, "device-code")
    AMDGPU.@device_code dir=code_directory begin
        Phase12BackendProfile.synchronized_steps!(integrator, 1)
    end
    Phase12BackendProfile.synchronized_steps!(integrator, 1)
    println("PHASE12_ROCPROF_BEGIN=", algorithm_name)
    profiled_seconds = Phase12BackendProfile.synchronized_steps!(integrator, 5)
    println("PHASE12_ROCPROF_END=", algorithm_name)
    profiles[algorithm_name] = Dict(
        "code" => Phase12BackendProfile.code_summary(code_directory),
        "profiled_mcs" => 5,
        "profiled_wall_seconds" => profiled_seconds,
    )
end

trace_status = get(ENV, "POTTS_ROCPROF_TRACE_STATUS", "external-capture-required")
path = Phase12BackendProfile.write_record(directory, backend_name, provenance,
    "AMDGPU", string(Base.pkgversion(AMDGPU)), profiles;
    trace_kind = "rocprofv3 HIP/HSA/kernel Perfetto trace",
    trace_status)
println("PHASE12_BACKEND_PROFILE=", path)
