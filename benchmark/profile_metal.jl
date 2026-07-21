VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

using Metal

include(joinpath(@__DIR__, "profile_common.jl"))
using .Phase12BackendProfile

backend_name = "metal"
probe = Metal.MtlArray(zeros(UInt8, 1))
backend = Phase12BackendProfile.KernelAbstractions.get_backend(probe)
directory, provenance = Phase12BackendProfile.profile_directory(
    backend_name, string(backend))
profiles = Dict{String, Any}()

for algorithm_name in Phase12BackendProfile.PROFILE_ALGORITHMS
    integrator = Phase12BackendProfile.prepare_integrator(
        backend_name, backend, algorithm_name)
    code_directory = joinpath(directory, algorithm_name, "device-code")
    # Compile and execute the ordinary KernelAbstractions path before reflection.
    # The umbrella `@device_code` dumper also asks GPUCompiler for unoptimized
    # LLVM, whose Metal address-space representation is not verifier-clean on
    # Julia 1.12.6 even though the optimized native kernels execute correctly.
    # Native-only AIR reflection captures every compilation job needed by the
    # resident step without requesting that irrelevant intermediate form.
    Phase12BackendProfile.synchronized_steps!(integrator, 1)
    mkpath(code_directory)
    native_path = joinpath(code_directory, "captured-kernels.asm")
    open(native_path, "w") do io
        Metal.@device_code_air io=io dump_module=true raw=true begin
            Phase12BackendProfile.synchronized_steps!(integrator, 1)
        end
    end
    profiled_seconds = Ref(0.0)
    profile_result = Metal.@profile trace=true begin
        profiled_seconds[] = Phase12BackendProfile.synchronized_steps!(integrator, 5)
    end
    profile_path = joinpath(directory, algorithm_name, "metal-profile.txt")
    mkpath(dirname(profile_path))
    open(profile_path, "w") do io
        show(io, MIME"text/plain"(), profile_result)
        println(io)
    end
    profiles[algorithm_name] = Dict(
        "code" => Phase12BackendProfile.code_summary(code_directory),
        "profile_text" => relpath(profile_path, directory),
        "profile_text_bytes" => filesize(profile_path),
        "profiled_mcs" => 5,
        "profiled_wall_seconds" => profiled_seconds[],
    )
end

path = Phase12BackendProfile.write_record(directory, backend_name, provenance,
    "Metal", string(Base.pkgversion(Metal)), profiles;
    trace_kind = "Metal integrated chronological device trace",
    trace_status = "captured")
println("PHASE12_BACKEND_PROFILE=", path)
