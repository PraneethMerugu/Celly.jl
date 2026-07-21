module PottsToolkitUnitfulExt

using PottsToolkit
using CorePotts
using Unitful

import PottsToolkit.Authoring: _with_units, _observe_with_units,
    _observation_table_with_units, _units_backend

function _length_dimension(value)
    return Unitful.dimension(value) == Unitful.dimension(one(Float64) * Unitful.m)
end

function _time_dimension(value)
    return Unitful.dimension(value) == Unitful.dimension(one(Float64) * Unitful.s)
end

function _with_units(solution::CorePotts.PottsSolution,
        scale::PottsToolkit.PhysicalScale)
    dimensions = length(solution.prob.geometry.dims)
    length(scale.lattice_spacing) == dimensions || throw(ArgumentError(
        "physical lattice spacing must match the solution dimensionality"))
    all(_length_dimension, scale.lattice_spacing) || throw(ArgumentError(
        "every physical lattice spacing must carry a length dimension"))
    scale.mcs_duration === nothing || _time_dimension(scale.mcs_duration) ||
        throw(ArgumentError("physical MCS duration must carry a time dimension"))
    return PottsToolkit.UnitfulSolutionView(solution, scale)
end

function _scale_cell_values(values::PottsToolkit.CellValues, factor)
    rows = map(values.rows) do row
        PottsToolkit.CellValue(
            row.id, row.generation, row.cell_type, row.value * factor)
    end
    return PottsToolkit.CellValues(rows)
end

function _observe_with_units(view::PottsToolkit.UnitfulSolutionView,
        observable::PottsToolkit.CellVolume)
    raw = PottsToolkit.observe(parent(view), observable)
    factor = prod(view.scale.lattice_spacing)
    frames = map(raw.frames) do frame
        PottsToolkit.CellFrame(frame.mcs, _scale_cell_values(frame.values, factor))
    end
    return PottsToolkit.CellSeries(frames)
end

function _units_backend(view::PottsToolkit.UnitfulSolutionView{S, P}) where {
        S <: CorePotts.PottsSolution,
        L <: Tuple{Vararg{Unitful.AbstractQuantity}},
        T <: Union{Nothing, Unitful.AbstractQuantity}, M <: NamedTuple,
        P <: PottsToolkit.PhysicalScale{L, T, M}}
    return Val(:unitful)
end

function _observation_table_with_units(view::PottsToolkit.UnitfulSolutionView,
        ::Val{:unitful}, observables...)
    raw = PottsToolkit.observation_table(parent(view), observables...)
    calibrated = Tuple(PottsToolkit.observe(view, observable) for observable in observables)
    names = Tuple(observable.name.name for observable in observables)
    rows = NamedTuple[]
    row_index = 1
    for frame_index in eachindex(parent(view).t)
        isempty(calibrated) && continue
        count = length(first(calibrated).frames[frame_index].values)
        for cell_index in 1:count
            base = raw[row_index]
            values = Tuple(series.frames[frame_index].values[cell_index].value
                for series in calibrated)
            physical_time = view.scale.mcs_duration === nothing ? missing :
                base.mcs * view.scale.mcs_duration
            push!(rows, merge(base, (physical_time = physical_time,),
                NamedTuple{names}(values)))
            row_index += 1
        end
    end
    return rows
end

end
