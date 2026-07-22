struct _UndeclaredTiledEnergy <: AbstractEnergy end
CorePotts.component_identity(::_UndeclaredTiledEnergy) =
    ComponentIdentity(:undeclared_tiled_test, v"1.0.0", :energy)
CorePotts.energy_change(::_UndeclaredTiledEnergy, proposal, state) = 0.0f0
CorePotts.scientific_access(::_UndeclaredTiledEnergy) = SnapshotScientificAccess()

function _tiled_reference_fixture(::Type{T} = Float32, dims = (6, 6)) where {
        T <: AbstractFloat}
    volume = QuadraticVolumeHamiltonian(number_type = T)
    schema = required_properties(volume)
    owners = fill(MediumOwner(1), dims)
    if length(dims) == 2
        owners[1:2, 1:2] .= fill(CellOwner(1), 2, 2)
        owners[end-1:end, end-1:end] .= fill(CellOwner(2), 2, 2)
    else
        owners[1:2, 1:2, 1:2] .= fill(CellOwner(1), 2, 2, 2)
        owners[end-1:end, end-1:end, end-1:end] .= fill(CellOwner(2), 2, 2, 2)
    end
    state = LogicalPottsState(owners, CellCapacity(2);
        cell_types = Dict(CellID(1) => CellTypeID(2), CellID(2) => CellTypeID(2)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :target_volume) .= T(5)
    property_values(state, :volume_strength) .= T(1.25)
    domain = CartesianDomain(dims; spacing = ntuple(_ -> one(T), length(dims)))
    proposal_relation = first_shell_relation(ProposalRole(), Val(length(dims));
        spacing = domain.spacing)
    contact_relation = first_shell_relation(ContactRole(), Val(length(dims));
        spacing = domain.spacing)
    contact = UnorderedContactHamiltonian(T[0 3; 3 1],
        MediumTypeTable(MediumID(1) => CellTypeID(1)), contact_relation)
    surface_relation = first_shell_relation(SurfaceRole(), Val(length(dims));
        spacing = domain.spacing)
    tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation)
    components = ScientificComponentSet(energies = (volume, contact))
    return (; state, domain, proposal_relation, components, tracker)
end


@testset "Tiled resident CPU vertical slice" begin
    fixture = _tiled_reference_fixture()
    first_state = compile_scientific_state(
        fixture.state, fixture.domain, fixture.tracker)
    second_state = compile_scientific_state(CorePotts._copy_logical_state(fixture.state),
        fixture.domain, fixture.tracker)
    algorithm = TiledCheckerboardCPM(temperature = 5.0f0, tile_size = (2, 2),
        switching_interval = 2, shared_memory = :disabled)
    first = init_scientific(first_state, fixture.proposal_relation,
        fixture.components, algorithm; seed = 0x12c5)
    second = init_scientific(second_state, fixture.proposal_relation,
        fixture.components, algorithm; seed = 0x12c5)
    reference = init_tiled_reference(CorePotts._copy_logical_state(fixture.state),
        fixture.domain, fixture.proposal_relation, fixture.components, algorithm;
        seed = 0x12c5)
    metrics_before = deepcopy(first.plan.metrics)

    @test CorePotts.SciMLBase.step!(first, 3) === first
    @test CorePotts.SciMLBase.step!(second, 3) === second
    for _ in 1:3
        step_tiled_reference!(reference)
    end
    @test first.plan.metrics.host_synchronizations ==
          metrics_before.host_synchronizations
    @test first.plan.metrics.device_to_host_transfers ==
          metrics_before.device_to_host_transfers
    report = current_mcs_report(first)
    @test report == current_mcs_report(second)
    @test report.mcs == 3
    @test report.scheduler_candidates == mutable_site_count(fixture.domain)
    @test report.activated_attempts == mutable_site_count(fixture.domain)
    @test report.realized_proposals ==
          report.acceptance_rejections + report.accepted_copies
    @test report.activated_attempts == report.same_owner_no_ops +
          report.boundary_no_ops + report.immutable_recipient_no_ops +
          report.acceptance_rejections + report.accepted_copies
    first_snapshot = logical_state(first)
    second_snapshot = logical_state(second)
    @test lattice_storage(first_snapshot) == lattice_storage(second_snapshot)
    @test lattice_storage(first_snapshot) == lattice_storage(logical_state(reference))
    @test assert_valid_state(first_snapshot) === first_snapshot
    @test isempty(tracker_conformance_errors(first.state, fixture.tracker, first_snapshot))
    @test_throws ArgumentError init_scientific(
        compile_scientific_state(fixture.state, fixture.domain, fixture.tracker),
        fixture.proposal_relation, fixture.components,
        TiledCheckerboardCPM(shared_memory = :required))

    fixture3 = _tiled_reference_fixture(Float32, (4, 4, 4))
    algorithm3 = TiledCheckerboardCPM(temperature = 5.0f0,
        tile_size = (2, 2, 2), switching_interval = 2, shared_memory = :disabled)
    resident3 = init_scientific(compile_scientific_state(
            fixture3.state, fixture3.domain, fixture3.tracker),
        fixture3.proposal_relation, fixture3.components, algorithm3; seed = 0x3125)
    reference3 = init_tiled_reference(CorePotts._copy_logical_state(fixture3.state),
        fixture3.domain, fixture3.proposal_relation, fixture3.components, algorithm3;
        seed = 0x3125)
    CorePotts.SciMLBase.step!(resident3)
    step_tiled_reference!(reference3)
    snapshot3 = logical_state(resident3)
    @test lattice_storage(snapshot3) == lattice_storage(logical_state(reference3))
    @test assert_valid_state(snapshot3) === snapshot3
    @test isempty(tracker_conformance_errors(
        resident3.state, fixture3.tracker, snapshot3))
