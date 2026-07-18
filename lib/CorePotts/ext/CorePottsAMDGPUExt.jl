module CorePottsAMDGPUExt

using CorePotts
using AMDGPU
using KernelAbstractions

CorePotts.backend_capabilities(::AMDGPU.ROCBackend) = CorePotts.BackendCapabilities(
    CorePotts.AMDGPUFamily, AMDGPU.functional(), true, true, false, ())

end
