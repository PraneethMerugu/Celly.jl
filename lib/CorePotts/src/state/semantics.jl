abstract type AbstractScientificID end

"""Public reusable finite-cell identity. Zero and negative values are never valid cell IDs."""
struct CellID <: AbstractScientificID
    value::UInt32
end

"""Read-only compiled finite-cell-type identity; user-facing types remain symbolic."""
struct CellTypeID <: AbstractScientificID
    value::UInt32
end

"""Conceptual medium-domain identity, distinct from finite-cell identities."""
struct MediumID <: AbstractScientificID
    value::UInt32
end

"""Internal fixed-capacity storage slot identity for a finite cell."""
struct CellSlot <: AbstractScientificID
    value::UInt32
end

"""Generation counter that distinguishes reuse of one finite-cell slot."""
struct CellGeneration
    value::UInt64
end

"""Validated fixed finite-cell capacity; this is not the active cell count."""
struct CellCapacity
    value::UInt32
end

"""A lifecycle or initialization request exceeded fixed finite-cell capacity."""
struct CellCapacityError <: Exception
    requested::Int
    capacity::CellCapacity
end

function Base.showerror(io::IO, error::CellCapacityError)
    print(io, "fixed cell capacity ", error.capacity,
        " cannot accommodate ", error.requested, " finite cells")
end

function _positive_uint32(value::Integer, name::AbstractString)
    0 < value <= typemax(UInt32) || throw(ArgumentError("$name must lie in 1:$(typemax(UInt32))"))
    return UInt32(value)
end

CellID(value::Integer) = CellID(_positive_uint32(value, "cell ID"))
CellTypeID(value::Integer) = CellTypeID(_positive_uint32(value, "cell-type ID"))
MediumID(value::Integer) = MediumID(_positive_uint32(value, "medium ID"))
CellSlot(value::Integer) = CellSlot(_positive_uint32(value, "cell slot"))
CellGeneration(value::Integer) = value >= 0 ? CellGeneration(UInt64(value)) :
    throw(ArgumentError("cell generation must be non-negative"))
CellCapacity(value::Integer) = 0 <= value <= typemax(UInt32) ? CellCapacity(UInt32(value)) :
    throw(ArgumentError("cell capacity must lie in 0:$(typemax(UInt32))"))

CellID(id::CellID) = id
CellTypeID(id::CellTypeID) = id
MediumID(id::MediumID) = id
CellSlot(id::CellSlot) = id
CellGeneration(generation::CellGeneration) = generation

Base.:(==)(left::T, right::T) where {T <: AbstractScientificID} = left.value == right.value
Base.hash(id::AbstractScientificID, seed::UInt) = hash(id.value, hash(typeof(id), seed))
Base.show(io::IO, id::AbstractScientificID) = print(io, nameof(typeof(id)), "(", id.value, ")")
Base.show(io::IO, generation::CellGeneration) = print(io, "CellGeneration(", generation.value, ")")
Base.show(io::IO, capacity::CellCapacity) = print(io, "CellCapacity(", capacity.value, ")")

value(id::Union{AbstractScientificID, CellGeneration, CellCapacity}) = id.value
nslots(capacity::CellCapacity) = Int(capacity.value)

abstract type AbstractMathMode end
struct AccurateMath <: AbstractMathMode end
struct QualifiedFastMath <: AbstractMathMode end

abstract type AbstractReductionMode end
struct DeterministicReductions <: AbstractReductionMode end
struct TolerantReductions <: AbstractReductionMode end

abstract type AbstractOverflowMode end
struct CheckedModelBounds <: AbstractOverflowMode end
struct QualifiedUncheckedBounds <: AbstractOverflowMode end

"""Typed numerical choices that belong to scientific model identity."""
struct NumericalPolicy{R <: AbstractFloat, A <: AbstractFloat, M <: AbstractMathMode,
        D <: AbstractReductionMode, O <: AbstractOverflowMode}
    math::M
    reductions::D
    overflow::O
end

function NumericalPolicy(real::Type{R} = Float32, accumulation::Type{A} = real;
        math::M = AccurateMath(), reductions::D = DeterministicReductions(),
        overflow::O = CheckedModelBounds()) where {R <: AbstractFloat, A <: AbstractFloat,
        M <: AbstractMathMode, D <: AbstractReductionMode, O <: AbstractOverflowMode}
    return NumericalPolicy{R, A, M, D, O}(math, reductions, overflow)
end

real_type(::NumericalPolicy{R}) where {R} = R
accumulation_type(::NumericalPolicy{R, A}) where {R, A} = A
portable_numerical_policy() = NumericalPolicy()

