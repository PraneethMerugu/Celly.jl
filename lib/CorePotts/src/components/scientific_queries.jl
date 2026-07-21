abstract type AbstractOwnerFilter end
struct AnyFiniteCell <: AbstractOwnerFilter end
struct CellIdentityFilter <: AbstractOwnerFilter
    id::CellID
end
struct CellTypeFilter <: AbstractOwnerFilter
    id::CellTypeID
end
struct MediumDomainFilter <: AbstractOwnerFilter
    id::MediumID
end
struct AnyMediumDomain <: AbstractOwnerFilter end

@inline _matches_filter(::AnyFiniteCell, state, medium_types, owner) = is_cell_owner(owner)
@inline _matches_filter(filter::CellIdentityFilter, state, medium_types, owner) = is_cell_owner(owner) &&
                                                                                  owner.value ==
                                                                                  value(filter.id)
@inline _matches_filter(filter::CellTypeFilter, state, medium_types, owner) = is_cell_owner(owner) &&
                                                                              owner_type(
    state, medium_types, owner) == value(filter.id)
@inline _matches_filter(filter::MediumDomainFilter, state, medium_types, owner) = is_medium_owner(owner) &&
                                                                                  owner.value ==
                                                                                  value(filter.id)
@inline _matches_filter(::AnyMediumDomain, state, medium_types, owner) = is_medium_owner(owner)

_query_sites(domain::CartesianDomain) = findall(vec(domain.mutable_mask))
_query_sites(domain::CompiledCartesianDomain) = domain.storage.mutable_sites

"""Device-safe finite-cell owner construction after compiled capacity validation."""
@inline compiled_cell_owner(cell::Integer) =
    _owner_ref_unchecked(_CELL_OWNER_TAG, Base.unsafe_trunc(UInt32, cell))

function contact_edge_count(
        state, domain, relation::StaticCartesianRelation{<:SpatialQueryRole},
        owner::OwnerRef, filter::AbstractOwnerFilter, medium_types::MediumTypeTable)
    result = Int64(0)
    for site_value in _query_sites(domain)
        site = Int(site_value)
        _proposal_owner_at(state, site) == owner || continue
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            other = _realized_owner(state, neighbor)
            other != owner && _matches_filter(filter, state, medium_types, other) &&
                (result += 1)
        end
    end
    return result
end

function contact_measure(
        state, domain, relation::StaticCartesianRelation{<:SpatialQueryRole},
        owner::OwnerRef, filter::AbstractOwnerFilter, medium_types::MediumTypeTable)
    T = eltype(relation.weights)
    result = zero(T)
    for site_value in _query_sites(domain)
        site = Int(site_value)
        _proposal_owner_at(state, site) == owner || continue
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            other = _realized_owner(state, neighbor)
            other != owner && _matches_filter(filter, state, medium_types, other) &&
                (result += T(relation_weight(relation, direction)))
        end
    end
    return result
end

function boundary_site_count(state, domain,
        relation::StaticCartesianRelation{<:SpatialQueryRole}, owner::OwnerRef,
        filter::AbstractOwnerFilter, medium_types::MediumTypeTable)
    result = Int64(0)
    for site_value in _query_sites(domain)
        site = Int(site_value)
        _proposal_owner_at(state, site) == owner || continue
        matches = false
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            other = _realized_owner(state, neighbor)
            if other != owner && _matches_filter(filter, state, medium_types, other)
                matches = true
                break
            end
        end
        matches && (result += 1)
    end
    return result
end

function neighbor_cells(
        state, domain, relation::StaticCartesianRelation{<:SpatialQueryRole},
        owner::OwnerRef, filter::AbstractOwnerFilter, medium_types::MediumTypeTable)
    ids = CellID[]
    for site_value in _query_sites(domain)
        site = Int(site_value)
        _proposal_owner_at(state, site) == owner || continue
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            other = _realized_owner(state, neighbor)
            is_cell_owner(other) && other != owner &&
                _matches_filter(filter, state, medium_types, other) &&
                push!(ids, CellID(other.value))
        end
    end
    sort!(unique!(ids); by = value)
    return ids
end

