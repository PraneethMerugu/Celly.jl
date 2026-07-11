using Test
using Potts.CorePotts
using Potts.PottsToolkit

# Dummy Event for testing fallback behavior
struct DummyEvent <: CorePotts.AbstractEvent end

# A PottsToolkit event for testing
struct DummyToolkitEvent <: PottsToolkit.Events.AbstractEvent end

@testset "Event System Architecture" begin

    @testset "Fallback Verification" begin
        dummy = DummyEvent()
        # evaluate_event! should return `nothing` if not implemented for an event
        # (This prevents MethodErrors and graceful fallback)
        res = CorePotts.evaluate_event!(dummy, nothing, nothing, nothing, 0.0, nothing)
        @test res === nothing
    end

    @testset "Dependency Isolation" begin
        dummy_toolkit = DummyToolkitEvent()
        # Test that the fallback works for PottsToolkit.Events.AbstractEvent too
        res = CorePotts.evaluate_event!(dummy_toolkit, nothing, nothing, nothing, 0.0, nothing)
        @test res === nothing
    end

    @testset "Event Dropping Prevention" begin
        # Verify that PottsProblem constructor properly preserves custom PottsToolkit events
        A = CellType(:A, is_background=true)
        B = CellType(:B)
        
        # Test 1: Native CorePotts Event
        sys1 = PottsSystem([A, B], [VolumeComponent(B => (target=10, λ=1.0))], events=(DummyEvent(),))
        prob1 = PottsProblem(sys1, Dict(B => 1), (10, 10))
        @test length(prob1.p.events) == 1
        @test typeof(prob1.p.events[1]) == DummyEvent

        # Test 2: PottsToolkit Event
        sys2 = PottsSystem([A, B], [VolumeComponent(B => (target=10, λ=1.0))], events=(DummyToolkitEvent(),))
        prob2 = PottsProblem(sys2, Dict(B => 1), (10, 10))
        @test length(prob2.p.events) == 1
        @test typeof(prob2.p.events[1]) == DummyToolkitEvent
    end
end
