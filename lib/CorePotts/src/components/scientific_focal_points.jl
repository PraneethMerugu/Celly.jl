"""Unwrapped coordinate moments for an explicit connected finite-cell subset."""
struct UnwrappedMomentTracker{T <: AbstractFloat,
    R <: StaticCartesianRelation{<:ConnectivityRole}, I <: Tuple} <: AbstractTracker
    relation::R
    tracked_ids::I
    track_all::Bool
end

function UnwrappedMomentTracker(relation::StaticCartesianRelation{<:ConnectivityRole}, ids;
        number_type::Type{T} = Float64) where {T <: AbstractFloat}
    tracked = Tuple(sort!(unique!(UInt32[value(CellID(id)) for id in ids])))
    isempty(tracked) &&
        throw(ArgumentError("an unwrapped-moment tracker requires finite cells"))
    return UnwrappedMomentTracker{T, typeof(relation), typeof(tracked)}(
        relation, tracked, false)
end


function UnwrappedMomentTracker(relation::StaticCartesianRelation{<:ConnectivityRole};
        number_type::Type{T} = Float64) where {T <: AbstractFloat}
    return UnwrappedMomentTracker{T, typeof(relation), Tuple{}}(
        relation, (), true)
end

function component_identity(::UnwrappedMomentTracker)
    ComponentIdentity(:unwrapped_coordinate_moments, v"1.0.0", :tracker)
end
required_relations(::UnwrappedMomentTracker) = (:connectivity,)

struct UnwrappedMomentStorage{N, T <: AbstractFloat, M, S, Q}
    tracked::M
    coordinate_sums::S
    quadratic_sums::Q
    track_all::Bool
end

function UnwrappedMomentStorage(tracked,
        coordinate_sums::NTuple{N, A}, quadratic_sums::NTuple{P, A},
        track_all::Bool) where
        {N, P, T <: AbstractFloat, A <: AbstractVector{T}}
    P == N * (N + 1) ÷ 2 || throw(ArgumentError(
        "unwrapped quadratic-moment storage has the wrong packed size"))
    return UnwrappedMomentStorage{N, T, typeof(tracked), typeof(coordinate_sums),
        typeof(quadratic_sums)}(tracked, coordinate_sums, quadratic_sums, track_all)
end

function Adapt.adapt_structure(to, storage::UnwrappedMomentStorage)
    return UnwrappedMomentStorage(
        Adapt.adapt(to, storage.tracked),
        map(array -> Adapt.adapt(to, array), storage.coordinate_sums),
        map(array -> Adapt.adapt(to, array), storage.quadratic_sums),
        storage.track_all
    )
end

function derived_observable_arrays(storage::UnwrappedMomentStorage)
    (storage.tracked, storage.coordinate_sums..., storage.quadratic_sums...)
end


@inline _packed_symmetric_count(::Val{N}) where {N} = N * (N + 1) ÷ 2
@inline function _packed_symmetric_index(row::Integer, column::Integer, ::Val{N}) where {N}
    first_axis = min(row, column)
    second_axis = max(row, column)
    return (first_axis - 1) * (2N - first_axis + 2) ÷ 2 +
           (second_axis - first_axis + 1)
end

