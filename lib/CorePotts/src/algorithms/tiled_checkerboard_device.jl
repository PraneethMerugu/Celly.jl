"""Resident workspace shared by device-global and cooperative local-memory tiled paths."""
struct TiledDeviceWorkspace{S, F, C, O, V, D, I, B, L, K}
    tile_sites::S
    tile_offsets::F
    color_tiles::C
    color_offsets::F
    color_order::O
    finite_snapshot::V
    finite_deltas::D
    boundary_snapshot::B
    boundary_deltas::D
    scratch_ids::I
    scratch_deltas::D
    tile_counters::I
    layout::L
    kernels::K
    color_count::UInt32
    maximum_color_tiles::UInt32
    maximum_tile_sites::UInt32
    scratch_stride::UInt32
    switching_interval::UInt32
    batches_per_color::UInt32
    shared_halo_capacity::UInt32
    uses_shared_memory::Bool
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
    shared_halo_dims = ntuple(dimension ->
        layout.tile_size[dimension] + 2 * layout.halo_radius,
        length(layout.tile_size))
    shared_halo_capacity = prod(shared_halo_dims)
    shared_memory_eligible = shared_halo_capacity <= plan.block_size
    algorithm.shared_memory === TiledSharedMemoryRequired &&
        !shared_memory_eligible && throw(ArgumentError(
            "shared_memory=:required needs $(shared_halo_capacity) work items for the " *
            "tile halo, exceeding the configured block size $(plan.block_size)"))
    uses_shared_memory = algorithm.shared_memory === TiledSharedMemoryRequired ||
        (algorithm.shared_memory === TiledSharedMemoryAuto &&
         !(plan.backend isa KernelAbstractions.CPU) && shared_memory_eligible)

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
    boundary_snapshot = recorded(similar(prototype,
        eltype(state.trackers.boundary_measures),
        length(state.trackers.boundary_measures)))
    boundary_deltas = recorded(similar(
        prototype, Int32, length(state.trackers.boundary_measures)))
    scratch_ids = recorded(similar(
        prototype, UInt32, prod(layout.tile_grid) * scratch_stride))
    scratch_deltas = recorded(similar(
        prototype, Int32, prod(layout.tile_grid) * scratch_stride))
    tile_counters = recorded(similar(
        prototype, UInt32, prod(layout.tile_grid) * 8))
    if !(plan.backend isa KernelAbstractions.CPU)
        record_transfer!(plan, :host_to_device)
    end
    cell_count = length(state.trackers.finite_volumes)
    prepare_size = max(cell_count, length(tile_counters), 1)
    execute_kernel = uses_shared_memory ?
        _tiled_execute_shared_batch!(plan.backend, shared_halo_capacity) :
        _execution_kernel(plan, _tiled_execute_batch!, maximum_color_tiles)
    kernels = (
        prepare = _execution_kernel(plan, _tiled_prepare_mcs!, prepare_size),
        snapshot = _execution_kernel(plan, _tiled_snapshot_cells!, max(cell_count, 1)),
        execute = execute_kernel,
        reconcile = _execution_kernel(
            plan, _tiled_reconcile_cells!, max(cell_count, 1)),
        report = _execution_kernel(plan, _tiled_reduce_report!, 1),
    )
    return TiledDeviceWorkspace(tile_sites, tile_offsets, color_tiles, color_offsets,
        color_order, finite_snapshot, finite_deltas, boundary_snapshot,
        boundary_deltas, scratch_ids, scratch_deltas, tile_counters, layout,
        kernels, UInt32(length(layout.color_offsets) - 1),
        UInt32(maximum_color_tiles), UInt32(maximum_tile_sites), UInt32(scratch_stride),
        UInt32(interval), UInt32(batches), UInt32(shared_halo_capacity),
        uses_shared_memory)
end