end

@testset "TiledCheckerboardCPM configuration and guarantees" begin
    algorithm = TiledCheckerboardCPM(temperature = 6.0f0, tile_size = (4, 3),
        switching_interval = 7, shared_memory = :required)
    @test algorithm.temperature === 6.0f0
    @test algorithm.tile_size == (4, 3)
    @test algorithm.switching_interval == UInt16(7)
    @test algorithm.shared_memory === TiledSharedMemoryRequired
    @test component_identity(algorithm).key == :tiled_checkerboard_cpm
    guarantees = algorithm_guarantees(algorithm)
    @test guarantees.mcs_normalization == :exact_mutable_site_attempt_budget
    @test guarantees.transaction_semantics.snapshot == :common_per_tile_color
    @test :semantic_rng_identity in guarantees.validation_evidence

    @test TiledCheckerboardCPM().shared_memory === TiledSharedMemoryAuto
    @test TiledCheckerboardCPM(shared_memory = :disabled).shared_memory ===
          TiledSharedMemoryDisabled
    @test_throws ArgumentError TiledCheckerboardCPM(temperature = -1.0f0)
    @test_throws ArgumentError TiledCheckerboardCPM(tile_size = (4,))
    @test_throws ArgumentError TiledCheckerboardCPM(tile_size = (4, 0))
    @test_throws ArgumentError TiledCheckerboardCPM(switching_interval = 0)
    @test_throws ArgumentError TiledCheckerboardCPM(shared_memory = :fallback)
end

@testset "Tiled open component access protocol" begin
    volume = QuadraticVolumeHamiltonian(number_type = Float32)
    relation = first_shell_relation(ContactRole(), Val(2))
    contact = UnorderedContactHamiltonian(Float32[0 1; 1 2],
        MediumTypeTable(MediumID(1) => CellTypeID(1)), relation)
    volume_access = tiled_scientific_access(volume)
    contact_access = tiled_scientific_access(contact)
    @test volume_access isa TiledSnapshotAccess
    @test volume_access.cell_wide
    @test volume_access.reconciliation === ExactAdditiveTiledReconciliation
    @test contact_access isa TiledSnapshotAccess
    @test contact_access.relations == (relation,)
    @test contact_access.dependency_radius == 1

    components = ScientificComponentSet(energies = (volume, contact))
    @test isempty(algorithm_component_compatibility(
        TiledCheckerboardCPM(), components))
    @test tiled_scientific_access(_UndeclaredTiledEnergy()) isa
          UnsupportedTiledScientificAccess
    unsupported = ScientificComponentSet(
        energies = (_UndeclaredTiledEnergy(),))
    @test !isempty(algorithm_component_compatibility(
        TiledCheckerboardCPM(), unsupported))

    @test_throws ArgumentError TiledSnapshotAccess(; dependency_radius = -1)
    @test_throws ArgumentError TiledSnapshotAccess(; scratch_words = -1)
end

