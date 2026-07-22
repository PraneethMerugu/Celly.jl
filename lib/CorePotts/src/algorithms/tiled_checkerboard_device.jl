"""Resident device-global workspace for the first qualified tiled execution path."""
struct TiledDeviceWorkspace{S, F, C, O, V, D, I, L, K}
    tile_sites::S
    tile_offsets::F
    color_tiles::C
    color_offsets::F
    color_order::O
    finite_snapshot::V
    finite_deltas::D
    scratch_ids::I
    scratch_deltas::D
    layout::L
    kernels::K
    color_count::UInt32
    maximum_color_tiles::UInt32
    maximum_tile_sites::UInt32
    scratch_stride::UInt32
    switching_interval::UInt32
    batches_per_color::UInt32
end

function _allocate_tiled_device_workspace(
        state, proposal_relation, algorithm, accesses, plan)
    if !(plan.backend isa KernelAbstractions.CPU)
        synchronize_observation!(plan)
        record_transfer!(plan, :device_to_host)
    end
    halo = _tiled_relation_radius(proposal_relation)
    for access in accesses
        halo = max(halo, Int(access.dependency_radius))
        for relation in access.relations
            halo = max(halo, _tiled_relation_radius(relation))
        end
    end
    halo = max(halo, _tiled_relation_radius(state.boundary_tracker.relation))
    host_domain = _host_domain(state.domain)
    periodic = ntuple(axis ->
        state.domain.descriptor.boundaries[axis].negative isa PeriodicBoundary,
        length(state.domain.descriptor.dims))
    layout = tiled_layout(algorithm, Tuple(Int.(state.domain.descriptor.dims));
        halo_radius = halo, periodic)

    host_sites = UInt32[]
    host_tile_offsets = UInt32[1]
    for tile in 1:prod(layout.tile_grid)
        for site in tiled_tile_sites(layout, tile)
            host_domain.storage.mutable_mask[Int(site)] != UInt8(0) &&
                push!(host_sites, site)
        end
        push!(host_tile_offsets, UInt32(length(host_sites) + 1))
    end
    maximum_tile_sites = maximum((Int(host_tile_offsets[index + 1] -
        host_tile_offsets[index]) for index in 1:length(host_tile_offsets)-1); init = 0)
    maximum_tile_sites > 0 || throw(ArgumentError(
        "tiled execution requires at least one mutable tile site"))
    maximum_color_tiles = maximum((Int(layout.color_offsets[index + 1] -
        layout.color_offsets[index]) for index in 1:length(layout.color_offsets)-1))
    interval = algorithm.switching_interval === nothing ? maximum_tile_sites :
               min(Int(algorithm.switching_interval), maximum_tile_sites)
    batches = cld(maximum_tile_sites, interval)
    scratch_stride = 2 * interval

    prototype = state.potts.storage.active
    recorded(source) = _record_checkerboard_array!(plan, source)
    tile_sites = recorded(_device_copy(prototype, host_sites))
    tile_offsets = recorded(_device_copy(prototype, host_tile_offsets))
    color_tiles = recorded(_device_copy(prototype, layout.color_tiles))
    color_offsets = recorded(_device_copy(prototype, layout.color_offsets))
    color_order = recorded(similar(prototype, UInt32,
        length(layout.color_offsets) - 1))
    finite_snapshot = recorded(similar(
        prototype, Int32, length(state.trackers.finite_volumes)))
    finite_deltas = recorded(similar(
        prototype, Int32, length(state.trackers.finite_volumes)))
    scratch_ids = recorded(similar(
        prototype, UInt32, prod(layout.tile_grid) * scratch_stride))
    scratch_deltas = recorded(similar(
        prototype, Int32, prod(layout.tile_grid) * scratch_stride))
    if !(plan.backend isa KernelAbstractions.CPU)
        record_transfer!(plan, :host_to_device)
    end
    cell_count = length(state.trackers.finite_volumes)
    kernels = (
        prepare = _execution_kernel(plan, _tiled_prepare_mcs!, max(cell_count, 1)),
        snapshot = _execution_kernel(plan, _tiled_snapshot_cells!, max(cell_count, 1)),
        execute = _execution_kernel(
            plan, _tiled_execute_batch!, maximum_color_tiles),
        reconcile = _execution_kernel(
            plan, _tiled_reconcile_cells!, max(cell_count, 1)),
    )
    return TiledDeviceWorkspace(tile_sites, tile_offsets, color_tiles, color_offsets,
        color_order, finite_snapshot, finite_deltas, scratch_ids, scratch_deltas,
        layout, kernels, UInt32(length(layout.color_offsets) - 1),
        UInt32(maximum_color_tiles), UInt32(maximum_tile_sites), UInt32(scratch_stride),
        UInt32(interval), UInt32(batches))