function _validate_tiled_device_components(components, state, moment_tracker, algorithm)
    isempty(components.constraints) && isempty(components.mechanics) ||
        throw(ArgumentError(
            "the resident tiled path rejects constraints and mechanical components"))
    moment_tracker === nothing || throw(ArgumentError(
        "the resident tiled vertical slice currently rejects moment-dependent components"))
    state.trackers.moments isa NoMomentStorage || throw(ArgumentError(
        "TiledCheckerboardCPM requires state compiled without moment storage"))
    eltype(state.trackers.boundary_measures) <: Integer || throw(ArgumentError(
        "the resident tiled vertical slice requires an exact integer boundary tracker"))
    all(component -> component isa Union{QuadraticVolumeHamiltonian,
            UnorderedContactHamiltonian, ExternalFieldOccupancyHamiltonian},
        components.energies) || throw(ArgumentError(
        "the resident tiled path qualifies volume, adhesion, and prescribed-field energies"))
    all(component -> component isa ChemotaxisDrive, components.drives) ||
        throw(ArgumentError(
            "the resident tiled path qualifies prescribed-field chemotaxis drives"))
    all(component -> component isa PositiveYield,
        components.kinetic_modifiers) || throw(ArgumentError(
            "the resident tiled path qualifies PositiveYield kinetic modifiers"))
    accesses = map(tiled_scientific_access, (components.energies...,
        components.drives..., components.kinetic_modifiers...))
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

struct NoTiledLocalOwnership end

struct TiledLocalOwnership{N, T, I}
    tags::T
    ids::I
    dims::NTuple{N, Int}
    tile_grid::NTuple{N, Int}
    tile_size::NTuple{N, Int}
    periodic::NTuple{N, Bool}
    tile::UInt32
    halo::UInt32
end

@inline function _tiled_local_slot(cache::TiledLocalOwnership{N}, site::Integer) where {N}
    coordinates = _site_coordinates(site, cache.dims)
    tile_coordinates = _site_coordinates(cache.tile, cache.tile_grid)
    halo = Int32(cache.halo)
    slot = Int32(1)
    stride = Int32(1)
    for dimension in 1:N
        origin = tile_coordinates[dimension] * Int32(cache.tile_size[dimension])
        delta = coordinates[dimension] - origin
        if cache.periodic[dimension]
            extent = Int32(cache.dims[dimension])
            lower = -halo
            upper = Int32(cache.tile_size[dimension] - 1) + halo
            while delta < lower
                delta += extent
            end
            while delta > upper
                delta -= extent
            end
        end
        slot += (delta + halo) * stride
        stride *= Int32(cache.tile_size[dimension]) + Int32(2) * halo
    end
    return slot
end

@inline _tiled_contact_owner(::NoTiledLocalOwnership, state, neighbor) =
    _realized_owner(state, neighbor)
@inline function _tiled_contact_owner(
        cache::TiledLocalOwnership, state, neighbor::RealizedNeighbor)
    neighbor.kind === MutableNeighbor || return _fixed_owner_unchecked(neighbor)
    slot = _tiled_local_slot(cache, neighbor.site)
    return _owner_ref_unchecked(
        @inbounds(cache.tags[Int(slot)]), @inbounds(cache.ids[Int(slot)]))
end

@inline _tiled_update_local!(::NoTiledLocalOwnership, site, owner) = nothing
@inline function _tiled_update_local!(cache::TiledLocalOwnership, site, owner)
    slot = _tiled_local_slot(cache, site)
    @inbounds begin
        cache.tags[Int(slot)] = owner.tag
        cache.ids[Int(slot)] = owner.value
    end
    return nothing
end

struct TiledDeviceEnergyContext{S, V, I, D, L}
    state::S
    finite_snapshot::V
    scratch_ids::I
    scratch_deltas::D
    scratch_start::UInt32
    scratch_count::UInt32
    local_ownership::L
end

@inline _contact_neighbor_owner(context::TiledDeviceEnergyContext, state,
        neighbor::RealizedNeighbor) =
    _tiled_contact_owner(context.local_ownership, state, neighbor)

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
    _contact_energy_change(
        component, proposal, context.state, context.state.domain, context)
@inline tiled_device_energy_change(component::ExternalFieldOccupancyHamiltonian,
    proposal::CopyProposal, context::TiledDeviceEnergyContext) =
    energy_change(component, proposal, context.state, context.state.domain)

