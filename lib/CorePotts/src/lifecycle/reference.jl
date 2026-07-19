struct LifecycleRNGContext{R <: AbstractRNGContract}
    contract::R
    seed::UInt64
    event_id::UInt64
end

struct AlwaysLifecycleTrigger <: AbstractLifecycleTrigger end
struct PropertyAtLeast{Key, T} <: AbstractLifecycleTrigger
    threshold::T
end
PropertyAtLeast(key::Symbol, threshold::T) where {T} = PropertyAtLeast{key, T}(threshold)
_trigger_property_key(::PropertyAtLeast{Key}) where {Key} = Key
struct BernoulliCellTrigger{T <: AbstractFloat} <: AbstractLifecycleTrigger
    probability::T
    operation::UInt16
    function BernoulliCellTrigger(probability::T, operation::Integer) where {T <: AbstractFloat}
        isfinite(probability) && zero(T) <= probability <= one(T) || throw(ArgumentError(
            "lifecycle Bernoulli probability must lie in [0, 1]"))
        0 <= operation <= 0x03ff || throw(ArgumentError(
            "lifecycle trigger draw role must fit the v1 10-bit domain"))
        new{T}(probability, UInt16(operation))
    end
end

lifecycle_triggered(::AlwaysLifecycleTrigger, snapshot::PreLifecycleSnapshot, target) = true
lifecycle_triggered(trigger::PropertyAtLeast, snapshot::PreLifecycleSnapshot, id::CellID) =
    property_value(snapshot.state, _trigger_property_key(trigger), id) >= trigger.threshold
function lifecycle_triggered(trigger::BernoulliCellTrigger, snapshot::PreLifecycleSnapshot,
        id::CellID, rng::LifecycleRNGContext)
    rng.event_id <= 0x0fff || throw(ArgumentError(
        "a stochastic lifecycle event semantic ID must fit the v1 operation domain"))
    address = RNGAddress(stream = EventStream, mcs = snapshot.mcs,
        operation = rng.event_id, entity_kind = CellEntity, entity = value(id),
        generation = value(generation(snapshot.state, id)), draw = trigger.operation)
    return bernoulli(rng.contract, rng.seed, address, trigger.probability)
end
lifecycle_triggered(trigger::AbstractLifecycleTrigger, snapshot::PreLifecycleSnapshot,
    target, ::LifecycleRNGContext) = lifecycle_triggered(trigger, snapshot, target)

abstract type AbstractLifecyclePlan end
abstract type AbstractPropertyLifecyclePlan <: AbstractLifecyclePlan end
abstract type AbstractTransitionLifecyclePlan <: AbstractLifecyclePlan end
abstract type AbstractDivisionLifecyclePlan <: AbstractLifecyclePlan end
abstract type AbstractDeathLifecyclePlan <: AbstractLifecyclePlan end

struct AddCellProperty{Key, T} <: AbstractLifecycleEffect
    amount::T
end
AddCellProperty(key::Symbol, amount::T) where {T} = AddCellProperty{key, T}(amount)
_effect_property_key(::AddCellProperty{Key}) where {Key} = Key
struct TransitionCell <: AbstractLifecycleEffect
    destination::CellTypeID
end
struct DivideCell{G <: AbstractDivisionGeometry} <: AbstractLifecycleEffect
    geometry::G
end
struct InitiateShrinkDeath{Key, T} <: AbstractLifecycleEffect
    decrement::T
end
InitiateShrinkDeath(key::Symbol, decrement::T) where {T} =
    InitiateShrinkDeath{key, T}(decrement)
_effect_property_key(::InitiateShrinkDeath{Key}) where {Key} = Key
abstract type AbstractRemovalCause end
struct ProgrammedImmediateDeath <: AbstractRemovalCause end
struct StochasticExtinction <: AbstractRemovalCause end

struct RemoveCellImmediately{C <: AbstractRemovalCause} <: AbstractLifecycleEffect
    medium::MediumID
    cause::C
end
RemoveCellImmediately(medium::MediumID) =
    RemoveCellImmediately(medium, ProgrammedImmediateDeath())
RemoveCellImmediately(medium::Integer) = RemoveCellImmediately(MediumID(medium))

struct AddCellPropertyPlan{T} <: AbstractPropertyLifecyclePlan
    cell::CellID
    key::Symbol
    amount::T
