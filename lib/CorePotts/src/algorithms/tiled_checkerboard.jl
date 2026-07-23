@enum TiledSharedMemoryMode::UInt8 begin
    TiledSharedMemoryAuto = 1
    TiledSharedMemoryRequired = 2
    TiledSharedMemoryDisabled = 3
end

function _tiled_shared_memory_mode(value::Symbol)
    value === :auto && return TiledSharedMemoryAuto
    value === :required && return TiledSharedMemoryRequired
    value === :disabled && return TiledSharedMemoryDisabled
    throw(ArgumentError(
        "shared_memory must be :auto, :required, or :disabled"))
end

"""Deterministic tile-local CPM with explicit snapshot and reconciliation subrounds."""
struct TiledCheckerboardCPM{T <: AbstractFloat, S, I} <: AbstractPottsAlgorithm
    temperature::T
    tile_size::S
    switching_interval::I
    shared_memory::TiledSharedMemoryMode
end

function TiledCheckerboardCPM(; temperature::AbstractFloat = 20.0f0,
        tile_size = nothing, switching_interval = nothing,
        shared_memory::Symbol = :auto)
    isfinite(temperature) && temperature >= zero(temperature) || throw(ArgumentError(
        "tiled checkerboard temperature must be finite and non-negative"))
    normalized_tile = if tile_size === nothing
        nothing
    else
        tile_size isa Tuple && length(tile_size) in (2, 3) || throw(ArgumentError(
            "tile_size must be nothing or a two-/three-dimensional tuple"))
        all(value -> value isa Integer && value > 0, tile_size) || throw(ArgumentError(
            "tile dimensions must be positive integers"))
        Tuple(Int(value) for value in tile_size)
    end
    normalized_interval = if switching_interval === nothing
        nothing
    else
        switching_interval isa Integer && switching_interval > 0 || throw(ArgumentError(
            "switching_interval must be nothing or a positive integer"))
        switching_interval <= typemax(UInt16) || throw(ArgumentError(
            "switching_interval must fit UInt16"))
        UInt16(switching_interval)
    end
    return TiledCheckerboardCPM(temperature, normalized_tile, normalized_interval,
        _tiled_shared_memory_mode(shared_memory))
end

component_identity(::TiledCheckerboardCPM) =
    ComponentIdentity(:tiled_checkerboard_cpm,
        TILED_CHECKERBOARD_EXPERIMENTAL_CONTRACT_VERSION, :algorithm)

algorithm_guarantees(::TiledCheckerboardCPM) = AlgorithmGuaranteeProfile(
    proposal_process = (
        recipient = :uniform_with_replacement_inside_active_tile,
        tile_order = :semantic_random_permutation_once_per_mcs,
        donor = :uniform_direction_with_boundary_no_ops,
    ),
    equilibrium_status = :not_claimed,
    kinetic_interpretation = :deterministic_subround_tile_local_cpm,
    transaction_semantics = (
        snapshot = :common_per_tile_color,
        conflicts = :disjoint_write_regions_with_halo_coloring,
        commit = :exact_subround_reconciliation,
    ),
    mcs_normalization = :exact_mutable_site_attempt_budget,
    reproducibility_scope = :strict_same_backend_run,
    compatible_component_scopes = (
        supported = (:tiled_snapshot_energy, :tiled_snapshot_drive,
            :tiled_snapshot_kinetic_modifier, :tiled_mechanical),
        rejected = (:undeclared_tiled_access, :unbounded_global_traversal),
    ),
    validation_evidence = (:tile_halo_coloring, :exact_accounting,
        :semantic_rng_identity, :strict_replay, :subround_reconciliation,
        :backend_conformance_matrix),
    backend_contract = (:cpu, :metal, :amdgpu),
    dimensions = (2, 3),
    api_status = :experimental,
    paper_scope = :non_paper,
)

function algorithm_component_compatibility(::TiledCheckerboardCPM,
        components::ScientificComponentSet, moment_tracker = nothing)
    messages = _scientific_interface_messages(components)
    isempty(components.constraints) || (messages = (messages...,
        "TiledCheckerboardCPM initial qualification rejects hard constraints",))
    moment_tracker === nothing || (messages = (messages...,
        "TiledCheckerboardCPM initial qualification rejects moment-dependent components",))
    for component in (components.energies..., components.drives...,
            components.kinetic_modifiers..., components.mechanics...)
        access = tiled_scientific_access(component)
        access isa TiledSnapshotAccess || (messages = (messages...,
            "TiledCheckerboardCPM component $(typeof(component)) has no tiled_scientific_access declaration",))
    end
    return messages
