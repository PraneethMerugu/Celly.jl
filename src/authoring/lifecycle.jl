function _lifecycle_scope(cell_types::Tuple)
    isempty(cell_types) && throw(ArgumentError(
        "a lifecycle declaration must target at least one cell type"))
    return Tuple(sort!(unique!(collect(cell_types)); by = _identity_text))
end

"""Convenience spelling for deterministic finite-cell target-volume growth."""
Growth(source, cell_types::CellType...; rate::Real,
        name::Symbol = :growth, namespace::Namespace = Namespace(), kwargs...) =
    PropertyUpdate(source, cell_types...; name, namespace,
        role = :target, amount = rate, kwargs...)

"""Scheduled finite-cell type transition at an integer-MCS boundary."""
struct Transition{S <: CorePotts.AbstractMCSSchedule,
        G <: CorePotts.AbstractLifecycleTrigger}
    name::SemanticName
    cell_types::Tuple
    destination::CellType
    schedule::S
    trigger::G
    priority::Int32
end

function Transition(cell_types::CellType...; destination::CellType,
        name::Symbol = :transition, namespace::Namespace = Namespace(),
        schedule::CorePotts.AbstractMCSSchedule = CorePotts.EveryMCS(),
        trigger::CorePotts.AbstractLifecycleTrigger = CorePotts.AlwaysLifecycleTrigger(),
        priority::Integer = 0)
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "lifecycle priority must fit Int32"))
    return Transition(SemanticName(name; namespace), _lifecycle_scope(cell_types),
        destination, schedule, trigger, Int32(priority))
end

semantic_identity(rule::Transition) = rule.name

"""Scheduled binary finite-cell division with an explicit geometry policy."""
struct Division{S <: CorePotts.AbstractMCSSchedule,
        G <: CorePotts.AbstractLifecycleTrigger,
        D <: CorePotts.AbstractDivisionGeometry}
    name::SemanticName
    cell_types::Tuple
    geometry::D
    schedule::S
    trigger::G
    priority::Int32
end

function Division(cell_types::CellType...;
        geometry::CorePotts.AbstractDivisionGeometry,
        name::Symbol = :division, namespace::Namespace = Namespace(),
        schedule::CorePotts.AbstractMCSSchedule = CorePotts.EveryMCS(),
        trigger::CorePotts.AbstractLifecycleTrigger = CorePotts.AlwaysLifecycleTrigger(),
        priority::Integer = 0)
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "lifecycle priority must fit Int32"))
    return Division(SemanticName(name; namespace), _lifecycle_scope(cell_types),
        geometry, schedule, trigger, Int32(priority))
end

semantic_identity(rule::Division) = rule.name

"""Scheduled decrement of a target property until CorePotts retires the shrunken cell."""
struct ShrinkDeath{T <: AbstractFloat, S <: CorePotts.AbstractMCSSchedule,
        G <: CorePotts.AbstractLifecycleTrigger}
    name::SemanticName
    source::SemanticName
    cell_types::Tuple
    decrement::T
    schedule::S
    trigger::G
    priority::Int32
end

function ShrinkDeath(source, cell_types::CellType...; decrement::Real,
        name::Symbol = :shrink_death, namespace::Namespace = Namespace(),
        schedule::CorePotts.AbstractMCSSchedule = CorePotts.EveryMCS(),
        trigger::CorePotts.AbstractLifecycleTrigger = CorePotts.AlwaysLifecycleTrigger(),
        priority::Integer = 0)
    T = float(typeof(decrement))
    amount = T(decrement)
    isfinite(amount) && amount > zero(T) || throw(ArgumentError(
        "shrink-death decrement must be finite and positive"))
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "lifecycle priority must fit Int32"))
    return ShrinkDeath(SemanticName(name; namespace), semantic_identity(source),
        _lifecycle_scope(cell_types), amount, schedule, trigger, Int32(priority))
end

semantic_identity(rule::ShrinkDeath) = rule.name

"""Scheduled immediate removal of finite cells into one declared medium."""
struct ImmediateDeath{S <: CorePotts.AbstractMCSSchedule,
        G <: CorePotts.AbstractLifecycleTrigger}
    name::SemanticName
    cell_types::Tuple
    medium::Medium
    schedule::S
    trigger::G
    priority::Int32
end


function ImmediateDeath(cell_types::CellType...; medium::Medium,
        name::Symbol = :immediate_death, namespace::Namespace = Namespace(),
        schedule::CorePotts.AbstractMCSSchedule = CorePotts.EveryMCS(),
        trigger::CorePotts.AbstractLifecycleTrigger = CorePotts.AlwaysLifecycleTrigger(),
        priority::Integer = 0)
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "lifecycle priority must fit Int32"))
    return ImmediateDeath(SemanticName(name; namespace),
        _lifecycle_scope(cell_types), medium, schedule, trigger, Int32(priority))
end

semantic_identity(rule::ImmediateDeath) = rule.name