@enum PropertyKind::UInt8 begin
    BiologicalProperty = 1
    DerivedProperty = 2
    AuxiliaryProperty = 3
    TransientProperty = 4
end

@enum PropertyMutability::UInt8 begin
    ReadOnlyProperty = 1
    MutableProperty = 2
end

abstract type AbstractDivisionPolicy end
abstract type AbstractTransitionPolicy end
abstract type AbstractRetirementPolicy end

"""Copy one authoritative parent value to both binary descendants."""
struct CloneOnDivision <: AbstractDivisionPolicy end

"""Conservatively split a numeric value, assigning `child_fraction` to the child."""
struct SplitOnDivision{T <: AbstractFloat} <: AbstractDivisionPolicy
    child_fraction::T

    function SplitOnDivision(child_fraction::T) where {T <: AbstractFloat}
        isfinite(child_fraction) && zero(T) <= child_fraction <= one(T) ||
            throw(ArgumentError("division child fraction must lie in [0, 1]"))
        new{T}(child_fraction)
    end
end

SplitOnDivision() = SplitOnDivision(0.5f0)
SplitOnDivision(fraction::Real) = SplitOnDivision(float(fraction))

"""Preserve the parent and initialize the child from the property initializer."""
struct ResetChildOnDivision <: AbstractDivisionPolicy end
"""Initialize both descendants from the property initializer."""
struct ResetBothOnDivision <: AbstractDivisionPolicy end

abstract type AbstractMechanicalDivisionPolicy <: AbstractDivisionPolicy end
"""Reset both descendant forces to their post-commit constitutive means."""
struct ConstitutiveResetAfterDivision <: AbstractMechanicalDivisionPolicy end
"""Clone an intensive mechanical state into both descendants."""
struct PreserveMechanicalOnDivision <: AbstractMechanicalDivisionPolicy end
"""Redraw both descendant forces from their post-commit stationary laws."""
struct StationaryRedrawAfterDivision <: AbstractMechanicalDivisionPolicy end

"""Assign explicit parent and child values after division."""
struct AsymmetricResetOnDivision{P, C} <: AbstractDivisionPolicy
    parent::P
    child::C
end

"""Explicitly reject division when this property is present."""
struct UnsupportedDivision{Reason} <: AbstractDivisionPolicy end
UnsupportedDivision(reason::Symbol) = UnsupportedDivision{reason}()
UnsupportedDivision() = UnsupportedDivision(:unspecified)

"""Preserve one property value across a compatible type transition."""
struct PreserveOnTransition <: AbstractTransitionPolicy end
"""Initialize one property from its schema initializer after transition."""
struct ResetOnTransition <: AbstractTransitionPolicy end
"""Mark a derived value for reconstruction after transition."""
struct RecomputeOnTransition <: AbstractTransitionPolicy end
"""Explicitly reject a type transition when this property is present."""
struct UnsupportedTransition{Reason} <: AbstractTransitionPolicy end
UnsupportedTransition(reason::Symbol) = UnsupportedTransition{reason}()
UnsupportedTransition() = UnsupportedTransition(:unspecified)

"""Reset a retired property slot to its canonical initializer value."""
struct ResetOnRetirement <: AbstractRetirementPolicy end

"""Context supplied to a schema-owned binary division policy."""
struct DivisionPropertyContext
    parent::CellID
    child::CellID
    original_volume::Int
    parent_volume::Int
    child_volume::Int
    dimensions::UInt8
end
DivisionPropertyContext(parent, child, original_volume, parent_volume, child_volume) =
    DivisionPropertyContext(parent, child, original_volume, parent_volume, child_volume, UInt8(0))

"""Complete parent/child result returned by a division policy."""
struct DivisionPropertyUpdate{T}
    parent::T
    child::T
end

"""Context supplied to a schema-owned type-transition policy."""
struct TransitionPropertyContext
    cell::CellID
    source::CellTypeID
    destination::CellTypeID
end

"""Open property lifecycle operations implemented by policy-value dispatch."""
function division_property_update end
function transition_property_value end
function retired_property_value end

"""Stable provenance for a scientific component or extension request."""
struct ComponentIdentity
    key::Symbol
    version::VersionNumber
    category::Symbol

    function ComponentIdentity(key::Symbol, version::VersionNumber, category::Symbol)
        isempty(String(key)) && throw(ArgumentError("component identity key must not be empty"))
        isempty(String(category)) && throw(ArgumentError("component category must not be empty"))
        new(key, version, category)
    end
end

ComponentIdentity(key::Symbol, version::AbstractString, category::Symbol) =
    ComponentIdentity(key, VersionNumber(version), category)