end

"""Host-side immutable description of one topology-derived tile and halo coloring."""
struct TiledLayout{N}
    dims::NTuple{N, Int}
    tile_size::NTuple{N, Int}
    tile_grid::NTuple{N, Int}
    periodic::NTuple{N, Bool}
    halo_radius::Int
    tile_colors::Vector{UInt16}
    color_tiles::Vector{UInt32}
    color_offsets::Vector{UInt32}
end

function _tiled_default_size(::Val{2})
    return (4, 4)
end

function _tiled_default_size(::Val{3})
    return (2, 2, 2)
end

function _tile_coordinate(grid, tile::Int)
    return Tuple(CartesianIndices(grid)[tile])
end

function _tiled_axis_separation(left::Int, right::Int, count::Int, periodic::Bool)
    direct = abs(left - right)
    return periodic ? min(direct, count - direct) : direct
end

function _tiled_tiles_conflict(left, right, grid, periodic, reach)
    all(dimension -> _tiled_axis_separation(left[dimension], right[dimension],
        grid[dimension], periodic[dimension]) <= reach[dimension], eachindex(grid))
end

function _tiled_greedy_coloring(grid::NTuple{N, Int}, periodic::NTuple{N, Bool},
        reach::NTuple{N, Int}) where {N}
    count = prod(grid)
    colors = zeros(UInt16, count)
    maximum_color = 0
    for tile in 1:count
        coordinate = _tile_coordinate(grid, tile)
        forbidden = falses(maximum_color + 1)
        for prior in 1:(tile - 1)
            prior_coordinate = _tile_coordinate(grid, prior)
            _tiled_tiles_conflict(coordinate, prior_coordinate, grid, periodic, reach) ||
                continue
            color = Int(colors[prior])
            color > length(forbidden) && resize!(forbidden, color)
            forbidden[color] = true
        end
        color = something(findfirst(!, forbidden), length(forbidden) + 1)
        color <= typemax(UInt16) || throw(ArgumentError(
            "tiled halo coloring exceeds the UInt16 color domain"))
        colors[tile] = UInt16(color)
        maximum_color = max(maximum_color, color)
    end
    ordered = UInt32[]
    offsets = UInt32[1]
    for color in 1:maximum_color
        for tile in 1:count
            colors[tile] == color && push!(ordered, UInt32(tile))
        end
        push!(offsets, UInt32(length(ordered) + 1))
    end
    return colors, ordered, offsets
end

function tiled_layout(algorithm::TiledCheckerboardCPM, dims::NTuple{N, <:Integer};
        halo_radius::Integer = 1,
        periodic::NTuple{N, Bool} = ntuple(_ -> false, N)) where {N}
    N in (2, 3) || throw(ArgumentError(
        "TiledCheckerboardCPM supports two- and three-dimensional layouts"))
    normalized_dims = ntuple(index -> Int(dims[index]), N)
    all(>(0), normalized_dims) || throw(ArgumentError(
        "tiled layout dimensions must be positive"))
    halo_radius >= 0 || throw(ArgumentError(
        "tiled halo radius must be non-negative"))
    chosen = algorithm.tile_size === nothing ? _tiled_default_size(Val(N)) :
             algorithm.tile_size
    length(chosen) == N || throw(ArgumentError(
        "configured tile dimensionality does not match the lattice"))
    tile_size = ntuple(index -> Int(chosen[index]), N)
    grid = ntuple(index -> cld(normalized_dims[index], tile_size[index]), N)
    reach = ntuple(index -> cld(Int(halo_radius), tile_size[index]), N)
    colors, ordered, offsets = _tiled_greedy_coloring(grid, periodic, reach)
    return TiledLayout(normalized_dims, tile_size, grid, periodic, Int(halo_radius),
        colors, ordered, offsets)
end

tiled_color(layout::TiledLayout, tile::Integer) = layout.tile_colors[Int(tile)]

