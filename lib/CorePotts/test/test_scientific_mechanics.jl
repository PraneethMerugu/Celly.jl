using SciMLBase
using Statistics

function _mechanical_clock_fixture(algorithm; seed = 0x91)
    surface_relation = first_shell_relation(SurfaceRole(), Val(2))
    volume = FluctuatingVolumePressure(; eta = 1.25f0,
        noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization,
        instance_id = 1)
    surface = FluctuatingSurfaceTension(BoundaryEdgeCount(), surface_relation;
        eta = 0.75f0, noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization,
        instance_id = 2)
    schema = merge_property_schemas(
        required_properties(volume), required_properties(surface))
    owners = fill(CellOwner(1), 4, 4)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :target_volume)[1] = 10.0f0
    property_values(state, :volume_strength)[1] = 2.0f0
    property_values(state, :target_boundary)[1] = 4
    property_values(state, :boundary_strength)[1] = 1.5f0
    domain = CartesianDomain((4, 4))
    tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation)
    compiled = compile_scientific_state(state, domain, tracker)
    proposal = first_shell_relation(ProposalRole(), Val(2))
    components = ScientificComponentSet(mechanics = (volume, surface))
    integrator = init_scientific(
        compiled, proposal, components, algorithm; seed)
    return (; integrator, volume, surface, tracker)
end

@testset "stable mechanical laws and schemas" begin
    volume = FluctuatingVolumePressure(; eta = 2.0f0)
    relation = first_shell_relation(SurfaceRole(), Val(2))
    surface = FluctuatingSurfaceTension(BoundaryEdgeCount(), relation;
        eta = 3.0f0, instance_id = 2)
    @test component_identity(volume).key == :fluctuating_volume_pressure
    @test component_identity(surface).category == :mechanical
    @test property_descriptor(required_properties(volume), :volume_pressure).kind ===
          AuxiliaryProperty
    @test property_descriptor(required_properties(surface), :surface_tension).division isa
          ConstitutiveResetAfterDivision
    @test property_descriptor(required_properties(surface), :target_boundary).division isa
          UnsupportedDivision
    @test scientific_access(volume).cell_wide
    @test only(scientific_access(surface).relations) == relation
    @test validate_mechanical_component(volume).category == :mechanical
    @test_throws ArgumentError FluctuatingVolumePressure(eta = 0.0f0)
    @test_throws ArgumentError FluctuatingSurfaceTension(
        BoundaryEdgeCount(), relation; instance_id = 0)
    @test_throws ArgumentError FixedMechanicalNoise(-1.0f0)

    q = mechanical_ou_transition(1.5, 3.0, 2.0, 0.75, 4.0, 0.2, -0.5)
    alpha = exp(-0.75 * 0.2)
    expected = alpha * 1.5 + (1 - alpha) * 12.0 -
               0.5 * sqrt(16.0 * (1 - alpha^2))
    @test q ≈ expected
    @test mechanical_ou_transition(1.5, 3.0, 2.0, 0.75, 0.0, 0.0, 7.0) == 1.5
    @test_throws ArgumentError mechanical_ou_transition(
        0.0, 0.0, -1.0, 1.0, 1.0, 1.0, 0.0)
end

@testset "mechanical work stays separate from conservative energy" begin
    relation = first_shell_relation(SurfaceRole(), Val(2))
    volume = FluctuatingVolumePressure(
        noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization, instance_id = 1)
    surface = FluctuatingSurfaceTension(BoundaryEdgeCount(), relation;
        noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization, instance_id = 2)
    schema = merge_property_schemas(
        required_properties(volume), required_properties(surface))
    owners = fill(MediumOwner(1), 3, 3)
    owners[5] = CellOwner(1)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :volume_pressure)[1] = 3.0f0
    property_values(state, :surface_tension)[1] = 2.0f0
    domain = CartesianDomain((3, 3))
    tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), relation)
    compiled = compile_scientific_state(state, domain, tracker)
    proposal = CopyProposal(5, 4, CellOwner(1), MediumOwner(1))
    transaction = stage_copy_transaction(compiled, tracker, proposal)
    context = ScientificProposalContext(compiled, transaction)
    components = ScientificComponentSet(mechanics = (volume, surface))
    evaluation = evaluate_copy(components, proposal, context, Float32)
    expected_volume = -3.0f0
    expected_surface = 2.0f0 * Float32(transaction.trackers.losing_boundary)
    @test evaluation.delta_h == 0.0f0
    @test evaluation.mechanical_work == expected_volume + expected_surface
    @test acceptance_inputs(evaluation).delta_h == evaluation.mechanical_work
    report = scientific_components_report(components)
    @test length(report.mechanics) == 2
    @test all(identity -> identity.category == :mechanical, report.mechanics)

    proposal_relation = first_shell_relation(ProposalRole(), Val(2))
    duplicate_instance = FluctuatingSurfaceTension(BoundaryEdgeCount(), relation;
        noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization, instance_id = 1)
    @test_throws ArgumentError init_scientific(compiled, proposal_relation,
        ScientificComponentSet(mechanics = (volume, duplicate_instance)),
        SequentialCPM())
    duplicate_state = FluctuatingVolumePressure(
        noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization, instance_id = 3)
    @test_throws ArgumentError init_scientific(compiled, proposal_relation,
        ScientificComponentSet(mechanics = (volume, duplicate_state)),
        SequentialCPM())
    alternative_relation = first_shell_relation(SurfaceRole(), Val(2);
        weights = ntuple(_ -> 2.0, 4))
    mismatched_surface = FluctuatingSurfaceTension(
        BoundaryEdgeCount(), alternative_relation;
        noise = FixedMechanicalNoise(0.0f0),
        initialization = PreserveMechanicalInitialization, instance_id = 4)
    @test_throws ArgumentError init_scientific(compiled, proposal_relation,
        ScientificComponentSet(mechanics = (mismatched_surface,)), SequentialCPM())