end

function _validate_tiled_device_components(components, state, moment_tracker, algorithm)
    isempty(components.drives) && isempty(components.constraints) &&
        isempty(components.kinetic_modifiers) && isempty(components.mechanics) ||
        throw(ArgumentError(
            "the resident tiled vertical slice currently qualifies conservative energies only"))
    moment_tracker === nothing || throw(ArgumentError(
        "the resident tiled vertical slice currently rejects moment-dependent components"))
    state.trackers.moments isa NoMomentStorage || throw(ArgumentError(
        "TiledCheckerboardCPM requires state compiled without moment storage"))
    eltype(state.trackers.boundary_measures) <: Integer || throw(ArgumentError(
        "the resident tiled vertical slice requires an exact integer boundary tracker"))
    algorithm.shared_memory === TiledSharedMemoryRequired && throw(ArgumentError(
        "shared_memory=:required is not qualified by the device-global vertical slice"))
    all(component -> component isa Union{QuadraticVolumeHamiltonian,
            UnorderedContactHamiltonian}, components.energies) || throw(ArgumentError(
        "the resident tiled vertical slice currently qualifies volume and adhesion energies"))
    accesses = map(tiled_scientific_access, components.energies)
    all(access -> access isa TiledSnapshotAccess, accesses) || throw(ArgumentError(
        "every tiled energy must declare tiled_scientific_access"))
    return accesses
end

function init_scientific(state::CompiledScientificState,
        proposal_relation::StaticCartesianRelation{<:ProposalRole},
        components::ScientificComponentSet, algorithm::TiledCheckerboardCPM;
        seed::Integer = 0, rng::AbstractRNGContract = Philox4x32x10V1(),
        plan::ExecutionPlan = _default_execution_plan(state), moment_tracker = nothing,
        connectivity_workspace = nothing, lifecycle = NoCompiledLifecycle(),
        initialize_mechanics::Bool = true)
    connectivity_workspace === nothing || throw(ArgumentError(
        "TiledCheckerboardCPM owns its resident workspace"))
    _validate_scientific_initialization(
        state, proposal_relation, components, algorithm, seed, rng, plan)
    accesses = _validate_tiled_device_components(
        components, state, moment_tracker, algorithm)
    _validate_zero_temperature(algorithm, components)
    workspace = _allocate_tiled_device_workspace(
        state, proposal_relation, algorithm, accesses, plan)
    report_storage = _record_checkerboard_array!(plan,
        similar(state.potts.storage.active, UInt64, _SEQUENTIAL_REPORT_FIELDS))
    integrator = ScientificPottsIntegrator(state, components, proposal_relation,
        algorithm, rng, plan, NoConnectivityWorkspace(), nothing, workspace,
        lifecycle, report_storage, UInt64(seed), UInt64(0))
    return initialize_mechanics ? _initialize_mechanics!(integrator) : integrator
end

struct TiledDeviceEnergyContext{S, V, I, D}
    state::S
    finite_snapshot::V
    scratch_ids::I
    scratch_deltas::D
    scratch_start::UInt32
    scratch_count::UInt32
end

@inline function _tiled_scratch_delta(context::TiledDeviceEnergyContext, owner::UInt32)
    iszero(context.scratch_count) && return Int32(0)
    for slot in UInt32(0):context.scratch_count-UInt32(1)
        index = context.scratch_start + slot
        @inbounds context.scratch_ids[Int(index)] == owner &&
            return context.scratch_deltas[Int(index)]
    end
    return Int32(0)
end

