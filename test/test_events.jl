using Test
using Potts.CorePotts
using Potts.PottsToolkit

# Dummy Event for testing fallback behavior
struct DummyEvent <: CorePotts.AbstractEvent end
CorePotts.get_event_args(::DummyEvent, mask, u, p, cache, t) = nothing

# A PottsToolkit event for testing
struct DummyToolkitEvent <: PottsToolkitEvent end
CorePotts.get_event_args(::DummyToolkitEvent, mask, u, p, cache, t) = nothing

@testset "Event System Architecture" begin
    @testset "Fallback Verification" begin
        dummy = DummyEvent()
        # process_event! should return `nothing` if not implemented for an event
        # (This prevents MethodErrors and graceful fallback)
        res = CorePotts.process_event!(
            dummy, nothing, nothing, nothing, nothing, 0.0, nothing)
        @test res === nothing
    end

    @testset "Dependency Isolation" begin
        dummy_toolkit = DummyToolkitEvent()
        # Test that the fallback works for PottsToolkitEvent too
        res = CorePotts.process_event!(
            dummy_toolkit, nothing, nothing, nothing, nothing, 0.0, nothing)
        @test res === nothing
    end

    @testset "Event Dropping Prevention" begin
        # Verify that PottsProblem constructor properly preserves custom PottsToolkit events
        A = CellType(:A, is_background = true)
        B = CellType(:B)

        # Test 1: Native CorePotts Event
        sys1 = PottsSystem([A, B], [VolumeComponent(B => (target = 10, λ = 1.0))], events = (DummyEvent(),))
        prob1 = PottsProblem(sys1, Dict(B => 1), (10, 10))
        @test length(prob1.p.events) == 1
        @test typeof(prob1.p.events[1]) == DummyEvent

        # Test 2: PottsToolkit Event
        sys2 = PottsSystem([A, B], [VolumeComponent(B => (target = 10, λ = 1.0))],
            events = (DummyToolkitEvent(),))
        prob2 = PottsProblem(sys2, Dict(B => 1), (10, 10))
        @test length(prob2.p.events) == 1
        @test typeof(prob2.p.events[1]) == DummyToolkitEvent
    end

    @testset "Functional Mask-Driven Execution" begin
        # Test that an event correctly resolves, initializes masks, and triggers in step!
        A = CellType(:A, is_background = true)
        B = CellType(:B)

        # Trigger apoptosis if volume > 0
        trigger = CustomTrigger((i, cd) -> cd.volumes[i] > 0)
        apoptosis = ApoptosisEvent(B, trigger = trigger)

        sys = PottsSystem([A, B], [VolumeComponent(B => (target = 10, λ = 1.0))],
            events = (apoptosis,), check_interval = 1)

        # Initialize a single cell
        prob = PottsProblem(sys, Dict(B => 1), (10, 10))

        # Before step, target volume is 10
        @test prob.u0.cell_data.target_volumes[1] == 10

        import SciMLBase
        alg = SequentialMetropolis(sweeps_per_step = 1)
        integrator = SciMLBase.init(prob, alg)

        # Execute 1 step
        SciMLBase.step!(integrator)

        # The event should have triggered, setting the target volume to 0
        @test integrator.u.cell_data.target_volumes[1] == 0
    end

    @testset "Event Resolution and Fallback" begin
        # Setup mock environment
        A = CellType(:A)
        B = CellType(:B)
        C = CellType(:C)
        type_to_id = Dict(A => UInt8(1), B => UInt8(2), C => UInt8(3))

        # Create mock events
        trigger = VolumeRatioTrigger(1.5)
        apop = ApoptosisEvent(B, trigger=trigger)
        trans = TransitionEvent(A => C, trigger=trigger)
        mitosis = MitosisEvent(A, trigger=trigger)
        prop = PropertyUpdateEvent(B, (target_volumes = CorePotts.RuleBuilder((cd, i, ctx, val) -> val),))

        events_tuple = (apop, trans, mitosis, prop)

        # Test 3-argument version
        res_3 = PottsToolkit.Events.resolve_events(events_tuple, type_to_id, 10)
        @test length(res_3) == 4
        @test res_3[1] isa PottsToolkit.Events.ResolvedApoptosisEvent
        @test res_3[1].check_interval == 10
        @test res_3[1].type_id == 2

        @test res_3[2] isa PottsToolkit.Events.ResolvedTransitionEvent
        @test res_3[2].check_interval == 10
        @test res_3[2].from_id == 1
        @test res_3[2].to_id == 3

        @test res_3[3] isa PottsToolkit.Events.ResolvedMitosisEvent
        @test res_3[3].check_interval == 10
        @test res_3[3].type_id == 1

        @test res_3[4] isa PottsToolkit.Events.ResolvedPropertyUpdateEvent
        @test res_3[4].check_interval == 10
        @test res_3[4].type_id == 2

        # Test 2-argument fallback version
        # Prior to fix, this would throw MethodError or drop events
        res_2 = PottsToolkit.Events.resolve_events(events_tuple, type_to_id)
        @test length(res_2) == 4
        @test res_2[1].check_interval == 1
        @test res_2[2].check_interval == 1
        @test res_2[3].check_interval == 1
        @test res_2[4].check_interval == 1
    end

    @testset "Poisson Random Sampling" begin
        # lambda < 15 uses Knuth
        l1 = 5.0f0
        samples1 = [CorePotts.gpu_rand_poisson(UInt32(i), UInt32(1), UInt32(0), l1) for i in 1:10000]
        mean1 = sum(samples1) / length(samples1)
        var1 = sum((x - mean1)^2 for x in samples1) / (length(samples1) - 1)
        @test isapprox(mean1, l1; rtol=0.1)
        @test isapprox(var1, l1; rtol=0.1)

        # lambda >= 15 uses Gaussian approximation
        l2 = 25.0f0
        samples2 = [CorePotts.gpu_rand_poisson(UInt32(i), UInt32(1), UInt32(0), l2) for i in 1:10000]
        mean2 = sum(samples2) / length(samples2)
        var2 = sum((x - mean2)^2 for x in samples2) / (length(samples2) - 1)
        @test isapprox(mean2, l2; rtol=0.1)
        @test isapprox(var2, l2; rtol=0.1)
    end
end