@inline _tiled_device_energy(::Tuple{}, proposal, context, result) = result
@inline function _tiled_device_energy(components::Tuple, proposal, context, result)
    updated = result + tiled_device_energy_change(first(components), proposal, context)
    return _tiled_device_energy(Base.tail(components), proposal, context, updated)
end

@inline _tiled_device_drive(::Tuple{}, proposal, context, result) = result
@inline function _tiled_device_drive(components::Tuple, proposal, context, result)
    component = first(components)
    updated = result + drive_log_bias(
        component, proposal, context.state, context.state.domain)
    return _tiled_device_drive(Base.tail(components), proposal, context, updated)
end

@inline _tiled_device_modifier(::Tuple{}, proposal, context, kinetic, barrier) =
    (kinetic = kinetic, barrier = barrier)
@inline function _tiled_device_modifier(
        components::Tuple, proposal, context, kinetic, barrier)
    component = first(components)
    updated = component isa PositiveYield ?
        (kinetic = kinetic, barrier = barrier + component.barrier) :
        (kinetic = kinetic, barrier = barrier)
    return _tiled_device_modifier(Base.tail(components), proposal, context,
        updated.kinetic, updated.barrier)
end

@inline function _tiled_device_address(mcs, subround, tile, local_proposal, draw)
    return _rng_address_unchecked(TiledProposalStream, mcs,
        Base.unsafe_trunc(UInt8, subround), Base.unsafe_trunc(UInt16, local_proposal),
        SiteEntity, tile, UInt64(0), UInt8(0), Base.unsafe_trunc(UInt16, draw))
end

@kernel function _tiled_prepare_mcs!(report, finite_snapshot, finite_deltas,
        finite_volumes, boundary_snapshot, boundary_deltas, boundary_measures,
        tile_counters, rng, seed, mcs, color_order, color_count, internal_rounds,
        mutable_sites)
    index = @index(Global, Linear)
    if index <= length(finite_volumes)
        @inbounds begin
            finite_snapshot[index] = finite_volumes[index]
            finite_deltas[index] = Int32(0)
            boundary_snapshot[index] = boundary_measures[index]
            boundary_deltas[index] = Int32(0)
        end
    end
    index <= length(tile_counters) && @inbounds(tile_counters[index] = UInt32(0))
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

@kernel function _tiled_snapshot_cells!(finite_snapshot, finite_deltas, finite_volumes,
        boundary_snapshot, boundary_deltas, boundary_measures)
    cell = @index(Global, Linear)
    @inbounds begin
        finite_snapshot[cell] = finite_volumes[cell]
        finite_deltas[cell] = Int32(0)
        boundary_snapshot[cell] = boundary_measures[cell]
        boundary_deltas[cell] = Int32(0)
    end
end

