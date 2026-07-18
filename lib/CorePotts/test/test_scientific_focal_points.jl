function _focal_fixture(::Type{T}, dims) where {T <: AbstractFloat}
    N = length(dims)
    owners = fill(MediumOwner(1), dims)
    first_sites = N == 2 ? ((1, 2), (dims[1], 2), (2, 2)) :
                  ((1, 2, 3), (dims[1], 2, 3), (2, 2, 3))
    second_sites = N == 2 ? ((3, 4), (4, 4), (3, 5)) :
                   ((3, 4, 3), (4, 4, 3), (3, 5, 3))
    for site in first_sites
        owners[site...] = CellOwner(1)
    end
    for site in second_sites
        owners[site...] = CellOwner(2)
    end
    state = LogicalPottsState(owners, CellCapacity(2);
        cell_types = Dict(CellID(1) => CellTypeID(1), CellID(2) => CellTypeID(1)),
        medium_domains = [MediumID(1)])
    domain = CartesianDomain(dims; spacing = ntuple(_ -> one(T), N))
    surface = first_shell_relation(SurfaceRole(), Val(N); spacing = domain.spacing)
    boundary_tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface)
    connectivity = first_shell_relation(ConnectivityRole(), Val(N); spacing = domain.spacing)
    moment_tracker = UnwrappedMomentTracker(connectivity, (CellID(1), CellID(2));
        number_type = T)
    compiled = compile_scientific_state(state, domain, boundary_tracker; moment_tracker)
    link = FocalPointLink(state, CellID(1), CellID(2);
        strength = T(2), target_length = T(1))
    component = FocalPointSpringHamiltonian(link)
    return (; state, domain, boundary_tracker, moment_tracker, compiled, component,
        first_sites, second_sites)
end

@testset "exact focal-point spring and unwrapped moments" begin
    for (T, dims) in ((Float32, (5, 5)), (Float64, (5, 5)),
        (Float32, (5, 5, 5)), (Float64, (5, 5, 5)))
        fixture = _focal_fixture(T, dims)
        (; state, domain, boundary_tracker, moment_tracker, compiled, component) = fixture
        @test scientific_storage_valid(compiled)
        @test isbitstype(typeof(component))
        center = unwrapped_center(compiled, CellOwner(1))
        @test center[1] ≈ T(0.5)
        @test global_energy(component, compiled) >= zero(T)

        N = length(dims)
        recipient_coordinates = N == 2 ? (2, 3) : (2, 3, 3)
        donor_coordinates = N == 2 ? (2, 2) : (2, 2, 3)
        linear = LinearIndices(dims)
        proposal = CopyProposal(
            linear[recipient_coordinates...], linear[donor_coordinates...],
            MediumOwner(1), CellOwner(1))
        transaction = stage_copy_transaction(compiled, boundary_tracker, proposal; moment_tracker)
        before = global_energy(component, compiled)
        delta = energy_change(component, proposal, compiled, transaction)
        @test is_allowed(FixedFocalEndpointConstraint(component), proposal, compiled)
        @test commit_staged!(compiled, transaction; accepted = true)
        after = global_energy(component, compiled)
        @test delta ≈ after - before

        logical_after = logical_snapshot(compiled.potts)
        rebuilt = compile_scientific_state(logical_after, domain, boundary_tracker; moment_tracker)
        for id in (CellOwner(1), CellOwner(2))
            old_center = unwrapped_center(compiled, id)
            rebuilt_center = unwrapped_center(rebuilt, id)
            @test all(
                axis -> isapprox(mod(old_center[axis], T(dims[axis])),
                    mod(rebuilt_center[axis], T(dims[axis]))),
                1:N)
        end
    end

    stale = _focal_fixture(Float32, (5, 5))
    stale.compiled.potts.storage.generations[1] += UInt64(1)
    @test_throws ArgumentError global_energy(stale.component, stale.compiled)
end

@testset "focal-point applicability rejects fragmented cells" begin
    owners = fill(MediumOwner(1), 5, 5)
    owners[1, 1] = owners[4, 4] = CellOwner(1)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)), medium_domains = [MediumID(1)])
    domain = CartesianDomain((5, 5))
    surface = first_shell_relation(SurfaceRole(), Val(2))
    boundary_tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface)
    moments = UnwrappedMomentTracker(first_shell_relation(ConnectivityRole(), Val(2)),
        (CellID(1),); number_type = Float32)
    @test_throws ArgumentError compile_scientific_state(state, domain, boundary_tracker;
        moment_tracker = moments)
end
