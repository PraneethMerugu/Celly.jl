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
        # process_event! should return `nothing` if not implemented for an event
        # (This prevents MethodErrors and graceful fallback)
        res = CorePotts.process_event!(dummy, nothing, nothing, nothing, nothing, 0.0, nothing)
        @test res === nothing
    end

    @testset "Dependency Isolation" begin
        dummy_toolkit = DummyToolkitEvent()
        # Test that the fallback works for PottsToolkit.Events.AbstractEvent too
        res = CorePotts.process_event!(dummy_toolkit, nothing, nothing, nothing, nothing, 0.0, nothing)
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

    @testset "Functional Mask-Driven Execution" begin
        # Test that an event correctly resolves, initializes masks, and triggers in step!
        A = CellType(:A, is_background=true)
        B = CellType(:B)
        
        # Trigger apoptosis if volume > 0
        trigger = CustomTrigger((i, cd) -> cd.volumes[i] > 0)
        apoptosis = ApoptosisEvent(B, trigger=trigger)
        
        sys = PottsSystem([A, B], [VolumeComponent(B => (target=10, λ=1.0))], events=(apoptosis,), check_interval=1)
        
        # Initialize a single cell
        prob = PottsProblem(sys, Dict(B => 1), (10, 10))
        
        # Before step, target volume is 10
        @test prob.u0.cell_data.target_volumes[1] == 10
        
        import SciMLBase
        alg = SequentialMetropolis(sweeps_per_step=1)
        integrator = SciMLBase.init(prob, alg)
        
        # Execute 1 step
        SciMLBase.step!(integrator)
        
        # The event should have triggered, setting the target volume to 0
        @test integrator.u.cell_data.target_volumes[1] == 0
    end
end
