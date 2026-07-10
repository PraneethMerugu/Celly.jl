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

# ------------------------------------------------------------------
# 1. Abstract Types
# ------------------------------------------------------------------
abstract type AbstractTrigger end
abstract type AbstractEvent end
abstract type AbstractAction end

# ------------------------------------------------------------------
# 2. Triggers
# ------------------------------------------------------------------
struct VolumeRatioTrigger <: AbstractTrigger
    factor::Float32
end
VolumeRatioTrigger(f::Real) = VolumeRatioTrigger(Float32(f))
required_variables(trigger::AbstractTrigger) = nothing

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

using AcceleratedKernels

# Traits
@inline is_apoptosis(::AbstractEvent) = false
@inline is_apoptosis(::ApoptosisEvent) = true

@inline is_transition(::AbstractEvent) = false
@inline is_transition(::TransitionEvent) = true

@inline is_mitosis(::AbstractEvent) = false
@inline is_mitosis(::MitosisEvent) = true

# Evaluate Triggers
@inline _evaluate_trigger(trigger::AbstractTrigger, cell_id::Integer, cell_data) = false
@inline _evaluate_trigger(trigger::VolumeRatioTrigger, cell_id::Integer,
    cell_data) = cell_data.volumes[cell_id] >=
                 (trigger.factor * cell_data.target_volumes[cell_id])
@inline _evaluate_trigger(trigger::AgeTrigger, cell_id::Integer, cell_data) = cell_data.cell_ages[cell_id] >=
                                                                              trigger.max_age
@inline _evaluate_trigger(trigger::ProbabilityTrigger, cell_id::Integer, cell_data) = rand(Float32) <
                                                                                      trigger.prob
@inline _evaluate_trigger(trigger::CustomTrigger, cell_id::Integer, cell_data) = trigger.func(
    cell_id, cell_data)

# Apoptosis Unrolling
@inline evaluate_apoptosis!(events::Tuple{}, t_id, cell_data, i) = false
@inline function evaluate_apoptosis!(events::Tuple, t_id, cell_data, i)
    evt = first(events)
    if is_apoptosis(evt) && t_id == get_cell_type_id(evt)
        if _evaluate_trigger(evt.trigger, i, cell_data)
            cell_data.cell_types[i] = 0
            if hasproperty(cell_data, :target_volumes)
                cell_data.target_volumes[i] = 0
            end
            return true
        end
    end
    return evaluate_apoptosis!(Base.tail(events), t_id, cell_data, i)
end

# Transition Unrolling
@inline evaluate_transitions!(events::Tuple{}, t_id, cell_data, i) = false
@inline function evaluate_transitions!(events::Tuple, t_id, cell_data, i)
    evt = first(events)
    if is_transition(evt) && t_id == get_transition_from_id(evt)
        if _evaluate_trigger(evt.trigger, i, cell_data)
            cell_data.cell_types[i] = get_transition_to_id(evt)
            return true
        end
    end
    return evaluate_transitions!(Base.tail(events), t_id, cell_data, i)
end

# Mitosis Unrolling
@inline evaluate_mitosis(events::Tuple{}, t_id, cell_data, i) = false
@inline function evaluate_mitosis(events::Tuple, t_id, cell_data, i)
    evt = first(events)
    if is_mitosis(evt) && t_id == get_cell_type_id(evt)
        if _evaluate_trigger(evt.trigger, i, cell_data)
            return true
        end
    end
    return evaluate_mitosis(Base.tail(events), t_id, cell_data, i)
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

@inline function (wrapper::MitosisTriggerWrapper)(i, cell_data)
    t_id = wrapper.types[i]
    if t_id == 0
        ;
        return false;
    end
    return evaluate_mitosis(wrapper.events, t_id, cell_data, i)
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
    type_id::UInt8
    trigger::T
end
@inline is_apoptosis(::ResolvedApoptosisEvent) = true

struct ResolvedTransitionEvent{T} <: AbstractEvent
    from_id::UInt8
    to_id::UInt8
    trigger::T
