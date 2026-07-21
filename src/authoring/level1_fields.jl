abstract type AbstractFieldPlacement end
"""Scalar samples live at Cartesian cell centers."""
struct CellCentered <: AbstractFieldPlacement end

abstract type AbstractFieldBoundary end
"""Zero-normal-derivative field boundary."""
struct NoFlux <: AbstractFieldBoundary end
"""Periodic field boundary, independent of ownership-domain boundaries."""
struct PeriodicField <: AbstractFieldBoundary end
"""Fixed scalar field value on the selected boundary face or axis."""
struct FixedValue{T <: AbstractFloat} <: AbstractFieldBoundary
    value::T
end
function FixedValue(value::Real)
    converted = float(value)
    isfinite(converted) || throw(ArgumentError(
        "a fixed field-boundary value must be finite"))
    return FixedValue(converted)
end

abstract type AbstractFieldInterpolation end
"""Multilinear interpolation on the declared Cartesian field geometry."""
struct Multilinear <: AbstractFieldInterpolation end
"""Nearest-sample interpolation on the declared Cartesian field geometry."""
struct Nearest <: AbstractFieldInterpolation end

"""Reusable field meaning whose concrete values are bound by a `PottsProblem`."""
struct Field{P <: AbstractFieldPlacement, B, I <: AbstractFieldInterpolation}
    name::SemanticName
    placement::P
    boundary::B
    interpolation::I
end

function Field(name::Symbol; namespace::Namespace = Namespace(),
        placement::AbstractFieldPlacement = CellCentered(),
        boundary = NoFlux(),
        interpolation::AbstractFieldInterpolation = Multilinear())
    boundary isa AbstractFieldBoundary ||
        (boundary isa Tuple && all(value -> value isa AbstractFieldBoundary, boundary)) ||
        throw(ArgumentError(
            "field boundary must be one typed value or one typed value per axis"))
    return Field(SemanticName(name; namespace), placement, boundary, interpolation)
end

semantic_identity(field::Field) = field.name
_is_field_declaration(::Field) = true
_field_declaration_dimension(::Field) = nothing
_field_declaration_values(::Field) = ()
_fixed_field_boundaries(boundary::FixedValue) = (boundary,)
_fixed_field_boundaries(boundaries::Tuple) = Tuple(boundary
    for value in boundaries for boundary in _fixed_field_boundaries(value))
_fixed_field_boundaries(boundary) = ()

function _validate_declaration(field::Field, context::_ValidationContext)
    T = _context_real_type(context)
    unsafe = Tuple(typeof(boundary.value) for boundary in
        _fixed_field_boundaries(field.boundary)
        if !_exact_automatic_conversion(typeof(boundary.value), T))
    isempty(unsafe) && return ()
    return (Diagnostic(:error, :unsafe_field_boundary_conversion,
        "fixed field-boundary values require an unsafe conversion to model precision";
        identity = field.name, related = (unsafe..., T),
        correction = "spell the boundary value in the model numerical type"),)
end
_normalize_component(field::Field, ::Type) = field
_canonical_write(io::IO, field::Field) = _canonical_fields(io, field)
_canonical_write(io::IO, value::Union{AbstractFieldPlacement,
    AbstractFieldBoundary, AbstractFieldInterpolation}) = _canonical_fields(io, value)
_lower_component(::Field, context::_LoweringContext) = _LoweredComponents()

function _declaration_report(field::Field)
    return DeclarationReport(field.name, :field, (), (field.name,),
        (:problem_bound_field_sampling,), (), (:CellCenteredField,),
        (placement = field.placement, boundary = field.boundary,
            interpolation = field.interpolation, realized_values = false),
        CorePotts.ScientificCapabilities(dimensions = (2, 3)))
end

function _scope_declaration(field::Field, fragment::ModelFragment, mapping)
    return Field(_mapped_identity(mapping, field.name), field.placement,
        field.boundary, field.interpolation)
end

function Chemotaxis(field::Field, pairs::Pair...; kwargs...)
    return _chemotaxis(semantic_identity(field), 0, Tuple(pairs); kwargs...)
