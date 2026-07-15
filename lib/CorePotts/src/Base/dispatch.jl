using KernelAbstractions

export dispatch_kernel!

"""
    dispatch_kernel!(kernel, args...; ndrange, dependencies=(), workgroupsize=nothing)

A robust wrapper for dispatching `KernelAbstractions` kernels across heterogeneous backends.
Strips the `dependencies` keyword argument when running on `MetalBackend`, 
where command queues serialize naturally and explicit deps are currently unsupported by `Metal.jl`.
Preserves dependencies for `CUDA` or `CPU` backends to ensure Zero-Sync safety.
"""
@inline function dispatch_kernel!(
        kernel, args...; ndrange, dependencies = (), workgroupsize = nothing)
    # Extract backend type string without explicitly depending on Metal.jl
    is_metal = occursin("MetalBackend", string(typeof(kernel).parameters[1]))

    # Handle dependencies=nothing by making it an empty tuple
    actual_deps = dependencies === nothing ? () : dependencies

    # Strip nothing from dependencies tuple if any slipped through (Metal returns nothing for events)
    clean_deps = filter(x -> x !== nothing, actual_deps)

    if is_metal
        if workgroupsize === nothing
            return kernel(args...; ndrange = ndrange)
        else
            return kernel(args...; ndrange = ndrange, workgroupsize = workgroupsize)
        end
    else
        if isempty(clean_deps)
            if workgroupsize === nothing
                return kernel(args...; ndrange = ndrange)
            else
                return kernel(args...; ndrange = ndrange, workgroupsize = workgroupsize)
            end
        else
            if workgroupsize === nothing
                return kernel(args...; ndrange = ndrange, dependencies = clean_deps)
            else
                return kernel(args...; ndrange = ndrange, dependencies = clean_deps,
                    workgroupsize = workgroupsize)
            end
        end
    end
end
