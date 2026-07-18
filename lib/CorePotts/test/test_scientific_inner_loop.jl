@testset "typed scientific inner-loop composition" begin
    fixture = _scientific_fixture(Float32, (4, 4))
    tracker = BoundaryMeasureTracker(fixture.boundary.metric, fixture.boundary.relation)
    compiled = compile_scientific_state(fixture.state, fixture.domain, tracker)
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
    transaction = stage_copy_transaction(compiled, tracker, selected)
    coupling = OwnerScalarCoupling(:volume_strength, MediumID(1) => 0.0f0;
        number_type = Float32)
    field = CellCenteredField(reshape(Float32.(1:16), 4, 4);
        interpolation = NearestFieldInterpolation())
    field_energy = ExternalFieldOccupancyHamiltonian(field, coupling; energy_scale = 1.0f0)
    drive = ChemotaxisDrive(field, coupling, LinearResponse(), ExtensionChemotaxis())
    connectivity = PreserveConnectedCells(
        first_shell_relation(ConnectivityRole(), Val(2)))
    modifier = PositiveYield(0.75f0)
    components = ScientificComponentSet(
        energies = (fixture.volume, fixture.contact, fixture.boundary, field_energy),
        drives = (drive,), constraints = (connectivity,),
        kinetic_modifiers = (modifier,))
    workspace = ConnectivityWorkspace(prod(fixture.domain.dims))
    context = ScientificProposalContext(
        compiled, transaction; connectivity_workspace = workspace, workspace_epoch = 7)
    evaluation = evaluate_copy(components, selected, context, Float32)

    expected_delta = energy_change(fixture.volume, selected, context.state) +
                     energy_change(fixture.contact, selected, context.state,
                         context.state.domain) +
                     energy_change(fixture.boundary, selected, context.state) +
                     energy_change(field_energy, selected, context.state,
                         context.state.domain)
    @test evaluation.delta_h ≈ expected_delta
    @test evaluation.drive_log_bias ≈
          drive_log_bias(drive, selected, context.state, context.state.domain)
    @test evaluation.kinetic_modifier == 0.0f0
    @test evaluation.yield_barrier == 0.75f0
    @test evaluation.constraints_allowed ==
          is_allowed(connectivity, selected, context.state, workspace, UInt32(8))
    @test evaluation.forward_multiplicity == selected.forward_multiplicity
    @test evaluation.reverse_multiplicity == selected.reverse_multiplicity
    @test all(!=(Any), fieldtypes(typeof(components)))
    @test all(!=(Any), fieldtypes(typeof(context)))
    @test isbitstype(typeof(evaluation))

    inputs = acceptance_inputs(evaluation)
    @test inputs.delta_h == evaluation.delta_h
    @test inputs.drive_log_bias == evaluation.drive_log_bias
    @test inputs.yield_barrier == evaluation.yield_barrier
    report = scientific_components_report(components)
    @test length(report.energies) == 4
    @test only(report.drives).category == :drive
    @test only(report.constraints).category == :constraint
    @test only(report.kinetic_modifiers).category == :kinetic_modifier

    @test_throws ArgumentError ScientificComponentSet(energies = (drive,))
    @test_throws ArgumentError ScientificProposalContext(
        compiled, transaction; connectivity_workspace = workspace, workspace_epoch = 0)
end

@testset "focal energy composes through the generic inner loop" begin
    fixture = _focal_fixture(Float32, (5, 5))
    linear = LinearIndices((5, 5))
    proposal = CopyProposal(
        linear[2, 3], linear[2, 2], MediumOwner(1), CellOwner(1))
    transaction = stage_copy_transaction(fixture.compiled, fixture.boundary_tracker,
        proposal; moment_tracker = fixture.moment_tracker)
    components = ScientificComponentSet(
        energies = (fixture.component,),
        constraints = (FixedFocalEndpointConstraint(fixture.component),))
    context = ScientificProposalContext(fixture.compiled, transaction)
    evaluation = evaluate_copy(components, proposal, context, Float32)
    @test evaluation.delta_h ≈ energy_change(
        fixture.component, proposal, fixture.compiled, transaction)
    @test evaluation.constraints_allowed
end
