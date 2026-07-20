function _elongation_fixture(::Type{T}, dims) where {T <: AbstractFloat}
    N = length(dims)
    component = QuadraticElongationHamiltonian(number_type = T,
        target_division = CloneOnDivision())
    owners = fill(MediumOwner(1), dims)
    sites = N == 2 ? ((2, 2), (2, 3), (3, 2)) :
            ((2, 2, 2), (2, 3, 2), (3, 2, 2))
    for site in sites
        owners[site...] = CellOwner(1)
    end
    state = LogicalPottsState(owners, CellCapacity(3);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = (MediumID(1),),
        property_schema = required_properties(component))
    property_values(state, :target_elongation)[1] = T(1.5)
    property_values(state, :elongation_strength)[1] = T(2)
    domain = CartesianDomain(dims; spacing = ntuple(_ -> one(T), N))
    surface = first_shell_relation(SurfaceRole(), Val(N); spacing = domain.spacing)
    connectivity = first_shell_relation(
        ConnectivityRole(), Val(N); spacing = domain.spacing)
    boundary_tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface)
    moment_tracker = UnwrappedMomentTracker(connectivity; number_type = T)
    compiled = compile_scientific_state(
        state, domain, boundary_tracker; moment_tracker)
    return (; component, state, domain, boundary_tracker, moment_tracker, compiled)
end

@testset "exact quadratic elongation Hamiltonian" begin
    for (T, dims) in ((Float32, (6, 6)), (Float64, (6, 6)),
        (Float32, (6, 6, 6)), (Float64, (6, 6, 6)))
        fixture = _elongation_fixture(T, dims)
        (; component, domain, boundary_tracker, moment_tracker, compiled) = fixture
        covariance = unwrapped_covariance(compiled, CellOwner(1))
        @test covariance ≈ transpose(covariance)
        @test major_axis_rms_length(covariance) >= zero(T)
        @test global_energy(component, compiled) >= zero(T)
        @test validate_energy_component(component).capabilities.portable
        @test validate_proposal_component(component) === component

        N = length(dims)
        recipient_coordinates = N == 2 ? (3, 3) : (3, 3, 2)
        donor_coordinates = N == 2 ? (3, 2) : (3, 2, 2)
        linear = LinearIndices(dims)
        proposal = CopyProposal(
            linear[recipient_coordinates...], linear[donor_coordinates...],
            MediumOwner(1), CellOwner(1))
        transaction = stage_copy_transaction(
            compiled, boundary_tracker, proposal; moment_tracker)
        before = global_energy(component, compiled)
        delta = energy_change(component, proposal, compiled, transaction)
        @test commit_staged!(compiled, transaction; accepted = true)
        after = global_energy(component, compiled)
        @test isapprox(delta, after - before; rtol = 64eps(T), atol = 64eps(T))

        rebuilt = compile_scientific_state(
            logical_snapshot(compiled.potts), domain, boundary_tracker; moment_tracker)
        @test all(isapprox.(compiled.trackers.moments.coordinate_sums,
            rebuilt.trackers.moments.coordinate_sums;
            rtol = 64eps(T), atol = 64eps(T)))
        @test all(isapprox.(compiled.trackers.moments.quadratic_sums,
            rebuilt.trackers.moments.quadratic_sums;
            rtol = 64eps(T), atol = 64eps(T)))
    end
end
