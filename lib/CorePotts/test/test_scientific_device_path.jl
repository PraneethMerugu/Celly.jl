@kernel function _scientific_probe!(output, metadata, state, proposal_relation,
        recipient, direction, volume, contact, boundary, field_energy, drive)
    index = @index(Global, Linear)
    if index == 1
        attempt = construct_copy_attempt(state, state.domain, proposal_relation,
            recipient, direction)
        metadata[1] = UInt32(attempt.outcome)
        metadata[2] = attempt.forward_multiplicity
        metadata[3] = attempt.reverse_multiplicity
        if is_actionable(attempt)
            proposal = actionable_proposal(attempt)
            output[1] = energy_change(volume, proposal, state)
            output[2] = energy_change(contact, proposal, state, state.domain)
            output[3] = energy_change(boundary, proposal, state)
            output[4] = energy_change(field_energy, proposal, state, state.domain)
            output[5] = drive_log_bias(drive, proposal, state, state.domain)
        end
    end
end

@testset "descriptor-free scientific device path" begin
    fixture = _scientific_fixture(Float32, (4, 4))
    tracker = BoundaryMeasureTracker(fixture.boundary.metric, fixture.boundary.relation)
    compiled = compile_scientific_state(fixture.state, fixture.domain, tracker)
    runtime = scientific_execution(compiled)
    coupling = OwnerScalarCoupling(:volume_strength, MediumID(1) => 0.0f0;
        number_type = Float32)
    field = CellCenteredField(reshape(Float32.(1:16), 4, 4);
        interpolation = NearestFieldInterpolation())
    field_energy = ExternalFieldOccupancyHamiltonian(field, coupling; energy_scale = 1.0f0)
    drive = ChemotaxisDrive(field, coupling, LinearResponse(), ExtensionChemotaxis())

    selected = nothing
    for recipient in 1:16, direction in 1:direction_count(fixture.proposal_relation)

        attempt = construct_copy_attempt(fixture.state, fixture.domain,
            fixture.proposal_relation, recipient, direction)
        if is_actionable(attempt)
            selected = (recipient, direction, actionable_proposal(attempt))
            break
        end
    end
    @test selected !== nothing
    recipient, direction, proposal = selected
    expected = Float32[
        energy_change(fixture.volume, proposal, fixture.state),
        energy_change(fixture.contact, proposal, fixture.state, fixture.domain),
        energy_change(fixture.boundary, proposal, fixture.state, fixture.domain),
        energy_change(field_energy, proposal, fixture.state, fixture.domain),
        drive_log_bias(drive, proposal, fixture.state, fixture.domain)
    ]
    output = zeros(Float32, 5)
    metadata = zeros(UInt32, 3)
    backend = KernelAbstractions.CPU()
    kernel = _scientific_probe!(backend, 1)
    kernel(output, metadata, runtime, fixture.proposal_relation, recipient, direction,
        fixture.volume, fixture.contact, fixture.boundary, field_energy, drive; ndrange = 1)
    KernelAbstractions.synchronize(backend)
    @test output ≈ expected
    @test metadata == UInt32[1, proposal.forward_multiplicity,
        proposal.reverse_multiplicity]
end
