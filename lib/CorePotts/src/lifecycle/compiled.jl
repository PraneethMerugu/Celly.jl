struct NoCompiledLifecycle end

struct CompiledPropertyLifecycle{Key, D <: AbstractDivisionPolicy,
        X <: AbstractTransitionPolicy, R <: AbstractRetirementPolicy, T}
    division::D
    transition::X
    retirement::R
    default::T
end

_compiled_property_lifecycle(descriptor::PropertyDescriptor{T}) where {T} =
    CompiledPropertyLifecycle{descriptor.key, typeof(descriptor.division),
        typeof(descriptor.transition), typeof(descriptor.retirement), T}(
        descriptor.division, descriptor.transition, descriptor.retirement,
        convert(T, _default_property_value(descriptor)))

struct CompiledLifecycleDescriptor{E <: Tuple, R <: AbstractLifecycleConflictResolver,
        P <: Tuple, I <: Tuple, Q <: Tuple}
    events::E
    resolver::R
    properties::P
    identity_flags::I
    priorities::Q
    minimum_daughter_volume::Int32
    requires_observation::Bool
end

struct CompiledLifecycleWorkspace{D, W, V, C, F, R}
    decisions::D
    winners::W
    division_valid::V
    child_ids::C
    failure::F
    report::R
end

struct CompiledLifecycle{D <: CompiledLifecycleDescriptor,
        W <: CompiledLifecycleWorkspace}
    descriptor::D
    workspace::W
end

function Adapt.adapt_structure(to, workspace::CompiledLifecycleWorkspace)
    return CompiledLifecycleWorkspace(
        Adapt.adapt(to, workspace.decisions),
        Adapt.adapt(to, workspace.winners),
        Adapt.adapt(to, workspace.division_valid),
        Adapt.adapt(to, workspace.child_ids),
        Adapt.adapt(to, workspace.failure),
        Adapt.adapt(to, workspace.report))
end

Adapt.adapt_structure(to, lifecycle::CompiledLifecycle) =
    CompiledLifecycle(lifecycle.descriptor, Adapt.adapt(to, lifecycle.workspace))

abstract type AbstractCompiledEffectCategory end
struct CompiledPropertyEffect <: AbstractCompiledEffectCategory end
struct CompiledTransitionEffect <: AbstractCompiledEffectCategory end
struct CompiledDivisionEffect <: AbstractCompiledEffectCategory end
struct CompiledDeathEffect <: AbstractCompiledEffectCategory end
struct CompiledCustomEffect <: AbstractCompiledEffectCategory end

compiled_effect_category(::AddCellProperty) = CompiledPropertyEffect()
compiled_effect_category(::InitiateShrinkDeath) = CompiledPropertyEffect()
compiled_effect_category(::TransitionCell) = CompiledTransitionEffect()
compiled_effect_category(::DivideCell) = CompiledDivisionEffect()
compiled_effect_category(::RemoveCellImmediately) = CompiledDeathEffect()

function _canonical_lifecycle_events(events)
    values = collect(events)
    all(event -> event isa LifecycleEvent, values) || throw(ArgumentError(
        "compiled lifecycle entries must be LifecycleEvent values"))
    sort!(values; by = event -> event.semantic_id)
    length(unique(event.semantic_id for event in values)) == length(values) ||
        throw(ArgumentError("compiled lifecycle semantic IDs must be unique"))
    result = Tuple(values)
    isbits(result) || throw(ArgumentError(
        "GPU-qualified lifecycle events must lower to an isbits tuple"))
    return result
end

compiled_identity_change(::AbstractCompiledEffectCategory) = false
compiled_identity_change(::Union{CompiledTransitionEffect, CompiledDivisionEffect,
    CompiledDeathEffect}) = true
compiled_identity_change(effect::AbstractLifecycleEffect) =
    compiled_identity_change(compiled_effect_category(effect))
compiled_is_division(::AbstractCompiledEffectCategory) = false
compiled_is_division(::CompiledDivisionEffect) = true
compiled_is_division(effect::AbstractLifecycleEffect) =
    compiled_is_division(compiled_effect_category(effect))

_compiled_division_policy_supported(::AbstractDivisionPolicy) = true
_compiled_division_policy_supported(::UnsupportedDivision) = false
_compiled_transition_policy_supported(::AbstractTransitionPolicy) = true
_compiled_transition_policy_supported(::UnsupportedTransition) = false

function _validate_compiled_lifecycle(events, schema)
    has_division = any(event -> compiled_is_division(event.effect), events)
    has_transition = any(event ->
        compiled_effect_phase(compiled_effect_category(event.effect)) == UInt8(2), events)
    if has_division
        for descriptor in schema.descriptors
            _compiled_division_policy_supported(descriptor.division) || throw(ArgumentError(
                "property `$(descriptor.key)` makes reachable compiled division unsupported"))
        end
    end
    if has_transition
        for descriptor in schema.descriptors
            _compiled_transition_policy_supported(descriptor.transition) || throw(ArgumentError(
                "property `$(descriptor.key)` makes reachable compiled transition unsupported"))
        end
    end
    identity_count = count(event -> compiled_identity_change(event.effect), events)
    return has_division || identity_count > 1
end

