using KernelAbstractions

export dispatch_kernel!

"""
    dispatch_kernel!(backend, kernel, args...; ndrange, workgroupsize=nothing)

KernelAbstractions 0.9 launch spelling for historical consumers. Launches are asynchronous and
ordered on every supported backend. New compiled execution code uses instrumented `launch!` and
synchronizes only through `synchronize_observation!`.
"""
@inline function dispatch_kernel!(
        backend::KernelAbstractions.Backend, kernel, args...;
        ndrange, workgroupsize = nothing)

    if workgroupsize === nothing
        return kernel(args...; ndrange = ndrange)
    else
        return kernel(args...; ndrange = ndrange, workgroupsize = workgroupsize)
    end
end