end

function _core_field_boundary(::NoFlux, ::Type)
    return CorePotts.AxisFieldBoundary(CorePotts.ZeroNeumannFieldBoundary())
end
function _core_field_boundary(::PeriodicField, ::Type)
    return CorePotts.AxisFieldBoundary(CorePotts.PeriodicFieldBoundary())
end
function _core_field_boundary(boundary::FixedValue, ::Type{T}) where {T}
    return CorePotts.AxisFieldBoundary(CorePotts.DirichletFieldBoundary(T(boundary.value)))
end

_core_field_interpolation(::Multilinear) =
    CorePotts.MultilinearFieldInterpolation()
_core_field_interpolation(::Nearest) = CorePotts.NearestFieldInterpolation()

function _realized_field_boundaries(field::Field, ::Val{N}, ::Type{T}) where {N, T}
    if field.boundary isa Tuple
        length(field.boundary) == N || throw(ArgumentError(
            "field boundary tuple must contain one value per problem axis"))
        return ntuple(axis -> _core_field_boundary(field.boundary[axis], T), Val(N))
    end
    return ntuple(_ -> _core_field_boundary(field.boundary, T), Val(N))
end

function _realize_field(field::Field, values::AbstractArray{<:Real, N},
        domain::CorePotts.CartesianDomain{N}) where {N}
    field.placement isa CellCentered || throw(ArgumentError(
        "only CellCentered field placement is qualified in the initial Level 1 slice"))
    all(>(0), size(values)) || throw(ArgumentError(
        "problem-bound fields must have a positive extent on every axis"))
    spacing = ntuple(axis ->
        domain.spacing[axis] * domain.dims[axis] / size(values, axis), Val(N))
    T = promote_type(eltype(values), eltype(domain.spacing))
    return PrescribedField(field.name.name, values;
        namespace = field.name.namespace, spacing,
        boundaries = _realized_field_boundaries(field, Val(N), T),
        interpolation = _core_field_interpolation(field.interpolation))
end

function _field_pairs(fields)
    fields isa Pair && return (fields,)
    fields isa Tuple || throw(ArgumentError(
        "problem field bindings must be a tuple of `Field => values` pairs"))
    all(value -> value isa Pair, fields) || throw(ArgumentError(
        "every problem field binding must be `Field => values`"))
    return fields
end

function _realize_problem_fields(model::PottsModel,
        domain::CorePotts.CartesianDomain{N}, fields) where {N}
    pairs = _field_pairs(fields)
    identities = Tuple(semantic_identity(first(pair)) for pair in pairs)
    length(unique(identities)) == length(identities) || throw(ArgumentError(
        "problem field bindings must use distinct field identities"))
    declared = Tuple(declaration for declaration in model.declarations
        if declaration isa Field)
    declared_identities = Tuple(semantic_identity(field) for field in declared)
    Set(identities) == Set(declared_identities) || throw(ArgumentError(
        "problem field bindings must provide exactly the model's reusable Field declarations"))

    realized = Dict{SemanticName, PrescribedField}()
    for pair in pairs
        field_index = findfirst(field -> semantic_identity(field) ==
            semantic_identity(first(pair)), declared)
        field = declared[field_index]
        values = last(pair)
        values isa AbstractArray{<:Real, N} || throw(ArgumentError(
            "field values must be a real array with the problem dimensionality"))
        realized[semantic_identity(field)] = _realize_field(field, values, domain)
    end

    declarations = map(model.declarations) do declaration
        if declaration isa Field
            realized[semantic_identity(declaration)]
        elseif declaration isa Chemotaxis && declaration.dimensions == 0
            Chemotaxis{typeof(first(declaration.sensitivity).value),
                typeof(declaration.response), typeof(declaration.mode)}(
                declaration.name, declaration.field, UInt8(N), declaration.sensitivity,
                declaration.response, declaration.mode)
        else
            declaration
        end
    end
    return PottsModel(Tuple(declarations), model.numerics)
end