function compile_lifecycle(events, state::CompiledScientificState,
        plan::ExecutionPlan; resolver::AbstractLifecycleConflictResolver =
            RejectLifecycleConflicts(), minimum_daughter_volume::Integer = 1)
    canonical = _canonical_lifecycle_events(events)
    minimum_daughter_volume > 0 || throw(ArgumentError(
        "compiled minimum daughter volume must be positive"))
    minimum_daughter_volume <= typemax(Int32) || throw(ArgumentError(
        "compiled minimum daughter volume must fit Int32"))
    requires_observation = _validate_compiled_lifecycle(
        canonical, state.potts.descriptor.property_schema)
    properties = map(_compiled_property_lifecycle,
        state.potts.descriptor.property_schema.descriptors)
    identity_flags = map(event -> compiled_identity_change(event.effect) ? UInt8(1) : UInt8(0),
        canonical)
    priorities = map(event -> event.priority, canonical)
    descriptor = CompiledLifecycleDescriptor(canonical, resolver, properties,
        identity_flags, priorities,
        Int32(minimum_daughter_volume), requires_observation)
    isbits(descriptor) || throw(ArgumentError(
        "compiled lifecycle descriptor must be isbits"))
    prototype = state.potts.storage.active
    capacity = length(prototype)
    decisions = similar(prototype, UInt8, max(1, length(canonical) * capacity))
    winners = similar(prototype, UInt16, capacity)
    division_valid = similar(prototype, UInt8, capacity)
    child_ids = similar(prototype, UInt32, capacity)
    failure = similar(prototype, UInt32, 4)
    report = similar(prototype, UInt64, 10)
    for array in (decisions, winners, division_valid, child_ids, failure, report)
        fill!(array, zero(eltype(array)))
        record_allocation!(plan, plan.backend isa KernelAbstractions.CPU ? :host : :device,
            _array_bytes(array))
    end
    return CompiledLifecycle(descriptor,
        CompiledLifecycleWorkspace(decisions, winners, division_valid, child_ids,
            failure, report))
end

compiled_lifecycle_bytes(::NoCompiledLifecycle) = 0
compiled_lifecycle_bytes(lifecycle::CompiledLifecycle) = sum(_array_bytes, (
    lifecycle.workspace.decisions, lifecycle.workspace.winners,
    lifecycle.workspace.division_valid, lifecycle.workspace.child_ids,
    lifecycle.workspace.failure, lifecycle.workspace.report))

@inline compiled_schedule_due(::EveryMCS, mcs::UInt64) = true
@inline compiled_schedule_due(schedule::OnceAtMCS, mcs::UInt64) = mcs == UInt64(schedule.mcs)
@inline compiled_schedule_due(schedule::AtMCS, mcs::UInt64) = Int64(mcs) in schedule.boundaries
@inline function compiled_schedule_due(schedule::PeriodicMCS, mcs::UInt64)
    time = Int64(mcs)
    time >= schedule.start || return false
    schedule.bounded && time > schedule.stop && return false
    return rem(time - schedule.start, schedule.period) == 0
end

@inline compiled_target_applies(::ActiveCellsTarget, state, cell) =
    @inbounds(state.core.active[cell]) != UInt8(0)
@inline compiled_target_applies(::GlobalModelTarget, state, cell) = cell == 1

@inline compiled_lifecycle_triggered(::AlwaysLifecycleTrigger, state, cell, mcs,
    rng, seed, event_id) = true
@inline function compiled_lifecycle_triggered(trigger::PropertyAtLeast{Key}, state,
        cell, mcs, rng, seed, event_id) where {Key}
    values = getproperty(state.core.properties, Key)
    return @inbounds(values[cell]) >= trigger.threshold
end
@inline function compiled_lifecycle_triggered(trigger::BernoulliCellTrigger, state,
        cell, mcs, rng, seed, event_id)
    address = _rng_address_unchecked(EventStream, mcs, UInt8(0),
        Base.unsafe_trunc(UInt16, event_id), CellEntity,
        Base.unsafe_trunc(UInt32, cell), @inbounds(state.core.generations[cell]),
        UInt8(0), trigger.operation)
    return bernoulli(rng, seed, address, trigger.probability)
end


@inline function compiled_lifecycle_triggered(trigger::CellTypeIn, state,
        cell, mcs, rng, seed, event_id)
    type_id = @inbounds state.core.cell_types[cell]
    return type_id in trigger.type_ids
end

@inline _compiled_all_lifecycle_triggered(::Tuple{}, state, cell, mcs, rng, seed,
    event_id) = true
@inline function _compiled_all_lifecycle_triggered(
        triggers::Tuple, state, cell, mcs, rng, seed, event_id)
    compiled_lifecycle_triggered(first(triggers), state, cell, mcs, rng, seed, event_id) ||
        return false
    return _compiled_all_lifecycle_triggered(
        Base.tail(triggers), state, cell, mcs, rng, seed, event_id)
end

@inline compiled_lifecycle_triggered(trigger::AllLifecycleTriggers, state,
    cell, mcs, rng, seed, event_id) = _compiled_all_lifecycle_triggered(
    trigger.triggers, state, cell, mcs, rng, seed, event_id)

@inline _decision_index(event_index, capacity, cell) =
    (event_index - 1) * capacity + cell

function _resolve_compiled_conflicts!(::RejectLifecycleConflicts, identity_flags,
        priorities, workspace,
        capacity)
    for cell in 1:capacity
        winner = UInt16(0)
        for event_index in eachindex(identity_flags)
            @inbounds(identity_flags[event_index]) == UInt8(0) && continue
            @inbounds(workspace.decisions[_decision_index(event_index, capacity, cell)]) == 0 &&
                continue
            winner == 0 || return UInt32(1), UInt32(cell), UInt32(winner), UInt32(event_index)
            winner = Base.unsafe_trunc(UInt16, event_index)
        end
        @inbounds workspace.winners[cell] = winner
    end
    return UInt32(0), UInt32(0), UInt32(0), UInt32(0)
end

function _resolve_compiled_conflicts!(::StableLifecyclePriority, identity_flags,
        priorities, workspace,
        capacity)
    for cell in 1:capacity
        winner = UInt16(0)
        best = typemin(Int32)
        tied = false
        for event_index in eachindex(identity_flags)
            @inbounds(identity_flags[event_index]) == UInt8(0) && continue
            @inbounds(workspace.decisions[_decision_index(event_index, capacity, cell)]) == 0 &&
                continue
            priority = @inbounds priorities[event_index]
            if winner == 0 || priority > best
                winner = Base.unsafe_trunc(UInt16, event_index)
                best = priority
                tied = false
            elseif priority == best
                tied = true
            end
        end
        tied && return UInt32(1), UInt32(cell), UInt32(winner), UInt32(0)
        @inbounds workspace.winners[cell] = winner
    end
    return UInt32(0), UInt32(0), UInt32(0), UInt32(0)