@inline function _tiled_add_scratch_delta!(ids, deltas, start::UInt32,
        count::UInt32, capacity::UInt32, owner::UInt32, change::Int32)
    if !iszero(count)
        for slot in UInt32(0):count-UInt32(1)
            index = start + slot
            if @inbounds(ids[Int(index)] == owner)
                @inbounds deltas[Int(index)] += change
                return count
            end
        end
    end
    count < capacity || return count
    index = start + count
    @inbounds begin
        ids[Int(index)] = owner
        deltas[Int(index)] = change
    end
    return count + UInt32(1)
end

@inline function tiled_device_energy_change(component::QuadraticVolumeHamiltonian,
        proposal::CopyProposal, context::TiledDeviceEnergyContext)
    state = context.state
    targets = _property_column(state, _volume_target(component))
    strengths = _property_column(state, _volume_strength(component))
    T = typeof(component).parameters[3]
    delta = zero(T)
    if is_cell_owner(proposal.losing)
        owner = proposal.losing.value
        index = Int(owner)
        volume = @inbounds context.finite_snapshot[index] +
            _tiled_scratch_delta(context, owner)
        delta += @inbounds _quadratic_volume_owner_change(
            T(strengths[index]), T(targets[index]), volume, Int32(-1))
    end
    if is_cell_owner(proposal.gaining)
        owner = proposal.gaining.value
        index = Int(owner)
        volume = @inbounds context.finite_snapshot[index] +
            _tiled_scratch_delta(context, owner)
        delta += @inbounds _quadratic_volume_owner_change(
            T(strengths[index]), T(targets[index]), volume, Int32(1))
    end
    return delta
end

@inline tiled_device_energy_change(component::UnorderedContactHamiltonian,
    proposal::CopyProposal, context::TiledDeviceEnergyContext) =
    energy_change(component, proposal, context.state, context.state.domain)

@inline _tiled_device_energy(::Tuple{}, proposal, context, result) = result
@inline function _tiled_device_energy(components::Tuple, proposal, context, result)
    updated = result + tiled_device_energy_change(first(components), proposal, context)
    return _tiled_device_energy(Base.tail(components), proposal, context, updated)
end

@inline function _tiled_device_address(mcs, subround, tile, local_proposal, draw)
    return _rng_address_unchecked(TiledProposalStream, mcs,
        Base.unsafe_trunc(UInt8, subround), Base.unsafe_trunc(UInt16, local_proposal),
        SiteEntity, tile, UInt64(0), UInt8(0), Base.unsafe_trunc(UInt16, draw))
end

@kernel function _tiled_prepare_mcs!(report, finite_snapshot, finite_deltas,
        finite_volumes, rng, seed, mcs, color_order, color_count, internal_rounds,
        mutable_sites)
    index = @index(Global, Linear)
    if index <= length(finite_volumes)
        @inbounds begin
            finite_snapshot[index] = finite_volumes[index]
            finite_deltas[index] = Int32(0)
        end
    end
    if index == 1
        @inbounds begin
            report[1] = mcs
            report[2] = UInt64(internal_rounds)
            report[3] = UInt64(mutable_sites)
            report[4] = UInt64(mutable_sites)
            for field in 5:_SEQUENTIAL_REPORT_FIELDS
                report[field] = UInt64(0)
            end
            count = Int(color_count)
            for color in 1:count
                color_order[color] = Base.unsafe_trunc(UInt32, color)
            end
            for color in count:-1:2
                address = _rng_address_unchecked(TiledOrderStream, mcs, UInt8(0),
                    UInt16(0), GlobalEntity, UInt32(0), UInt64(0), UInt8(0),
                    Base.unsafe_trunc(UInt16, count - color))
                selected = Int(bounded_uint(
                    rng, seed, address, Base.unsafe_trunc(UInt32, color))) + 1
                color_order[color], color_order[selected] =
                    color_order[selected], color_order[color]
            end
        end
    end
end

@kernel function _tiled_snapshot_cells!(finite_snapshot, finite_deltas, finite_volumes)
    cell = @index(Global, Linear)
    @inbounds begin
        finite_snapshot[cell] = finite_volumes[cell]
        finite_deltas[cell] = Int32(0)
    end
end

