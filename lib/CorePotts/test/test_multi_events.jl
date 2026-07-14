using Test
using CorePotts
using KernelAbstractions

@testset "AbstractMultiEvent Routing" begin
    # Dummy Sub-Events
    struct TestSubEventA <: CorePotts.AbstractEvent end
    struct TestSubEventB <: CorePotts.AbstractEvent end
    struct TestSubEventC <: CorePotts.AbstractEvent end
    
    # Track execution count
    global test_execution_counts = Dict(:A => 0, :B => 0, :C => 0)
    
    @kernel function dummy_kernel_A!(dummy_arg)
        i = @index(Global, Linear)
        # Dummy op
    end
    
    @kernel function dummy_kernel_B!(dummy_arg)
        i = @index(Global, Linear)
    end
    
    @kernel function dummy_kernel_C!(dummy_arg)
        i = @index(Global, Linear)
    end
    
    CorePotts.get_event_kernel(::TestSubEventA, backend, block_size) = dummy_kernel_A!(backend, block_size)
    CorePotts.get_event_kernel(::TestSubEventB, backend, block_size) = dummy_kernel_B!(backend, block_size)
    CorePotts.get_event_kernel(::TestSubEventC, backend, block_size) = dummy_kernel_C!(backend, block_size)
    
    # Custom get_event_args for each to verify mask routing
    CorePotts.get_event_args(::TestSubEventA, mask, u, p, cache, t) = begin global test_execution_counts[:A] += 1; (mask,) end
    CorePotts.get_event_args(::TestSubEventB, mask, u, p, cache, t) = begin global test_execution_counts[:B] += 1; (mask,) end
    CorePotts.get_event_args(::TestSubEventC, mask, u, p, cache, t) = begin global test_execution_counts[:C] += 1; (mask,) end
    
    # Custom get_event_ndrange to verify it gets called
    CorePotts.get_event_ndrange(::TestSubEventA, mask, u) = length(mask)
    CorePotts.get_event_ndrange(::TestSubEventB, mask, u) = length(u.grid)
    CorePotts.get_event_ndrange(::TestSubEventC, mask, u) = length(mask)
    
    # Multi Event
    struct TestMultiEvent <: CorePotts.AbstractMultiEvent end
    CorePotts.get_sub_events(::TestMultiEvent) = (TestSubEventA(), TestSubEventB(), TestSubEventC())
    
    # Mock structs
    struct MockGrid end
    Base.length(::MockGrid) = 100
    
    struct MockU
        grid::MockGrid
    end
    u = MockU(MockGrid())
    mask = zeros(Bool, 10)
    
    # Set KernelAbstractions backend mock 
    CorePotts.KernelAbstractions.get_backend(::MockGrid) = CPU()
    
    p = nothing
    cache = (block_size=256,)
    
    deps = ()
    deps_out = CorePotts.process_event!(TestMultiEvent(), mask, u, p, cache, 1, deps)
    
    @test test_execution_counts[:A] == 1
    @test test_execution_counts[:B] == 1
    @test test_execution_counts[:C] == 1
    
    # Output deps should be updated properly (in real usage it returns a tuple of events)
    @test typeof(deps_out) <: Tuple
end
