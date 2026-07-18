module CorePottsMetalExt

using CorePotts
using Metal
using KernelAbstractions

CorePotts.backend_capabilities(::Metal.MetalBackend) = CorePotts.BackendCapabilities(
    CorePotts.MetalFamily, Metal.functional(), true, false, true, (v"1.0.0",))

end