end

@inline function _compiled_event_selected(workspace, event_index, capacity, cell,
        event)
    @inbounds(workspace.decisions[_decision_index(event_index, capacity, cell)]) != 0 ||
        return false
    return !compiled_identity_change(event.effect) ||
           @inbounds(workspace.winners[cell]) == UInt16(event_index)
end

function _compiled_cell_moments(state, cell, ::Val{N}) where {N}
    count = 0
    center = zero(SVector{N, Float32})
    dims = state.domain.descriptor.dims
    indices = CartesianIndices(dims)
    for site in 1:length(state.core.ownership.ids)
        if @inbounds(state.core.ownership.tags[site]) == _CELL_OWNER_TAG &&
                @inbounds(state.core.ownership.ids[site]) == UInt32(cell)
            coordinate = indices[site]
            center += SVector{N, Float32}(ntuple(axis -> Float32(coordinate[axis]), N))
            count += 1
        end
    end
    count == 0 && return center, zero(SMatrix{N, N, Float32}), 0
    center /= Float32(count)
    covariance = zero(SMatrix{N, N, Float32})
    for site in 1:length(state.core.ownership.ids)
        if @inbounds(state.core.ownership.tags[site]) == _CELL_OWNER_TAG &&
                @inbounds(state.core.ownership.ids[site]) == UInt32(cell)
            coordinate = indices[site]
            point = SVector{N, Float32}(ntuple(axis -> Float32(coordinate[axis]), N))
            displacement = point - center
            covariance += displacement * transpose(displacement)
        end
    end
    return center, covariance, count
end

function _compiled_power_axis(covariance::SMatrix{N, N, Float32}, major::Bool) where {N}
    trace_value = sum(covariance[index, index] for index in 1:N)
    matrix = major ? covariance : SMatrix{N, N, Float32}(
        ntuple(index -> begin
            row = ((index - 1) % N) + 1
            column = ((index - 1) ÷ N) + 1
            (row == column ? trace_value : 0.0f0) - covariance[row, column]
        end, N * N))
    vector = SVector{N, Float32}(ntuple(index -> Float32(index), N))
    vector /= sqrt(sum(abs2, vector))
    for _ in 1:16
        updated = matrix * vector
        magnitude = sqrt(sum(abs2, updated))
        vector = magnitude > 32eps(Float32) ? updated / magnitude :
                 SVector{N, Float32}(ntuple(index -> index == 1 ? 1.0f0 : 0.0f0, N))
    end
    for value in vector
        if abs(value) > 32eps(Float32)
            return value < 0 ? -vector : vector
        end
    end
    return vector
end

@inline compiled_prepare_division_geometry(geometry::AbstractDivisionGeometry,
    state, cell, mcs, rng, seed, event_id, covariance) = geometry
@inline compiled_prepare_division_geometry(::MajorAxisDivision, state, cell, mcs,
    rng, seed, event_id, covariance) = VectorDivision(_compiled_power_axis(covariance, true))
@inline compiled_prepare_division_geometry(::MinorAxisDivision, state, cell, mcs,
    rng, seed, event_id, covariance) = VectorDivision(_compiled_power_axis(covariance, false))
function compiled_prepare_division_geometry(geometry::RandomOrientationDivision,
        state, cell, mcs, rng, seed, event_id, covariance)
    address = _rng_address_unchecked(DivisionOrientationStream, mcs, UInt8(0),
        Base.unsafe_trunc(UInt16, event_id), CellEntity,
        Base.unsafe_trunc(UInt32, cell), @inbounds(state.core.generations[cell]),
        UInt8(0), geometry.operation)
    first_draw = uniform_open01(Float32, rng, seed, address; lane = 1)
    N = length(state.domain.descriptor.dims)
    if N == 2
        angle = 2.0f0 * Float32(pi) * first_draw
        return VectorDivision((cos(angle), sin(angle)))
    end
    second_draw = uniform_open01(Float32, rng, seed, address; lane = 2)
    z = 2.0f0 * first_draw - 1.0f0
    radius = sqrt(max(0.0f0, 1.0f0 - z * z))
    angle = 2.0f0 * Float32(pi) * second_draw
    return VectorDivision((radius * cos(angle), radius * sin(angle), z))
end

@inline compiled_division_region(geometry::AbstractDivisionGeometry, context) =
    division_region(geometry, context)

function _compiled_partition_counts(geometry, state, cell, mcs, rng, seed,
        event_id, ::Val{N}) where {N}
    center, covariance, volume = _compiled_cell_moments(state, cell, Val(N))
    prepared = compiled_prepare_division_geometry(
        geometry, state, cell, mcs, rng, seed, event_id, covariance)
    parent_count = 0
    child_count = 0
    indices = CartesianIndices(state.domain.descriptor.dims)
    for site in 1:length(state.core.ownership.ids)
        if @inbounds(state.core.ownership.tags[site]) == _CELL_OWNER_TAG &&
                @inbounds(state.core.ownership.ids[site]) == UInt32(cell)
            coordinate = indices[site]
            point = SVector{N, Float32}(ntuple(axis -> Float32(coordinate[axis]), N))
            label = compiled_division_region(prepared,
                DivisionSiteContext(point, center))
            label == UInt8(1) ? (parent_count += 1) :
            label == UInt8(2) ? (child_count += 1) : (return 0, 0, prepared)
        end
    end
    return parent_count, child_count, prepared
end

@inline _compiled_property_values(values, ::CompiledPropertyLifecycle{Key}) where {Key} =
    getproperty(values, Key)