function tiled_tile_sites(layout::TiledLayout{N}, tile::Integer) where {N}
    1 <= tile <= prod(layout.tile_grid) || throw(BoundsError(1:prod(layout.tile_grid), tile))
    tile_coordinate = _tile_coordinate(layout.tile_grid, Int(tile))
    first_site = ntuple(dimension ->
        (tile_coordinate[dimension] - 1) * layout.tile_size[dimension] + 1, N)
    last_site = ntuple(dimension -> min(layout.dims[dimension],
        first_site[dimension] + layout.tile_size[dimension] - 1), N)
    ranges = ntuple(dimension -> first_site[dimension]:last_site[dimension], N)
    linear = LinearIndices(layout.dims)
    return vec(UInt32[UInt32(linear[index]) for index in CartesianIndices(ranges)])
end

function tiled_color_order(rng::AbstractRNGContract, seed::Integer, mcs::Integer,
        layout::TiledLayout)
    0 <= seed <= typemax(UInt64) || throw(ArgumentError(
        "tiled RNG seed must fit UInt64"))
    0 <= mcs <= _RNG_MAX_MCS || throw(ArgumentError(
        "tiled RNG MCS exceeds the v1 address domain"))
    count = length(layout.color_offsets) - 1
    count <= 1024 || throw(ArgumentError(
        "tiled color order exceeds the v1 RNG draw domain"))
    order = collect(UInt16(1):UInt16(count))
    for color in count:-1:2
        address = RNGAddress(TiledOrderStream, UInt64(mcs), UInt8(0), UInt16(0),
            GlobalEntity, UInt32(0), UInt64(0), UInt8(0), UInt16(count - color))
        selected = Int(bounded_uint(rng, UInt64(seed), address, UInt32(color))) + 1
        order[color], order[selected] = order[selected], order[color]
    end
    return order
end

function tiled_rng_address(mcs::Integer, subround::Integer, tile::Integer,
        local_proposal::Integer; draw::Integer = 0,
        stream::RNGStream = TiledProposalStream)
    0 <= mcs <= _RNG_MAX_MCS || throw(ArgumentError(
        "tiled RNG MCS exceeds the v1 address domain"))
    0 <= subround <= typemax(UInt8) || throw(ArgumentError(
        "tiled RNG subround must fit UInt8"))
    1 <= tile <= typemax(UInt32) || throw(ArgumentError(
        "tiled RNG tile identity must be positive and fit UInt32"))
    1 <= local_proposal <= _RNG_MAX_OPERATION || throw(ArgumentError(
        "tiled local proposal identity exceeds the v1 RNG operation domain"))
    0 <= draw <= _RNG_MAX_DRAW || throw(ArgumentError(
        "tiled RNG draw identity exceeds the v1 RNG draw domain"))
    return RNGAddress(stream, UInt64(mcs), UInt8(subround), UInt16(local_proposal),
        SiteEntity, UInt32(tile), UInt64(0), UInt8(0), UInt16(draw))
end

"""Small host reference whose semantics are independent of optimized backend kernels."""
mutable struct TiledReferenceIntegrator{S <: LogicalPottsState,
        D <: CartesianDomain, R <: StaticCartesianRelation{<:ProposalRole},
        C <: ScientificComponentSet, A <: TiledCheckerboardCPM,
        G <: AbstractRNGContract, L <: TiledLayout}
    state::S
    domain::D
    proposal_relation::R
    components::C
    algorithm::A
    rng::G
    layout::L
    seed::UInt64
    mcs::UInt64
    last_report::Union{Nothing, ScientificMCSReport}
end

logical_state(integrator::TiledReferenceIntegrator) = integrator.state
current_mcs_report(integrator::TiledReferenceIntegrator) = integrator.last_report

function _tiled_relation_radius(relation::StaticCartesianRelation)
    radius = 0
    for direction in 1:direction_count(relation)
        offset = relation_offset(relation, direction)
        radius = max(radius, maximum(abs, offset))
    end
    return radius
end

function _tiled_required_halo(components::ScientificComponentSet, proposal_relation)
    radius = _tiled_relation_radius(proposal_relation)
    for component in (components.energies..., components.drives...,
            components.kinetic_modifiers..., components.mechanics...)
        access = tiled_scientific_access(component)
        access isa TiledSnapshotAccess || throw(ArgumentError(
            "component $(typeof(component)) has no tiled scientific access declaration"))
        radius = max(radius, Int(access.dependency_radius))
        for relation in access.relations
            radius = max(radius, _tiled_relation_radius(relation))
        end
    end
    return radius
end

"""Open logical-state energy hook used only by the executable tiled reference."""
tiled_reference_energy_change(component::AbstractEnergy, proposal::CopyProposal,
    state::LogicalPottsState, domain::CartesianDomain) =
    energy_change(component, proposal, state)