@inline function _tiled_execute_tile_batch!(tile, tile_sites, tile_offsets,
        finite_snapshot, finite_deltas, scratch_ids, scratch_deltas, scratch_stride,
        boundary_deltas, tile_counters, state, components, algorithm, relation, rng,
        seed, mcs, subround, batch_start, interval, local_ownership)
        first_site = @inbounds tile_offsets[Int(tile)]
        stop_site = @inbounds tile_offsets[Int(tile) + 1]
        site_count = stop_site - first_site
        if batch_start <= site_count
            realized = UInt32(0)
            same_owner = UInt32(0)
            boundary = UInt32(0)
            immutable = UInt32(0)
            conflicts = UInt32(0)
            constraint_rejections = UInt32(0)
            acceptance_rejections = UInt32(0)
            accepted = UInt32(0)
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
                    same_owner += UInt32(1)
                    continue
                elseif attempt.outcome === BoundaryNullAttempt
                    boundary += UInt32(1)
                    continue
                elseif attempt.outcome === ImmutableRecipientAttempt
                    immutable += UInt32(1)
                    continue
                end
                realized += UInt32(1)
                proposal = _copy_proposal_unchecked(attempt.recipient, attempt.donor,
                    attempt.losing, attempt.gaining, attempt.direction, attempt.mcs,
                    attempt.semantic_id, attempt.forward_multiplicity,
                    attempt.reverse_multiplicity)
                transaction = _stage_copy_transaction_unchecked(
                    state, state.boundary_tracker, proposal; moment_tracker = nothing)
                context = TiledDeviceEnergyContext(state, finite_snapshot, scratch_ids,
                    scratch_deltas, scratch_start, scratch_count, local_ownership)
                T = typeof(algorithm.temperature)
                delta_h = T(_tiled_device_energy(
                    components.energies, proposal, context, zero(T)))
                drive = T(_tiled_device_drive(
                    components.drives, proposal, context, zero(T)))
                modifier = _tiled_device_modifier(components.kinetic_modifiers,
                    proposal, context, zero(T), zero(T))
                inputs = AcceptanceInputs(delta_h, proposal;
                    drive_log_bias = drive,
                    kinetic_modifier = modifier.kinetic,
                    yield_barrier = modifier.barrier)
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
                        Atomix.@atomic boundary_deltas[
                            Int(delta.losing_cell)] += Int32(delta.losing_boundary)
                    end
                    if delta.gaining_cell != 0
                        Atomix.@atomic boundary_deltas[
                            Int(delta.gaining_cell)] += Int32(delta.gaining_boundary)
                    end
                    @inbounds begin
                        state.core.ownership.tags[Int(proposal.recipient)] =
                            proposal.gaining.tag
                        state.core.ownership.ids[Int(proposal.recipient)] =
                            proposal.gaining.value
                    end
                    _tiled_update_local!(
                        local_ownership, proposal.recipient, proposal.gaining)
                    accepted += UInt32(1)
                else
                    acceptance_rejections += UInt32(1)
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
            counter_start = (tile - UInt32(1)) * UInt32(8)
            @inbounds begin
                tile_counters[Int(counter_start + UInt32(1))] += realized
                tile_counters[Int(counter_start + UInt32(2))] += same_owner
                tile_counters[Int(counter_start + UInt32(3))] += boundary
                tile_counters[Int(counter_start + UInt32(4))] += immutable
                tile_counters[Int(counter_start + UInt32(5))] += conflicts
                tile_counters[Int(counter_start + UInt32(6))] += constraint_rejections
                tile_counters[Int(counter_start + UInt32(7))] += acceptance_rejections
                tile_counters[Int(counter_start + UInt32(8))] += accepted
            end
        end
end

@kernel function _tiled_execute_batch!(tile_sites, tile_offsets, color_tiles,
        color_offsets, color_order, finite_snapshot, finite_deltas, scratch_ids,
        scratch_deltas, scratch_stride, boundary_deltas, tile_counters, state,
        components, algorithm, relation, rng, seed, mcs, ordinal, subround,
        batch_start, interval)
    local_tile = @index(Global, Linear)
    color = @inbounds color_order[Int(ordinal)]
    color_first = @inbounds color_offsets[Int(color)]
    color_stop = @inbounds color_offsets[Int(color) + 1]
    color_size = color_stop - color_first
    if local_tile <= color_size
        color_index = color_first + Base.unsafe_trunc(UInt32, local_tile - 1)
        tile = @inbounds color_tiles[Int(color_index)]
        _tiled_execute_tile_batch!(tile, tile_sites, tile_offsets, finite_snapshot,
            finite_deltas, scratch_ids, scratch_deltas, scratch_stride,
            boundary_deltas, tile_counters, state, components, algorithm, relation,
            rng, seed, mcs, subround, batch_start, interval,
            NoTiledLocalOwnership())
    end
end