@inline compiled_division_property_update(::CloneOnDivision, value, default, context) =
    DivisionPropertyUpdate(value, value)
@inline function compiled_division_property_update(policy::SplitOnDivision, value,
        default, context)
    if value isa Integer
        child = convert(typeof(value), floor(value * policy.child_fraction))
    else
        child = value * convert(typeof(value), policy.child_fraction)
    end
    return DivisionPropertyUpdate(value - child, child)
end
@inline compiled_division_property_update(::ResetChildOnDivision, value, default, context) =
    DivisionPropertyUpdate(value, default)
@inline compiled_division_property_update(::ResetBothOnDivision, value, default, context) =
    DivisionPropertyUpdate(default, default)
@inline compiled_division_property_update(policy::AsymmetricResetOnDivision, value,
    default, context) = DivisionPropertyUpdate(convert(typeof(value), policy.parent),
    convert(typeof(value), policy.child))
@inline compiled_division_property_update(::ConstitutiveResetAfterDivision, value,
    default, context) = DivisionPropertyUpdate(default, default)
@inline compiled_division_property_update(::PreserveMechanicalOnDivision, value,
    default, context) = DivisionPropertyUpdate(value, value)
@inline compiled_division_property_update(::StationaryRedrawAfterDivision, value,
    default, context) = DivisionPropertyUpdate(default, default)

@inline compiled_transition_property_value(::PreserveOnTransition, value, default) = value
@inline compiled_transition_property_value(::ResetOnTransition, value, default) = default
@inline compiled_transition_property_value(::RecomputeOnTransition, value, default) = default
@inline compiled_retired_property_value(::ResetOnRetirement, default) = default

struct NoCompiledDerivedDivision end
struct CompiledMomentDivisionContext{N, T <: AbstractFloat}
    tracked::Bool
    center::SVector{N, T}
end

@inline compiled_prepare_derived_division!(::NoMomentStorage, state, parent, child) =
    NoCompiledDerivedDivision()
@inline function compiled_prepare_derived_division!(storage::UnwrappedMomentStorage{N, T},
        state, parent, child) where {N, T}
    tracked = @inbounds storage.tracked[parent] != UInt8(0)
    volume = @inbounds state.trackers.finite_volumes[parent]
    center = tracked ? SVector{N, T}(ntuple(axis ->
        @inbounds(storage.coordinate_sums[axis][parent] / T(volume)), Val(N))) :
        zero(SVector{N, T})
    @inbounds storage.tracked[child] = UInt8(0)
    for axis in 1:N
        @inbounds begin
            storage.coordinate_sums[axis][parent] = zero(T)
            storage.coordinate_sums[axis][child] = zero(T)
        end
    end
    return CompiledMomentDivisionContext(tracked, center)
end

@inline compiled_accumulate_derived_division!(::NoMomentStorage,
    ::NoCompiledDerivedDivision, state, site, label, parent, child) = nothing
@inline function compiled_accumulate_derived_division!(
        storage::UnwrappedMomentStorage{N, T},
        context::CompiledMomentDivisionContext{N, T}, state, site, label,
        parent, child) where {N, T}
    context.tracked && label == UInt8(1) || return nothing
    wrapped = _physical_site_center(state.domain, site, T)
    position = SVector{N, T}(ntuple(axis_index -> begin
        axis = state.domain.descriptor.boundaries[axis_index]
        if _axis_is_periodic(axis)
            extent = T(state.domain.descriptor.dims[axis_index]) *
                T(state.domain.descriptor.spacing[axis_index])
            image = floor((context.center[axis_index] - wrapped[axis_index]) /
                extent + T(0.5))
            wrapped[axis_index] + image * extent
        else
            wrapped[axis_index]
        end
    end, Val(N)))
    for axis in 1:N
        @inbounds storage.coordinate_sums[axis][parent] += position[axis]
    end
    return nothing
end

@inline compiled_retire_derived!(::NoMomentStorage, state, cell) = nothing
@inline function compiled_retire_derived!(storage::UnwrappedMomentStorage{N, T},
        state, cell) where {N, T}
    @inbounds storage.tracked[cell] = UInt8(0)
    for axis in 1:N
        @inbounds storage.coordinate_sums[axis][cell] = zero(T)
    end
    return nothing
end

@inline _compiled_apply_division_properties!(::Tuple{}, state, parent, child,
    parent_volume, child_volume) = nothing
@inline function _compiled_apply_division_properties!(properties::Tuple, state,
        parent, child, parent_volume, child_volume)
    context = DivisionPropertyContext(
        CellID(Base.unsafe_trunc(UInt32, parent)),
        CellID(Base.unsafe_trunc(UInt32, child)),
        parent_volume + child_volume, parent_volume, child_volume,
        UInt8(length(state.domain.descriptor.dims)))
    property = first(properties)
    values = _compiled_property_values(state.core.properties, property)
    value = @inbounds values[parent]
    update = compiled_division_property_update(
        property.division, value, property.default, context)
    @inbounds begin
        values[parent] = update.parent
        values[child] = update.child
    end
    _compiled_apply_division_properties!(Base.tail(properties), state, parent,
        child, parent_volume, child_volume)
    return nothing
end

@inline _compiled_apply_transition_properties!(::Tuple{}, state, cell) = nothing
@inline function _compiled_apply_transition_properties!(properties::Tuple, state, cell)
    property = first(properties)
    values = _compiled_property_values(state.core.properties, property)
    @inbounds values[cell] = compiled_transition_property_value(
        property.transition, values[cell], property.default)
    _compiled_apply_transition_properties!(Base.tail(properties), state, cell)
    return nothing
end

@inline _compiled_retire_properties!(::Tuple{}, state, cell) = nothing
@inline function _compiled_retire_properties!(properties::Tuple, state, cell)
    property = first(properties)
    values = _compiled_property_values(state.core.properties, property)
    @inbounds values[cell] = compiled_retired_property_value(
        property.retirement, property.default)
    _compiled_retire_properties!(Base.tail(properties), state, cell)
    return nothing
