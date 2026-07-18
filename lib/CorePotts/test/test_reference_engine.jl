@testset "sequential reference engine" begin
    identity = ComponentIdentity(:reference_test, v"1.0.0", :test)
    schema = PropertySchema(
        PropertyDescriptor(:target_volume, Float64, ConstantInitializer(2.0); requester = identity),
        PropertyDescriptor(:volume_strength, Float64, ConstantInitializer(1.0); requester = identity),
    )
    owners = reshape(OwnerRef[
        CellOwner(1), CellOwner(1), MediumOwner(1),
        CellOwner(1), CellOwner(2), MediumOwner(1),
        MediumOwner(1), CellOwner(2), CellOwner(2),
    ], 3, 3)
    state = LogicalPottsState(owners, CellCapacity(3);
        cell_types = Dict(CellID(1) => CellTypeID(2), CellID(2) => CellTypeID(2)),
        medium_domains = [MediumID(1)], property_schema = schema)
    interactions = [0.0 3.0; 3.0 1.0]
    volume = ReferenceVolumeEnergy()
    contact = ReferenceContactEnergy(interactions; medium_type = CellTypeID(1))
    model = ReferenceModel(energies = (volume, contact))

    proposal = CopyProposal(3, 2, MediumOwner(1), CellOwner(1); direction = 1, mcs = 1)
    before = reference_energy(model, state)
    after = reference_energy(model, commit_copy_proposal(state, proposal).state)
    @test sum(term -> energy_change(term, proposal, state), model.energies) ≈ after - before

    first_run = init_reference(state, model, SequentialReference(temperature = 2.0, seed = 0x1234))
    second_run = init_reference(state, model, SequentialReference(temperature = 2.0, seed = 0x1234))
    first_report = step_reference!(first_run)
    second_report = step_reference!(second_run)
    @test first_report == second_report
    @test lattice_storage(first_run.state) == lattice_storage(second_run.state)
    @test first_report.mcs == 1
    @test first_report.candidate_attempts == length(owners)
    @test first_report.candidate_attempts == first_report.no_op_attempts +
        first_report.constraint_rejections + first_report.energy_rejections +
        first_report.accepted_copies
    @test assert_valid_state(first_run.state) === first_run.state
    @test reference_rng_version(first_run.algorithm) == v"0.1.0-reference-splitmix64"

    second_mcs = step_reference!(first_run)
    @test second_mcs.mcs == 2
    @test first_run.mcs == 2
end

@testset "reference extinction and deferred reuse" begin
    identity = ComponentIdentity(:extinction_test, v"1.0.0", :test)
    schema = PropertySchema(
        PropertyDescriptor(:target_volume, Float64, ConstantInitializer(2.0); requester = identity),
        PropertyDescriptor(:volume_strength, Float64, ConstantInitializer(1.0); requester = identity),
    )
    state = LogicalPottsState(reshape(OwnerRef[
        CellOwner(1), MediumOwner(1), MediumOwner(1), MediumOwner(1)
    ], 2, 2), CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(2)), medium_domains = [MediumID(1)],
        property_schema = schema)
    model = ReferenceModel(energies = (ReferenceVolumeEnergy(),))
    extinction = CopyProposal(1, 2, CellOwner(1), MediumOwner(1); direction = 1, mcs = 1)
    @test energy_change(only(model.energies), extinction, state) ≈
          reference_energy(model, commit_copy_proposal(state, extinction).state) -
          reference_energy(model, state)

    # Find a stable semantic seed whose first MCS removes the single-site cell.
    selected = nothing
    for seed in UInt64(0):UInt64(10_000)
        candidate = init_reference(state, model,
            SequentialReference(temperature = 0.0, seed = seed))
        report = step_reference!(candidate)
        if CellID(1) in report.retired_cells
            selected = candidate
            break
        end
    end
    @test selected !== nothing
    if selected !== nothing
        @test !is_active(selected.state, CellID(1))
        @test isempty(reusable_cell_slots(selected.state))
        step_reference!(selected)
        @test reusable_cell_slots(selected.state) == [CellSlot(1)]
    end
end