@testset "Tiled topology-derived layout and halo coloring" begin
    algorithm = TiledCheckerboardCPM(tile_size = (4, 3))
    layout = tiled_layout(algorithm, (9, 7); halo_radius = 1)
    @test layout.dims == (9, 7)
    @test layout.tile_grid == (3, 3)
    @test prod(layout.tile_grid) == length(layout.tile_colors)
    sites = reduce(vcat, [tiled_tile_sites(layout, tile)
        for tile in 1:prod(layout.tile_grid)])
    @test sort!(Int.(sites)) == collect(1:63)
    @test length(unique(sites)) == 63

    periodic = tiled_layout(TiledCheckerboardCPM(tile_size = (4, 4)), (12, 12);
        halo_radius = 1, periodic = (true, true))
    @test periodic.tile_grid == (3, 3)
    @test length(unique(periodic.tile_colors)) >= 3
    reach = (1, 1)
    for left in 1:prod(periodic.tile_grid), right in 1:(left - 1)
        left_coordinate = CorePotts._tile_coordinate(periodic.tile_grid, left)
        right_coordinate = CorePotts._tile_coordinate(periodic.tile_grid, right)
        if CorePotts._tiled_tiles_conflict(left_coordinate, right_coordinate,
                periodic.tile_grid, periodic.periodic, reach)
            @test tiled_color(periodic, left) != tiled_color(periodic, right)
        end
    end

    @test_throws ArgumentError tiled_layout(algorithm, (9, 7, 2))
    @test_throws ArgumentError tiled_layout(algorithm, (9, 7); halo_radius = -1)
end

@testset "Tiled schedule RNG identities" begin
    rng = Philox4x32x10V1()
    layout = tiled_layout(TiledCheckerboardCPM(tile_size = (3, 3)), (11, 11);
        halo_radius = 1, periodic = (true, true))
    first = tiled_color_order(rng, 0x125, 1, layout)
    repeat = tiled_color_order(rng, 0x125, 1, layout)
    @test first == repeat
    @test sort(first) == collect(UInt16(1):UInt16(length(first)))
    observed = Set(Tuple(tiled_color_order(rng, 0x125, mcs, layout)) for mcs in 1:12)
    @test length(observed) > 1

    addresses = [tiled_rng_address(2, 1, tile, proposal; draw)
        for tile in 1:3, proposal in 1:4, draw in 0:1]
    @test length(unique(vec(addresses))) == length(addresses)
    @test tiled_rng_address(2, 1, 1, 1) == tiled_rng_address(2, 1, 1, 1)
    @test_throws ArgumentError tiled_rng_address(2, 1, 1, 0)
    @test_throws ArgumentError tiled_rng_address(2, 256, 1, 1)
end

@testset "Tiled logical reference exact accounting and replay" begin
    fixture = _tiled_reference_fixture()
    algorithm = TiledCheckerboardCPM(temperature = 5.0f0, tile_size = (2, 2),
        switching_interval = 2)
    first = init_tiled_reference(CorePotts._copy_logical_state(fixture.state),
        fixture.domain, fixture.proposal_relation, fixture.components, algorithm;
        seed = 0x12c5)
    second = init_tiled_reference(CorePotts._copy_logical_state(fixture.state),
        fixture.domain, fixture.proposal_relation, fixture.components, algorithm;
        seed = 0x12c5)

    @test current_mcs_report(first) === nothing
    @test first.layout.halo_radius == 1
    @test step_tiled_reference!(first) === first
    @test step_tiled_reference!(second) === second
    first_report = current_mcs_report(first)
    @test first_report == current_mcs_report(second)
    @test first_report.mcs == 1
    @test first_report.internal_rounds > length(first.layout.color_offsets) - 1
    @test first_report.scheduler_candidates == mutable_site_count(fixture.domain)
    @test first_report.activated_attempts == mutable_site_count(fixture.domain)
    @test first_report.realized_proposals ==
          first_report.acceptance_rejections + first_report.accepted_copies
    @test first_report.activated_attempts ==
          first_report.same_owner_no_ops + first_report.boundary_no_ops +
          first_report.immutable_recipient_no_ops + first_report.acceptance_rejections +
          first_report.accepted_copies
    @test lattice_storage(logical_state(first)) == lattice_storage(logical_state(second))
    @test assert_valid_state(logical_state(first)) === logical_state(first)

    for _ in 1:4
        step_tiled_reference!(first)
        step_tiled_reference!(second)
    end
    @test current_mcs_report(first) == current_mcs_report(second)
    @test lattice_storage(logical_state(first)) == lattice_storage(logical_state(second))
    @test property_values(logical_state(first), :target_volume) ==
          property_values(logical_state(second), :target_volume)
    @test assert_valid_state(logical_state(first)) === logical_state(first)
end