end
struct TransitionCellPlan <: AbstractTransitionLifecyclePlan
    cell::CellID
    destination::CellTypeID
end
struct DivideCellPlan{G <: AbstractDivisionGeometry} <: AbstractDivisionLifecyclePlan
    cell::CellID
    geometry::G
end
struct ShrinkDeathPlan{T} <: AbstractPropertyLifecyclePlan
    cell::CellID
    target_key::Symbol
    decrement::T
end
struct RemoveCellPlan{C <: AbstractRemovalCause} <: AbstractDeathLifecyclePlan
    cell::CellID
    medium::MediumID
    cause::C
end

plan_lifecycle_effect(effect::AddCellProperty, snapshot::PreLifecycleSnapshot, id::CellID) =
    AddCellPropertyPlan(id, _effect_property_key(effect), effect.amount)
plan_lifecycle_effect(effect::TransitionCell, snapshot::PreLifecycleSnapshot, id::CellID) =
    TransitionCellPlan(id, effect.destination)
plan_lifecycle_effect(effect::DivideCell, snapshot::PreLifecycleSnapshot, id::CellID) =
    DivideCellPlan(id, effect.geometry)
plan_lifecycle_effect(effect::InitiateShrinkDeath, snapshot::PreLifecycleSnapshot, id::CellID) =
    ShrinkDeathPlan(id, _effect_property_key(effect), effect.decrement)
plan_lifecycle_effect(effect::RemoveCellImmediately, snapshot::PreLifecycleSnapshot, id::CellID) =
    RemoveCellPlan(id, effect.medium, effect.cause)
plan_lifecycle_effect(effect::AbstractLifecycleEffect, snapshot::PreLifecycleSnapshot,
    target, ::LifecycleRNGContext) = plan_lifecycle_effect(effect, snapshot, target)

struct VectorDivision{N, T <: AbstractFloat} <: AbstractDivisionGeometry
    direction::SVector{N, T}
end

function VectorDivision(direction::NTuple{N, <:Real}; number_type::Type{T} = Float32) where {
        N, T <: AbstractFloat}
    N in (2, 3) || throw(ArgumentError("division vectors must be 2D or 3D"))
    values = SVector{N, T}(direction)
    magnitude = sqrt(sum(abs2, values))
    isfinite(magnitude) && magnitude > 0 || throw(ArgumentError(
        "division direction must be finite and nonzero"))
    normalized = values / magnitude
    return VectorDivision{N, T}(normalized)
end

struct RandomOrientationDivision <: AbstractDivisionGeometry
    operation::UInt16
    function RandomOrientationDivision(operation::Integer)
        0 <= operation <= 0x03ff || throw(ArgumentError(
            "division orientation draw role must fit the v1 10-bit domain"))
        new(UInt16(operation))
    end
end
struct MajorAxisDivision <: AbstractDivisionGeometry end
struct MinorAxisDivision <: AbstractDivisionGeometry end

division_region(geometry::VectorDivision{N}, context::DivisionSiteContext{N}) where {N} =
    sum((context.coordinate - context.center) .* geometry.direction) < 0 ? UInt8(1) : UInt8(2)

function _parent_coordinates(state::LogicalPottsState{N}, id::CellID) where {N}
    coordinates = SVector{N, Float64}[]
    for site in CartesianIndices(state._owners)
        state._owners[site] == CellOwner(id) && push!(coordinates,
            SVector{N, Float64}(ntuple(axis -> Float64(site[axis]), N)))
    end
    return coordinates
end

function _canonical_axis(vector)
    for value in vector
        if abs(value) > 64eps(eltype(vector))
            return value < 0 ? -vector : vector
        end
    end
    return vector
end

function _moment_axis(state::LogicalPottsState{N}, id::CellID, major::Bool) where {N}
    coordinates = _parent_coordinates(state, id)
    center = sum(coordinates) / length(coordinates)
    covariance = zeros(Float64, N, N)
    for coordinate in coordinates
        displacement = coordinate - center
        covariance .+= displacement * transpose(displacement)
    end
    decomposition = eigen(Symmetric(covariance))
    index = major ? lastindex(decomposition.values) : firstindex(decomposition.values)
    return VectorDivision(Tuple(_canonical_axis(decomposition.vectors[:, index])))
end

prepare_division_geometry(geometry::AbstractDivisionGeometry, snapshot::PreLifecycleSnapshot,
    id::CellID, rng::LifecycleRNGContext) = geometry
