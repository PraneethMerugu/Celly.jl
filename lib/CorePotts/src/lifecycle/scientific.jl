abstract type AbstractMCSSchedule end

"""Run at every positive integer-MCS lifecycle boundary."""
struct EveryMCS <: AbstractMCSSchedule end

"""Run at exactly one positive integer-MCS boundary."""
struct OnceAtMCS <: AbstractMCSSchedule
    mcs::Int64
    function OnceAtMCS(mcs::Integer)
        mcs > 0 || throw(ArgumentError("a lifecycle schedule must use positive MCS values"))
        new(Int64(mcs))
    end
end

"""Run at an explicit, canonical collection of positive integer-MCS boundaries."""
struct AtMCS{T <: Tuple} <: AbstractMCSSchedule
    boundaries::T
    function AtMCS(boundaries::T) where {T <: Tuple}
        times = Tuple(sort!(unique!(Int64.(collect(boundaries)))))
        isempty(times) && throw(ArgumentError("an explicit MCS schedule must not be empty"))
        all(>(0), times) || throw(ArgumentError(
            "a lifecycle schedule must use positive MCS values"))
        new{typeof(times)}(times)
    end
end

function AtMCS(boundaries)
    return AtMCS(Tuple(boundaries))
end

"""Run from `start` every `period` MCS, optionally through an inclusive `stop`."""
struct PeriodicMCS <: AbstractMCSSchedule
    start::Int64
    period::Int64
    stop::Int64
    bounded::Bool

    function PeriodicMCS(start::Integer, period::Integer, stop::Integer, bounded::Bool)
        start > 0 || throw(ArgumentError("a periodic lifecycle schedule must start after MCS 0"))
        period > 0 || throw(ArgumentError("a periodic lifecycle period must be positive"))
        !bounded || stop >= start || throw(ArgumentError(
            "a bounded periodic lifecycle schedule must stop at or after its start"))
        new(Int64(start), Int64(period), Int64(stop), bounded)
    end
end

PeriodicMCS(start::Integer, period::Integer; stop = nothing) = stop === nothing ?
    PeriodicMCS(start, period, 0, false) : PeriodicMCS(start, period, stop, true)

@inline function _positive_mcs(mcs::Integer)
    mcs > 0 || throw(ArgumentError("lifecycle schedule membership is defined only after MCS 0"))
    return Int64(mcs)
end

@inline is_due(::EveryMCS, mcs::Integer) = (_positive_mcs(mcs); true)
@inline is_due(schedule::OnceAtMCS, mcs::Integer) = _positive_mcs(mcs) == schedule.mcs
@inline is_due(schedule::AtMCS, mcs::Integer) = _positive_mcs(mcs) in schedule.boundaries
@inline function is_due(schedule::PeriodicMCS, mcs::Integer)
    time = _positive_mcs(mcs)
    time >= schedule.start || return false
    schedule.bounded && time > schedule.stop && return false
    return rem(time - schedule.start, schedule.period) == 0
end

abstract type AbstractLifecycleTarget end
"""The active finite cells in the common pre-lifecycle snapshot."""
struct ActiveCellsTarget <: AbstractLifecycleTarget end
"""One global model target at a lifecycle boundary."""
struct GlobalModelTarget <: AbstractLifecycleTarget end

"""Read-only-by-contract view observed by every trigger at one completed MCS boundary."""
struct PreLifecycleSnapshot{S}
    state::S
    mcs::Int64
    function PreLifecycleSnapshot(state::S, mcs::Integer) where {S}
        mcs > 0 || throw(ArgumentError("a pre-lifecycle snapshot requires a positive MCS"))
        new{S}(state, Int64(mcs))
    end
end

abstract type AbstractLifecycleTrigger end
abstract type AbstractLifecycleEffect end

"""Restrict a lifecycle event to one immutable set of finite cell-type IDs."""
struct CellTypeIn{N} <: AbstractLifecycleTrigger
    type_ids::NTuple{N, UInt32}

    function CellTypeIn(type_ids::NTuple{N, UInt32}) where {N}
        N > 0 || throw(ArgumentError("a cell-type lifecycle trigger must not be empty"))
        values = Tuple(sort!(unique!(collect(type_ids))))
        length(values) == N || throw(ArgumentError(
            "a cell-type lifecycle trigger must not contain duplicates"))
        all(!iszero, values) || throw(ArgumentError("cell-type IDs must be positive"))
        return new{N}(values)
    end
end

CellTypeIn(type_ids...) = CellTypeIn(Tuple(UInt32(value(CellTypeID(id))) for id in type_ids))

"""Conjunction of allocation-free lifecycle triggers evaluated against one snapshot."""
struct AllLifecycleTriggers{T <: Tuple} <: AbstractLifecycleTrigger
    triggers::T

    function AllLifecycleTriggers(triggers::T) where {T <: Tuple}
        isempty(triggers) && throw(ArgumentError("a trigger conjunction must not be empty"))
        all(trigger -> trigger isa AbstractLifecycleTrigger, triggers) || throw(ArgumentError(
            "every conjunction member must be an AbstractLifecycleTrigger"))
        return new{T}(triggers)
    end
