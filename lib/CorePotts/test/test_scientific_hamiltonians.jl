function _scientific_fixture(::Type{T}, dims) where {T <: AbstractFloat}
    N = length(dims)
    volume = QuadraticVolumeHamiltonian(number_type = T)
    surface_relation = first_shell_relation(SurfaceRole(), Val(N);
        spacing = ntuple(_ -> one(T), N))
    boundary = QuadraticBoundaryHamiltonian(BoundaryEdgeCount(), surface_relation;
        number_type = T)
    raw_weights = ntuple(index -> T(1 + (mod(index - 1, N) / 4)), 2N)
    weighted_relation = first_shell_relation(SurfaceRole(), Val(N);
        spacing = ntuple(_ -> one(T), N), weights = raw_weights)
    weighted_boundary = QuadraticBoundaryHamiltonian(
        WeightedBoundaryCount(), weighted_relation;
        target = :target_weighted_boundary, strength = :weighted_boundary_strength,
        number_type = T)
    schema = merge_property_schemas(required_properties(volume),
        required_properties(boundary), required_properties(weighted_boundary))

    owners = fill(MediumOwner(1), dims)
    if N == 2
        owners[1, 1] = owners[2, 1] = owners[1, 2] = CellOwner(1)
        owners[end, end] = owners[end - 1, end] = owners[end, end - 1] = CellOwner(2)
    else
        owners[1, 1, 1] = owners[2, 1, 1] = owners[1, 2, 1] = CellOwner(1)
        owners[end, end, end] = owners[end - 1, end, end] = owners[end, end - 1, end] = CellOwner(2)
    end
    state = LogicalPottsState(owners, CellCapacity(2);
        cell_types = Dict(CellID(1) => CellTypeID(2), CellID(2) => CellTypeID(2)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :target_volume) .= T(4)
    property_values(state, :volume_strength) .= T(1.25)
    property_values(state, :target_boundary) .= 8
    property_values(state, :boundary_strength) .= T(0.75)
    property_values(state, :target_weighted_boundary) .= T(8.5)
    property_values(state, :weighted_boundary_strength) .= T(0.5)

    domain = CartesianDomain(dims; spacing = ntuple(_ -> one(T), N))
    proposal_relation = first_shell_relation(ProposalRole(), Val(N);
        spacing = domain.spacing)
    contact_relation = first_shell_relation(ContactRole(), Val(N);
        spacing = domain.spacing)
    contact = UnorderedContactHamiltonian(T[0 3; 3 1],
        MediumTypeTable(MediumID(1) => CellTypeID(1)), contact_relation)
    return (; state, domain, proposal_relation, volume, contact, boundary,
        weighted_boundary)
end

@testset "scientific Hamiltonian local/global conformance" begin
    for (T, dims) in ((Float32, (4, 4)), (Float64, (4, 4)),
        (Float32, (4, 4, 4)), (Float64, (4, 4, 4)))
        fixture = _scientific_fixture(T, dims)
        (; state, domain, proposal_relation, volume, contact, boundary,
            weighted_boundary) = fixture
        @test isbitstype(typeof(volume))
        @test isbitstype(typeof(contact))
        @test isbitstype(typeof(boundary))
        @test isbitstype(typeof(weighted_boundary))
        @test global_energy(volume, state) isa T
        @test global_energy(contact, state, domain) isa T
        @test global_energy(boundary, state, domain) isa T
        @test global_energy(weighted_boundary, state, domain) isa T

        checked = 0
        for recipient in eachindex(lattice_storage(state))
            for direction in 1:direction_count(proposal_relation)
                attempt = construct_copy_attempt(state, domain, proposal_relation,
                    recipient, direction)
                is_actionable(attempt) || continue
                proposal = actionable_proposal(attempt)
                after = logical_state(commit_copy_proposal(state, proposal))
                @test energy_change(volume, proposal, state) ≈
                      global_energy(volume, after) - global_energy(volume, state)
                @test energy_change(contact, proposal, state, domain) ≈
                      global_energy(contact, after, domain) -
                      global_energy(contact, state, domain)
                @test energy_change(boundary, proposal, state, domain) ≈
                      global_energy(boundary, after, domain) -
                      global_energy(boundary, state, domain)
                @test energy_change(weighted_boundary, proposal, state, domain) ≈
                      global_energy(weighted_boundary, after, domain) -
                      global_energy(weighted_boundary, state, domain)
                checked += 1
            end
        end
        @test checked > 0
    end
end

@testset "published normalized-kernel surface conformance" begin
    for (T, dims) in ((Float32, (6, 6)), (Float64, (6, 6)),
        (Float32, (6, 6, 6)), (Float64, (6, 6, 6)))
        N = length(dims)
        domain = CartesianDomain(dims; spacing = ntuple(_ -> one(T), N))
        relation = normalized_kernel_relation(Val(N); spacing = domain.spacing)
        metric = NormalizedKernelMeasure(domain, relation)
        component = QuadraticBoundaryHamiltonian(metric, relation;
            target = :target_normalized_boundary,
            strength = :normalized_boundary_strength, number_type = T)
        schema = required_properties(component)
        owners = fill(MediumOwner(1), dims)
        first = ntuple(_ -> 2, N)
        second = Base.setindex(first, 3, 1)
        third = Base.setindex(first, 3, 2)
        owners[first...] = owners[second...] = owners[third...] = CellOwner(1)
        state = LogicalPottsState(owners, CellCapacity(1);
            cell_types = Dict(CellID(1) => CellTypeID(1)),
            medium_domains = [MediumID(1)], property_schema = schema)
        property_values(state, :target_normalized_boundary)[1] = T(5)
        property_values(state, :normalized_boundary_strength)[1] = T(0.75)
        proposal_relation = first_shell_relation(ProposalRole(), Val(N);
            spacing = domain.spacing)
        checked = 0
        selected = nothing
        for recipient in eachindex(lattice_storage(state))
            for direction in 1:direction_count(proposal_relation)
                attempt = construct_copy_attempt(
                    state, domain, proposal_relation, recipient, direction)
                is_actionable(attempt) || continue
                proposal = actionable_proposal(attempt)
                selected === nothing && (selected = proposal)
                after = logical_state(commit_copy_proposal(state, proposal))
                @test energy_change(component, proposal, state, domain) ≈
                      global_energy(component, after, domain) -
                      global_energy(component, state, domain)
                checked += 1
                checked >= 32 && break
            end
            checked >= 32 && break
        end
        @test checked > 0
        tracker = BoundaryMeasureTracker(metric, relation)
        compiled = compile_scientific_state(state, domain, tracker)
        transaction = stage_copy_transaction(compiled, tracker, selected)
        @test energy_change(component, selected, scientific_execution(compiled)) ≈
              energy_change(component, selected, state, domain)
        expected = logical_state(commit_copy_proposal(state, selected))
        @test commit_staged!(compiled, transaction; accepted = true)
        @test isempty(tracker_conformance_errors(compiled, tracker, expected))
        report = surface_semantics_report(component, domain)
        @test report.metric == :normalized_kernel_measure
        @test report.metric_descriptor.neighborhood_order == (N == 2 ? 4 : 6)
        @test report.metric_descriptor.correction_factor == T(N == 2 ? 11 : 39)
        @test report.metric_descriptor.isotropy_claim == :not_claimed
    end

    for (T, dims) in ((Float32, (8, 7)), (Float64, (8, 7)),
        (Float32, (8, 7, 7)), (Float64, (8, 7, 7)))
        N = length(dims)
        spacing = ntuple(_ -> T(0.5), N)
        boundaries = ntuple(
            axis -> axis == 1 ?
                    AxisBoundary(ClosedBoundary()) : AxisBoundary(PeriodicBoundary()),
            N)
        domain = CartesianDomain(dims; spacing, boundaries)
        relation = normalized_kernel_relation(Val(N); spacing)
        metric = NormalizedKernelMeasure(domain, relation)
        owners = fill(MediumOwner(1), dims)
        for site in CartesianIndices(dims)
            site[1] <= 4 && (owners[site] = CellOwner(1))
        end
        state = LogicalPottsState(owners, CellCapacity(1);
            cell_types = Dict(CellID(1) => CellTypeID(1)),
            medium_domains = [MediumID(1)])
        expected = T(prod(dims[2:end])) * T(0.5)^(N - 1)
        @test boundary_measure(
            state, domain, relation, CellOwner(1), metric) ≈ expected
    end

    anisotropic = CartesianDomain((6, 6); spacing = (1.0, 2.0))
    anisotropic_relation = normalized_kernel_relation(Val(2);
        spacing = anisotropic.spacing)
    @test_throws ArgumentError NormalizedKernelMeasure(
        anisotropic, anisotropic_relation)
end

@testset "fixed-domain and obstacle local/global conformance" begin
    surface_relation = first_shell_relation(SurfaceRole(), Val(2))
    boundary = QuadraticBoundaryHamiltonian(
        BoundaryEdgeCount(), surface_relation; number_type = Float32)
    schema = required_properties(boundary)
    medium_types = MediumTypeTable(
        MediumID(1) => CellTypeID(1), MediumID(2) => CellTypeID(2))
    contact_relation = first_shell_relation(ContactRole(), Val(2))
    contact = UnorderedContactHamiltonian(Float32[0 3; 3 1],
        medium_types, contact_relation)

    cases = (
        (
            domain = CartesianDomain((4, 4);
                boundaries = (
                    AxisBoundary(FixedExterior(MediumOwner(2)), ClosedBoundary()),
                    AxisBoundary(ClosedBoundary()))),
            cell_sites = (CartesianIndex(1, 2), CartesianIndex(2, 2),
                CartesianIndex(1, 3)),
            obstacle = nothing,
            proposal_sites = (CartesianIndex(1, 1), CartesianIndex(1, 2))
        ),
        (
            domain = CartesianDomain((4, 4);
                obstacles = (CartesianIndex(2, 2) => MediumOwner(2),)),
            cell_sites = (CartesianIndex(1, 1), CartesianIndex(1, 2)),
            obstacle = CartesianIndex(2, 2),
            proposal_sites = (CartesianIndex(2, 1), CartesianIndex(1, 1))
        )
    )

    for case in cases
        owners = fill(MediumOwner(1), 4, 4)
        for site in case.cell_sites
            owners[site] = CellOwner(1)
        end
        case.obstacle === nothing || (owners[case.obstacle] = MediumOwner(2))
        state = LogicalPottsState(owners, CellCapacity(1);
            cell_types = Dict(CellID(1) => CellTypeID(2)),
            medium_domains = [MediumID(1), MediumID(2)], property_schema = schema)
        property_values(state, :target_boundary)[1] = 6
        property_values(state, :boundary_strength)[1] = 0.75f0
        linear = LinearIndices((4, 4))
        recipient, donor = map(site -> linear[site], case.proposal_sites)
        proposal = CopyProposal(
            recipient, donor, MediumOwner(1), CellOwner(1))
        after = logical_state(commit_copy_proposal(state, proposal))
        @test energy_change(contact, proposal, state, case.domain) ≈
              global_energy(contact, after, case.domain) -
              global_energy(contact, state, case.domain)
        @test energy_change(boundary, proposal, state, case.domain) ≈
              global_energy(boundary, after, case.domain) -
              global_energy(boundary, state, case.domain)

        tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation)
        compiled = compile_scientific_state(state, case.domain, tracker)
        transaction = stage_copy_transaction(compiled, tracker, proposal)
        @test commit_staged!(compiled, transaction; accepted = true)
        @test isempty(tracker_conformance_errors(compiled, tracker, after))
    end
