"""A validated request to transfer selected parent-owned sites to one daughter cell."""
struct DivisionRequest
    parent::CellID
    daughter_sites::Vector{Int}
end

DivisionRequest(parent, daughter_sites::AbstractVector{<:Integer}) =
    DivisionRequest(CellID(parent), collect(Int, daughter_sites))

struct LogicalDivisionResult{S <: LogicalPottsState}
    state::S
    assignments::Vector{Pair{CellID, CellID}}
end

struct LogicalRetirementResult{S <: LogicalPottsState}
    state::S
    retired::Vector{CellID}
end

logical_state(result::LogicalDivisionResult) = result.state
logical_state(result::LogicalRetirementResult) = result.state

function _copy_property_store(store::PropertyStore)
    names = propertynames(store.columns)
    columns = NamedTuple{names}(map(copy, values(store.columns)))
    return PropertyStore(store.schema, columns)
end

function _copy_logical_state(state::LogicalPottsState)
    return LogicalPottsState(copy(state._owners), state._capacity, copy(state._active),
        copy(state._reusable), copy(state._generations), copy(state._cell_types),
        copy(state._medium_ids), _copy_property_store(state.properties),
        OccupancyDerivedState(copy(state._derived.finite_volumes), copy(state._derived.medium_volumes)))
end

function _set_reset_properties!(state::LogicalPottsState, index::Int)
    for descriptor in state.properties.schema.descriptors
        property_values(state, descriptor.key)[index] =
            retired_property_value(descriptor.retirement, descriptor)
    end
    return state
end

function _available_lifecycle_slots(state::LogicalPottsState)
    reusable = copy(state._reusable)
    fresh = CellSlot[CellSlot(index) for index in 1:nslots(state._capacity)
        if !state._active[index] && state._generations[index] == CellGeneration(0) &&
           !(CellSlot(index) in reusable)]
    return vcat(reusable, fresh)
end

function _split_division_value(value::Integer, fraction::AbstractFloat)
    child = convert(typeof(value), floor(value * fraction))
    return DivisionPropertyUpdate(value - child, child)
end
function _split_division_value(value::AbstractFloat, fraction::AbstractFloat)
    child = value * convert(typeof(value), fraction)
    return DivisionPropertyUpdate(value - child, child)
end

division_property_update(::CloneOnDivision, descriptor, value,
    context::DivisionPropertyContext) = DivisionPropertyUpdate(value, value)
division_property_update(policy::SplitOnDivision, descriptor, value::Number,
    context::DivisionPropertyContext) = _split_division_value(value, policy.child_fraction)
division_property_update(::ResetChildOnDivision, descriptor, value,
    context::DivisionPropertyContext) =
    DivisionPropertyUpdate(value, _default_property_value(descriptor))
function division_property_update(::ResetBothOnDivision, descriptor, value,
        context::DivisionPropertyContext)
    reset = _default_property_value(descriptor)
    return DivisionPropertyUpdate(reset, reset)
end
function division_property_update(::ConstitutiveResetAfterDivision, descriptor, value,
        context::DivisionPropertyContext)
    reset = _default_property_value(descriptor)
    return DivisionPropertyUpdate(reset, reset)
end
division_property_update(::PreserveMechanicalOnDivision, descriptor, value,
    context::DivisionPropertyContext) = DivisionPropertyUpdate(value, value)
function division_property_update(::StationaryRedrawAfterDivision, descriptor, value,
        context::DivisionPropertyContext)
    reset = _default_property_value(descriptor)
    return DivisionPropertyUpdate(reset, reset)
end
function division_property_update(policy::AsymmetricResetOnDivision, descriptor, value,
        context::DivisionPropertyContext)
    T = value_type(descriptor)
    return DivisionPropertyUpdate(convert(T, policy.parent), convert(T, policy.child))
end
function division_property_update(::UnsupportedDivision{Reason}, descriptor, value,
        context::DivisionPropertyContext) where {Reason}
    throw(ArgumentError("property `$(descriptor.key)` does not support division ($Reason)"))
end

transition_property_value(::PreserveOnTransition, descriptor, value,
    context::TransitionPropertyContext) = value
transition_property_value(::ResetOnTransition, descriptor, value,
    context::TransitionPropertyContext) = _default_property_value(descriptor)
transition_property_value(::RecomputeOnTransition, descriptor, value,
    context::TransitionPropertyContext) = _default_property_value(descriptor)
function transition_property_value(::UnsupportedTransition{Reason}, descriptor, value,
        context::TransitionPropertyContext) where {Reason}
    throw(ArgumentError(
        "property `$(descriptor.key)` does not support type transition ($Reason)"))
end

retired_property_value(::ResetOnRetirement, descriptor) = _default_property_value(descriptor)

function _apply_division_properties!(state::LogicalPottsState, parent::Int, child::Int,
        context::DivisionPropertyContext)
    for descriptor in state.properties.schema.descriptors
        values = property_values(state, descriptor.key)
        update = division_property_update(
            descriptor.division, descriptor, values[parent], context)
        values[parent] = convert(eltype(values), update.parent)
        values[child] = convert(eltype(values), update.child)
    end
    return state
end

