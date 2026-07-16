module CorePottsCUDAExt

using CorePotts
using CUDA
using KernelAbstractions

CorePotts.requires_explicit_dependencies(::CUDA.CUDABackend) = false

end
