using Test
using SciMLBase
using CorePotts
using PottsToolkit
using PottsToolkit.Events
using Adapt

@testset "GPU Closure Compatibility (isbits)" begin
    medium = CellType(:Medium, is_background = true)
    cell = CellType(:Cell)

    sys = PottsSystem(
        cell_types = [medium, cell],
        penalties = [
            VolumeComponent(cell => (λ = 2.0f0, target = 250)),
            AdhesionComponent((cell, cell) => 2.0f0, (cell, medium) => 15.0f0)
        ],
        events = [
            ApoptosisEvent(cell, trigger = VolumeRatioTrigger(0.2f0)),
            MitosisEvent(cell, trigger = CustomTrigger((i, cd) -> false))
        ]
    )

    # Check that required_variables extract properly from the whole pipeline
    type_to_id = Dict(medium => UInt8(0), cell => UInt8(1))
    comp_pens, req_trackers, init_props,
    custom_vars = PottsToolkit.Problem.compile_penalties(sys, type_to_id, 2)
    cb_set, event_reqs = PottsToolkit.Events.compile_events(sys.events, sys, type_to_id, 10)

    # The MitosisTriggerWrapper must be Adapt-compatible to become an isbits type
    # We can mock a ResolvedMitosisEvent
    res_mit = PottsToolkit.Events.ResolvedMitosisEvent(
        10,
        UInt8(1),
        VolumeRatioTrigger(0.5f0),
        CorePotts.RandomOrientation(),
        (target_volumes = CorePotts.Split(0.5f0),),
        nothing
    )

    trigger_wrapper = PottsToolkit.Events.MitosisTriggerWrapper(
        (res_mit,),
        UInt8[0, 1, 1] # mock cell_types array
    )

    # Convert Array to an array-like backend for the test? No, Adapt with a generic backend mock
    struct MockGPUBackend end
    Adapt.adapt_storage(::MockGPUBackend, x::Array) = (1,) # just mock arrays as tuples

    gpu_wrapper = Adapt.adapt(MockGPUBackend(), trigger_wrapper)

    @test isbits(gpu_wrapper)
    @test isbits(gpu_wrapper.events)
end
