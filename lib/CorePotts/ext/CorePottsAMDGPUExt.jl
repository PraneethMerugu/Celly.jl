module CorePottsAMDGPUExt

using CorePotts
using AMDGPU
using KernelAbstractions

CorePotts.requires_explicit_dependencies(::AMDGPU.ROCBackend) = false

end
