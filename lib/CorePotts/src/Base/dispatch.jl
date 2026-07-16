using KernelAbstractions

export dispatch_kernel!

"""
    requires_explicit_dependencies(backend::KernelAbstractions.Backend)

Returns `true` if the backend requires explicit event dependencies (e.g., CUDA, CPU).
Returns `false` if the backend naturally serializes command queues (e.g., Metal).
"""
requires_explicit_dependencies(::KernelAbstractions.Backend) = true

@inline _filter_nothing(::Tuple{}) = ()
@inline _filter_nothing(t::Tuple) = t[1] === nothing ? _filter_nothing(Base.tail(t)) : (t[1], _filter_nothing(Base.tail(t))...)

"""
    dispatch_kernel!(backend, kernel, args...; ndrange, dependencies=(), workgroupsize=nothing)

A robust wrapper for dispatching `KernelAbstractions` kernels across heterogeneous backends.
Strips the `dependencies` keyword argument when running on backends that serialize naturally 
(like `MetalBackend`), avoiding explicit dependencies unsupported by those backends.
Preserves dependencies for `CUDA` or `CPU` backends to ensure Zero-Sync safety.
"""
@inline function dispatch_kernel!(
        backend::KernelAbstractions.Backend, kernel, args...; 
        ndrange, dependencies = (), workgroupsize = nothing)
    
    # Handle dependencies=nothing by making it an empty tuple
    actual_deps = dependencies === nothing ? () : dependencies

    # Strip nothing from dependencies tuple if any slipped through
    clean_deps = _filter_nothing(actual_deps)

    if !requires_explicit_dependencies(backend)
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
