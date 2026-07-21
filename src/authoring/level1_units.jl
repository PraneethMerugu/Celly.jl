"""Explicit physical calibration attached only to a solution-side analysis view."""
struct PhysicalScale{S <: Tuple, T, M <: NamedTuple}
    lattice_spacing::S
    mcs_duration::T
    metadata::M
end

function PhysicalScale(; lattice_spacing::Tuple, mcs_duration = nothing,
        method = nothing, citation = nothing, notes = nothing)
    isempty(lattice_spacing) && throw(ArgumentError(
        "physical lattice spacing must contain one value per spatial axis"))
    all(value -> value > zero(value), lattice_spacing) || throw(ArgumentError(
        "physical lattice spacing must be positive"))
    mcs_duration === nothing || mcs_duration > zero(mcs_duration) ||
        throw(ArgumentError("physical MCS duration must be positive"))
    metadata = (; method, citation, notes)
    return PhysicalScale(lattice_spacing, mcs_duration, metadata)
end

"""Lazy immutable physical-unit analysis view sharing one parent Potts solution."""
struct UnitfulSolutionView{S <: CorePotts.PottsSolution, P <: PhysicalScale}
    solution::S
    scale::P
end

Base.parent(view::UnitfulSolutionView) = view.solution
mcs(view::UnitfulSolutionView) = view.solution.t
Base.length(view::UnitfulSolutionView) = length(view.solution)
Base.getindex(view::UnitfulSolutionView, index::Integer) = view.solution[index]

function Base.getproperty(view::UnitfulSolutionView, name::Symbol)
    if name === :t
        duration = getfield(view, :scale).mcs_duration
        duration === nothing && throw(ArgumentError(
            "this physical solution view has no MCS-duration calibration"))
        return getfield(view, :solution).t .* duration
    end
    return getfield(view, name)
end

_with_units(solution, scale::PhysicalScale) = throw(ArgumentError(
    "load Unitful.jl to construct a validated physical solution view"))
with_units(solution::CorePotts.PottsSolution, scale::PhysicalScale) =
    _with_units(solution, scale)

_observe_with_units(view::UnitfulSolutionView, observable) =
    observe(parent(view), observable)
observe(view::UnitfulSolutionView, observable::AbstractScientificObservable) =
    _observe_with_units(view, observable)

_units_backend(view::UnitfulSolutionView) = nothing
_observation_table_with_units(view::UnitfulSolutionView, ::Nothing, observables...) =
    observation_table(parent(view), observables...)
observation_table(view::UnitfulSolutionView,
        observables::AbstractScientificObservable...) =
    _observation_table_with_units(view, _units_backend(view), observables...)
