module Events

using CorePotts
using SciMLBase
using KernelAbstractions
using CorePotts.Atomix
import Random

import ..System: CellType, PottsSystem, required_variables

export AbstractEvent, AbstractTrigger, AbstractAction
export VolumeRatioTrigger, AgeTrigger, ProbabilityTrigger, CustomTrigger
export MitosisEvent, ApoptosisEvent, TransitionEvent

# Inheritance rules re-exported from CorePotts
export Reset, ResetChild, AsymmetricReset, Add, Multiply, RandomUniform, RandomNormal

# Continuous Property Update rules
export PropertyUpdateEvent

# ------------------------------------------------------------------
# 1. Abstract Types
# ------------------------------------------------------------------
abstract type AbstractTrigger end
abstract type AbstractEvent <: CorePotts.AbstractEvent end
abstract type AbstractAction end

# ------------------------------------------------------------------
# 2. Triggers
# ------------------------------------------------------------------
struct VolumeRatioTrigger <: AbstractTrigger
    factor::Float32
end
VolumeRatioTrigger(f::Real) = VolumeRatioTrigger(Float32(f))
required_variables(trigger::AbstractTrigger) = (;)

struct AgeTrigger <: AbstractTrigger
    max_age::Int32
end
AgeTrigger(a::Integer) = AgeTrigger(Int32(a))
required_variables(trigger::AgeTrigger) = (ages = Int32,)

struct ProbabilityTrigger <: AbstractTrigger
    prob::Float32
end
ProbabilityTrigger(p::Real) = ProbabilityTrigger(Float32(p))

struct CustomTrigger{F} <: AbstractTrigger
    func::F
end

# ------------------------------------------------------------------
# 3. Events
# ------------------------------------------------------------------
struct MitosisEvent{
    T <: AbstractTrigger, O <: CorePotts.DivisionOrientation, I <: NamedTuple, A} <:
       AbstractEvent
    cell_type::CellType
    trigger::T
    orientation::O
    inheritance::I
    action::A
end

function MitosisEvent(cell_type::CellType; trigger::AbstractTrigger,
        orientation::CorePotts.DivisionOrientation = CorePotts.RandomOrientation(),
        inheritance::NamedTuple = (target_volumes = CorePotts.Split(0.5f0),),
        action = nothing)
    return MitosisEvent(cell_type, trigger, orientation, inheritance, action)
end

struct ApoptosisEvent{T <: AbstractTrigger} <: AbstractEvent
    cell_type::CellType
    trigger::T
end

function ApoptosisEvent(cell_type::CellType; trigger::AbstractTrigger)
    return ApoptosisEvent(cell_type, trigger)
end

struct TransitionEvent{T <: AbstractTrigger} <: AbstractEvent
    transition::Pair{CellType, CellType}
    trigger::T
end

function TransitionEvent(transition::Pair{CellType, CellType}; trigger::AbstractTrigger)
    return TransitionEvent(transition, trigger)
end

# ------------------------------------------------------------------
# 4. Compilation & Unified Master Callback
# ------------------------------------------------------------------


# Traits
@inline is_apoptosis(::AbstractEvent) = false
@inline is_apoptosis(::ApoptosisEvent) = true

@inline is_transition(::AbstractEvent) = false
@inline is_transition(::TransitionEvent) = true

@inline is_mitosis(::AbstractEvent) = false
@inline is_mitosis(::MitosisEvent) = true

# Evaluate Triggers
@inline _evaluate_trigger(trigger::AbstractTrigger, cell_id::Integer, cell_data, step) = false
@inline _evaluate_trigger(trigger::VolumeRatioTrigger, cell_id::Integer,
    cell_data, step) = cell_data.target_volumes[cell_id] > 0 &&
                 cell_data.volumes[cell_id] >=
                 (trigger.factor * cell_data.target_volumes[cell_id])
@inline _evaluate_trigger(trigger::AgeTrigger, cell_id::Integer, cell_data, step) = cell_data.cell_ages[cell_id] >=
                                                                              trigger.max_age
@inline _evaluate_trigger(trigger::ProbabilityTrigger, cell_id::Integer, cell_data, step) = CorePotts.gpu_rand_uniform(cell_id, step, 1, 0.0f0, 1.0f0) <
                                                                                      trigger.prob
