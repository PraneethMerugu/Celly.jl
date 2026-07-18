using Test
using CorePotts

@testset "logical CPU state accessors and invariants" begin
    provenance = ComponentIdentity(:logical_state_test, v"1.0.0", :test)
    schema = PropertySchema(
        PropertyDescriptor(:target_volume, Int32, ConstantInitializer(Int32(0));
            requester = provenance),
        PropertyDescriptor(:age, UInt16, ConstantInitializer(UInt16(0)); requester = provenance),
    )
    owners = reshape(OwnerRef[
        CellOwner(1), CellOwner(1), MediumOwner(1), CellOwner(2),
    ], 2, 2)
    state = LogicalPottsState(owners, CellCapacity(4);
        reusable_slots = CellSlot[CellSlot(3)],
        generations = CellGeneration[CellGeneration(1), CellGeneration(2),
            CellGeneration(0), CellGeneration(0)],
        cell_types = Dict(CellID(1) => CellTypeID(1), CellID(2) => CellTypeID(2)),
        medium_domains = MediumID[MediumID(1)], property_schema = schema)

    @test lattice_size(state) == (2, 2)
    @test owner_at(state, 1) == CellOwner(1)
    @test owner_at(state, CartesianIndex(2, 1)) == CellOwner(1)
    @test owner_at(state, 1, 2) == MediumOwner(1)
    @test capacity(state) == CellCapacity(4)
    @test n_cells(state) == 2
    @test active_cell_ids(state) == CellID[CellID(1), CellID(2)]
    @test reusable_cell_slots(state) == CellSlot[CellSlot(3)]
    @test medium_ids(state) == MediumID[MediumID(1)]
    @test cell_type(state, CellID(2)) == CellTypeID(2)
    @test generation(state, CellID(1)) == CellGeneration(1)
    @test finite_volume(state, CellID(1)) == 2
    @test finite_volume(state, CellID(2)) == 1
    @test medium_occupancy(state, MediumID(1)) == 1
    @test property_values(state, :target_volume) == Int32[0, 0, 0, 0]
    @test isempty(state_invariant_errors(state))
    @test assert_valid_state(state) === state

    # The logical format keeps medium identity distinct from the historical zero sentinel and has
    # the same valid contract in both supported Cartesian dimensions.
    multi_medium = LogicalPottsState(reshape(OwnerRef[
            MediumOwner(1), MediumOwner(2), MediumOwner(2), MediumOwner(1),
        ], 2, 2), CellCapacity(0); medium_domains = MediumID[MediumID(1), MediumID(2)])
    @test n_cells(multi_medium) == 0
    @test medium_occupancy(multi_medium, MediumID(1)) == 2
    @test medium_occupancy(multi_medium, MediumID(2)) == 2
    state_3d = LogicalPottsState(fill(MediumOwner(1), 2, 2, 2), CellCapacity(0);
        medium_domains = MediumID[MediumID(1)])
    @test lattice_size(state_3d) == (2, 2, 2)
    @test medium_occupancy(state_3d, MediumID(1)) == 8

    # Derived values are intentionally a cache boundary: after a controlled ownership update,
    # validation rejects the stale cache until it is rebuilt from the lattice.
    state._owners[3] = CellOwner(2)
    @test !isempty(state_invariant_errors(state))
    @test rebuild_derived_state!(state) === state
    @test finite_volume(state, CellID(2)) == 2
    @test medium_occupancy(state, MediumID(1)) == 0
    @test assert_valid_state(state) === state

    invalid_owner = reshape(OwnerRef[CellOwner(1), MediumOwner(2), MediumOwner(1), CellOwner(2)], 2, 2)
    @test_throws LogicalStateInvariantError LogicalPottsState(invalid_owner, CellCapacity(2);
        cell_types = Dict(CellID(1) => CellTypeID(1), CellID(2) => CellTypeID(2)),
        medium_domains = MediumID[MediumID(1)], property_schema = schema)
    @test_throws LogicalStateInvariantError LogicalPottsState(owners, CellCapacity(4);
        reusable_slots = CellSlot[CellSlot(3), CellSlot(3)],
        cell_types = Dict(CellID(1) => CellTypeID(1), CellID(2) => CellTypeID(2)),
        medium_domains = MediumID[MediumID(1)], property_schema = schema)
    @test_throws ArgumentError cell_type(state, CellID(3))
end