end

@testset "one normalized mechanical MCS across algorithms" begin
    algorithms = (
        SequentialCPM(temperature = 5.0f0),
        CheckerboardSweepCPM(temperature = 5.0f0),
        LotteryCPM(temperature = 5.0f0),
    )
    observed = Tuple{Float32, Float32}[]
    for algorithm in algorithms
        fixture = _mechanical_clock_fixture(algorithm)
        baseline_syncs = fixture.integrator.plan.metrics.host_synchronizations
        step!(fixture.integrator)
        @test fixture.integrator.plan.metrics.host_synchronizations == baseline_syncs
        snapshot = logical_state(fixture.integrator)
        pressure = property_values(snapshot, :volume_pressure)[1]
        tension = property_values(snapshot, :surface_tension)[1]
        expected_pressure = 24.0f0 * (1.0f0 - exp(-1.25f0))
        expected_tension = -12.0f0 * (1.0f0 - exp(-0.75f0))
        @test pressure ≈ expected_pressure rtol = 2.0f-6
        @test tension ≈ expected_tension rtol = 2.0f-6
        push!(observed, (pressure, tension))
    end
    @test observed[2][1] ≈ observed[1][1] rtol = 2.0f-6
    @test observed[3][1] ≈ observed[1][1] rtol = 2.0f-6
    @test observed[2][2] ≈ observed[1][2] rtol = 2.0f-6
    @test observed[3][2] ≈ observed[1][2] rtol = 2.0f-6
end

@testset "mechanical initialization and strict replay" begin
    component = FluctuatingVolumePressure(; eta = 1.0f0,
        initialization = StationaryMechanicalInitialization,
        instance_id = 7)
    schema = required_properties(component)
    owners = fill(CellOwner(1), 3, 3)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :target_volume)[1] = 5.0f0
    property_values(state, :volume_strength)[1] = 2.0f0
    domain = CartesianDomain((3, 3))
    surface_relation = first_shell_relation(SurfaceRole(), Val(2))
    tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation)
    proposal = first_shell_relation(ProposalRole(), Val(2))
    components = ScientificComponentSet(mechanics = (component,))
    first = init_scientific(compile_scientific_state(state, domain, tracker), proposal,
        components, SequentialCPM(temperature = 3.0f0); seed = 0x1234)
    second = init_scientific(compile_scientific_state(state, domain, tracker), proposal,
        components, SequentialCPM(temperature = 3.0f0); seed = 0x1234)
    first_initial = property_values(logical_state(first), :volume_pressure)[1]
    second_initial = property_values(logical_state(second), :volume_pressure)[1]
    @test first_initial == second_initial
    step!(first)
    step!(second)
    @test property_values(logical_state(first), :volume_pressure) ==
          property_values(logical_state(second), :volume_pressure)
    @test_throws ArgumentError init_scientific(
        compile_scientific_state(state, domain, tracker), proposal, components,
        SequentialEquilibrium(temperature = 3.0f0); seed = 0x1234)
end

@testset "mechanical evolution kernel moments" begin
    dims = (64, 64)
    slot_count = prod(dims)
    component = FluctuatingVolumePressure(; eta = 1.0f0,
        initialization = PreserveMechanicalInitialization, instance_id = 11)
    owners = reshape(
        OwnerRef[CellOwner(CellID(index)) for index in 1:slot_count], dims)
    state = LogicalPottsState(owners, CellCapacity(slot_count);
        cell_types = Dict(CellID(index) => CellTypeID(1) for index in 1:slot_count),
        medium_domains = [MediumID(1)], property_schema = required_properties(component))
    property_values(state, :target_volume) .= 1.0f0
    property_values(state, :volume_strength) .= 2.0f0
    domain = CartesianDomain(dims; spacing = (1.0f0, 1.0f0))
    surface_relation = first_shell_relation(SurfaceRole(), Val(2);
        spacing = domain.spacing)
    tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation)
    proposal = first_shell_relation(ProposalRole(), Val(2); spacing = domain.spacing)
    integrator = init_scientific(
        compile_scientific_state(state, domain, tracker), proposal,
        ScientificComponentSet(mechanics = (component,)),
        SequentialCPM(temperature = 3.0f0); seed = 0x65766f6c7574696f)
    CorePotts._advance_mechanics!(
        integrator, UInt64(1), UInt8(0), UInt8(0), 1.0f0)
    samples = property_values(logical_state(integrator), :volume_pressure)
    expected_variance = 12.0f0 * (1.0f0 - exp(-2.0f0))
    @test abs(mean(samples)) < 0.2f0
    @test abs(var(samples; corrected = false) - expected_variance) < 0.6f0
end
