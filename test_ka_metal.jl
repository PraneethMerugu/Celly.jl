using KernelAbstractions
using Metal

@kernel function dummy_kernel!(A)
    i = @index(Global)
    A[i] = 1
end

backend = MetalBackend()
A = Metal.zeros(Int, 10)
k = dummy_kernel!(backend)
ev1 = k(A, ndrange = 10)
ev2 = k(A, ndrange = 10, dependencies = (ev1,))
KernelAbstractions.synchronize(backend)
println("Success!")