end

@inline function compiled_apply_effect!(effect::AddCellProperty{Key}, state, cell,
        properties, mcs, rng, seed) where {Key}
    values = getproperty(state.core.properties, Key)
    @inbounds values[cell] += effect.amount
    return nothing
end
@inline function compiled_apply_effect!(effect::InitiateShrinkDeath{Key}, state,
        cell, properties, mcs, rng, seed) where {Key}
    values = getproperty(state.core.properties, Key)
    @inbounds values[cell] = max(zero(eltype(values)), values[cell] - effect.decrement)
    return nothing
end
@inline function compiled_apply_effect!(effect::TransitionCell, state, cell,
        properties, mcs, rng, seed)
    _compiled_apply_transition_properties!(properties, state, cell)
    @inbounds state.core.cell_types[cell] = value(effect.destination)
    return nothing
end

function _commit_reusable_boundary!(state, workspace)
    capacity = length(state.core.active)
    count = 0
    for slot in 1:capacity
        allocated = false
        for parent in 1:capacity
            @inbounds(workspace.child_ids[parent]) == UInt32(slot) && (allocated = true; break)
        end
        if @inbounds(state.core.active[slot]) == UInt8(0) && !allocated &&
                @inbounds(state.core.generations[slot]) > UInt64(0)
            count += 1
            @inbounds state.core.reusable_slots[count] = UInt32(slot)
        end
    end
    for index in (count + 1):capacity
        @inbounds state.core.reusable_slots[index] = UInt32(0)
    end
    @inbounds state.core.reusable_count[1] = UInt32(count)
    return nothing
end

function _rebuild_compiled_trackers!(state)
    fill!(state.trackers.finite_volumes, Int32(0))
    fill!(state.trackers.medium_volumes, Int32(0))
    fill!(state.trackers.boundary_measures, zero(eltype(state.trackers.boundary_measures)))
    for site in 1:length(state.core.ownership.ids)
        tag = @inbounds state.core.ownership.tags[site]
        id = @inbounds state.core.ownership.ids[site]
        if tag == _CELL_OWNER_TAG
            @inbounds state.trackers.finite_volumes[Int(id)] += Int32(1)
        else
            for medium_index in eachindex(state.medium_ids)
                if state.medium_ids[medium_index] == id
                    @inbounds state.trackers.medium_volumes[medium_index] += Int32(1)
                    break
                end
            end
        end
    end
    for cell in 1:length(state.core.active)
        @inbounds(state.core.active[cell]) == UInt8(0) && continue
        @inbounds state.trackers.boundary_measures[cell] = boundary_measure(state,
            state.domain, state.boundary_tracker.relation,
            OwnerRef(_CELL_OWNER_TAG, Base.unsafe_trunc(UInt32, cell)),
            state.boundary_tracker.metric)
    end
    return nothing
end

@inline function _compiled_mechanical_mean(component::FluctuatingVolumePressure,
        state, cell)
    targets = _property_column(state, _mechanical_target(component))
    strengths = _property_column(state, _mechanical_strength(component))
    return @inbounds 2 * strengths[cell] *
        (state.trackers.finite_volumes[cell] - targets[cell])
end
@inline function _compiled_mechanical_mean(component::FluctuatingSurfaceTension,
        state, cell)
    targets = _property_column(state, _mechanical_target(component))
    strengths = _property_column(state, _mechanical_strength(component))
    return @inbounds 2 * strengths[cell] *
        (state.trackers.boundary_measures[cell] - targets[cell])
end

function _write_compiled_lifecycle_failure!(workspace, failure)
    @inbounds begin
        workspace.failure[1] = failure[1]
        workspace.failure[2] = failure[2]
        workspace.failure[3] = failure[3]
        workspace.failure[4] = failure[4]
    end
    return nothing
end

@inline _compiled_transaction_open(workspace) = @inbounds(workspace.failure[1]) == UInt32(0)

@kernel function _clear_compiled_lifecycle_kernel!(workspace)
    index = @index(Global, Linear)
    index <= length(workspace.winners) && (@inbounds workspace.winners[index] = UInt16(0))
    index <= length(workspace.division_valid) &&
        (@inbounds workspace.division_valid[index] = UInt8(0))
    index <= length(workspace.child_ids) &&
        (@inbounds workspace.child_ids[index] = UInt32(0))
    index <= length(workspace.failure) && (@inbounds workspace.failure[index] = UInt32(0))
    index <= length(workspace.report) && (@inbounds workspace.report[index] = UInt64(0))
end

@kernel function _compiled_decision_kernel!(event, event_index, decisions, state,
        mcs, rng, seed)
    cell = @index(Global, Linear)
    capacity = length(state.core.active)
    if cell <= capacity
        decision = compiled_schedule_due(event.schedule, mcs) &&
            compiled_target_applies(event.target, state, cell) &&
            compiled_lifecycle_triggered(event.trigger, state, cell, mcs, rng,
                seed, event.semantic_id)
        @inbounds decisions[_decision_index(event_index, capacity, cell)] =
            ifelse(decision, UInt8(1), UInt8(0))
    end
end

@kernel function _compiled_conflict_kernel!(resolver, identity_flags, priorities,
        workspace, capacity)
    index = @index(Global, Linear)
    if index == 1
        failure = _resolve_compiled_conflicts!(resolver, identity_flags, priorities,
            workspace, capacity)
        failure[1] == 0 || _write_compiled_lifecycle_failure!(workspace, failure)
    end
end