end
@inline is_transition(::ResolvedTransitionEvent) = true

struct ResolvedMitosisEvent{T, O, I, A} <: AbstractEvent
    type_id::UInt8
    trigger::T
    orientation::O
    inheritance::I
    action::A
end
@inline is_mitosis(::ResolvedMitosisEvent) = true

function resolve_events(events::Tuple, type_to_id::Dict)
    resolved = []
    for evt in events
        if evt isa ApoptosisEvent
            if haskey(type_to_id, evt.cell_type)
                push!(resolved, ResolvedApoptosisEvent(type_to_id[evt.cell_type], evt.trigger))
            end
        elseif evt isa TransitionEvent
            if haskey(type_to_id, evt.transition.first) &&
               haskey(type_to_id, evt.transition.second)
                push!(resolved,
                    ResolvedTransitionEvent(type_to_id[evt.transition.first],
                        type_to_id[evt.transition.second], evt.trigger))
            end
        elseif evt isa MitosisEvent
            if haskey(type_to_id, evt.cell_type)
                push!(resolved,
                    ResolvedMitosisEvent(type_to_id[evt.cell_type], evt.trigger,
                        evt.orientation, evt.inheritance, evt.action))
            end
        end
    end
    return Tuple(resolved)
end

function compile_events(events::Tuple, sys::PottsSystem, type_to_id::Dict, check_interval::Int = 10)
    reqs = []
    for evt in events
        req_trigger = required_variables(evt.trigger)
        if req_trigger !== nothing
            push!(reqs, req_trigger)
        end
        req_action = required_variables(hasproperty(evt, :action) ? evt.action : nothing)
        if req_action !== nothing
            push!(reqs, req_action)
        end
        req_evt = required_variables(evt)
        if req_evt !== nothing
            push!(reqs, req_evt)
        end
        if evt isa MitosisEvent
            push!(reqs, (volumes = Int32,))
        end
    end

    resolved_events = resolve_events(events, type_to_id)
    if isempty(resolved_events)
        return SciMLBase.CallbackSet(), reqs, nothing
    end

    ws_ref = Ref{CorePotts.MitosisWorkspace}()
    condition(u, t, integrator) = (t % check_interval == 0)

    mitosis_evt = get_first_mitosis_event(resolved_events)

    function affect!(integrator)
        u = integrator.u
        p = integrator.p
        cache = integrator.cache
        cd = u.cell_data

        # Phase 1 & 2: Apoptosis and Transitions (GPU/CPU native)
        AcceleratedKernels.foreachindex(cd.cell_types; block_size = cache.block_size) do i
            t_id = cd.cell_types[i]
            if t_id != 0
                if !evaluate_apoptosis!(resolved_events, t_id, cd, i)
                    evaluate_transitions!(resolved_events, t_id, cd, i)
                end
            end
        end
        KernelAbstractions.synchronize(KernelAbstractions.get_backend(u.grid))

        # Phase 3: Mitosis
        if mitosis_evt !== nothing
            if !isassigned(ws_ref)
                ws_ref[] = CorePotts.MitosisWorkspace(u.grid, length(u.cell_data.volumes))
            end

            trigger_wrapper = MitosisTriggerWrapper(resolved_events, u.cell_data.cell_types)
            num_divisions = CorePotts.populate_dividing_parents!(u, cache, trigger_wrapper, ws_ref[])

            if num_divisions > 0
                CorePotts.process_mitosis_events!(
                    u, p, cache, ws_ref[];
                    trigger = trigger_wrapper,
                    orientation = mitosis_evt.orientation,
                    inheritance_rules = mitosis_evt.inheritance
                )
                if mitosis_evt.action !== nothing
                    mitosis_evt.action(u, p, cache, ws_ref[], num_divisions)
                end
            end
        end
    end

    cb = SciMLBase.DiscreteCallback(condition, affect!, save_positions = (false, false))
    return SciMLBase.CallbackSet(cb), reqs, (mitosis_evt !== nothing ? ws_ref : nothing)
end

end