function _canonical_unwrapped_sums(tracker::UnwrappedMomentTracker{T},
        state::LogicalPottsState, domain::CartesianDomain{N}) where {T, N}
    capacity_value = nslots(capacity(state))
    tracked = zeros(UInt8, capacity_value)
    sums = ntuple(_ -> zeros(T, capacity_value), Val(N))
    quadratic = ntuple(_ -> zeros(T, capacity_value),
        Val(_packed_symmetric_count(Val(N))))
    spacing = SVector{N, T}(domain.spacing)
    site_count = prod(domain.dims)
    tracked_ids = tracker.track_all ? Tuple(value(id) for id in active_cell_ids(state)) :
                  tracker.tracked_ids
    for raw_id in tracked_ids
        id = CellID(raw_id)
        is_active(state, id) || throw(ArgumentError(
            "unwrapped moments cannot track an inactive cell"))
        owner = CellOwner(id)
        owned = findall(index -> owner_at(state, index) == owner, 1:site_count)
        isempty(owned) && throw(ArgumentError("tracked cell has no owned sites"))
        start = first(owned)
        assigned = Vector{SVector{N, T}}(undef, site_count)
        visited = falses(site_count)
        queue = Vector{UInt32}(undef, length(owned))
        start_coordinates = _site_coordinates(start, domain.dims)
        assigned[start] = SVector{N, T}(ntuple(
            axis -> (T(start_coordinates[axis]) + T(0.5)) * spacing[axis], Val(N)))
        visited[start] = true
        queue[1] = UInt32(start)
        head = 1
        tail = 1
        while head <= tail
            site = Int(queue[head])
            head += 1
            origin = assigned[site]
            for direction in 1:direction_count(tracker.relation)
                neighbor = realize_neighbor(domain, tracker.relation, site, direction)
                neighbor.kind === MutableNeighbor || continue
                next_site = Int(neighbor.site)
                owner_at(state, next_site) == owner || continue
                candidate = origin +
                            SVector{N, T}(relation_offset(
                    tracker.relation, direction)) .* spacing
                if !visited[next_site]
                    tail += 1
                    queue[tail] = neighbor.site
                    visited[next_site] = true
                    assigned[next_site] = candidate
                elseif assigned[next_site] != candidate
                    throw(ArgumentError(
                        "tracked cell winds around a periodic axis and has no unique unwrapped center"))
                end
            end
        end
        tail == length(owned) || throw(ArgumentError(
            "tracked cell is fragmented under the declared unwrapping relation"))
        tracked[Int(raw_id)] = UInt8(1)
        for site in owned
            position = assigned[site]
            for axis in 1:N
                sums[axis][Int(raw_id)] += position[axis]
            end
            for row in 1:N, column in row:N
                packed = _packed_symmetric_index(row, column, Val(N))
                quadratic[packed][Int(raw_id)] += position[row] * position[column]
            end
        end
    end
    return UnwrappedMomentStorage(tracked, sums, quadratic, tracker.track_all)
end

function rebuild_tracker(tracker::UnwrappedMomentTracker, state::LogicalPottsState,
        domain::CartesianDomain)
    _canonical_unwrapped_sums(tracker, state, domain)
end

function compile_derived_observable(tracker::UnwrappedMomentTracker,
        state::LogicalPottsState, domain::CartesianDomain)
    validate_relation_domain(domain, tracker.relation)
    return rebuild_tracker(tracker, state, domain)
end

@inline moment_is_tracked(storage::UnwrappedMomentStorage, owner::OwnerRef) = is_cell_owner(owner) &&
                                                                              @inbounds(storage.tracked[Int(owner.value)] !=
                                                                                        0)

@inline function unwrapped_center(
        state::Union{CompiledScientificState, ScientificExecutionState},
        owner::OwnerRef)
    storage = state.trackers.moments
    storage isa UnwrappedMomentStorage || throw(ArgumentError(
        "compiled scientific state has no unwrapped moments"))
    moment_is_tracked(storage, owner) || throw(ArgumentError(
        "owner has no unwrapped-moment tracker"))
    volume = @inbounds state.trackers.finite_volumes[Int(owner.value)]
    volume > 0 || throw(ArgumentError("an extinct owner has no center"))
    N = length(storage.coordinate_sums)
    T = eltype(first(storage.coordinate_sums))
    return SVector{N, T}(ntuple(
        axis -> @inbounds(storage.coordinate_sums[axis][Int(owner.value)] / T(volume)),
        Val(N)))
end


