using Test
using CorePotts

struct ProtocolEnergy <: AbstractEnergy
    scale::Float32
end
CorePotts.component_identity(::ProtocolEnergy) = ComponentIdentity(:protocol_energy, v"1.0.0", :energy)
CorePotts.energy_change(energy::ProtocolEnergy, proposal::CopyProposal, state::LogicalPottsState) = energy.scale
CorePotts.required_properties(::ProtocolEnergy) = PropertySchema()

struct ProtocolDrive <: AbstractDrive end
CorePotts.component_identity(::ProtocolDrive) = ComponentIdentity(:protocol_drive, v"1.0.0", :drive)
CorePotts.drive_log_bias(::ProtocolDrive, proposal::CopyProposal, state::LogicalPottsState) = 0.0f0

struct ProtocolConstraint <: AbstractHardConstraint end
CorePotts.component_identity(::ProtocolConstraint) = ComponentIdentity(:protocol_constraint, v"1.0.0", :constraint)
CorePotts.is_allowed(::ProtocolConstraint, proposal::CopyProposal, state::LogicalPottsState) = true

struct ProtocolTracker <: AbstractTracker end
CorePotts.component_identity(::ProtocolTracker) = ComponentIdentity(:protocol_tracker, v"1.0.0", :tracker)
CorePotts.rebuild_tracker(::ProtocolTracker, state::LogicalPottsState) = sum(finite_volume(state, id) for id in active_cell_ids(state))

struct ProtocolEvent <: AbstractEvent end
CorePotts.component_identity(::ProtocolEvent) = ComponentIdentity(:protocol_event, v"1.0.0", :event)
CorePotts.event_effects(::ProtocolEvent) = ()

struct ProtocolAlgorithm <: AbstractPottsAlgorithm end
CorePotts.component_identity(::ProtocolAlgorithm) = ComponentIdentity(:protocol_algorithm, v"1.0.0", :algorithm)
CorePotts.algorithm_guarantees(::ProtocolAlgorithm) = AlgorithmGuaranteeProfile(
    proposal_process = :protocol_reference,
    equilibrium_status = :not_claimed,
    kinetic_interpretation = :protocol_reference,
    transaction_semantics = :serial,
    mcs_normalization = :exact_reference_budget,
    reproducibility_scope = :test_fixture,
    compatible_component_scopes = (:protocol,),
    validation_evidence = (:protocol_fixture,),
    backend_contract = (:cpu,),
    dimensions = (2,),
)

struct MalformedProtocolAlgorithm <: AbstractPottsAlgorithm end
CorePotts.component_identity(::MalformedProtocolAlgorithm) =
    ComponentIdentity(:malformed_protocol_algorithm, v"1.0.0", :algorithm)
CorePotts.algorithm_guarantees(::MalformedProtocolAlgorithm) = :unstructured

struct ProtocolTopology <: AbstractTopology{2} end
CorePotts.component_identity(::ProtocolTopology) = ComponentIdentity(:protocol_topology, v"1.0.0", :topology)
CorePotts.topology_dimensions(::ProtocolTopology) = (2, 3)

struct IncompleteEnergy <: AbstractEnergy end

@testset "public scientific extension protocols" begin
    state = LogicalPottsState(reshape(OwnerRef[CellOwner(1), MediumOwner(1)], 1, 2), CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)), medium_domains = MediumID[MediumID(1)])
    proposal = CopyProposal(2, 1, MediumOwner(1), CellOwner(1); direction = 1, mcs = 2,
        semantic_id = 7)

    @test test_energy_component(ProtocolEnergy(2.5f0), proposal, state).category === :energy
    @test validate_drive_component(ProtocolDrive()).category === :drive
    @test validate_constraint_component(ProtocolConstraint()).category === :constraint
    @test test_tracker(ProtocolTracker(), state).category === :tracker
    @test test_event(ProtocolEvent()).category === :event
    @test test_algorithm(ProtocolAlgorithm()).category === :algorithm
    @test_throws ArgumentError test_algorithm(MalformedProtocolAlgorithm())
    @test test_topology(ProtocolTopology()).category === :topology
    @test rebuild_tracker(ProtocolTracker(), state) == 1
    @test_throws ScientificInterfaceError validate_energy_component(IncompleteEnergy())
    @test_throws ArgumentError CopyProposal(1, 2, CellOwner(1), CellOwner(1))

    committed = commit_copy_proposal(state, proposal)
    @test committed.accepted
    @test owner_at(logical_state(committed), 2) == CellOwner(1)
    @test finite_volume(logical_state(committed), CellID(1)) == 2
    @test !commit_copy_proposal(state, proposal; accepted = false).accepted
    @test commit_copy_proposal(state, proposal; constraints = (ProtocolConstraint(),)).accepted

    read_only_schema = PropertySchema(PropertyDescriptor(:frozen, Int32, ConstantInitializer(Int32(1));
        mutability = ReadOnlyProperty, requester = ComponentIdentity(:frozen_test, v"1.0.0", :test)))
    protected_state = LogicalPottsState(reshape(OwnerRef[CellOwner(1), MediumOwner(1)], 1, 2), CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)), medium_domains = MediumID[MediumID(1)],
        property_schema = read_only_schema)
    @test property_value(protected_state, :frozen, CellID(1)) == Int32(1)
    @test_throws ArgumentError set_cell_property!(protected_state, :frozen, CellID(1), 2)
end