@kernel function _compiled_division_validation_kernel!(event, event_index,
        workspace, state, mcs, rng, seed, minimum_daughter_volume)
    cell = @index(Global, Linear)
    capacity = length(state.core.active)
    if cell <= capacity && _compiled_transaction_open(workspace) &&
            _compiled_event_selected(workspace, event_index, capacity, cell, event)
        N = length(state.domain.descriptor.dims)
        parent_count, child_count, _ = _compiled_partition_counts(
            event.effect.geometry, state, cell, mcs, rng, seed,
            event.semantic_id, Val(N))
        @inbounds workspace.division_valid[cell] =
            parent_count >= minimum_daughter_volume &&
            child_count >= minimum_daughter_volume ? UInt8(1) : UInt8(0)
    end
end

function _assign_compiled_children!(workspace, state)
    capacity = length(state.core.active)
    valid_count = count(cell -> @inbounds(workspace.division_valid[cell]) != UInt8(0),
        1:capacity)
    available = count(cell -> @inbounds(state.core.active[cell]) == UInt8(0), 1:capacity)
    valid_count <= available || return UInt32(2), UInt32(valid_count),
        UInt32(available), UInt32(0)
    ordinal = 0
    reused_count = count(cell -> @inbounds(state.core.active[cell]) == UInt8(0) &&
        @inbounds(state.core.generations[cell]) > UInt64(0), 1:capacity)
    for parent in 1:capacity
        @inbounds(workspace.division_valid[parent]) == UInt8(0) && continue
        ordinal += 1
        selected = 0
        seen = 0
        if ordinal <= reused_count
            for slot in 1:capacity
                if @inbounds(state.core.active[slot]) == UInt8(0) &&
                        @inbounds(state.core.generations[slot]) > UInt64(0)
                    seen += 1
                    seen == ordinal && (selected = slot; break)
                end
            end
        else
            fresh_ordinal = ordinal - reused_count
            for slot in 1:capacity
                if @inbounds(state.core.active[slot]) == UInt8(0) &&
                        @inbounds(state.core.generations[slot]) == UInt64(0)
                    seen += 1
                    seen == fresh_ordinal && (selected = slot; break)
                end
            end
        end
        @inbounds workspace.child_ids[parent] = Base.unsafe_trunc(UInt32, selected)
    end
    return UInt32(0), UInt32(0), UInt32(0), UInt32(0)
end

@kernel function _compiled_capacity_kernel!(workspace, state)
    index = @index(Global, Linear)
    if index == 1 && _compiled_transaction_open(workspace)
        failure = _assign_compiled_children!(workspace, state)
        failure[1] == 0 || _write_compiled_lifecycle_failure!(workspace, failure)
    end
end

@kernel function _compiled_reusable_boundary_kernel!(workspace, state)
    index = @index(Global, Linear)
    if index == 1 && _compiled_transaction_open(workspace)
        _commit_reusable_boundary!(state, workspace)
    end
end

@kernel function _compiled_effect_kernel!(event, event_index, workspace, state,
        properties, mcs, rng, seed)
    cell = @index(Global, Linear)
    capacity = length(state.core.active)
    if cell <= capacity && _compiled_transaction_open(workspace) &&
            _compiled_event_selected(workspace, event_index, capacity, cell, event)
        compiled_apply_effect!(event.effect, state, cell, properties, mcs, rng, seed)
    end
end

function _commit_compiled_division_event!(event, event_index, workspace, state,
        properties, mcs, rng, seed, parent)
    capacity = length(state.core.active)
    @inbounds(workspace.division_valid[parent]) == UInt8(0) && return nothing
    _compiled_event_selected(workspace, event_index, capacity, parent, event) || return nothing
    child = Int(@inbounds workspace.child_ids[parent])
    N = length(state.domain.descriptor.dims)
    indices = CartesianIndices(state.domain.descriptor.dims)
    center, covariance, _ = _compiled_cell_moments(state, parent, Val(N))
    prepared = compiled_prepare_division_geometry(event.effect.geometry, state,
        parent, mcs, rng, seed, event.semantic_id, covariance)
    derived_context = compiled_prepare_derived_division!(
        state.trackers.moments, state, parent, child)
    parent_volume = 0
    child_volume = 0
    for site in 1:length(state.core.ownership.ids)
        if @inbounds(state.core.ownership.tags[site]) == _CELL_OWNER_TAG &&
                @inbounds(state.core.ownership.ids[site]) == UInt32(parent)
            coordinate = indices[site]
            point = SVector{N, Float32}(ntuple(axis -> Float32(coordinate[axis]), N))
            label = compiled_division_region(prepared, DivisionSiteContext(point, center))
            compiled_accumulate_derived_division!(state.trackers.moments,
                derived_context, state, site, label, parent, child)
            if label == UInt8(2)
                @inbounds state.core.ownership.ids[site] = UInt32(child)
                child_volume += 1
            else
                parent_volume += 1
            end
        end
    end
    @inbounds begin
        state.core.active[child] = UInt8(1)
        state.core.cell_types[child] = state.core.cell_types[parent]
    end
    _compiled_apply_division_properties!(properties, state, parent, child,
        parent_volume, child_volume)
    return nothing
end

@kernel function _compiled_division_commit_kernel!(event, event_index, workspace,
        state, properties, mcs, rng, seed)
    parent = @index(Global, Linear)
    if parent <= length(state.core.active) && _compiled_transaction_open(workspace)
        _commit_compiled_division_event!(event, event_index, workspace, state,
            properties, mcs, rng, seed, parent)
    end
end

function _commit_compiled_death_event!(event, event_index, workspace, state,
        properties, cell)
    capacity = length(state.core.active)
    _compiled_event_selected(workspace, event_index, capacity, cell, event) || return nothing
    for site in 1:length(state.core.ownership.ids)
        if @inbounds(state.core.ownership.tags[site]) == _CELL_OWNER_TAG &&
                @inbounds(state.core.ownership.ids[site]) == UInt32(cell)
            @inbounds begin
                state.core.ownership.tags[site] = _MEDIUM_OWNER_TAG
                state.core.ownership.ids[site] = value(event.effect.medium)
            end
        end
    end
    @inbounds begin
        state.core.active[cell] = UInt8(0)
        state.core.cell_types[cell] = UInt32(0)
        state.core.generations[cell] += UInt64(1)
    end
    _compiled_retire_properties!(properties, state, cell)
    compiled_retire_derived!(state.trackers.moments, state, cell)
    return nothing