end


AllLifecycleTriggers(triggers::AbstractLifecycleTrigger...) =
    AllLifecycleTriggers(Tuple(triggers))

"""Open, side-effect-free trigger query for one target in one common snapshot."""
function lifecycle_triggered end
"""Open effect-planning operation. Planning must not mutate the supplied snapshot."""
function plan_lifecycle_effect end

"""Typed composition of one lifecycle target, schedule, trigger, and effect."""
struct LifecycleEvent{T <: AbstractLifecycleTarget, S <: AbstractMCSSchedule,
        G <: AbstractLifecycleTrigger, E <: AbstractLifecycleEffect}
    target::T
    schedule::S
    trigger::G
    effect::E
    semantic_id::UInt64
    priority::Int32
end

function LifecycleEvent(target::AbstractLifecycleTarget, schedule::AbstractMCSSchedule,
        trigger::AbstractLifecycleTrigger, effect::AbstractLifecycleEffect;
        semantic_id::Integer, priority::Integer = 0)
    semantic_id >= 0 || throw(ArgumentError("lifecycle semantic IDs must be nonnegative"))
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "lifecycle priority must fit in Int32"))
    return LifecycleEvent(target, schedule, trigger, effect, UInt64(semantic_id), Int32(priority))
end

"""One identity-changing claim used by an explicit lifecycle conflict resolver."""
struct LifecycleConflictClaim
    target::CellID
    priority::Int32
    semantic_id::UInt64
    source_index::Int32
end

abstract type AbstractLifecycleConflictResolver end
"""Reject every target receiving more than one identity-changing claim."""
struct RejectLifecycleConflicts <: AbstractLifecycleConflictResolver end
"""Select the unique greatest explicit priority for each target; reject priority ties."""
struct StableLifecyclePriority <: AbstractLifecycleConflictResolver end

struct LifecycleConflictError <: Exception
    target::CellID
    source_indices::Vector{Int32}
end

function Base.showerror(io::IO, error::LifecycleConflictError)
    print(io, "unresolved lifecycle conflict for ", error.target,
        " from sources ", error.source_indices)
end

"""Return winning source indices in ascending target-ID order."""
function resolve_lifecycle_conflicts end

function _claims_by_target(claims)
    ordered = sort!(collect(claims); by = claim ->
        (value(claim.target), -Int64(claim.priority), claim.semantic_id, claim.source_index))
    groups = Vector{UnitRange{Int}}()
    first_index = 1
    while first_index <= length(ordered)
        last_index = first_index
        while last_index < length(ordered) &&
                ordered[last_index + 1].target == ordered[first_index].target
            last_index += 1
        end
        push!(groups, first_index:last_index)
        first_index = last_index + 1
    end
    return ordered, groups
end

function resolve_lifecycle_conflicts(::RejectLifecycleConflicts, claims)
    ordered, groups = _claims_by_target(claims)
    winners = Int32[]
    for group in groups
        length(group) == 1 || throw(LifecycleConflictError(ordered[first(group)].target,
            sort!(Int32[ordered[index].source_index for index in group])))
        push!(winners, ordered[first(group)].source_index)
    end
    return winners
end

function resolve_lifecycle_conflicts(::StableLifecyclePriority, claims)
    ordered, groups = _claims_by_target(claims)
    winners = Int32[]
    for group in groups
        winner = ordered[first(group)]
        tied = Int32[ordered[index].source_index for index in group
            if ordered[index].priority == winner.priority]
        length(tied) == 1 || throw(LifecycleConflictError(winner.target, sort!(tied)))
        push!(winners, winner.source_index)
    end
    return winners
end

abstract type AbstractDivisionGeometry end

"""Scalar geometry data for labeling one parent-owned site into a descendant region."""
struct DivisionSiteContext{N, T <: AbstractFloat}
    coordinate::SVector{N, T}
    center::SVector{N, T}
end

DivisionSiteContext(coordinate::NTuple{N, T}, center::NTuple{N, T}) where {
    N, T <: AbstractFloat} = DivisionSiteContext(SVector{N, T}(coordinate), SVector{N, T}(center))

"""Open allocation-free query returning a compact descendant-region label."""
function division_region end

struct BinaryPartitionReport
    parent_sites::Int
    child_sites::Int
    valid::Bool
end

"""Validate that labels form exactly two nonempty binary descendant regions."""
function validate_binary_partition(labels)
    parent_sites = 0
    child_sites = 0
    for label in labels
        label == UInt8(1) ? (parent_sites += 1) :
        label == UInt8(2) ? (child_sites += 1) :
        return BinaryPartitionReport(parent_sites, child_sites, false)
    end
    return BinaryPartitionReport(parent_sites, child_sites,
        parent_sites > 0 && child_sites > 0)
end