@kernel function _tiled_execute_batch!(tile_sites, tile_offsets, color_tiles,
        color_offsets, color_order, finite_snapshot, finite_deltas, scratch_ids,
        scratch_deltas, scratch_stride, state, components, algorithm, relation,
        rng, seed, mcs, ordinal, subround, batch_start, interval, report)
    local_tile = @index(Global, Linear)
    color = @inbounds color_order[Int(ordinal)]
    color_first = @inbounds color_offsets[Int(color)]
    color_stop = @inbounds color_offsets[Int(color) + 1]
    color_size = color_stop - color_first
    if local_tile <= color_size
        color_index = color_first + Base.unsafe_trunc(UInt32, local_tile - 1)
        tile = @inbounds color_tiles[Int(color_index)]
        first_site = @inbounds tile_offsets[Int(tile)]
        stop_site = @inbounds tile_offsets[Int(tile) + 1]
        site_count = stop_site - first_site
        if batch_start <= site_count
            scratch_start = (tile - UInt32(1)) * scratch_stride + UInt32(1)
            scratch_count = UInt32(0)
            batch_stop = min(site_count, batch_start + interval - UInt32(1))
            for local_proposal in batch_start:batch_stop
                recipient_address = _tiled_device_address(
                    mcs, subround, tile, local_proposal, UInt16(0))
                selected = bounded_uint(rng, seed, recipient_address, site_count)
                recipient = @inbounds tile_sites[Int(first_site + selected)]
                direction_address = _tiled_device_address(
                    mcs, subround, tile, local_proposal, UInt16(1))
                direction = bounded_uint(rng, seed, direction_address,
                    UInt32(direction_count(relation))) + UInt32(1)
                semantic_id = (UInt64(tile) << 32) | UInt64(local_proposal)
                attempt = construct_proposal_attempt(proposal_law(algorithm), state,
                    state.domain, relation, Int(recipient), direction, mcs, semantic_id)
                if attempt.outcome === SameOwnerAttempt
                    Atomix.@atomic report[6] += UInt64(1)
                    continue
                elseif attempt.outcome === BoundaryNullAttempt
                    Atomix.@atomic report[7] += UInt64(1)
                    continue
                elseif attempt.outcome === ImmutableRecipientAttempt
                    Atomix.@atomic report[8] += UInt64(1)
                    continue
                end
                Atomix.@atomic report[5] += UInt64(1)
                proposal = _copy_proposal_unchecked(attempt.recipient, attempt.donor,
                    attempt.losing, attempt.gaining, attempt.direction, attempt.mcs,
                    attempt.semantic_id, attempt.forward_multiplicity,
                    attempt.reverse_multiplicity)
                transaction = _stage_copy_transaction_unchecked(
                    state, state.boundary_tracker, proposal; moment_tracker = nothing)
                context = TiledDeviceEnergyContext(state, finite_snapshot, scratch_ids,
                    scratch_deltas, scratch_start, scratch_count)
                T = typeof(algorithm.temperature)
                delta_h = T(_tiled_device_energy(
                    components.energies, proposal, context, zero(T)))
                inputs = AcceptanceInputs(delta_h, proposal)
                probability = _acceptance_probability(
                    ConventionalMetropolis(), inputs, algorithm.temperature)
                acceptance_address = _tiled_device_address(
                    mcs, subround, tile, local_proposal, UInt16(2))
                draw = uniform_open01(T, rng, seed, acceptance_address)
                if draw < probability
                    delta = transaction.trackers
                    if delta.losing_cell != 0
                        scratch_count = _tiled_add_scratch_delta!(scratch_ids,
                            scratch_deltas, scratch_start, scratch_count,
                            scratch_stride, delta.losing_cell, Int32(-1))
                    else
                        Atomix.@atomic state.trackers.medium_volumes[
                            Int(delta.losing_medium)] -= Int32(1)
                    end
                    if delta.gaining_cell != 0
                        scratch_count = _tiled_add_scratch_delta!(scratch_ids,
                            scratch_deltas, scratch_start, scratch_count,
                            scratch_stride, delta.gaining_cell, Int32(1))
                    else
                        Atomix.@atomic state.trackers.medium_volumes[
                            Int(delta.gaining_medium)] += Int32(1)
                    end
                    if delta.losing_cell != 0
                        Atomix.@atomic state.trackers.boundary_measures[
                            Int(delta.losing_cell)] += delta.losing_boundary
                    end
                    if delta.gaining_cell != 0
                        Atomix.@atomic state.trackers.boundary_measures[
                            Int(delta.gaining_cell)] += delta.gaining_boundary
                    end
                    @inbounds begin
                        state.core.ownership.tags[Int(proposal.recipient)] =
                            proposal.gaining.tag
                        state.core.ownership.ids[Int(proposal.recipient)] =
                            proposal.gaining.value
                    end
                    Atomix.@atomic report[12] += UInt64(1)
                else
                    Atomix.@atomic report[11] += UInt64(1)
                end
            end
            if !iszero(scratch_count)
                for slot in UInt32(0):scratch_count-UInt32(1)
                    index = scratch_start + slot
                    owner = @inbounds scratch_ids[Int(index)]
                    change = @inbounds scratch_deltas[Int(index)]
                    Atomix.@atomic finite_deltas[Int(owner)] += change
                end
            end
        end
    end
