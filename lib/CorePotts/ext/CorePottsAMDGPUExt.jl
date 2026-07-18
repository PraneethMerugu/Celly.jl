module CorePottsAMDGPUExt

using CorePotts
using AMDGPU
using KernelAbstractions

CorePotts.backend_capabilities(::AMDGPU.ROCBackend) = CorePotts.BackendCapabilities(
    CorePotts.AMDGPUFamily, CorePotts.QualifiedBackend,
    AMDGPU.functional(), true, true, false, (v"1.0.0",))

end