end

@testset "fixed exterior contact and boundary incidences" begin
    wall = MediumOwner(2)
    boundaries = (
        AxisBoundary(FixedExterior(wall), ClosedBoundary()),
        AxisBoundary(ClosedBoundary())
    )
    domain = CartesianDomain((4, 4); boundaries)
    state = LogicalPottsState(fill(CellOwner(1), 4, 4), CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(2)), medium_domains = [MediumID(1)])
    contact_relation = first_shell_relation(ContactRole(), Val(2))
    contact = UnorderedContactHamiltonian([0.0 3.0; 3.0 1.0],
        MediumTypeTable(MediumID(1) => CellTypeID(1), MediumID(2) => CellTypeID(1)),
        contact_relation)
    surface_relation = first_shell_relation(SurfaceRole(), Val(2))
    @test global_energy(contact, state, domain) == 12.0
    @test boundary_measure(state, domain, surface_relation, CellOwner(1),
        BoundaryEdgeCount()) == 4
    query_relation = first_shell_relation(SpatialQueryRole(), Val(2); symmetric = true)
    @test global_interface_measure(state, domain, query_relation,
        CellIdentityFilter(CellID(1)), MediumDomainFilter(MediumID(2)),
        contact.medium_types) == 4

    boundary = QuadraticBoundaryHamiltonian(BoundaryEdgeCount(), surface_relation)
    report = surface_semantics_report(boundary, domain)
    @test report.category == :hamiltonian
    @test report.metric == :boundary_edge_count
    @test report.accumulator_type === Int64
    @test report.relation.role == :SurfaceRole
    @test report.relation.offsets == ((-1, 0), (0, -1), (0, 1), (1, 0))
    @test report.domain.boundaries[1].negative ==
          (kind = :fixed_exterior, owner_kind = :medium, owner_id = UInt32(2))
    @test report.domain.boundaries[1].positive == (kind = :closed,)
end