end

@kernel function _tiled_reconcile_cells!(state, finite_snapshot, finite_deltas)
    cell = @index(Global, Linear)
    updated = @inbounds finite_snapshot[cell] + finite_deltas[cell]
    @inbounds state.trackers.finite_volumes[cell] = updated
    if iszero(updated) && @inbounds(state.core.active[cell] != UInt8(0))
        @inbounds begin
            state.core.active[cell] = UInt8(0)
            state.core.cell_types[cell] = UInt32(0)
            _reset_columns!(Tuple(state.core.properties),
                Tuple(state.retirement_defaults), cell)
        end
    end
end

function perform_scientific_mcs!(integrator::ScientificPottsIntegrator{S, C, R,
        <:TiledCheckerboardCPM}, ::TiledCheckerboardCPM) where {S, C, R}
    next_mcs = integrator.mcs + UInt64(1)
    workspace = integrator.algorithm_workspace
    state = scientific_execution(integrator.state)
    cell_count = length(integrator.state.trackers.finite_volumes)
    internal_rounds = workspace.color_count * workspace.batches_per_color
    kernels = workspace.kernels
    launch!(integrator.plan, kernels.prepare, integrator.report_storage,
        workspace.finite_snapshot, workspace.finite_deltas,
        integrator.state.trackers.finite_volumes, integrator.rng, integrator.seed,
        next_mcs, workspace.color_order, workspace.color_count, internal_rounds,
        length(integrator.state.domain.storage.mutable_sites); ndrange = max(cell_count, 1))
    subround = UInt32(0)
    for ordinal in UInt32(1):workspace.color_count
        for batch in UInt32(1):workspace.batches_per_color
            subround += UInt32(1)
            subround > UInt32(1) && launch!(integrator.plan, kernels.snapshot,
                workspace.finite_snapshot, workspace.finite_deltas,
                integrator.state.trackers.finite_volumes; ndrange = max(cell_count, 1))
            batch_start = (batch - UInt32(1)) * workspace.switching_interval + UInt32(1)
            launch!(integrator.plan, kernels.execute, workspace.tile_sites,
                workspace.tile_offsets, workspace.color_tiles, workspace.color_offsets,
                workspace.color_order, workspace.finite_snapshot, workspace.finite_deltas,
                workspace.scratch_ids, workspace.scratch_deltas,
                workspace.scratch_stride, state, integrator.components,
                integrator.algorithm, integrator.proposal_relation, integrator.rng,
                integrator.seed, next_mcs, ordinal, subround, batch_start,
                workspace.switching_interval, integrator.report_storage;
                ndrange = Int(workspace.maximum_color_tiles))
            launch!(integrator.plan, kernels.reconcile, state, workspace.finite_snapshot,
                workspace.finite_deltas; ndrange = max(cell_count, 1))
        end
    end
    run_compiled_lifecycle!(integrator, integrator.lifecycle, next_mcs)
    integrator.mcs = next_mcs
    return integrator
end

_current_mcs_report(integrator::ScientificPottsIntegrator,
    ::TiledCheckerboardCPM) = _standard_current_mcs_report(integrator)