neighbor_cell_count(args...) = length(neighbor_cells(args...))

"""Return whether two distinct owners share at least one realized query-relation incidence."""
@inline function owners_are_neighbors(state, domain,
        relation::StaticCartesianRelation{<:SpatialQueryRole},
        left::OwnerRef, right::OwnerRef)
    left == right && return false
    for site_value in _query_sites(domain)
        site = Int(site_value)
        _proposal_owner_at(state, site) == left || continue
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            _realized_owner(state, neighbor) == right && return true
        end
    end
    return false
end

"""Canonical unordered interface measure between two explicit owner filters."""
function global_interface_measure(state, domain,
        relation::StaticCartesianRelation{<:SpatialQueryRole},
        left_filter::AbstractOwnerFilter, right_filter::AbstractOwnerFilter,
        medium_types::MediumTypeTable, metric::AbstractBoundaryMetric = BoundaryEdgeCount())
    T = metric isa BoundaryEdgeCount ? Int64 : eltype(relation.weights)
    result = zero(T)
    for site_value in _query_sites(domain)
        site = Int(site_value)
        left_owner = _proposal_owner_at(state, site)
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            if neighbor.kind === MutableNeighbor && site > Int(neighbor.site)
                continue
            end
            right_owner = _realized_owner(state, neighbor)
            left_owner == right_owner && continue
            left_to_right = _matches_filter(left_filter, state, medium_types, left_owner) &&
                            _matches_filter(right_filter, state, medium_types, right_owner)
            right_to_left = _matches_filter(right_filter, state, medium_types, left_owner) &&
                            _matches_filter(left_filter, state, medium_types, right_owner)
            matched = left_to_right || right_to_left
            matched && (result += T(_boundary_weight(metric, relation, direction)))
        end
    end
    return result
end

"""Reusable exact distinct-cell set storage for CPU and device rule evaluation."""
struct DistinctNeighborWorkspace{S <: AbstractVector{UInt32}, I <: AbstractVector{UInt32},
    C <: AbstractVector{UInt32}}
    seen_epochs::S
    ids::I
    count::C
end

function DistinctNeighborWorkspace(capacity::Integer)
    capacity >= 0 || throw(ArgumentError("workspace capacity must be non-negative"))
    return DistinctNeighborWorkspace(
        zeros(UInt32, capacity), zeros(UInt32, capacity), zeros(UInt32, 1))
end

function Adapt.adapt_structure(to, workspace::DistinctNeighborWorkspace)
    return DistinctNeighborWorkspace(
        Adapt.adapt(to, workspace.seen_epochs), Adapt.adapt(to, workspace.ids),
        Adapt.adapt(to, workspace.count))
end

function workspace_bytes(workspace::DistinctNeighborWorkspace)
    return _array_bytes(workspace.seen_epochs) + _array_bytes(workspace.ids) +
           _array_bytes(workspace.count)
end

function validate_workspace(workspace::DistinctNeighborWorkspace,
        state::Union{CompiledScientificState, ScientificExecutionState})
    capacity = length(state isa CompiledScientificState ?
                      state.potts.storage.active : state.core.active)
    length(workspace.seen_epochs) == capacity && length(workspace.ids) == capacity ||
        throw(ArgumentError(
            "distinct-neighbor workspace capacity does not match finite-cell capacity"))
    length(workspace.count) == 1 || throw(ArgumentError(
        "distinct-neighbor workspace requires one count slot"))
    return workspace
end

@inline function _insert_sorted!(ids, count::Int, value::UInt32)
    position = count
    @inbounds while position > 1 && ids[position - 1] > value
        ids[position] = ids[position - 1]
        position -= 1
    end
    @inbounds ids[position] = value
    return nothing
end