prepare_division_geometry(::MajorAxisDivision, snapshot::PreLifecycleSnapshot,
    id::CellID, rng::LifecycleRNGContext) = _moment_axis(snapshot.state, id, true)
prepare_division_geometry(::MinorAxisDivision, snapshot::PreLifecycleSnapshot,
    id::CellID, rng::LifecycleRNGContext) = _moment_axis(snapshot.state, id, false)
function prepare_division_geometry(geometry::RandomOrientationDivision,
        snapshot::PreLifecycleSnapshot, id::CellID, rng::LifecycleRNGContext)
    N = ndims(snapshot.state._owners)
    rng.event_id <= 0x0fff || throw(ArgumentError(
        "a stochastic division event semantic ID must fit the v1 operation domain"))
    address = RNGAddress(stream = DivisionOrientationStream, mcs = snapshot.mcs,
        operation = rng.event_id, entity_kind = CellEntity, entity = value(id),
        generation = value(generation(snapshot.state, id)), draw = geometry.operation)
    first_draw = uniform_open01(Float64, rng.contract, rng.seed, address; lane = 1)
    if N == 2
        angle = 2pi * first_draw
        return VectorDivision((cos(angle), sin(angle)))
    end
    second_draw = uniform_open01(Float64, rng.contract, rng.seed, address; lane = 3)
    z = 2first_draw - 1
    radius = sqrt(max(0.0, 1 - z * z))
    angle = 2pi * second_draw
    return VectorDivision((radius * cos(angle), radius * sin(angle), z))
end

function division_sites(geometry::AbstractDivisionGeometry, snapshot::PreLifecycleSnapshot,
        id::CellID, rng::LifecycleRNGContext)
    coordinates = _parent_coordinates(snapshot.state, id)
    center = sum(coordinates) / length(coordinates)
    prepared = prepare_division_geometry(geometry, snapshot, id, rng)
    labels = UInt8[]
    sites = Int[]
    for site in eachindex(snapshot.state._owners)
        snapshot.state._owners[site] == CellOwner(id) || continue
        coordinate = CartesianIndices(snapshot.state._owners)[site]
        context = DivisionSiteContext(
            ntuple(axis -> Float64(coordinate[axis]), length(center)), Tuple(center))
        label = division_region(prepared, context)
        push!(labels, label)
        label == UInt8(2) && push!(sites, site)
    end
    return validate_binary_partition(labels).valid ? sites : nothing
end

struct PlannedLifecycleAction{P <: AbstractLifecyclePlan}
    plan::P
    semantic_id::UInt64
    priority::Int32
end

identity_target(::AbstractLifecyclePlan) = nothing
identity_target(plan::Union{TransitionCellPlan, DivideCellPlan, RemoveCellPlan}) = plan.cell

function validate_lifecycle_plan end
function commit_property_plan! end

function validate_lifecycle_plan(plan::Union{AddCellPropertyPlan, ShrinkDeathPlan}, snapshot)
    is_active(snapshot.state, plan.cell) || throw(ArgumentError("lifecycle property target is inactive"))
    descriptor = property_descriptor(snapshot.state.properties.schema,
        plan isa AddCellPropertyPlan ? plan.key : plan.target_key)
    descriptor.mutability === MutableProperty || throw(ArgumentError(
        "lifecycle property target is read-only"))
    return nothing
end
validate_lifecycle_plan(plan::TransitionCellPlan, snapshot) =
    is_active(snapshot.state, plan.cell) || throw(ArgumentError("transition target is inactive"))
validate_lifecycle_plan(plan::DivideCellPlan, snapshot) =
    is_active(snapshot.state, plan.cell) || throw(ArgumentError("division target is inactive"))
function validate_lifecycle_plan(plan::RemoveCellPlan, snapshot)
    is_active(snapshot.state, plan.cell) || throw(ArgumentError("death target is inactive"))
    plan.medium in snapshot.state._medium_ids || throw(ArgumentError("death medium is undeclared"))
    return nothing
end

function commit_property_plan!(state, plan::AddCellPropertyPlan)
    current = property_value(state, plan.key, plan.cell)
    return set_cell_property!(state, plan.key, plan.cell, current + plan.amount)
end
function commit_property_plan!(state, plan::ShrinkDeathPlan)
    current = property_value(state, plan.target_key, plan.cell)
    return set_cell_property!(state, plan.target_key, plan.cell,
        max(zero(current), current - plan.decrement))