@inline function _tiled_load_local_ownership!(local_tags, local_ids, lane,
        state, dims::NTuple{N, Int}, tile_grid::NTuple{N, Int},
        tile_size::NTuple{N, Int}, periodic::NTuple{N, Bool}, tile, halo) where {N}
    halo_dims = ntuple(dimension -> tile_size[dimension] + 2 * Int(halo), Val(N))
    local_coordinates = _site_coordinates(lane, halo_dims)
    tile_coordinates = _site_coordinates(tile, tile_grid)
    coordinates = SVector{N, Int32}(ntuple(_ -> Int32(0), Val(N)))
    valid = true
    for dimension in 1:N
        coordinate = tile_coordinates[dimension] * Int32(tile_size[dimension]) +
                     local_coordinates[dimension] - Int32(halo)
        if periodic[dimension]
            extent = Int32(dims[dimension])
            while coordinate < Int32(0)
                coordinate += extent
            end
            while coordinate >= extent
                coordinate -= extent
            end
        else
            valid &= Int32(0) <= coordinate < Int32(dims[dimension])
        end
        coordinates = setindex(coordinates, coordinate, dimension)
    end
    if valid
        site = _linear_index(coordinates, dims)
        @inbounds begin
            local_tags[lane] = state.core.ownership.tags[Int(site)]
            local_ids[lane] = state.core.ownership.ids[Int(site)]
        end
    else
        @inbounds begin
            local_tags[lane] = UInt8(0)
            local_ids[lane] = UInt32(0)
        end
    end
    return nothing
end

@kernel function _tiled_execute_shared_batch!(tile_sites, tile_offsets, color_tiles,
        color_offsets, color_order, finite_snapshot, finite_deltas, scratch_ids,
        scratch_deltas, scratch_stride, boundary_deltas, tile_counters, state,
        components, algorithm, relation, rng, seed, mcs, ordinal, subround,
        batch_start, interval, dims, tile_grid, tile_size, periodic, halo)
    local_tile = @index(Group, Linear)
    lane = @index(Local, Linear)
    group_size = @uniform prod(@groupsize())
    local_tags = @localmem UInt8 (group_size,)
    local_ids = @localmem UInt32 (group_size,)
    color = @inbounds color_order[Int(ordinal)]
    color_first = @inbounds color_offsets[Int(color)]
    color_stop = @inbounds color_offsets[Int(color) + 1]
    color_size = color_stop - color_first
    tile = UInt32(1)
    if local_tile <= color_size
        color_index = color_first + Base.unsafe_trunc(UInt32, local_tile - 1)
        tile = @inbounds color_tiles[Int(color_index)]
    end
    _tiled_load_local_ownership!(local_tags, local_ids, lane, state, dims,
        tile_grid, tile_size, periodic, tile, halo)
    @synchronize
    lane_after_load = @index(Local, Linear)
    local_tile_after_load = @index(Group, Linear)
    color_after_load = @inbounds color_order[Int(ordinal)]
    color_first_after_load = @inbounds color_offsets[Int(color_after_load)]
    color_stop_after_load = @inbounds color_offsets[Int(color_after_load) + 1]
    color_size_after_load = color_stop_after_load - color_first_after_load
    if lane_after_load == 1 && local_tile_after_load <= color_size_after_load
        color_index_after_load = color_first_after_load +
            Base.unsafe_trunc(UInt32, local_tile_after_load - 1)
        tile_after_load = @inbounds color_tiles[Int(color_index_after_load)]
        local_ownership = TiledLocalOwnership(local_tags, local_ids, dims,
            tile_grid, tile_size, periodic, tile_after_load, UInt32(halo))
        _tiled_execute_tile_batch!(tile_after_load, tile_sites, tile_offsets, finite_snapshot,
            finite_deltas, scratch_ids, scratch_deltas, scratch_stride,
            boundary_deltas, tile_counters, state, components, algorithm, relation,
            rng, seed, mcs, subround, batch_start, interval, local_ownership)
    end
end

@kernel function _tiled_reconcile_cells!(state, finite_snapshot, finite_deltas,
        boundary_snapshot, boundary_deltas)
    cell = @index(Global, Linear)
    updated = @inbounds finite_snapshot[cell] + finite_deltas[cell]
    @inbounds begin
        state.trackers.finite_volumes[cell] = updated
        state.trackers.boundary_measures[cell] =
            boundary_snapshot[cell] + boundary_deltas[cell]
    end
    if iszero(updated) && @inbounds(state.core.active[cell] != UInt8(0))
        @inbounds begin
            state.core.active[cell] = UInt8(0)
            state.core.cell_types[cell] = UInt32(0)
            _reset_columns!(Tuple(state.core.properties),
                Tuple(state.retirement_defaults), cell)
        end
    end