@inline function unwrapped_covariance(
        state::Union{CompiledScientificState, ScientificExecutionState},
        owner::OwnerRef)
    storage = state.trackers.moments
    storage isa UnwrappedMomentStorage || throw(ArgumentError(
        "compiled scientific state has no unwrapped moments"))
    moment_is_tracked(storage, owner) || throw(ArgumentError(
        "owner has no unwrapped-moment tracker"))
    volume = @inbounds state.trackers.finite_volumes[Int(owner.value)]
    volume > 0 || throw(ArgumentError("an extinct owner has no covariance"))
    N = length(storage.coordinate_sums)
    T = eltype(first(storage.coordinate_sums))
    inverse_volume = inv(T(volume))
    return SMatrix{N, N, T}(ntuple(N * N) do linear_index
        row = (linear_index - 1) % N + 1
        column = (linear_index - 1) ÷ N + 1
        packed = _packed_symmetric_index(row, column, Val(N))
        first_row = @inbounds storage.coordinate_sums[row][Int(owner.value)]
        first_column = @inbounds storage.coordinate_sums[column][Int(owner.value)]
        second = @inbounds storage.quadratic_sums[packed][Int(owner.value)]
        second * inverse_volume -
        (first_row * inverse_volume) * (first_column * inverse_volume)
    end)
end

@inline _axis_is_periodic(axis) = axis.negative isa PeriodicBoundary

@inline function _site_image_near_center(
        state::Union{CompiledScientificState, ScientificExecutionState},
        owner::OwnerRef, site::Integer)
    center = unwrapped_center(state, owner)
    domain = state.domain.descriptor
    N = length(domain.dims)
    T = eltype(center)
    wrapped = _physical_site_center(state.domain, site, T)
    return SVector{N, T}(ntuple(
        axis_index -> begin
            axis = domain.boundaries[axis_index]
            if _axis_is_periodic(axis)
                extent = T(domain.dims[axis_index]) * T(domain.spacing[axis_index])
                image = floor((center[axis_index] - wrapped[axis_index]) / extent + T(0.5))
                wrapped[axis_index] + image * extent
            else
                wrapped[axis_index]
            end
        end,
        Val(N)))
end

struct UnwrappedMomentDelta{N, T <: AbstractFloat}
    losing_tracked::Bool
    gaining_tracked::Bool
    losing_position::SVector{N, T}
    gaining_position::SVector{N, T}
end

function stage_derived_observable_delta(tracker::UnwrappedMomentTracker{T},
        state::Union{CompiledScientificState, ScientificExecutionState},
        proposal::CopyProposal) where {T}
    storage = state.trackers.moments
    storage isa UnwrappedMomentStorage || throw(ArgumentError(
        "moment tracker was requested but no moment storage was compiled"))
    losing = moment_is_tracked(storage, proposal.losing)
    gaining = moment_is_tracked(storage, proposal.gaining)
    N = length(storage.coordinate_sums)
    zero_position = zero(SVector{N, T})
    losing_position = losing ?
                      T.(_site_image_near_center(state,
        proposal.losing, proposal.recipient)) : zero_position
    gaining_position = gaining ?
                       T.(_site_image_near_center(state,
        proposal.gaining, proposal.recipient)) : zero_position
    return UnwrappedMomentDelta(losing, gaining, losing_position, gaining_position)
end

@inline function apply_derived_observable_delta!(storage::UnwrappedMomentStorage,
        moments::UnwrappedMomentDelta{N}, delta) where {N}
    if moments.losing_tracked
        index = Int(delta.losing_cell)
        @inbounds for axis in 1:N
            storage.coordinate_sums[axis][index] -= moments.losing_position[axis]
        end
        @inbounds for row in 1:N, column in row:N
            packed = _packed_symmetric_index(row, column, Val(N))
            storage.quadratic_sums[packed][index] -=
                moments.losing_position[row] * moments.losing_position[column]
        end
    end
    if moments.gaining_tracked
        index = Int(delta.gaining_cell)
        @inbounds for axis in 1:N
            storage.coordinate_sums[axis][index] += moments.gaining_position[axis]
        end
        @inbounds for row in 1:N, column in row:N
            packed = _packed_symmetric_index(row, column, Val(N))
            storage.quadratic_sums[packed][index] +=
                moments.gaining_position[row] * moments.gaining_position[column]
        end
    end
    return nothing