tiled_reference_energy_change(component::UnorderedContactHamiltonian,
    proposal::CopyProposal, state::LogicalPottsState, domain::CartesianDomain) =
    energy_change(component, proposal, state, domain)
tiled_reference_energy_change(component::QuadraticBoundaryHamiltonian,
    proposal::CopyProposal, state::LogicalPottsState, domain::CartesianDomain) =
    energy_change(component, proposal, state, domain)
tiled_reference_energy_change(component::ExternalFieldOccupancyHamiltonian,
    proposal::CopyProposal, state::LogicalPottsState, domain::CartesianDomain) =
    energy_change(component, proposal, state, domain)

@inline _tiled_reference_energy(::Tuple{}, proposal, state, domain, result) = result
@inline function _tiled_reference_energy(components::Tuple, proposal, state, domain, result)
    updated = result + tiled_reference_energy_change(
        first(components), proposal, state, domain)
    return _tiled_reference_energy(
        Base.tail(components), proposal, state, domain, updated)
end

@inline _tiled_reference_drive(::Tuple{}, proposal, state, domain, result) = result
@inline function _tiled_reference_drive(components::Tuple, proposal, state, domain, result)
    updated = result + drive_log_bias(first(components), proposal, state, domain)
    return _tiled_reference_drive(Base.tail(components), proposal, state, domain, updated)
end

@inline _tiled_reference_modifier(::Tuple{}, proposal, state, kinetic, barrier) =
    (kinetic = kinetic, barrier = barrier)
@inline function _tiled_reference_modifier(
        components::Tuple, proposal, state, kinetic, barrier)
    component = first(components)
    updated = component isa PositiveYield ?
        (kinetic = kinetic, barrier = barrier + component.barrier) :
        (kinetic = kinetic, barrier = barrier)
    return _tiled_reference_modifier(Base.tail(components), proposal, state,
        updated.kinetic, updated.barrier)
end

function _tiled_periodic_axes(domain::CartesianDomain{N}) where {N}
    return ntuple(index ->
        domain.boundaries[index].negative isa PeriodicBoundary, N)
end

function init_tiled_reference(state::LogicalPottsState, domain::CartesianDomain,
        proposal_relation::StaticCartesianRelation{<:ProposalRole},
        components::ScientificComponentSet, algorithm::TiledCheckerboardCPM;
        seed::Integer = 0, rng::AbstractRNGContract = Philox4x32x10V1())
    lattice_size(state) == domain.dims || throw(ArgumentError(
        "tiled reference state and domain dimensions must match"))
    0 <= seed <= typemax(UInt64) || throw(ArgumentError(
        "tiled reference seed must fit UInt64"))
    messages = algorithm_component_compatibility(algorithm, components)
    isempty(messages) || throw(ArgumentError(join(messages, "; ")))
    isempty(components.constraints) && isempty(components.mechanics) ||
        throw(ArgumentError(
            "the tiled reference rejects constraints and mechanical components"))
    halo = _tiled_required_halo(components, proposal_relation)
    layout = tiled_layout(algorithm, domain.dims; halo_radius = halo,
        periodic = _tiled_periodic_axes(domain))
    length(layout.color_offsets) - 1 <= typemax(UInt8) || throw(ArgumentError(
        "tiled reference color count exceeds the v1 RNG subround domain"))
    return TiledReferenceIntegrator(state, domain, proposal_relation, components,
        algorithm, rng, layout, UInt64(seed), UInt64(0), nothing)
end

function _tiled_mutable_sites(layout, domain, tile)
    return UInt32[site for site in tiled_tile_sites(layout, tile)
        if domain.mutable_mask[Int(site)]]
end

function _tiled_reconcile_states(snapshot::LogicalPottsState, layout::TiledLayout,
        tile_states)
    candidate = _copy_logical_state(snapshot)
    for (tile, tile_state) in tile_states
        for site in tiled_tile_sites(layout, tile)
            candidate._owners[Int(site)] = tile_state._owners[Int(site)]
        end
    end
    rebuild_derived_state!(candidate)
    return logical_state(retire_zero_volume(candidate))
end

