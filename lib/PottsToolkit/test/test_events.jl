using Test
using SciMLBase
using CorePotts
using StructArrays
using PottsToolkit
using PottsToolkit.Events
import PottsToolkit.Events: _evaluate_trigger, AbstractAction

@testset "PottsToolkit Events" begin
    medium = CellType(:Medium, is_background = true)
    cell = CellType(:Cell)

    @testset "Trigger Evaluation" begin
        struct DummyTrigger <: AbstractTrigger end
        PottsToolkit.System.required_variables(::DummyTrigger) = (volumes = Int32,)
        # Need to provide an _evaluate_trigger
        PottsToolkit.Events._evaluate_trigger(::DummyTrigger, cell_id, cell_data) = cell_data.volumes[cell_id] >
                                                                                    10

        # Test required fields extraction works
        reqs = PottsToolkit.System.required_variables(DummyTrigger())
        @test reqs == (volumes = Int32,)

        # CustomTrigger
        ct = CustomTrigger((i, cd) -> cd.volumes[i] == 5)
        cd_mock = (volumes = Int32[0, 5, 20],)
        @test _evaluate_trigger(ct, 2, cd_mock) == true
        @test _evaluate_trigger(ct, 3, cd_mock) == false
    end

    @testset "Event Priority (compile_events)" begin
        log = String[]

        struct MockAction <: AbstractAction
            name::String
        end
        (a::MockAction)(args...) = push!(log, a.name)

        death = ApoptosisEvent(cell, trigger = CustomTrigger((i, cd)->true))
        mitosis = MitosisEvent(cell, trigger = CustomTrigger((i, cd)->true), action = MockAction("Mitosis"))

        sys = PottsSystem(
            cell_types = [medium, cell],
            penalties = [],
            events = [mitosis, death] # Note: reversed order in array!
        )

        type_to_id = Dict(medium => UInt8(0), cell => UInt8(1))
        cb_set, reqs = PottsToolkit.Events.compile_events(sys.events, sys, type_to_id, 2)

        @test length(cb_set) == 2
        @test cb_set[1] isa PottsToolkit.Events.ResolvedMitosisEvent
        @test cb_set[2] isa PottsToolkit.Events.ResolvedApoptosisEvent
    end
end
