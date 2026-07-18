function _scientific_array_snapshot(state)
    core = state.potts.storage
    trackers = state.trackers
    return (
        tags = copy(core.ownership.tags), ids = copy(core.ownership.ids),
        active = copy(core.active), cell_types = copy(core.cell_types),
        properties = map(copy, core.properties),
        finite = copy(trackers.finite_volumes), media = copy(trackers.medium_volumes),
        boundary = copy(trackers.boundary_measures)
    )
end

@testset "staged scientific tracker transactions" begin
    fixture = _scientific_fixture(Float32, (4, 4))
    tracker = BoundaryMeasureTracker(fixture.boundary.metric, fixture.boundary.relation)
    compiled = compile_scientific_state(fixture.state, fixture.domain, tracker)
    @test scientific_storage_valid(compiled)
    expected_bytes = sum(array -> sizeof(eltype(array)) * length(array),
        (
            CorePotts._storage_arrays(compiled.potts.storage)...,
            compiled.domain.storage.mutable_mask, compiled.domain.storage.mutable_sites,
            compiled.domain.storage.immutable_tags, compiled.domain.storage.immutable_ids,
            compiled.trackers.finite_volumes, compiled.trackers.medium_volumes,
            compiled.trackers.boundary_measures
        ))
    @test scientific_state_bytes(compiled) == expected_bytes
    @test isempty(tracker_conformance_errors(compiled, tracker, fixture.state))

    attempt = nothing
    for recipient in eachindex(lattice_storage(fixture.state)),
        direction in 1:direction_count(fixture.proposal_relation)

        candidate = construct_copy_attempt(fixture.state, fixture.domain,
            fixture.proposal_relation, recipient, direction)
        if is_actionable(candidate)
            attempt = candidate
            break
        end
    end
    @test attempt !== nothing
    proposal = actionable_proposal(attempt)
    mismatched_tracker = BoundaryMeasureTracker(
        fixture.weighted_boundary.metric, fixture.weighted_boundary.relation)
    @test_throws ArgumentError stage_copy_transaction(
        compiled, mismatched_tracker, proposal)
    @test_throws ArgumentError energy_change(
        fixture.weighted_boundary, proposal, scientific_execution(compiled))
    @test "requested boundary tracker does not match the compiled tracker descriptor" in
          tracker_conformance_errors(compiled, mismatched_tracker, fixture.state)
    weighted_compiled = compile_scientific_state(
        fixture.state, fixture.domain, mismatched_tracker)
    alternative_relation = first_shell_relation(SurfaceRole(), Val(2);
        spacing = fixture.domain.spacing, weights = ntuple(_ -> 2.0f0, 4))
    alternative_tracker = BoundaryMeasureTracker(
        WeightedBoundaryCount(), alternative_relation)
    alternative_component = QuadraticBoundaryHamiltonian(
        WeightedBoundaryCount(), alternative_relation;
        target = :target_weighted_boundary, strength = :weighted_boundary_strength,
        number_type = Float32)
    @test alternative_tracker.identity != mismatched_tracker.identity
    @test_throws ArgumentError stage_copy_transaction(
        weighted_compiled, alternative_tracker, proposal)
    @test_throws ArgumentError energy_change(
        alternative_component, proposal, scientific_execution(weighted_compiled))
    transaction = stage_copy_transaction(compiled, tracker, proposal)
    @test isbitstype(typeof(transaction))

    unchanged = _scientific_array_snapshot(compiled)
    @test !commit_staged!(compiled, transaction; accepted = false)
    @test _scientific_array_snapshot(compiled) == unchanged

    expected = logical_state(commit_copy_proposal(fixture.state, proposal))
    @test commit_staged!(compiled, transaction; accepted = true)
    observed = logical_snapshot(compiled.potts)
    @test lattice_storage(observed) == lattice_storage(expected)
    @test isempty(tracker_conformance_errors(compiled, tracker, observed))
    @test_throws ArgumentError commit_staged!(compiled, transaction; accepted = true)
end

@testset "compiled immutable-domain owner validation" begin
    fixture = _scientific_fixture(Float32, (4, 4))
    tracker = BoundaryMeasureTracker(fixture.boundary.metric, fixture.boundary.relation)
    undeclared_obstacle = CartesianDomain((4, 4); obstacles = (1 => MediumOwner(2),))
    @test_throws ArgumentError compile_scientific_state(
        fixture.state, undeclared_obstacle, tracker)
    mismatched_obstacle = CartesianDomain((4, 4); obstacles = (1 => MediumOwner(1),))
    @test_throws ArgumentError compile_scientific_state(
        fixture.state, mismatched_obstacle, tracker)
    undeclared_exterior = CartesianDomain((4, 4);
        boundaries = (
            AxisBoundary(FixedExterior(MediumOwner(2)), ClosedBoundary()),
            AxisBoundary(ClosedBoundary())))
    @test_throws ArgumentError compile_scientific_state(
        fixture.state, undeclared_exterior, tracker)
end

@testset "transactional tracker reconstruction matrix" begin
    for (T, dims) in ((Float32, (4, 4)), (Float64, (4, 4)),
        (Float32, (4, 4, 4)), (Float64, (4, 4, 4)))
        fixture = _scientific_fixture(T, dims)
        for component in (fixture.boundary, fixture.weighted_boundary)
            tracker = BoundaryMeasureTracker(component.metric, component.relation)
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
            snapshot = _scientific_array_snapshot(compiled)
            @test !commit_staged!(compiled, transaction; accepted = false)
            @test _scientific_array_snapshot(compiled) == snapshot
            expected = logical_state(commit_copy_proposal(fixture.state, selected))
            @test commit_staged!(compiled, transaction; accepted = true)
            @test isempty(tracker_conformance_errors(compiled, tracker, expected))
        end
    end
end

@testset "kernel-launched transaction and extinction" begin
    identity = ComponentIdentity(:transaction_extinction, v"1.0.0", :test)
    schema = PropertySchema(PropertyDescriptor(:marker, Float32,
        ConstantInitializer(0.0f0); requester = identity))
    owners = fill(MediumOwner(1), 3, 3)
    owners[5] = CellOwner(1)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(2)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :marker)[1] = 7.0f0
    boundaries = (AxisBoundary(ClosedBoundary()), AxisBoundary(ClosedBoundary()))
    domain = CartesianDomain((3, 3); boundaries)
    surface = first_shell_relation(SurfaceRole(), Val(2))
    tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface)
    compiled = compile_scientific_state(state, domain, tracker)
    proposal = CopyProposal(5, 4, CellOwner(1), MediumOwner(1))
    transaction = stage_copy_transaction(compiled, tracker, proposal)
    plan = ExecutionPlan(KernelAbstractions.CPU())
    event = launch_staged_commit!(plan, compiled, transaction; accepted = true)
    event === nothing || wait(event)
    observed = logical_snapshot(compiled.potts)
    @test !is_active(observed, CellID(1))
    @test property_values(observed, :marker)[1] == 0.0f0
    @test compiled.trackers.finite_volumes == Int32[0]
    @test compiled.trackers.medium_volumes == Int32[9]
    @test compiled.trackers.boundary_measures == Int64[0]
    @test isempty(tracker_conformance_errors(compiled, tracker, observed))
    @test plan.metrics.launches == 1
    @test plan.metrics.host_synchronizations == 0
end
