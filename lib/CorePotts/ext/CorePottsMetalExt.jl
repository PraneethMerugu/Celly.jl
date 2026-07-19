module CorePottsMetalExt

using CorePotts
using Metal
using KernelAbstractions

CorePotts.backend_capabilities(::Metal.MetalBackend) = CorePotts.BackendCapabilities(
    CorePotts.MetalFamily, CorePotts.QualifiedBackend,
    Metal.functional(), true, false, true, (v"1.0.0",))

CorePotts.execution_adaptor(::Metal.MetalBackend) = Metal.MtlArray

end