end

"""Open family-owned repair hook after committed division and derived-state reconstruction."""
function repair_division_state! end

_division_policy(component, state) = property_descriptor(state.properties.schema,
    property_key(_mechanical_state(component))).division

function _constitutive_mechanical_value(component::FluctuatingVolumePressure, state, id)
    index = Int(value(id))
    target = property_values(state, property_key(_mechanical_target(component)))[index]
    strength = property_values(state, property_key(_mechanical_strength(component)))[index]
    return 2 * strength * (finite_volume(state, id) - target)
end

function _constitutive_mechanical_value(component::FluctuatingSurfaceTension, state, id, domain)
    domain === nothing && throw(ArgumentError(
        "surface-tension division repair requires the realized Cartesian domain"))
    index = Int(value(id))
    target = property_values(state, property_key(_mechanical_target(component)))[index]
    strength = property_values(state, property_key(_mechanical_strength(component)))[index]
    observable = boundary_measure(state, domain, component.relation, CellOwner(id), component.metric)
    return 2 * strength * (observable - target)
end

_constitutive_mechanical_value(component::FluctuatingVolumePressure, state, id, domain) =
    _constitutive_mechanical_value(component, state, id)

_lifecycle_mechanical_noise(noise::FixedMechanicalNoise, supplied) = noise.value
function _lifecycle_mechanical_noise(::AlgorithmTemperatureNoise, supplied)
    supplied === nothing && throw(ArgumentError(
        "stationary mechanical redraw with algorithm-temperature noise requires `mechanical_noise_scale`"))
    return supplied
end

function _repair_mechanical_division!(::PreserveMechanicalOnDivision,
        component, state, assignments, mcs, rng; domain, mechanical_noise_scale)
    return state
end

function _repair_mechanical_division!(::ConstitutiveResetAfterDivision,
        component, state, assignments, mcs, rng; domain, mechanical_noise_scale)
    values = property_values(state, property_key(_mechanical_state(component)))
    for (parent, child) in assignments
        values[Int(value(parent))] =
            _constitutive_mechanical_value(component, state, parent, domain)
        values[Int(value(child))] =
            _constitutive_mechanical_value(component, state, child, domain)
    end
    return state
end

function _repair_mechanical_division!(::StationaryRedrawAfterDivision,
        component, state, assignments, mcs, rng; domain, mechanical_noise_scale)
    component.instance_id <= 0x0fff || throw(ArgumentError(
        "mechanical instance ID exceeds the v1 lifecycle RNG operation domain"))
    values = property_values(state, property_key(_mechanical_state(component)))
    strength_values = property_values(state,
        property_key(_mechanical_strength(component)))
    noise = _lifecycle_mechanical_noise(component.noise, mechanical_noise_scale)
    for (parent, child) in assignments
        for id in (parent, child)
            mean = _constitutive_mechanical_value(component, state, id, domain)
            index = Int(value(id))
            address = RNGAddress(stream = PropertyInheritanceStream, mcs = mcs,
                operation = component.instance_id, entity_kind = CellEntity,
                entity = value(id), generation = value(generation(state, id)))
            normal = normal_box_muller(eltype(values), rng.contract, rng.seed, address)
            values[index] = mean + sqrt(2 * strength_values[index] * noise) * normal
        end
    end
    return state
end

function repair_division_state!(component::Union{FluctuatingVolumePressure,
        FluctuatingSurfaceTension}, state::LogicalPottsState, assignments, mcs,
        rng::LifecycleRNGContext; domain = nothing, mechanical_noise_scale = nothing)
    policy = _division_policy(component, state)
    return _repair_mechanical_division!(policy, component, state, assignments,
        mcs, rng; domain, mechanical_noise_scale)
end

struct LifecyclePhaseReport
    mcs::Int64
    property_updates::Int
    death_program_initiations::Int
    type_transitions::Int
    successful_divisions::Int
    failed_division_geometry::Int
    immediate_deaths::Int
    stochastic_extinctions::Int
    active_cells::Int
    free_slots::Int
end

function _release_pending_slots(state::LogicalPottsState)
    candidate = _copy_logical_state(state)
    for index in eachindex(candidate._active)
        if !candidate._active[index] && candidate._generations[index] != CellGeneration(0) &&
                !(CellSlot(index) in candidate._reusable)
            push!(candidate._reusable, CellSlot(index))
        end
    end
    sort!(unique!(candidate._reusable); by = value)
    return candidate
