using Test
using CorePotts

@testset "logical state initialization finalization" begin
    provenance = ComponentIdentity(:logical_initialization_test, v"1.0.0", :test)
    schema = PropertySchema(PropertyDescriptor(:age, UInt16, ConstantInitializer(UInt16(0));
        requester = provenance))
    cell_nine = InitialCellLayout(9, 2, Bool[true false false; false false false])
    cell_three = InitialCellLayout(3, 1, Bool[false true false; false true false])
    vanished = InitialCellLayout(6, 1, falses(2, 3))
    medium_two = InitialMediumLayout(2, Bool[false false true; false false false])
    initialized = finalize_initial_state((2, 3), cell_nine, cell_three, vanished, medium_two;
        capacity = CellCapacity(4), medium_domains = MediumID[MediumID(1), MediumID(2)],
        property_schema = schema)
    state = logical_state(initialized)
    report = initialization_report(initialized)

    # Surviving provisional IDs are compacted in deterministic ascending order: 3 -> 1, 9 -> 2.
    @test report.provisional_to_runtime == [CellID(3) => CellID(1), CellID(9) => CellID(2)]
    @test report.discarded_provisional_ids == CellID[CellID(6)]
    @test active_cell_ids(state) == CellID[CellID(1), CellID(2)]
    @test cell_type(state, CellID(1)) == CellTypeID(1)
    @test cell_type(state, CellID(2)) == CellTypeID(2)
    @test owner_at(state, 1, 1) == CellOwner(2)
    @test owner_at(state, 1, 2) == CellOwner(1)
    @test owner_at(state, 1, 3) == MediumOwner(2)
    @test finite_volume(state, CellID(1)) == 2
    @test finite_volume(state, CellID(2)) == 1
    @test medium_occupancy(state, MediumID(1)) == 2
    @test medium_occupancy(state, MediumID(2)) == 1
    @test property_values(state, :age) == UInt16[0, 0, 0, 0]
    @test assert_valid_state(state) === state

    first = InitialCellLayout(4, 1, Bool[true false; false false])
    second = InitialCellLayout(5, 2, Bool[true false; false false])
    @test_throws InitialLayoutOverlapError finalize_initial_state((2, 2), first, second;
        capacity = CellCapacity(2), medium_domains = MediumID[MediumID(1)])
    preserved = logical_state(finalize_initial_state((2, 2), first, second;
        capacity = CellCapacity(2), medium_domains = MediumID[MediumID(1)],
        overlap_policy = PreserveOnOverlap))
    replaced = logical_state(finalize_initial_state((2, 2), first, second;
        capacity = CellCapacity(2), medium_domains = MediumID[MediumID(1)],
        overlap_policy = ReplaceOnOverlap))
    @test cell_type(preserved, CellID(1)) == CellTypeID(1)
    @test cell_type(replaced, CellID(1)) == CellTypeID(2)

    @test_throws CellCapacityError finalize_initial_state((2, 3), cell_nine, cell_three;
        capacity = CellCapacity(1), medium_domains = MediumID[MediumID(1)])
    @test_throws ArgumentError finalize_initial_state((2, 2),
        InitialMediumLayout(2, trues(2, 2)); capacity = CellCapacity(0),
        medium_domains = MediumID[MediumID(1)])

    state_3d = logical_state(finalize_initial_state((2, 2, 2),
        InitialCellLayout(11, 3, reshape(Bool[true, false, false, false, false, false, false, false], 2, 2, 2));
        capacity = CellCapacity(1), medium_domains = MediumID[MediumID(1)]))
    @test lattice_size(state_3d) == (2, 2, 2)
    @test finite_volume(state_3d, CellID(1)) == 1
end
