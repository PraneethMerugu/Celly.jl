@testset "field sampling, conservative coupling, and chemotaxis" begin
    identity = ComponentIdentity(:field_test, v"1.0.0", :test)
    schema = PropertySchema(
        PropertyDescriptor(:field_coupling, Float32, ConstantInitializer(0.0f0);
            requester = identity),
        PropertyDescriptor(:chemotaxis_sensitivity, Float32, ConstantInitializer(0.0f0);
            requester = identity)
    )
    owners = fill(MediumOwner(1), 3, 3)
    owners[4] = owners[6] = CellOwner(1)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :field_coupling)[1] = 2.0f0
    property_values(state, :chemotaxis_sensitivity)[1] = 2.0f0
    domain = CartesianDomain((3, 3); spacing = (1.0f0, 1.0f0))
    values = reshape(Float32.(1:9), 3, 3)
    field = CellCenteredField(values; spacing = (1.0f0, 1.0f0),
        interpolation = MultilinearFieldInterpolation(), semantic_time = 3.0f0,
        synchronization_epoch = 7)
    @test sample_field(field, domain, 5) == values[5]
    @test !isbitstype(typeof(field)) # CPU Array remains host storage until adaptation.

    coupling = OwnerScalarCoupling(:field_coupling, MediumID(1) => 0.5f0;
        number_type = Float32)
    conservative = ExternalFieldOccupancyHamiltonian(field, coupling;
        response = LinearResponse(), energy_scale = 1.5f0)
    proposal = CopyProposal(5, 4, MediumOwner(1), CellOwner(1))
    after = logical_state(commit_copy_proposal(state, proposal))
    @test energy_change(conservative, proposal, state, domain) ≈
          global_energy(conservative, after, domain) -
          global_energy(conservative, state, domain)

    sensitivity = OwnerScalarCoupling(:chemotaxis_sensitivity, MediumID(1) => 0.0f0;
        number_type = Float32)
    extension = ChemotaxisDrive(field, sensitivity, LinearResponse(), ExtensionChemotaxis())
    @test drive_log_bias(extension, proposal, state, domain) == 2.0f0
    retraction_proposal = CopyProposal(4, 5, CellOwner(1), MediumOwner(1))
    retraction = ChemotaxisDrive(field, sensitivity, LinearResponse(), RetractionChemotaxis())
    @test drive_log_bias(retraction, retraction_proposal, state, domain) == 2.0f0
    reciprocal = ChemotaxisDrive(field, sensitivity, LinearResponse(), ReciprocalChemotaxis())
    @test drive_log_bias(reciprocal, proposal, state, domain) == 2.0f0

    report = field_semantics_report(field, domain)
    @test report.placement === :cell_centered
    @test report.interpolation === :MultilinearFieldInterpolation
    @test report.field_shape == (3, 3)
    @test report.field_boundaries[1].negative == (kind = :periodic,)
    @test report.potts_domain.boundaries[1].negative == (kind = :periodic,)
    @test report.sampling_role == :field_discretization
    @test report.semantic_time == 3.0f0
    @test report.synchronization_epoch == 7

    energy_report = field_semantics_report(conservative, domain)
    @test energy_report.category == :hamiltonian
    @test energy_report.coupling.finite_cell_property == :field_coupling
    @test energy_report.coupling.medium_values ==
          ((medium_id = UInt32(1), value = 0.5f0),)
    drive_report = field_semantics_report(extension, domain)
    @test drive_report.category == :nonconservative_drive
    @test drive_report.mode == :ExtensionChemotaxis
    @test !drive_report.contributes_to_hamiltonian

    energy_data = component_semantic_data(conservative)
    @test energy_data.field.shape == (3, 3)
    @test energy_data.field.values == reshape(Float32.(1:9), 3, 3)
    @test energy_data.coupling.finite_cell_property == :field_coupling
    @test energy_data.response == (kind = :linear,)
    @test energy_data.energy_scale == 1.5f0
    @test capabilities(conservative).dimensions == (2,)

    drive_data = component_semantic_data(extension)
    @test drive_data.field.semantic_time == 3.0f0
    @test drive_data.sensitivity.finite_cell_property == :chemotaxis_sensitivity
    @test drive_data.mode === :extension
    @test capabilities(extension).dimensions == (2,)