end

function _lifecycle_targets(::ActiveCellsTarget, snapshot)
    return active_cell_ids(snapshot.state)
end
_lifecycle_targets(::GlobalModelTarget, snapshot) = (nothing,)

function apply_lifecycle_phase(state::LogicalPottsState, events, mcs::Integer;
        resolver::AbstractLifecycleConflictResolver = RejectLifecycleConflicts(),
        seed::Integer = 0, rng_contract::AbstractRNGContract = Philox4x32x10V1(),
        minimum_daughter_volume::Integer = 1, lifecycle_components = (),
        domain = nothing, mechanical_noise_scale = nothing)
    assert_valid_state(state)
    0 <= seed <= typemax(UInt64) || throw(ArgumentError("lifecycle seed must fit in UInt64"))
    released = _release_pending_slots(state)
    snapshot = PreLifecycleSnapshot(_copy_logical_state(released), mcs)
    actions = PlannedLifecycleAction[]
    for event in events
        is_due(event.schedule, mcs) || continue
        rng = LifecycleRNGContext(rng_contract, UInt64(seed), event.semantic_id)
        for target in _lifecycle_targets(event.target, snapshot)
            lifecycle_triggered(event.trigger, snapshot, target, rng) || continue
            plan = plan_lifecycle_effect(event.effect, snapshot, target, rng)
            validate_lifecycle_plan(plan, snapshot)
            push!(actions, PlannedLifecycleAction(plan, event.semantic_id, event.priority))
        end
    end

    claims = LifecycleConflictClaim[]
    for (index, action) in enumerate(actions)
        target = identity_target(action.plan)
        target === nothing || push!(claims, LifecycleConflictClaim(target, action.priority,
            action.semantic_id, Int32(index)))
    end
    winners = Set(resolve_lifecycle_conflicts(resolver, claims))
    selected = [action for (index, action) in enumerate(actions)
        if identity_target(action.plan) === nothing || Int32(index) in winners]
    sort!(selected; by = action -> action.semantic_id)
    candidate = _copy_logical_state(released)
    property_updates = 0
    shrink_initiations = 0
    transitions = 0
    failed_geometry = 0
    for action in selected
        action.plan isa AbstractPropertyLifecyclePlan || continue
        commit_property_plan!(candidate, action.plan)
        property_updates += 1
        action.plan isa ShrinkDeathPlan && (shrink_initiations += 1)
    end
    for action in selected
        action.plan isa AbstractTransitionLifecyclePlan || continue
        candidate = transition_cell_type(candidate, action.plan.cell, action.plan.destination)
        transitions += 1
    end
    division_requests = DivisionRequest[]
    for action in selected
        action.plan isa AbstractDivisionLifecyclePlan || continue
        rng = LifecycleRNGContext(rng_contract, UInt64(seed), action.semantic_id)
        sites = division_sites(action.plan.geometry, snapshot, action.plan.cell, rng)
        sites === nothing ? (failed_geometry += 1) :
            push!(division_requests, DivisionRequest(action.plan.cell, sites))
    end
    division_assignments = Pair{CellID, CellID}[]
    if !isempty(division_requests)
        division_result = apply_division_batch(candidate, division_requests;
            minimum_daughter_volume)
        candidate = logical_state(division_result)
        division_assignments = division_result.assignments
        rng = LifecycleRNGContext(rng_contract, UInt64(seed), UInt64(0))
        for component in lifecycle_components
            repair_division_state!(component, candidate, division_assignments, mcs, rng;
                domain, mechanical_noise_scale)
        end
    end
    immediate_deaths = 0
    stochastic_extinctions = 0
    for action in selected
        action.plan isa AbstractDeathLifecyclePlan || continue
        candidate = logical_state(immediately_remove_cell(candidate,
            action.plan.cell, action.plan.medium))
        immediate_deaths += 1
        action.plan.cause isa StochasticExtinction && (stochastic_extinctions += 1)
    end
    assert_valid_state(candidate)
    report = LifecyclePhaseReport(Int64(mcs), property_updates, shrink_initiations,
        transitions, length(division_requests), failed_geometry, immediate_deaths,
        stochastic_extinctions,
        n_cells(candidate), nslots(capacity(candidate)) - n_cells(candidate))
    return candidate, report
end