function step_tiled_reference!(integrator::TiledReferenceIntegrator)
    next_mcs = integrator.mcs + UInt64(1)
    color_order = tiled_color_order(
        integrator.rng, integrator.seed, next_mcs, integrator.layout)
    # A compact host-only accumulator keeps mutable diagnostics out of the public execution
    # contract while the resulting report remains typed and backend-independent.
    values = zeros(UInt64, 8)
    interval = integrator.algorithm.switching_interval === nothing ?
               prod(integrator.layout.tile_size) :
               Int(integrator.algorithm.switching_interval)
    maximum_attempts = maximum((length(_tiled_mutable_sites(
        integrator.layout, integrator.domain, tile))
        for tile in 1:prod(integrator.layout.tile_grid)); init = 0)
    subround = 0
    for color in color_order
        first_tile = Int(integrator.layout.color_offsets[Int(color)])
        stop_tile = Int(integrator.layout.color_offsets[Int(color) + 1]) - 1
        tiles = integrator.layout.color_tiles[first_tile:stop_tile]
        site_groups = [_tiled_mutable_sites(
            integrator.layout, integrator.domain, Int(tile)) for tile in tiles]
        for batch_start in 1:interval:maximum_attempts
            subround += 1
            subround <= typemax(UInt8) || throw(ArgumentError(
                "tiled switching policy exceeds the v1 RNG subround domain"))
            snapshot = integrator.state
            tile_states = Tuple{Int, typeof(snapshot)}[]
            for (tile_value, mutable_sites) in zip(tiles, site_groups)
                isempty(mutable_sites) && continue
                tile = Int(tile_value)
                tile_state = snapshot
                batch_stop = min(length(mutable_sites), batch_start + interval - 1)
                for local_proposal in batch_start:batch_stop
                    recipient_address = tiled_rng_address(next_mcs, subround,
                        tile, local_proposal; draw = 0)
                    recipient_index = Int(bounded_uint(integrator.rng, integrator.seed,
                        recipient_address, UInt32(length(mutable_sites)))) + 1
                    recipient = Int(mutable_sites[recipient_index])
                    direction_address = tiled_rng_address(next_mcs, subround,
                        tile, local_proposal; draw = 1)
                    direction = Int(bounded_uint(integrator.rng, integrator.seed,
                        direction_address,
                        UInt32(direction_count(integrator.proposal_relation)))) + 1
                    semantic_id = (UInt64(tile) << 32) | UInt64(local_proposal)
                    attempt = construct_copy_attempt(tile_state, integrator.domain,
                        integrator.proposal_relation, recipient, direction;
                        mcs = next_mcs, semantic_id)
                    values[1] += 1
                    values[2] += 1
                    if attempt.outcome === SameOwnerAttempt
                        values[4] += 1
                    elseif attempt.outcome === BoundaryNullAttempt
                        values[5] += 1
                    elseif attempt.outcome === ImmutableRecipientAttempt
                        values[6] += 1
                    else
                        values[3] += 1
                        proposal = actionable_proposal(attempt)
                        T = typeof(integrator.algorithm.temperature)
                        delta_h = T(_tiled_reference_energy(
                            integrator.components.energies, proposal, tile_state,
                            integrator.domain, zero(T)))
                        drive = T(_tiled_reference_drive(
                            integrator.components.drives, proposal, tile_state,
                            integrator.domain, zero(T)))
                        modifier = _tiled_reference_modifier(
                            integrator.components.kinetic_modifiers, proposal,
                            tile_state, zero(T), zero(T))
                        inputs = AcceptanceInputs(delta_h, proposal;
                            drive_log_bias = drive,
                            kinetic_modifier = modifier.kinetic,
                            yield_barrier = modifier.barrier)
                        acceptance_address = tiled_rng_address(next_mcs, subround,
                            tile, local_proposal; draw = 2)
                        draw = uniform_open01(T, integrator.rng, integrator.seed,
                            acceptance_address)
                        if acceptance_decision(ConventionalMetropolis(), inputs,
                                integrator.algorithm.temperature, draw)
                            values[8] += 1
                            tile_state = logical_state(
                                commit_copy_proposal(tile_state, proposal))
                        else
                            values[7] += 1
                        end
                    end
                end
                push!(tile_states, (tile, tile_state))
            end
            integrator.state = _tiled_reconcile_states(
                snapshot, integrator.layout, tile_states)
        end
    end
    integrator.mcs = next_mcs
    integrator.last_report = ScientificMCSReport(next_mcs, UInt64(subround),
        values[1], values[2], values[3], values[4], values[5], values[6], UInt64(0),
        UInt64(0), values[7], values[8])
    return integrator
end
