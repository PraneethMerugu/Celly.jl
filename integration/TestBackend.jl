module TestBackend

using KernelAbstractions
using Test

const BACKEND_GROUP = get(ENV, "BACKEND_GROUP", "CPU")

function load_backend()
    if BACKEND_GROUP == "CUDA"
        @eval begin
            using CUDA
            return CUDA.CUDABackend()
        end
    elseif BACKEND_GROUP == "Metal"
        @eval begin
            using Metal
            return Metal.MetalBackend()
        end
    elseif BACKEND_GROUP == "AMDGPU"
        @eval begin
            using AMDGPU
            return AMDGPU.ROCBackend()
        end
    else
        # Default: CPU — no extra imports needed
        return KernelAbstractions.CPU()
    end
end

# Called once at test startup
const BACKEND = load_backend()

"""
    backend_array(T, dims...)

Create an array of type `T` and shape `dims` on the current test backend.
On CPU this is `Array`, on CUDA it's `CuArray`, on Metal it's `MtlArray`, etc.
Uses `KernelAbstractions.allocate` which is backend-agnostic.
"""
function backend_array(T, dims::Tuple)
    return KernelAbstractions.allocate(BACKEND, T, dims)
end
function backend_array(T, dims::Integer...)
    return KernelAbstractions.allocate(BACKEND, T, dims)
end

"""
    backend_zeros(T, dims...)

Create a zero-filled array on the test backend.
"""
function backend_zeros(T, dims::Tuple)
    arr = backend_array(T, dims)
    fill!(arr, zero(T))
    return arr
end
function backend_zeros(T, dims::Integer...)
    arr = backend_array(T, dims)
    fill!(arr, zero(T))
    return arr
end

macro skip_if_no_gpu(ex)
    if BACKEND_GROUP == "CPU"
        return quote
            @test_skip $(string(ex))
        end
    else
        return esc(ex)
    end
end

export BACKEND, BACKEND_GROUP, backend_array, backend_zeros, @skip_if_no_gpu

end # module
