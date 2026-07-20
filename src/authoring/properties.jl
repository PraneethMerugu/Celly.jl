abstract type AbstractPropertyInvariant end

"""Explicitly declare that a property has no value-range invariant."""
struct UnboundedProperty <: AbstractPropertyInvariant end

"""Inclusive finite value range checked during authoring and initialization."""
struct ClosedPropertyInterval{T} <: AbstractPropertyInvariant
    lower::T
    upper::T

    function ClosedPropertyInterval(lower::T, upper::T) where {T}
        lower <= upper || throw(ArgumentError(
            "a property interval lower bound must not exceed its upper bound"))
        return new{T}(lower, upper)
    end
end

ClosedPropertyInterval(lower, upper) = begin
    T = promote_type(typeof(lower), typeof(upper))
    ClosedPropertyInterval(T(lower), T(upper))
end

@enum PropertyVisibility::UInt8 begin
    PublicProperty = 1
    PrivateProperty = 2
end

@enum PropertyPersistence::UInt8 begin
    CheckpointedProperty = 1
    EphemeralProperty = 2
end

@enum PropertyOptionality::UInt8 begin
    RequiredProperty = 1
    OptionalProperty = 2
end

_satisfies_invariant(value, ::UnboundedProperty) = true
_satisfies_invariant(value, interval::ClosedPropertyInterval) =
    interval.lower <= value <= interval.upper

"""
A declared finite-cell property with explicit scope, initialization, lifecycle, persistence,
visibility, and optionality semantics. Unsupported lifecycle behavior is represented by an
explicit rejecting CorePotts policy, never by missing storage.
"""
struct CellProperty{T, I <: AbstractPropertyInvariant, D, X, R}
    name::SemanticName
    cell_types::Tuple
    initial::T
    invariant::I
    mutability::CorePotts.PropertyMutability
    division::D
    transition::X
    retirement::R
    visibility::PropertyVisibility
    persistence::PropertyPersistence
    optionality::PropertyOptionality
end

function CellProperty(name::Symbol, cell_types::CellType...;
        namespace::Namespace = Namespace(), initial,
        invariant::AbstractPropertyInvariant = UnboundedProperty(),
        mutability::CorePotts.PropertyMutability = CorePotts.MutableProperty,
        division::CorePotts.AbstractDivisionPolicy =
            CorePotts.UnsupportedDivision(:property_policy_required),
        transition::CorePotts.AbstractTransitionPolicy =
            CorePotts.UnsupportedTransition(:property_policy_required),
        retirement::CorePotts.AbstractRetirementPolicy = CorePotts.ResetOnRetirement(),
        visibility::PropertyVisibility = PublicProperty,
        persistence::PropertyPersistence = CheckpointedProperty,
        optionality::PropertyOptionality = RequiredProperty)
    isempty(cell_types) && throw(ArgumentError(
        "a cell property must declare at least one applicable cell type"))
    T = typeof(initial)
    isbitstype(T) || throw(ArgumentError("cell property values must use an isbits type"))
    _satisfies_invariant(initial, invariant) || throw(ArgumentError(
        "cell property initial value violates its declared invariant"))
    ordered = Tuple(sort!(unique!(collect(cell_types)); by = _identity_text))
    return CellProperty(SemanticName(name; namespace), ordered, initial, invariant,
        mutability, division, transition, retirement, visibility, persistence, optionality)
end

semantic_identity(property::CellProperty) = property.name