"""An isbits constant property initializer suitable for compiled state."""
struct ConstantInitializer{T}
    value::T

    function ConstantInitializer{T}(value::T) where {T}
        isbitstype(T) || throw(ArgumentError("constant property initializers must be isbits"))
        return new{T}(value)
    end
end

ConstantInitializer(value::T) where {T} = ConstantInitializer{T}(value)

abstract type AbstractPropertyDescriptor end

"""Immutable, provenance-aware declaration for one logical fixed-capacity property."""
struct PropertyDescriptor{T, I, D, X, R, P} <: AbstractPropertyDescriptor
    key::Symbol
    initializer::I
    mutability::PropertyMutability
    division::D
    transition::X
    retirement::R
    kind::PropertyKind
    requesters::P
end

function PropertyDescriptor(key::Symbol, ::Type{T}, initializer::I;
        mutability::PropertyMutability = MutableProperty,
        division::D = UnsupportedDivision(),
        transition::X = UnsupportedTransition(),
        retirement::R = ResetOnRetirement(),
        kind::PropertyKind = BiologicalProperty,
        requester::ComponentIdentity) where {T, I, D <: AbstractDivisionPolicy,
        X <: AbstractTransitionPolicy, R <: AbstractRetirementPolicy}
    isempty(String(key)) && throw(ArgumentError("property key must not be empty"))
    isbitstype(T) || throw(ArgumentError("property `$key` must use an isbits logical type"))
    isbitstype(I) || throw(ArgumentError("property `$key` initializer must be isbits"))
    isbitstype(D) || throw(ArgumentError("property `$key` division policy must be isbits"))
    isbitstype(X) || throw(ArgumentError("property `$key` transition policy must be isbits"))
    isbitstype(R) || throw(ArgumentError("property `$key` retirement policy must be isbits"))
    return PropertyDescriptor{T, I, D, X, R, Tuple{ComponentIdentity}}(
        key, initializer, mutability, division, transition, retirement, kind, (requester,))
end

value_type(::PropertyDescriptor{T}) where {T} = T
property_requesters(descriptor::PropertyDescriptor) = descriptor.requesters

function _same_property_contract(left::PropertyDescriptor, right::PropertyDescriptor)
    return left.key === right.key && value_type(left) === value_type(right) &&
           isequal(left.initializer, right.initializer) &&
           left.mutability === right.mutability && isequal(left.division, right.division) &&
           isequal(left.transition, right.transition) &&
           isequal(left.retirement, right.retirement) &&
           left.kind === right.kind
end

function _with_requesters(descriptor::PropertyDescriptor{T, I, D, X, R}, requesters) where {
        T, I, D, X, R}
    return PropertyDescriptor{T, I, D, X, R, typeof(requesters)}(
        descriptor.key, descriptor.initializer, descriptor.mutability, descriptor.division,
        descriptor.transition, descriptor.retirement, descriptor.kind, requesters)
end

struct PropertySchema{D <: Tuple}
    descriptors::D

    function PropertySchema(descriptors::D) where {D <: Tuple}
        keys = map(descriptor -> descriptor.key, descriptors)
        length(unique(keys)) == length(keys) || throw(ArgumentError(
            "a property schema must contain each logical key exactly once"))
        return new{D}(descriptors)
    end
end

PropertySchema(descriptors::AbstractPropertyDescriptor...) = PropertySchema(tuple(descriptors...))
property_keys(schema::PropertySchema) = map(descriptor -> descriptor.key, schema.descriptors)

function property_descriptor(schema::PropertySchema, key::Symbol)
    for descriptor in schema.descriptors
        descriptor.key === key && return descriptor
    end
    throw(KeyError(key))
end

struct PropertySchemaConflictError <: Exception
    key::Symbol
    existing::PropertyDescriptor
    requested::PropertyDescriptor
end

function Base.showerror(io::IO, error::PropertySchemaConflictError)
    print(io, "incompatible declarations for property `", error.key, "` requested by ",
        property_requesters(error.existing), " and ", property_requesters(error.requested))
end

function merge_property_schemas(schemas::PropertySchema...)
    merged = AbstractPropertyDescriptor[]
    for schema in schemas, descriptor in schema.descriptors
        index = findfirst(existing -> existing.key === descriptor.key, merged)
        if index === nothing
            push!(merged, descriptor)
        else
            existing = merged[index]
            _same_property_contract(existing, descriptor) ||
                throw(PropertySchemaConflictError(descriptor.key, existing, descriptor))
            requesters = unique((property_requesters(existing)..., property_requesters(descriptor)...))
            merged[index] = _with_requesters(existing, requesters)
        end
    end
    return PropertySchema(tuple(merged...))
end