"""
    neighbor_cells!(workspace, state, domain, relation, owner, filter, medium_types, epoch)

Write canonical distinct finite-cell IDs into `workspace.ids` and return their count. `epoch` must
be nonzero and unique for every live use of the workspace; clear `seen_epochs` before epoch reuse.
The routine allocates nothing and is valid inside a single device work item.
"""
@inline function neighbor_cells!(workspace::DistinctNeighborWorkspace,
        state, domain, relation::StaticCartesianRelation{<:SpatialQueryRole},
        owner::OwnerRef, filter::AbstractOwnerFilter, medium_types::MediumTypeTable,
        epoch::UInt32)
    epoch != 0 || throw(ArgumentError("workspace epoch must be nonzero"))
    @inbounds workspace.count[1] = UInt32(0)
    for site_value in _query_sites(domain)
        site = Int(site_value)
        _proposal_owner_at(state, site) == owner || continue
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            other = _realized_owner(state, neighbor)
            if !is_cell_owner(other) || other == owner ||
               !_matches_filter(filter, state, medium_types, other)
                continue
            end
            index = Int(other.value)
            @inbounds workspace.seen_epochs[index] == epoch && continue
            count = Int(@inbounds(workspace.count[1])) + 1
            @inbounds workspace.count[1] = UInt32(count)
            @inbounds workspace.seen_epochs[index] = epoch
            _insert_sorted!(workspace.ids, count, other.value)
        end
    end
    return Int(@inbounds(workspace.count[1]))
end

@inline function neighbor_cell_count(workspace::DistinctNeighborWorkspace,
        state, domain, relation::StaticCartesianRelation{<:SpatialQueryRole},
        owner::OwnerRef, filter::AbstractOwnerFilter, medium_types::MediumTypeTable,
        epoch::UInt32)
    return neighbor_cells!(
        workspace, state, domain, relation, owner, filter, medium_types, epoch)
end

@inline function neighbor_property_sum(state, property::CellPropertyRef,
        workspace::DistinctNeighborWorkspace, domain,
        relation::StaticCartesianRelation{<:SpatialQueryRole}, owner::OwnerRef,
        filter::AbstractOwnerFilter, medium_types::MediumTypeTable, epoch::UInt32)
    count = neighbor_cells!(workspace, state, domain, relation, owner, filter,
        medium_types, epoch)
    values = _property_column(state, property)
    T = eltype(values)
    result = zero(T)
    @inbounds for index in 1:count
        result += values[Int(workspace.ids[index])]
    end
    return result
end

@inline function neighbor_property_mean(state, property::CellPropertyRef,
        workspace::DistinctNeighborWorkspace, domain,
        relation::StaticCartesianRelation{<:SpatialQueryRole}, owner::OwnerRef,
        filter::AbstractOwnerFilter, medium_types::MediumTypeTable, epoch::UInt32;
        empty)
    count = neighbor_cells!(workspace, state, domain, relation, owner, filter,
        medium_types, epoch)
    count == 0 && return empty
    values = _property_column(state, property)
    T = eltype(values)
    result = zero(T)
    @inbounds for index in 1:count
        result += values[Int(workspace.ids[index])]
    end
    return result / count
end

function neighbor_property_sum(state, property::CellPropertyRef, args...)
    ids = neighbor_cells(state, args...)
    values = _property_column(state, property)
    T = eltype(values)
    return sum(id -> @inbounds(values[Int(value(id))]), ids; init = zero(T))
end

function neighbor_property_mean(state, property::CellPropertyRef, args...; empty = missing)
    ids = neighbor_cells(state, args...)
    isempty(ids) && return empty
    values = _property_column(state, property)
    return sum(id -> @inbounds(values[Int(value(id))]), ids) / length(ids)
end

"""Exact global connectedness constraint; fragmentation remains legal when omitted."""
struct PreserveConnectedCells{R <: StaticCartesianRelation{<:ConnectivityRole}} <:
       AbstractHardConstraint
    relation::R
end

"""Preallocated exact connectivity traversal storage for one work item at a time."""
struct ConnectivityWorkspace{V <: AbstractVector{UInt32}, Q <: AbstractVector{UInt32}}
    visited_epochs::V
    queue::Q
end

function ConnectivityWorkspace(site_count::Integer)
    site_count > 0 || throw(ArgumentError("connectivity workspace must contain a site"))
    return ConnectivityWorkspace(zeros(UInt32, site_count), zeros(UInt32, site_count))
end