@inline _evaluate_trigger(trigger::CustomTrigger, cell_id::Integer, cell_data, step) = trigger.func(
    cell_id, cell_data)

# Apoptosis Unrolling
@inline evaluate_apoptosis!(events::Tuple{}, t_id, cell_data, i, step) = false
@inline function evaluate_apoptosis!(events::Tuple, t_id, cell_data, i, step)
    evt = first(events)
    if is_apoptosis(evt) && t_id == get_cell_type_id(evt)
        if _evaluate_trigger(evt.trigger, i, cell_data, step)
            if hasproperty(cell_data, :target_volumes)
                cell_data.target_volumes[i] = 0
            end
            return true
        end
    end
    return evaluate_apoptosis!(Base.tail(events), t_id, cell_data, i, step)
end

# Transition Unrolling
@inline evaluate_transitions!(events::Tuple{}, t_id, cell_data, i, step) = false
@inline function evaluate_transitions!(events::Tuple, t_id, cell_data, i, step)
    evt = first(events)
    if is_transition(evt) && t_id == get_transition_from_id(evt)
        if _evaluate_trigger(evt.trigger, i, cell_data, step)
            cell_data.cell_types[i] = get_transition_to_id(evt)
            return true
        end
    end
    return evaluate_transitions!(Base.tail(events), t_id, cell_data, i, step)
end

# Mitosis Unrolling
@inline evaluate_mitosis(events::Tuple{}, t_id, cell_data, i, step) = false
@inline function evaluate_mitosis(events::Tuple, t_id, cell_data, i, step)
    evt = first(events)
    if is_mitosis(evt) && t_id == get_cell_type_id(evt)
        if _evaluate_trigger(evt.trigger, i, cell_data, step)
            return true
        end
    end
    return evaluate_mitosis(Base.tail(events), t_id, cell_data, i, step)
end

# Mitosis Trigger Wrapper for CorePotts
struct MitosisTriggerWrapper{E, T}
    events::E
    types::T
end
import Adapt
function Adapt.adapt_structure(to, x::MitosisTriggerWrapper)
    MitosisTriggerWrapper(
        Adapt.adapt(to, x.events),
        Adapt.adapt(to, x.types)
    )
end

@inline function (wrapper::MitosisTriggerWrapper)(i, cell_data, step)
    t_id = wrapper.types[i]
    if t_id == 0
        ;
        return false;
    end
    return evaluate_mitosis(wrapper.events, t_id, cell_data, i, step)
end

# Find first Mitosis event for inheritance rules
@inline get_first_mitosis_event(events::Tuple{}) = nothing
@inline function get_first_mitosis_event(events::Tuple)
    evt = first(events)
    if is_mitosis(evt)
        return evt
    end
    return get_first_mitosis_event(Base.tail(events))
end

# Resolve Cell Type IDs dynamically within the Tuple wrappers
@inline get_cell_type_id(evt::AbstractEvent) = evt.type_id
@inline get_transition_from_id(evt::TransitionEvent) = evt.from_id
@inline get_transition_to_id(evt::TransitionEvent) = evt.to_id

# ------------------------------------------------------------------
# Internal Wrappers with Resolved IDs
# ------------------------------------------------------------------
struct ResolvedApoptosisEvent{T} <: AbstractEvent
    check_interval::Int
    type_id::UInt8
    trigger::T
end
@inline is_apoptosis(::ResolvedApoptosisEvent) = true

struct ResolvedTransitionEvent{T} <: AbstractEvent
    check_interval::Int
    from_id::UInt8
    to_id::UInt8
    trigger::T
end
@inline is_transition(::ResolvedTransitionEvent) = true

struct ResolvedMitosisEvent{T, O, I, A, W} <: AbstractEvent
    check_interval::Int
    type_id::UInt8
    trigger::T
    orientation::O
    inheritance::I
    action::A
    workspace::W
end
@inline is_mitosis(::ResolvedMitosisEvent) = true

struct ResolvedPropertyUpdateEvent{R, W} <: AbstractEvent
    check_interval::Int
    type_id::UInt8
    rules::R
    workspace::W
    function ResolvedPropertyUpdateEvent(check_interval::Int, type_id::UInt8, rules::R, workspace::W=nothing) where {R, W}
        new{R, W}(check_interval, type_id, rules, workspace)
    end