end

@kernel function _compiled_death_commit_kernel!(event, event_index, workspace,
        state, properties)
    cell = @index(Global, Linear)
    if cell <= length(state.core.active) && _compiled_transaction_open(workspace)
        _commit_compiled_death_event!(event, event_index, workspace, state,
            properties, cell)
    end
end

@kernel function _compiled_tracker_rebuild_kernel!(workspace, state)
    index = @index(Global, Linear)
    if index == 1 && _compiled_transaction_open(workspace)
        _rebuild_compiled_trackers!(state)
    end
end

@inline _compiled_mechanical_repair_required(::PreserveMechanicalOnDivision) = false
@inline _compiled_mechanical_repair_required(::ConstitutiveResetAfterDivision) = true
@inline _compiled_mechanical_repair_required(::StationaryRedrawAfterDivision) = true

@inline function _repair_compiled_mechanical_cell!(
        ::ConstitutiveResetAfterDivision, component, state, algorithm,
        rng, seed, mcs, cell)
    values = _property_column(state, _mechanical_state(component))
    mean = _compiled_mechanical_mean(component, state, cell)
    @inbounds values[cell] = mean
    return nothing
end

@inline function _repair_compiled_mechanical_cell!(
        ::StationaryRedrawAfterDivision, component, state, algorithm,
        rng, seed, mcs, cell)
    values = _property_column(state, _mechanical_state(component))
    strengths = _property_column(state, _mechanical_strength(component))
    mean = _compiled_mechanical_mean(component, state, cell)
    address = _rng_address_unchecked(PropertyInheritanceStream, mcs,
        UInt8(0), component.instance_id, CellEntity,
        Base.unsafe_trunc(UInt32, cell), @inbounds(state.core.generations[cell]),
        UInt8(0), UInt16(0))
    normal = normal_box_muller(eltype(values), rng, seed, address)
    noise = _mechanical_noise_scale(component, algorithm)
    @inbounds values[cell] = mean + sqrt(2 * strengths[cell] * noise) * normal
    return nothing
end

@kernel function _compiled_mechanical_repair_kernel!(component, workspace, state,
        algorithm, rng, seed, mcs)
    parent = @index(Global, Linear)
    if parent <= length(state.core.active) && _compiled_transaction_open(workspace) &&
            @inbounds(workspace.division_valid[parent]) != UInt8(0) &&
            _compiled_mechanical_repair_required(component.division)
        child = Int(@inbounds workspace.child_ids[parent])
        _repair_compiled_mechanical_cell!(component.division, component, state,
            algorithm, rng, seed, mcs, parent)
        _repair_compiled_mechanical_cell!(component.division, component, state,
            algorithm, rng, seed, mcs, child)
    end
end

@kernel function _compiled_lifecycle_report_kernel!(workspace, state, mcs)
    index = @index(Global, Linear)
    if index == 1 && _compiled_transaction_open(workspace)
        active = UInt64(0)
        divisions = UInt64(0)
        for cell in eachindex(state.core.active)
            active += UInt64(@inbounds(state.core.active[cell]) != UInt8(0))
            divisions += UInt64(@inbounds(workspace.division_valid[cell]) != UInt8(0))
        end
        @inbounds begin
            workspace.report[1] = mcs
            workspace.report[2] = active
            workspace.report[3] = divisions
            workspace.report[4] = UInt64(length(state.core.active)) - active
        end
    end
end

_launch_compiled_decisions!(plan, ::Tuple{}, event_index, workspace, state,
    mcs, rng, seed) = nothing
function _launch_compiled_decisions!(plan, events::Tuple, event_index, workspace,
        state, mcs, rng, seed)
    event = first(events)
    kernel = _compiled_decision_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, event, event_index, workspace.decisions, state, mcs, rng,
        seed; ndrange = length(state.core.active))
    _launch_compiled_decisions!(plan, Base.tail(events), event_index + 1, workspace,
        state, mcs, rng, seed)
    return nothing
end

_launch_compiled_division_validation!(plan, ::Tuple{}, event_index, workspace,
    state, mcs, rng, seed, minimum) = nothing
function _launch_compiled_division_validation!(plan, events::Tuple, event_index,
        workspace, state, mcs, rng, seed, minimum)
    event = first(events)
    if compiled_is_division(event.effect)
        kernel = _compiled_division_validation_kernel!(plan.backend, plan.block_size)
        launch!(plan, kernel, event, event_index, workspace, state, mcs, rng, seed,
            minimum; ndrange = length(state.core.active))
    end
    _launch_compiled_division_validation!(plan, Base.tail(events), event_index + 1,
        workspace, state, mcs, rng, seed, minimum)
    return nothing
end

function _launch_compiled_effect!(plan, ::CompiledPropertyEffect, event, event_index,
        workspace, state, properties, mcs, rng, seed)
    kernel = _compiled_effect_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, event, event_index, workspace, state, properties, mcs, rng,
        seed; ndrange = length(state.core.active))
end
function _launch_compiled_effect!(plan, ::CompiledTransitionEffect, event, event_index,
        workspace, state, properties, mcs, rng, seed)
    kernel = _compiled_effect_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, event, event_index, workspace, state, properties, mcs, rng,
        seed; ndrange = length(state.core.active))
end
function _launch_compiled_effect!(plan, ::CompiledDivisionEffect, event, event_index,
        workspace, state, properties, mcs, rng, seed)
    kernel = _compiled_division_commit_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, event, event_index, workspace, state, properties, mcs, rng,
        seed; ndrange = length(state.core.active))
