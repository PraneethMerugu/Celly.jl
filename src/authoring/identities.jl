"""An immutable hierarchical namespace used by biological and component identities."""
struct Namespace
    parts::Tuple

    function Namespace(parts::Tuple)
        all(part -> part isa Symbol && !isempty(String(part)), parts) || throw(ArgumentError(
            "namespace segments must be nonempty symbols"))
        return new(parts)
    end
end

Namespace(parts::Symbol...) = Namespace(parts)
Namespace(part::Symbol) = Namespace((part,))
Namespace() = Namespace(())

Base.:(==)(left::Namespace, right::Namespace) = left.parts == right.parts
Base.hash(namespace::Namespace, seed::UInt) = hash(namespace.parts, seed)
Base.isless(left::Namespace, right::Namespace) = _identity_text(left) < _identity_text(right)

function _identity_text(namespace::Namespace)
    isempty(namespace.parts) && return ""
    return join(String.(namespace.parts), ".")
end

function Base.show(io::IO, namespace::Namespace)
    isempty(namespace.parts) ? print(io, "Namespace()") :
    print(io, "Namespace(", join((repr(part) for part in namespace.parts), ", "), ")")
end

"""A semantic name whose namespace is independent of source and declaration order."""
struct SemanticName
    namespace::Namespace
    name::Symbol

    function SemanticName(namespace::Namespace, name::Symbol)
        isempty(String(name)) && throw(ArgumentError("semantic names must not be empty"))
        return new(namespace, name)
    end
end

SemanticName(name::Symbol; namespace::Namespace = Namespace()) = SemanticName(namespace, name)
semantic_identity(name::SemanticName) = name

function _identity_text(name::SemanticName)
    prefix = _identity_text(name.namespace)
    return isempty(prefix) ? String(name.name) : string(prefix, '.', name.name)
end

Base.:(==)(left::SemanticName, right::SemanticName) =
    left.namespace == right.namespace && left.name == right.name
Base.hash(name::SemanticName, seed::UInt) = hash((name.namespace, name.name), seed)
Base.isless(left::SemanticName, right::SemanticName) = _identity_text(left) < _identity_text(right)

function Base.show(io::IO, name::SemanticName)
    if isempty(name.namespace.parts)
        print(io, ':', name.name)
    else
        print(io, _identity_text(name))
    end
end

abstract type AbstractBiologicalType end

"""A named finite-cell category. It is never a runtime cell-type index."""
struct CellType <: AbstractBiologicalType
    identity::SemanticName
end

CellType(name::Symbol; namespace::Namespace = Namespace()) =
    CellType(SemanticName(name; namespace))

"""A named medium domain, distinct from a finite `CellType`."""
struct Medium <: AbstractBiologicalType
    identity::SemanticName
end

Medium(name::Symbol; namespace::Namespace = Namespace()) =
    Medium(SemanticName(name; namespace))

semantic_identity(value::Union{CellType, Medium}) = value.identity
_identity_text(value::Union{CellType, Medium}) = _identity_text(semantic_identity(value))

Base.:(==)(left::CellType, right::CellType) = left.identity == right.identity
Base.:(==)(left::Medium, right::Medium) = left.identity == right.identity
Base.hash(value::CellType, seed::UInt) = hash((:cell_type, value.identity), seed)
Base.hash(value::Medium, seed::UInt) = hash((:medium, value.identity), seed)
Base.isless(left::T, right::T) where {T <: Union{CellType, Medium}} =
    isless(left.identity, right.identity)

Base.show(io::IO, value::CellType) = print(io, "CellType(", repr(value.identity.name),
    isempty(value.identity.namespace.parts) ? "" : "; namespace=$(repr(value.identity.namespace))", ")")
Base.show(io::IO, value::Medium) = print(io, "Medium(", repr(value.identity.name),
    isempty(value.identity.namespace.parts) ? "" : "; namespace=$(repr(value.identity.namespace))", ")")
