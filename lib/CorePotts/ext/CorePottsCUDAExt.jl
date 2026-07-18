module CorePottsCUDAExt

using CorePotts
using CUDA
using KernelAbstractions

CorePotts.backend_capabilities(::CUDA.CUDABackend) = CorePotts.BackendCapabilities(
    CorePotts.CUDAFamily, CorePotts.DeferredBackend,
    CUDA.functional(), true, true, true, ())

end
