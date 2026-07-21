"""Read-only authoring snapshot of array values without encoding field size in its type."""
struct CapturedFieldValues{T, N, A <: Array{T, N}} <: AbstractArray{T, N}
    storage::A
end

CapturedFieldValues(values::AbstractArray{T, N}) where {T, N} =
    CapturedFieldValues{T, N, Array{T, N}}(Array(values))

Base.size(values::CapturedFieldValues) = size(values.storage)
Base.axes(values::CapturedFieldValues) = axes(values.storage)
Base.IndexStyle(::Type{<:CapturedFieldValues}) = IndexLinear()
Base.getindex(values::CapturedFieldValues, index::Int) = @inbounds values.storage[index]

"""Immutable Level 2 snapshot of a cell-centered prescribed scalar field."""
struct PrescribedField{N, T <: AbstractFloat, V <: CapturedFieldValues{T, N},
        O <: Tuple, S <: Tuple, B <: Tuple, I <: CorePotts.AbstractFieldInterpolation}
    name::SemanticName
    values::V
    origin::O
    spacing::S
    boundaries::B
    interpolation::I
    semantic_time::T
    synchronization_epoch::UInt64
end

function PrescribedField(name::Symbol, values::AbstractArray{<:Real, N};
        namespace::Namespace = Namespace(),
        origin = ntuple(_ -> 0, Val(N)), spacing = ntuple(_ -> 1, Val(N)),
        boundaries = ntuple(
            _ -> CorePotts.AxisFieldBoundary(CorePotts.PeriodicFieldBoundary()), Val(N)),
        interpolation::CorePotts.AbstractFieldInterpolation =
            CorePotts.MultilinearFieldInterpolation(),
        semantic_time::Real = 0, synchronization_epoch::Integer = 0) where {N}
    N in (2, 3) || throw(ArgumentError(
        "prescribed fields support exactly two or three dimensions"))
    T = float(promote_type(eltype(values), eltype(origin), eltype(spacing),
        typeof(semantic_time)))
    captured = CapturedFieldValues(T.(values))
    core = CorePotts.CellCenteredField(captured;
        origin = Tuple(T.(origin)), spacing = Tuple(T.(spacing)),
        boundaries = Tuple(boundaries), interpolation,
        semantic_time = T(semantic_time), synchronization_epoch)
    all(isfinite, captured) || throw(ArgumentError(
        "prescribed field values must be finite"))
    return PrescribedField{N, T, typeof(captured), typeof(Tuple(core.origin)),
        typeof(Tuple(core.spacing)), typeof(core.boundaries), typeof(interpolation)}(
        SemanticName(name; namespace), captured, Tuple(core.origin), Tuple(core.spacing),
        core.boundaries, interpolation, core.semantic_time, core.synchronization_epoch)
end

semantic_identity(field::PrescribedField) = field.name

function _field_as_core(field::PrescribedField)
    return CorePotts.CellCenteredField(copy(field.values.storage);
        origin = field.origin, spacing = field.spacing, boundaries = field.boundaries,
        interpolation = field.interpolation, semantic_time = field.semantic_time,
        synchronization_epoch = field.synchronization_epoch)
end

"""Cell-type sensitivity bindings for a named prescribed-field chemotaxis drive."""
struct Chemotaxis{T <: AbstractFloat, R <: CorePotts.AbstractFieldResponse,
        M <: CorePotts.AbstractChemotaxisMode}
    name::SemanticName
    field::SemanticName
    dimensions::UInt8
    sensitivity::BindingTable{CellType, T}
    response::R
    mode::M
end

function _chemotaxis(field_identity::SemanticName, dimensions::Integer,
        pairs::Tuple; name::Symbol = :chemotaxis,
        namespace::Namespace = Namespace(),
        response::CorePotts.AbstractFieldResponse = CorePotts.LinearResponse(),
        mode::CorePotts.AbstractChemotaxisMode = CorePotts.ExtensionChemotaxis())
    isempty(pairs) && throw(ArgumentError(
        "chemotaxis must bind a sensitivity for at least one cell type"))
    all(pair -> first(pair) isa CellType && last(pair) isa Real, pairs) ||
        throw(ArgumentError("chemotaxis entries must be `CellType => Real` pairs"))
    T = float(promote_type(map(pair -> typeof(last(pair)), pairs)...))
    entries = Tuple(Binding{CellType, T}(first(pair), T(last(pair))) for pair in pairs)
    all(entry -> isfinite(entry.value), entries) || throw(ArgumentError(
        "chemotaxis sensitivities must be finite"))
    return Chemotaxis{T, typeof(response), typeof(mode)}(
        SemanticName(name; namespace), field_identity, UInt8(dimensions),
        BindingTable{CellType, T}(entries), response, mode)
end

function Chemotaxis(field::PrescribedField, pairs::Pair...; kwargs...)
    return _chemotaxis(semantic_identity(field), ndims(field.values), Tuple(pairs); kwargs...)
end

semantic_identity(component::Chemotaxis) = component.name
