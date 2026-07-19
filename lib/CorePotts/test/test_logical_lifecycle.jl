using Test
using CorePotts

@testset "logical lifecycle transactions" begin
    provenance = ComponentIdentity(:logical_lifecycle_test, v"1.0.0", :test)
    schema = PropertySchema(
        PropertyDescriptor(:age, Int32, ConstantInitializer(Int32(0));
            division = CloneOnDivision(), transition = PreserveOnTransition(), requester = provenance),
        PropertyDescriptor(:resource, Int32, ConstantInitializer(Int32(0));
            division = SplitOnDivision(), transition = ResetOnTransition(), requester = provenance),
        PropertyDescriptor(:signal, Int32, ConstantInitializer(Int32(0));
            division = ResetChildOnDivision(), transition = PreserveOnTransition(),
            requester = provenance),
    )
    owners = reshape(OwnerRef[
        CellOwner(1), CellOwner(1), CellOwner(1), CellOwner(2), MediumOwner(1), MediumOwner(1),
    ], 2, 3)
    state = LogicalPottsState(owners, CellCapacity(4);
        cell_types = Dict(CellID(1) => CellTypeID(1), CellID(2) => CellTypeID(2)),
        medium_domains = MediumID[MediumID(1)], property_schema = schema)
    property_values(state, :age)[1] = 10
    property_values(state, :resource)[1] = 7
    property_values(state, :signal)[1] = 99

    divided = apply_division_batch(state, [DivisionRequest(1, [2])])
    after_division = logical_state(divided)
    @test divided.assignments == [CellID(1) => CellID(3)]
    @test active_cell_ids(after_division) == CellID[CellID(1), CellID(2), CellID(3)]
    @test owner_at(after_division, 2) == CellOwner(3)
    @test finite_volume(after_division, CellID(1)) == 2
    @test finite_volume(after_division, CellID(3)) == 1
    @test cell_type(after_division, CellID(3)) == CellTypeID(1)
    @test generation(after_division, CellID(3)) == CellGeneration(0)
    @test property_values(after_division, :age)[3] == 10
    @test property_values(after_division, :resource)[1] == 4
    @test property_values(after_division, :resource)[3] == 3
    @test property_values(after_division, :signal)[3] == 0
    @test assert_valid_state(after_division) === after_division
    @test owner_at(state, 2) == CellOwner(1) # copy-on-commit leaves the original untouched

    transitioned = transition_cell_type(after_division, CellID(1), CellTypeID(3))
    @test cell_type(transitioned, CellID(1)) == CellTypeID(3)
    @test property_values(transitioned, :age)[1] == 10
    @test property_values(transitioned, :resource)[1] == 0

    retirement = immediately_remove_cell(after_division, CellID(2), MediumID(1))
    retired_state = logical_state(retirement)
    @test retirement.retired == CellID[CellID(2)]
    @test !is_active(retired_state, CellID(2))
    @test property_values(retired_state, :age)[2] == 0
    @test isempty(reusable_cell_slots(retired_state))
    released = release_retired_slots(retirement)
    @test reusable_cell_slots(released) == CellSlot[CellSlot(2)]

    reused = logical_state(apply_division_batch(released, [DivisionRequest(1, [1])]))
    @test is_active(reused, CellID(2))
    @test generation(reused, CellID(2)) == CellGeneration(1)
    @test isempty(reusable_cell_slots(reused))

    full = LogicalPottsState(reshape(OwnerRef[CellOwner(1), CellOwner(1), CellOwner(2)], 1, 3), CellCapacity(2);
        cell_types = Dict(CellID(1) => CellTypeID(1), CellID(2) => CellTypeID(1)),
        medium_domains = MediumID[MediumID(1)], property_schema = schema)
    original_owners = copy(full._owners)
    @test_throws CellCapacityError apply_division_batch(full, [DivisionRequest(1, [1])])
    @test full._owners == original_owners
    @test_throws ArgumentError apply_division_batch(after_division, [DivisionRequest(1, [1, 1])])
end