end

struct FocalPointLink{T <: AbstractFloat}
    first::UInt32
    second::UInt32
    first_generation::UInt64
    second_generation::UInt64
    strength::T
    target_length::T
end

function FocalPointLink(state::LogicalPottsState, first_id::CellID, second_id::CellID;
        strength::T, target_length::T) where {T <: AbstractFloat}
    first_id != second_id || throw(ArgumentError("a focal-point link requires two cells"))
    is_active(state, first_id) && is_active(state, second_id) || throw(ArgumentError(
        "focal-point link endpoints must be active"))
    isfinite(strength) && strength >= zero(T) || throw(ArgumentError(
        "focal-point strength must be finite and non-negative"))
    isfinite(target_length) && target_length >= zero(T) || throw(ArgumentError(
        "focal-point target length must be finite and non-negative"))
    left, right = value(first_id) < value(second_id) ? (first_id, second_id) :
                  (second_id, first_id)
    return FocalPointLink(value(left), value(right), value(generation(state, left)),
        value(generation(state, right)), strength, target_length)
end

struct FocalPointSpringHamiltonian{L <: Tuple} <: AbstractEnergy
    links::L
    function FocalPointSpringHamiltonian(links::L) where {L <: Tuple}
        pairs = map(link -> (link.first, link.second), links)
        length(unique(pairs)) == length(pairs) || throw(ArgumentError(
            "fixed focal-point links must be unique"))
        new{L}(links)
    end
end
FocalPointSpringHamiltonian(links::FocalPointLink...) = FocalPointSpringHamiltonian(links)

function component_identity(::FocalPointSpringHamiltonian)
    ComponentIdentity(:focal_point_spring, v"1.0.0", :energy)
end
component_semantic_data(component::FocalPointSpringHamiltonian) = (
    links = Tuple((first = link.first, second = link.second,
        first_generation = link.first_generation,
        second_generation = link.second_generation,
        strength = link.strength, target_length = link.target_length)
        for link in component.links),)
required_relations(::FocalPointSpringHamiltonian) = (:center_unwrapping,)

_focal_core(state::CompiledScientificState) = state.potts.storage
_focal_core(state::ScientificExecutionState) = state.core

@inline function _link_generation_is_current(state, link::FocalPointLink)
    core = _focal_core(state)
    first = Int(link.first)
    second = Int(link.second)
    return @inbounds(core.active[first] != 0 && core.active[second] != 0 &&
                     core.generations[first] == link.first_generation &&
                     core.generations[second] == link.second_generation)
end

@inline function _minimum_image_displacement(
        state::Union{CompiledScientificState, ScientificExecutionState},
        first::UInt32, second::UInt32, first_center, second_center)
    descriptor = state.domain.descriptor
    N = length(descriptor.dims)
    T = eltype(first_center)
    return SVector{N, T}(ntuple(
        axis_index -> begin
            delta = second_center[axis_index] - first_center[axis_index]
            axis = descriptor.boundaries[axis_index]
            if _axis_is_periodic(axis)
                extent = T(descriptor.dims[axis_index]) * T(descriptor.spacing[axis_index])
                half = extent / T(2)
                delta > half && (delta -= extent)
                delta < -half && (delta += extent)
                abs(delta) == half && (delta = first < second ? half : -half)
            end
            delta
        end,
        Val(N)))
end

@inline function _link_energy(
        state::Union{CompiledScientificState, ScientificExecutionState},
        link::FocalPointLink,
        first_center, second_center)
    displacement = _minimum_image_displacement(state, link.first, link.second,
        first_center, second_center)
    distance = sqrt(sum(abs2, displacement))
    return link.strength * (distance - link.target_length)^2
