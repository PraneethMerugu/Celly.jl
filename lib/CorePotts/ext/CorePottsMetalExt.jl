module CorePottsMetalExt

using CorePotts
using Metal
using KernelAbstractions

CorePotts.requires_explicit_dependencies(::Metal.MetalBackend) = false

end
