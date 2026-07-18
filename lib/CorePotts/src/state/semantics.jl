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

@enum DivisionPolicy::UInt8 begin
    CloneOnDivision = 1
    SplitOnDivision = 2
    ResetChildOnDivision = 3
    ResetBothOnDivision = 4
    AsymmetricResetOnDivision = 5
    TransformOnDivision = 6
end

@enum TransitionPolicy::UInt8 begin
    PreserveOnTransition = 1
    ResetOnTransition = 2
    TransformOnTransition = 3
    RecomputeOnTransition = 4
    InvalidTransition = 5
end

@enum RetirementPolicy::UInt8 begin
    ResetOnRetirement = 1
end

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
struct PropertyDescriptor{T, I, P} <: AbstractPropertyDescriptor
    key::Symbol
    initializer::I
    mutability::PropertyMutability
    division::DivisionPolicy
    transition::TransitionPolicy
    retirement::RetirementPolicy
    kind::PropertyKind
    requesters::P
end

function PropertyDescriptor(key::Symbol, ::Type{T}, initializer::I;
        mutability::PropertyMutability = MutableProperty,
        division::DivisionPolicy = CloneOnDivision,
        transition::TransitionPolicy = PreserveOnTransition,
        retirement::RetirementPolicy = ResetOnRetirement,
        kind::PropertyKind = BiologicalProperty,
        requester::ComponentIdentity) where {T, I}
    isempty(String(key)) && throw(ArgumentError("property key must not be empty"))
    isbitstype(T) || throw(ArgumentError("property `$key` must use an isbits logical type"))
    isbitstype(I) || throw(ArgumentError("property `$key` initializer must be isbits"))
    return PropertyDescriptor{T, I, Tuple{ComponentIdentity}}(
        key, initializer, mutability, division, transition, retirement, kind, (requester,))
end

value_type(::PropertyDescriptor{T}) where {T} = T
property_requesters(descriptor::PropertyDescriptor) = descriptor.requesters

function _same_property_contract(left::PropertyDescriptor, right::PropertyDescriptor)
    return left.key === right.key && value_type(left) === value_type(right) &&
           isequal(left.initializer, right.initializer) &&
           left.mutability === right.mutability && left.division === right.division &&
           left.transition === right.transition && left.retirement === right.retirement &&
           left.kind === right.kind
end

function _with_requesters(descriptor::PropertyDescriptor{T, I}, requesters) where {T, I}
    return PropertyDescriptor{T, I, typeof(requesters)}(
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