end

function global_energy(component::FocalPointSpringHamiltonian,
        state::Union{CompiledScientificState, ScientificExecutionState})
    isempty(component.links) && return 0.0
    T = typeof(first(component.links).strength)
    result = zero(T)
    for link in component.links
        _link_generation_is_current(state, link) || throw(ArgumentError(
            "focal-point link endpoint generation is stale"))
        result += _link_energy(state, link, unwrapped_center(state, CellOwner(link.first)),
            unwrapped_center(state, CellOwner(link.second)))
    end
    return result
end

@inline function _proposed_center(
        state::Union{CompiledScientificState, ScientificExecutionState}, owner::OwnerRef,
        proposal::CopyProposal, moments::UnwrappedMomentDelta)
    center = unwrapped_center(state, owner)
    index = Int(owner.value)
    volume = state.trackers.finite_volumes[index]
    sums = state.trackers.moments.coordinate_sums
    N = length(sums)
    T = eltype(center)
    if owner == proposal.losing
        volume > 1 || throw(ArgumentError(
            "a linked focal-point endpoint cannot become extinct in the fixed-link phase"))
        return SVector{N, T}(ntuple(
            axis -> (sums[axis][index] - moments.losing_position[axis]) / T(volume - 1),
            Val(N)))
    elseif owner == proposal.gaining
        return SVector{N, T}(ntuple(
            axis -> (sums[axis][index] + moments.gaining_position[axis]) / T(volume + 1),
            Val(N)))
    end
    return center
end

function energy_change(component::FocalPointSpringHamiltonian, proposal::CopyProposal,
        state::Union{CompiledScientificState, ScientificExecutionState},
        transaction::StagedCopyTransaction)
    moments = transaction.trackers.moments
    moments isa UnwrappedMomentDelta || throw(ArgumentError(
        "focal-point energy requires a staged unwrapped-moment delta"))
    isempty(component.links) && return 0.0
    T = typeof(first(component.links).strength)
    result = zero(T)
    for link in component.links
        _link_generation_is_current(state, link) || throw(ArgumentError(
            "focal-point link endpoint generation is stale"))
        first_owner = CellOwner(link.first)
        second_owner = CellOwner(link.second)
        if proposal.losing in (first_owner, second_owner) ||
           proposal.gaining in (first_owner, second_owner)
            old_first = unwrapped_center(state, first_owner)
            old_second = unwrapped_center(state, second_owner)
            new_first = _proposed_center(state, first_owner, proposal, moments)
            new_second = _proposed_center(state, second_owner, proposal, moments)
            result += _link_energy(state, link, new_first, new_second) -
                      _link_energy(state, link, old_first, old_second)
        end
    end
    return result
end

struct FixedFocalEndpointConstraint{I <: Tuple} <: AbstractHardConstraint
    endpoint_ids::I
end

function FixedFocalEndpointConstraint(component::FocalPointSpringHamiltonian)
    ids = Tuple(sort!(unique!(UInt32[v for link in component.links
                                     for v in (link.first, link.second)])))
    return FixedFocalEndpointConstraint(ids)
end

function component_identity(::FixedFocalEndpointConstraint)
    ComponentIdentity(:fixed_focal_endpoint_lifecycle, v"1.0.0", :constraint)
end
component_semantic_data(component::FixedFocalEndpointConstraint) =
    (endpoint_ids = component.endpoint_ids,)

function is_allowed(constraint::FixedFocalEndpointConstraint, proposal::CopyProposal,
        state::Union{CompiledScientificState, ScientificExecutionState})
    return !is_cell_owner(proposal.losing) ||
           !(proposal.losing.value in constraint.endpoint_ids) ||
           state.trackers.finite_volumes[Int(proposal.losing.value)] > 1
end