end
function _launch_compiled_effect!(plan, ::CompiledDeathEffect, event, event_index,
        workspace, state, properties, mcs, rng, seed)
    kernel = _compiled_death_commit_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, event, event_index, workspace, state, properties;
        ndrange = length(state.core.active))
end
function _launch_compiled_effect!(plan, ::CompiledCustomEffect, event, event_index,
        workspace, state, properties, mcs, rng, seed)
    kernel = _compiled_effect_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, event, event_index, workspace, state, properties, mcs, rng,
        seed; ndrange = length(state.core.active))
end

_launch_compiled_effects!(plan, ::Tuple{}, event_index, workspace, state,
    properties, mcs, rng, seed, phase) = nothing
compiled_effect_phase(::CompiledPropertyEffect) = UInt8(1)
compiled_effect_phase(::CompiledCustomEffect) = UInt8(1)
compiled_effect_phase(::CompiledTransitionEffect) = UInt8(2)
compiled_effect_phase(::CompiledDivisionEffect) = UInt8(3)
compiled_effect_phase(::CompiledDeathEffect) = UInt8(4)
function _launch_compiled_effects!(plan, events::Tuple, event_index, workspace, state,
        properties, mcs, rng, seed, phase)
    event = first(events)
    category = compiled_effect_category(event.effect)
    if compiled_effect_phase(category) == phase
        _launch_compiled_effect!(plan, category, event, event_index, workspace,
            state, properties, mcs, rng, seed)
    end
    _launch_compiled_effects!(plan, Base.tail(events), event_index + 1, workspace,
        state, properties, mcs, rng, seed, phase)
    return nothing
end

_launch_compiled_mechanics!(plan, ::Tuple{}, workspace, state, algorithm, rng,
    seed, mcs) = nothing
function _launch_compiled_mechanics!(plan, mechanics::Tuple, workspace, state,
        algorithm, rng, seed, mcs)
    component = first(mechanics)
    kernel = _compiled_mechanical_repair_kernel!(plan.backend, plan.block_size)
    launch!(plan, kernel, component, workspace, state, algorithm, rng, seed, mcs;
        ndrange = length(state.core.active))
    _launch_compiled_mechanics!(plan, Base.tail(mechanics), workspace, state,
        algorithm, rng, seed, mcs)
    return nothing
end

struct CompiledLifecycleError <: Exception
    code::UInt32
    detail1::UInt32
    detail2::UInt32
    detail3::UInt32
end

function Base.showerror(io::IO, error::CompiledLifecycleError)
    if error.code == UInt32(1)
        print(io, "compiled lifecycle conflict for cell ", error.detail1,
            " (event indices ", error.detail2, ", ", error.detail3, ")")
    elseif error.code == UInt32(2)
        print(io, "compiled lifecycle capacity failure: ", error.detail1,
            " valid divisions but only ", error.detail2, " slots available")
    else
        print(io, "compiled lifecycle failure code ", error.code)
    end
end

function run_compiled_lifecycle! end

function run_compiled_lifecycle!(integrator, lifecycle::CompiledLifecycle, mcs)
    plan = integrator.plan
    descriptor = lifecycle.descriptor
    workspace = lifecycle.workspace
    state = scientific_execution(integrator.state)
    capacity = length(state.core.active)
    clear = _clear_compiled_lifecycle_kernel!(plan.backend, plan.block_size)
    launch!(plan, clear, workspace; ndrange = max(capacity, length(workspace.report)))
    _launch_compiled_decisions!(plan, descriptor.events, 1, workspace, state, mcs,
        integrator.rng, integrator.seed)
    conflicts = _compiled_conflict_kernel!(plan.backend, 1)
    launch!(plan, conflicts, descriptor.resolver, descriptor.identity_flags,
        descriptor.priorities, workspace, capacity; ndrange = 1)
    _launch_compiled_division_validation!(plan, descriptor.events, 1, workspace,
        state, mcs, integrator.rng, integrator.seed,
        descriptor.minimum_daughter_volume)
    capacity_kernel = _compiled_capacity_kernel!(plan.backend, 1)
    launch!(plan, capacity_kernel, workspace, state; ndrange = 1)
    reusable = _compiled_reusable_boundary_kernel!(plan.backend, 1)
    launch!(plan, reusable, workspace, state; ndrange = 1)
    for phase in UInt8(1):UInt8(4)
        _launch_compiled_effects!(plan, descriptor.events, 1, workspace, state,
            descriptor.properties, mcs, integrator.rng, integrator.seed, phase)
    end
    rebuild = _compiled_tracker_rebuild_kernel!(plan.backend, 1)
    launch!(plan, rebuild, workspace, state; ndrange = 1)
    _launch_compiled_mechanics!(plan, integrator.components.mechanics, workspace,
        state, integrator.algorithm, integrator.rng, integrator.seed, mcs)
    report = _compiled_lifecycle_report_kernel!(plan.backend, 1)
    launch!(plan, report, workspace, state, mcs; ndrange = 1)
    if lifecycle.descriptor.requires_observation
        synchronize_observation!(plan)
        if !(plan.backend isa KernelAbstractions.CPU)
            record_transfer!(plan, :device_to_host)
        end
        failure = Array(lifecycle.workspace.failure)
        iszero(failure[1]) || throw(CompiledLifecycleError(failure...))
    end
    return integrator
end

function current_lifecycle_report(integrator)
    integrator.lifecycle isa NoCompiledLifecycle && return nothing
    synchronize_observation!(integrator.plan)
    if !(integrator.plan.backend isa KernelAbstractions.CPU)
        record_transfer!(integrator.plan, :device_to_host)
    end
    values = Array(integrator.lifecycle.workspace.report)
    return (mcs = values[1], active_cells = values[2], successful_divisions = values[3],
        free_slots = values[4])
end

run_compiled_lifecycle!(integrator, ::NoCompiledLifecycle, mcs) = integrator
