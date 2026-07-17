VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

function requested_backend(arguments)
    prefix = "--backend="
    argument = findfirst(arg -> startswith(arg, prefix), arguments)
    return isnothing(argument) ? "cpu" : arguments[argument][(length(prefix) + 1):end]
end

# Load the selected GPU runtime before CorePotts. Besides avoiding world-age artifacts in the
# harness, this makes extension load/precompile failures part of the measured backend qualification.
backend = requested_backend(ARGS)
backend == "metal" && (@eval using Metal)
backend == "cuda" && (@eval using CUDA)
backend == "amdgpu" && (@eval using AMDGPU)

include(joinpath(@__DIR__, "src", "PottsBenchmarks.jl"))

exit(PottsBenchmarks.main(ARGS))