function _validate_division_requests(state::LogicalPottsState, requests, minimum_daughter_volume::Int)
    minimum_daughter_volume > 0 || throw(ArgumentError("minimum daughter volume must be positive"))
    ordered = sort!(collect(requests); by = request -> value(request.parent))
    length(unique(request.parent for request in ordered)) == length(ordered) || throw(ArgumentError(
        "at most one division request may target one parent per lifecycle boundary"))
    for request in ordered
        is_active(state, request.parent) || throw(ArgumentError(
            "division parent $(request.parent) is not active"))
        isempty(request.daughter_sites) && throw(ArgumentError(
            "division daughter geometry must contain at least one site"))
        length(unique(request.daughter_sites)) == length(request.daughter_sites) || throw(ArgumentError(
            "division daughter geometry must not repeat a site"))
        parent = CellOwner(request.parent)
        all(site -> checkbounds(Bool, state._owners, site) && state._owners[site] == parent,
            request.daughter_sites) || throw(ArgumentError(
                "division daughter geometry must contain only parent-owned snapshot sites"))
        length(request.daughter_sites) >= minimum_daughter_volume || throw(ArgumentError(
            "division daughter geometry is below the configured minimum volume"))
        finite_volume(state, request.parent) - length(request.daughter_sites) >= minimum_daughter_volume ||
            throw(ArgumentError("division must leave the parent above the configured minimum volume"))
    end
    return ordered
end

"""
    apply_division_batch(state, requests; minimum_daughter_volume=1)

Validate all requested geometries from one snapshot, preflight the full fixed-capacity batch, then
commit deterministic parent/child assignments to a private candidate.  Capacity failure leaves the
input state untouched; slots retired in this MCS are absent from `_available_lifecycle_slots` until
`release_retired_slots` is called at the next boundary.
"""
function apply_division_batch(state::LogicalPottsState,
        requests::AbstractVector{<:DivisionRequest}; minimum_daughter_volume::Integer = 1)
    isempty(requests) && return LogicalDivisionResult(state, Pair{CellID, CellID}[])
    assert_valid_state(state)
    ordered = _validate_division_requests(state, requests, Int(minimum_daughter_volume))
    available = _available_lifecycle_slots(state)
    length(available) >= length(ordered) || throw(CellCapacityError(length(ordered), state._capacity))

    candidate = _copy_logical_state(state)
    assignments = Pair{CellID, CellID}[]
    for (request, slot) in zip(ordered, available)
        child = CellID(value(slot))
        parent_index = Int(value(request.parent))
        child_index = Int(value(child))
        for site in request.daughter_sites
            candidate._owners[site] = CellOwner(child)
        end
        candidate._active[child_index] = true
        filter!(existing -> existing != slot, candidate._reusable)
        candidate._cell_types[child_index] = candidate._cell_types[parent_index]
        original_volume = finite_volume(state, request.parent)
        child_volume = length(request.daughter_sites)
        context = DivisionPropertyContext(request.parent, child, original_volume,
            original_volume - child_volume, child_volume, UInt8(ndims(state._owners)))
        _apply_division_properties!(candidate, parent_index, child_index, context)
        push!(assignments, request.parent => child)
    end
    rebuild_derived_state!(candidate)
    assert_valid_state(candidate)
    return LogicalDivisionResult(candidate, assignments)
end

"""Retire all zero-occupancy finite cells, reset their schema properties, and defer reuse."""
function retire_zero_volume(state::LogicalPottsState)
    candidate = _copy_logical_state(state)
    retired = CellID[id for id in active_cell_ids(candidate) if finite_volume(candidate, id) == 0]
    # A valid state cannot currently contain a zero-volume active cell; this scan becomes meaningful
    # after a lifecycle candidate modifies ownership. It remains the one retirement primitive.
    for id in retired
        index = Int(value(id))
        candidate._active[index] = false
        candidate._cell_types[index] = UInt32(0)
        candidate._generations[index] = CellGeneration(value(candidate._generations[index]) + 1)
        _set_reset_properties!(candidate, index)
    end
    rebuild_derived_state!(candidate)
    assert_valid_state(candidate)
    return LogicalRetirementResult(candidate, retired)
end

"""Release retirement results at the next integer-MCS boundary in ascending slot order."""
function release_retired_slots(result::LogicalRetirementResult)
    candidate = _copy_logical_state(result.state)
    append!(candidate._reusable, CellSlot.(value.(result.retired)))
    sort!(unique!(candidate._reusable); by = value)
    assert_valid_state(candidate)
    return candidate
end

"""Immediately remove one cell by replacing all of its sites with a declared medium domain."""
function immediately_remove_cell(state::LogicalPottsState, id::CellID, domain::MediumID)
    assert_valid_state(state)
    is_active(state, id) || throw(ArgumentError("cell $id is not active"))
    domain in state._medium_ids || throw(ArgumentError("medium domain $domain is not declared"))
    candidate = _copy_logical_state(state)
    for index in eachindex(candidate._owners)
        candidate._owners[index] == CellOwner(id) && (candidate._owners[index] = MediumOwner(domain))
    end
    rebuild_derived_state!(candidate)
    # Retire after ownership has become zero, before publication; reuse stays deferred in the result.
    result = retire_zero_volume(candidate)
    id in result.retired || throw(ArgumentError("immediate death did not retire cell $id"))
    return result
end

"""Apply one type transition atomically according to every schema property's transition policy."""
function transition_cell_type(state::LogicalPottsState, id::CellID, destination::CellTypeID)
    assert_valid_state(state)
    is_active(state, id) || throw(ArgumentError("cell $id is not active"))
    candidate = _copy_logical_state(state)
    index = Int(value(id))
    source = cell_type(state, id)
    context = TransitionPropertyContext(id, source, destination)
    for descriptor in candidate.properties.schema.descriptors
        values = property_values(candidate, descriptor.key)
        values[index] = convert(eltype(values), transition_property_value(
            descriptor.transition, descriptor, values[index], context))
    end
    candidate._cell_types[index] = value(destination)
    rebuild_derived_state!(candidate)
    assert_valid_state(candidate)
    return candidate
end