end

function resolve_events(events::Tuple, type_to_id::Dict, check_interval::Int)
    resolved = []
    for evt in events
        if evt isa ApoptosisEvent
            if haskey(type_to_id, evt.cell_type)
                push!(resolved, ResolvedApoptosisEvent(check_interval, type_to_id[evt.cell_type], evt.trigger))
            end
        elseif evt isa TransitionEvent
            if haskey(type_to_id, evt.transition.first) &&
               haskey(type_to_id, evt.transition.second)
                push!(resolved,
                    ResolvedTransitionEvent(
                        check_interval, type_to_id[evt.transition.first],
                        type_to_id[evt.transition.second], evt.trigger))
            end
        elseif evt isa MitosisEvent
            if haskey(type_to_id, evt.cell_type)
                push!(resolved,
                    ResolvedMitosisEvent(
                        check_interval, type_to_id[evt.cell_type], evt.trigger,
                        evt.orientation, evt.inheritance, evt.action, nothing))
            end
        elseif evt isa CorePotts.PropertyUpdateEvent
            if haskey(type_to_id, evt.cell_type)
                compiled_rules = map(CorePotts.build_rule, evt.rules)
                push!(resolved,
                    ResolvedPropertyUpdateEvent(check_interval, type_to_id[evt.cell_type], compiled_rules))
            end

        elseif evt isa CorePotts.AbstractMultiEvent
            append!(resolved, resolve_events(CorePotts.get_sub_events(evt), type_to_id, check_interval))
        elseif evt isa CorePotts.AbstractEvent
            push!(resolved, evt)
        end
    end
    return Tuple(resolved)
end

function CorePotts.initialize_workspace(evt::ResolvedMitosisEvent, u, topology)
    ws = CorePotts.MitosisWorkspace(u.grid, length(u.cell_data.volumes))
    return ResolvedMitosisEvent(evt.check_interval, evt.type_id, evt.trigger, evt.orientation, evt.inheritance, evt.action, ws)
end

function CorePotts.initialize_workspace(evt::ResolvedPropertyUpdateEvent, u, topology)
    all_spatial = CorePotts.extract_spatial_rules(evt.rules)
    buf_size = length(all_spatial) * length(u.cell_data.volumes)
    max_edges = length(u.grid) * length(CorePotts.offsets(topology))
    
    ws = if buf_size > 0
        (;
            spatial_buffer = similar(u.grid, UInt32, buf_size),
            edge_list = similar(u.grid, UInt64, max_edges),
            edge_count = similar(u.grid, UInt32, 1)
        )
    else
        nothing
    end
    
    return ResolvedPropertyUpdateEvent(evt.check_interval, evt.type_id, evt.rules, ws)
end

function resolve_events(events::Tuple, type_to_id::Dict)
    return resolve_events(events, type_to_id, 1)
end

function compile_events(events::Tuple, sys::PottsSystem, type_to_id::Dict, check_interval::Int = 10)
    reqs = []
    for evt in events
        if hasproperty(evt, :trigger)
            req_trigger = required_variables(evt.trigger)
            push!(reqs, req_trigger)
        end
        req_action = required_variables(hasproperty(evt, :action) ? evt.action : nothing)
        push!(reqs, req_action)
        
        req_evt = required_variables(evt)
        push!(reqs, req_evt)
        
        if evt isa MitosisEvent
            push!(reqs, (volumes = Int32,))
        end
    end

    resolved_events = resolve_events(events, type_to_id, check_interval)
    return resolved_events, reqs
end

# ------------------------------------------------------------------
# 5. CorePotts process_event! Implementations
# ------------------------------------------------------------------

CorePotts.has_device_trigger(::ResolvedApoptosisEvent) = true
@inline function CorePotts.evaluate_trigger(evt::ResolvedApoptosisEvent, i, cd, t)
    if t % evt.check_interval == 0
        t_id = cd.cell_types[i]
        if t_id == evt.type_id
            if cd.volumes[i] > 0
                return _evaluate_trigger(evt.trigger, i, cd, t)
            end
        end
    end
    return false
end