end

@kernel function _tiled_reduce_report!(report, tile_counters)
    index = @index(Global, Linear)
    if index == 1
        totals = ntuple(_ -> UInt64(0), 8)
        tiles = length(tile_counters) ÷ 8
        for tile in 1:tiles
            start = (tile - 1) * 8
            totals = ntuple(field -> totals[field] +
                UInt64(@inbounds(tile_counters[start + field])), 8)
        end
        @inbounds for field in 1:8
            report[field + 4] = totals[field]
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
    prepare_size = max(cell_count, length(workspace.tile_counters), 1)
    launch!(integrator.plan, kernels.prepare, integrator.report_storage,
        workspace.finite_snapshot, workspace.finite_deltas,
        integrator.state.trackers.finite_volumes, workspace.boundary_snapshot,
        workspace.boundary_deltas, integrator.state.trackers.boundary_measures,
        workspace.tile_counters, integrator.rng, integrator.seed, next_mcs,
        workspace.color_order, workspace.color_count, internal_rounds,
        length(integrator.state.domain.storage.mutable_sites); ndrange = prepare_size)
    subround = UInt32(0)
    for ordinal in UInt32(1):workspace.color_count
        for batch in UInt32(1):workspace.batches_per_color
            subround += UInt32(1)
            subround > UInt32(1) && launch!(integrator.plan, kernels.snapshot,
                workspace.finite_snapshot, workspace.finite_deltas,
                integrator.state.trackers.finite_volumes, workspace.boundary_snapshot,
                workspace.boundary_deltas, integrator.state.trackers.boundary_measures;
                ndrange = max(cell_count, 1))
            batch_start = (batch - UInt32(1)) * workspace.switching_interval + UInt32(1)
            if workspace.uses_shared_memory
                layout = workspace.layout
                launch!(integrator.plan, kernels.execute, workspace.tile_sites,
                    workspace.tile_offsets, workspace.color_tiles,
                    workspace.color_offsets, workspace.color_order,
                    workspace.finite_snapshot, workspace.finite_deltas,
                    workspace.scratch_ids, workspace.scratch_deltas,
                    workspace.scratch_stride, workspace.boundary_deltas,
                    workspace.tile_counters, state, integrator.components,
                    integrator.algorithm, integrator.proposal_relation, integrator.rng,
                    integrator.seed, next_mcs, ordinal, subround, batch_start,
                    workspace.switching_interval, layout.dims, layout.tile_grid,
                    layout.tile_size, layout.periodic, UInt32(layout.halo_radius);
                    ndrange = Int(workspace.maximum_color_tiles *
                                  workspace.shared_halo_capacity))
            else
                launch!(integrator.plan, kernels.execute, workspace.tile_sites,
                    workspace.tile_offsets, workspace.color_tiles,
                    workspace.color_offsets, workspace.color_order,
                    workspace.finite_snapshot, workspace.finite_deltas,
                    workspace.scratch_ids, workspace.scratch_deltas,
                    workspace.scratch_stride, workspace.boundary_deltas,
                    workspace.tile_counters, state, integrator.components,
                    integrator.algorithm, integrator.proposal_relation, integrator.rng,
                    integrator.seed, next_mcs, ordinal, subround, batch_start,
                    workspace.switching_interval;
                    ndrange = Int(workspace.maximum_color_tiles))
            end
            launch!(integrator.plan, kernels.reconcile, state, workspace.finite_snapshot,
                workspace.finite_deltas, workspace.boundary_snapshot,
                workspace.boundary_deltas; ndrange = max(cell_count, 1))
        end
    end
    launch!(integrator.plan, kernels.report, integrator.report_storage,
        workspace.tile_counters; ndrange = 1)
    run_compiled_lifecycle!(integrator, integrator.lifecycle, next_mcs)
    integrator.mcs = next_mcs
    return integrator
end

_current_mcs_report(integrator::ScientificPottsIntegrator,
    ::TiledCheckerboardCPM) = _standard_current_mcs_report(integrator)
