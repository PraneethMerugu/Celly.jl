module TestDispatch
    struct MetalBackend end
    struct CPUBackend end
    struct Kernel{B} end

    @inline is_metal(::Type{T}) where {T} = nameof(T) === :MetalBackend

    function dispatch(k::Kernel{B}) where {B}
        if is_metal(B)
            return 1
        else
            return 2
        end
    end
end

using InteractiveUtils
@code_llvm TestDispatch.dispatch(TestDispatch.Kernel{TestDispatch.MetalBackend}())
@code_llvm TestDispatch.dispatch(TestDispatch.Kernel{TestDispatch.CPUBackend}())