function Adapt.adapt_structure(to, workspace::ConnectivityWorkspace)
    return ConnectivityWorkspace(
        Adapt.adapt(to, workspace.visited_epochs), Adapt.adapt(to, workspace.queue))
end

function workspace_bytes(workspace::ConnectivityWorkspace)
    return _array_bytes(workspace.visited_epochs) + _array_bytes(workspace.queue)
end

function validate_workspace(workspace::ConnectivityWorkspace,
        state::Union{CompiledScientificState, ScientificExecutionState})
    domain = state.domain
    site_count = prod(domain.descriptor.dims)
    length(workspace.visited_epochs) == site_count &&
    length(workspace.queue) == site_count || throw(ArgumentError(
        "connectivity workspace capacity does not match ownership-domain storage"))
    return workspace
end

function component_identity(::PreserveConnectedCells)
    ComponentIdentity(:preserve_connected_cells, v"1.0.0", :constraint)
end
component_semantic_data(component::PreserveConnectedCells) =
    (relation = relation_semantics_report(component.relation),)
required_relations(::PreserveConnectedCells) = (:connectivity,)

function _connected_after_copy(constraint::PreserveConnectedCells,
        proposal::CopyProposal, state, domain)
    is_cell_owner(proposal.losing) || return true
    losing = proposal.losing
    remaining = 0
    start = 0
    for site_value in _query_sites(domain)
        site = Int(site_value)
        site == proposal.recipient && continue
        if _proposal_owner_at(state, site) == losing
            remaining += 1
            start == 0 && (start = site)
        end
    end
    remaining <= 1 && return true
    visited = falses(prod(_proposal_dims(domain)))
    queue = Vector{UInt32}(undef, remaining)
    head = 1
    tail = 1
    queue[1] = UInt32(start)
    visited[start] = true
    reached = 1
    while head <= tail
        site = Int(queue[head])
        head += 1
        for direction in 1:direction_count(constraint.relation)
            neighbor = realize_neighbor(domain, constraint.relation, site, direction)
            neighbor.kind === MutableNeighbor || continue
            next_site = Int(neighbor.site)
            next_site == proposal.recipient && continue
            if !visited[next_site] && _proposal_owner_at(state, next_site) == losing
                tail += 1
                queue[tail] = neighbor.site
                visited[next_site] = true
                reached += 1
            end
        end
    end
    return reached == remaining
end

function is_allowed(constraint::PreserveConnectedCells, proposal::CopyProposal, state, domain)
    _connected_after_copy(constraint, proposal, state, domain)
end

"""Allocation-free exact connectivity predicate for compiled CPU/GPU execution."""
@inline function is_allowed(constraint::PreserveConnectedCells,
        proposal::CopyProposal, state::ScientificExecutionState,
        workspace::ConnectivityWorkspace, epoch::UInt32)
    epoch != 0 || throw(ArgumentError("workspace epoch must be nonzero"))
    is_cell_owner(proposal.losing) || return true
    losing = proposal.losing
    remaining = 0
    start = 0
    for site_value in state.domain.storage.mutable_sites
        site = Int(site_value)
        site == proposal.recipient && continue
        if _proposal_owner_at(state, site) == losing
            remaining += 1
            start == 0 && (start = site)
        end
    end
    remaining <= 1 && return true
    head = 1
    tail = 1
    reached = 1
    @inbounds begin
        workspace.queue[1] = UInt32(start)
        workspace.visited_epochs[start] = epoch
    end
    while head <= tail
        site = Int(@inbounds workspace.queue[head])
        head += 1
        for direction in 1:direction_count(constraint.relation)
            neighbor = realize_neighbor(state.domain, constraint.relation, site, direction)
            neighbor.kind === MutableNeighbor || continue
            next_site = Int(neighbor.site)
            next_site == proposal.recipient && continue
            if @inbounds(workspace.visited_epochs[next_site] != epoch) &&
               _proposal_owner_at(state, next_site) == losing
                tail += 1
                @inbounds begin
                    workspace.queue[tail] = neighbor.site
                    workspace.visited_epochs[next_site] = epoch
                end
                reached += 1
            end
        end
    end
    return reached == remaining
end