@kernel function apoptosis_kernel!(mask, target_volumes)
    i = @index(Global, Linear)
    if mask[i]
        target_volumes[i] = 0
    end
end

function CorePotts.get_event_kernel(::ResolvedApoptosisEvent, backend, block_size)
    apoptosis_kernel!(backend, block_size)
end

function CorePotts.get_event_args(evt::ResolvedApoptosisEvent, mask, u, p, cache, t)
    if t % evt.check_interval != 0 || !hasproperty(u.cell_data, :target_volumes)
        return nothing
    end
    return (mask, u.cell_data.target_volumes)
end

CorePotts.has_device_trigger(::ResolvedTransitionEvent) = true
@inline function CorePotts.evaluate_trigger(evt::ResolvedTransitionEvent, i, cd, t)
    if t % evt.check_interval == 0
        t_id = cd.cell_types[i]
        if t_id == evt.from_id
            if cd.volumes[i] > 0
                return _evaluate_trigger(evt.trigger, i, cd, t)
            end
        end
    end
    return false
end

@kernel function transition_kernel!(mask, cell_types, to_id)
    i = @index(Global, Linear)
    if mask[i]
        cell_types[i] = to_id
    end
end

function CorePotts.get_event_kernel(::ResolvedTransitionEvent, backend, block_size)
    transition_kernel!(backend, block_size)
end

function CorePotts.get_event_args(evt::ResolvedTransitionEvent, mask, u, p, cache, t)
    if t % evt.check_interval != 0
        return nothing
    end
    return (mask, u.cell_data.cell_types, evt.to_id)
end

struct MaskTrigger{M}
    mask::M
end
@inline (mt::MaskTrigger)(i, cd, step) = mt.mask[i]
import Adapt
Adapt.adapt_structure(to, x::MaskTrigger) = MaskTrigger(Adapt.adapt(to, x.mask))

CorePotts.has_device_trigger(::ResolvedMitosisEvent) = true
@inline function CorePotts.evaluate_trigger(evt::ResolvedMitosisEvent, i, cd, t)
    if t % evt.check_interval == 0
        t_id = cd.cell_types[i]
        if t_id == evt.type_id
            if cd.volumes[i] > 0
                return _evaluate_trigger(evt.trigger, i, cd, t)
            end
        end
    end
    return false
end

function CorePotts.process_event!(evt::ResolvedMitosisEvent, mask, u, p, cache, t, deps)
    if t % evt.check_interval != 0
        return nothing
    end

    ws = evt.workspace

    trigger_wrapper = MaskTrigger(mask)
    
    # Process the entire mitosis logic on the GPU. `deps` is passed through and waited on implicitly by the kernels.
    CorePotts.process_mitosis_events!(
        u, p, cache, ws;
        trigger = trigger_wrapper,
        orientation = evt.orientation,
        inheritance_rules = evt.inheritance,
        deps = deps
    )

    # CorePotts.process_mitosis_events! currently synchronizes internally before updating local metrics.
    return nothing
end

CorePotts.has_device_trigger(::ResolvedPropertyUpdateEvent) = false

function CorePotts.process_event!(
        evt::ResolvedPropertyUpdateEvent, mask, u, p, cache, t, deps)
    if t % evt.check_interval != 0
        return deps
    end
    backend = KernelAbstractions.get_backend(u.grid)
    all_spatial = CorePotts.extract_spatial_rules(evt.rules)

    spatial_buffer = nothing
    spatial_buffer = nothing
    if length(all_spatial) > 0
        spatial_buffer, ev_spatial = CorePotts.populate_spatial_buffer!(
            u, p.topology, cache, evt.workspace, all_spatial, deps)
        if ev_spatial !== nothing
            deps = (deps..., ev_spatial)
        end
    end

    ctx = (t = t, step_counter = cache.step_counter[], spatial_buffer = spatial_buffer)
    k_prop = CorePotts._kernel_property_update!(backend, cache.block_size)
    nd_prop = length(u.cell_data.volumes)

    ev_prop = CorePotts.dispatch_kernel!(
        k_prop, u.cell_data, evt.rules, evt.type_id, ctx;
        ndrange = nd_prop, dependencies = deps)

    return ev_prop === nothing ? deps : (ev_prop,)
end

end