end

@testset "2D/3D field-component numerical conformance" begin
    for (T, dims) in ((Float32, (4, 4)), (Float64, (4, 4)),
        (Float32, (4, 4, 4)), (Float64, (4, 4, 4)))
        fixture = _scientific_fixture(T, dims)
        field = CellCenteredField(reshape(T.(1:prod(dims)), dims);
            interpolation = NearestFieldInterpolation())
        coupling = OwnerScalarCoupling(:volume_strength, MediumID(1) => zero(T);
            number_type = T)
        conservative = ExternalFieldOccupancyHamiltonian(
            field, coupling; energy_scale = one(T))
        selected = nothing
        for recipient in eachindex(lattice_storage(fixture.state)),
            direction in 1:direction_count(fixture.proposal_relation)

            attempt = construct_copy_attempt(fixture.state, fixture.domain,
                fixture.proposal_relation, recipient, direction)
            if is_actionable(attempt)
                selected = actionable_proposal(attempt)
                break
            end
        end
        @test selected !== nothing
        after = logical_state(commit_copy_proposal(fixture.state, selected))
        @test energy_change(conservative, selected, fixture.state, fixture.domain) ≈
              global_energy(conservative, after, fixture.domain) -
              global_energy(conservative, fixture.state, fixture.domain)
        for mode in (ExtensionChemotaxis(), RetractionChemotaxis(), ReciprocalChemotaxis())
            drive = ChemotaxisDrive(field, coupling, LinearResponse(), mode)
            @test drive_log_bias(drive, selected, fixture.state, fixture.domain) isa T
            @test capabilities(drive).dimensions == (length(dims),)
        end
    end
end

@testset "independent-resolution and 3D field interpolation" begin
    coarse_values = Float64[3 7; 5 9] # f(x,y) = x + 2y at centers (1,1), (3,1), ...
    coarse = CellCenteredField(coarse_values; spacing = (2.0, 2.0),
        boundaries = (AxisFieldBoundary(ZeroNeumannFieldBoundary()),
            AxisFieldBoundary(ZeroNeumannFieldBoundary())))
    domain = CartesianDomain((4, 4))
    @test sample_field(coarse, domain, LinearIndices((4, 4))[CartesianIndex(2, 2)]) ≈ 4.5

    values3 = reshape(Float32.(1:64), 4, 4, 4)
    field3 = CellCenteredField(values3; interpolation = NearestFieldInterpolation())
    domain3 = CartesianDomain((4, 4, 4))
    @test sample_field(field3, domain3, 37) == values3[37]

    dirichlet = CellCenteredField(ones(Float32, 2, 2);
        origin = (1.0f0, 1.0f0),
        boundaries = (AxisFieldBoundary(DirichletFieldBoundary(5.0f0)),
            AxisFieldBoundary(DirichletFieldBoundary(5.0f0))),
        interpolation = NearestFieldInterpolation())
    @test sample_field(dirichlet, CartesianDomain((2, 2)), 1) == 5.0f0
end

@testset "positive-yield acceptance semantics" begin
    modifier = PositiveYield(2.0)
    @test kinetic_barrier(modifier, nothing, nothing) == 2.0
    inputs = AcceptanceInputs(-1.0; yield_barrier = modifier.barrier)
    @test acceptance_probability(ConventionalMetropolis(), inputs, 1.0) ≈ exp(-1)
    @test acceptance_probability(ConventionalMetropolis(), inputs, 0.0) == 0.0
    @test acceptance_probability(ConventionalMetropolis(),
        AcceptanceInputs(-3.0; yield_barrier = modifier.barrier), 0.0) == 1.0
    @test_throws ArgumentError AcceptanceInputs(0.0; yield_barrier = -1.0)
end

@testset "named field response laws" begin
    @test field_response(LinearResponse(), 3.0f0) == 3.0f0
    @test field_response(MichaelisMentenResponse(2.0f0), 3.0f0) == 0.6f0
    @test field_response(SaturationLinearResponse(0.5f0), 3.0f0) == 1.2f0
    @test_throws DomainError field_response(MichaelisMentenResponse(2.0), -1.0)
    @test_throws DomainError field_response(SaturationLinearResponse(1.0), -2.0)
end
