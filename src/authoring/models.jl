"""An immutable reusable bundle of declarations with a lexical namespace."""
struct ModelFragment
    name::SemanticName
    declarations::Tuple
    requirements::Tuple
    exports::Tuple
end

_fragment_reference(identity::SemanticName) = identity
_fragment_reference(value) = semantic_identity(value)

function ModelFragment(name::Symbol, declarations...; namespace::Namespace = Namespace(),
        requirements = (), exports = ())
    normalized_requirements = Tuple(_fragment_reference(value) for value in requirements)
    normalized_exports = Tuple(_fragment_reference(value) for value in exports)
    length(unique(normalized_requirements)) == length(normalized_requirements) ||
        throw(ArgumentError("fragment requirements must be unique"))
    length(unique(normalized_exports)) == length(normalized_exports) ||
        throw(ArgumentError("fragment exports must be unique"))
    return ModelFragment(SemanticName(name; namespace), Tuple(declarations),
        normalized_requirements, normalized_exports)
end

semantic_identity(fragment::ModelFragment) = fragment.name

function _prepend_namespace(prefix::Namespace, identity::SemanticName)
    return SemanticName(Namespace((prefix.parts..., identity.namespace.parts...)), identity.name)
end

function _fragment_prefix(fragment::ModelFragment)
    return Namespace((fragment.name.namespace.parts..., fragment.name.name))
end

_is_fragment_export(fragment::ModelFragment, identity::SemanticName) =
    identity in fragment.exports

function _scoped_identity(fragment::ModelFragment, identity::SemanticName)
    _is_fragment_export(fragment, identity) && return identity
    return _prepend_namespace(_fragment_prefix(fragment), identity)
end

function _identity_mapping(fragment::ModelFragment)
    return Tuple(semantic_identity(declaration) =>
        _scoped_identity(fragment, semantic_identity(declaration))
        for declaration in fragment.declarations)
end

function _mapped_identity(mapping::Tuple, identity::SemanticName)
    entry = findfirst(pair -> first(pair) == identity, mapping)
    return entry === nothing ? identity : last(mapping[entry])
end

function _scope_biological(value::CellType, mapping::Tuple)
    return CellType(_mapped_identity(mapping, value.identity))
end
function _scope_biological(value::Medium, mapping::Tuple)
    return Medium(_mapped_identity(mapping, value.identity))
end

_scope_declaration(value::CellType, fragment::ModelFragment, mapping) =
    CellType(_mapped_identity(mapping, value.identity))
_scope_declaration(value::Medium, fragment::ModelFragment, mapping) =
    Medium(_mapped_identity(mapping, value.identity))

function _scope_volume_bindings(bindings::BindingTable{CellType, VolumeParameters{T}},
        mapping::Tuple) where {T}
    entries = Tuple(Binding{CellType, VolumeParameters{T}}(
        _scope_biological(entry.key, mapping), entry.value) for entry in bindings)
    return BindingTable{CellType, VolumeParameters{T}}(entries)
end

function _scope_declaration(component::VolumeConstraint{T},
        fragment::ModelFragment, mapping) where {T}
    return VolumeConstraint{T}(_mapped_identity(mapping, component.name),
        _scope_volume_bindings(component.bindings, mapping))
end

function _scope_declaration(component::FluctuatingVolumeConstraint{T, N, D},
        fragment::ModelFragment, mapping) where {T, N, D}
    return FluctuatingVolumeConstraint{T, N, D}(
        _mapped_identity(mapping, component.name),
        _scope_volume_bindings(component.bindings, mapping), component.eta,
        component.noise, component.initialization, component.division)
end

function _scope_boundary_bindings(bindings::BindingTable{
        CellType, BoundaryParameters{Q, T}}, mapping::Tuple) where {Q, T}
    entries = Tuple(Binding{CellType, BoundaryParameters{Q, T}}(
        _scope_biological(entry.key, mapping), entry.value) for entry in bindings)
    return BindingTable{CellType, BoundaryParameters{Q, T}}(entries)
end

function _scope_declaration(component::BoundaryConstraint{Q, T, M},
        fragment::ModelFragment, mapping) where {Q, T, M}
    return BoundaryConstraint{Q, T, M}(_mapped_identity(mapping, component.name),
        _scope_boundary_bindings(component.bindings, mapping), component.metric)
end

function _scope_declaration(component::FluctuatingBoundaryConstraint{Q, T, N, M, TD, D},
        fragment::ModelFragment, mapping) where {Q, T, N, M, TD, D}
    return FluctuatingBoundaryConstraint{Q, T, N, M, TD, D}(
        _mapped_identity(mapping, component.name),
        _scope_boundary_bindings(component.bindings, mapping), component.eta,
        component.noise, component.initialization, component.metric,
        component.target_division, component.division)
end

function _scope_declaration(component::PreserveConnectivity,
        fragment::ModelFragment, mapping)
    return PreserveConnectivity(_mapped_identity(mapping, component.name))
end

function _scope_declaration(component::Adhesion{T},
        fragment::ModelFragment, mapping) where {T}
    entries = Tuple(Binding{PairIdentity, T}(
        PairIdentity(_scope_biological(entry.key.left, mapping),
            _scope_biological(entry.key.right, mapping);
            symmetric = component.law.symmetric), entry.value)
        for entry in component.law.values)
    name = _mapped_identity(mapping, component.name)
    law = PairwiseLaw{T}(name, BindingTable{PairIdentity, T}(entries),
        component.law.symmetric, component.law.default)
    return Adhesion{T}(name, law)
end

function _scope_declaration(field::PrescribedField{N, T, V, O, S, B, I},
        fragment::ModelFragment, mapping) where {N, T, V, O, S, B, I}
    return PrescribedField{N, T, V, O, S, B, I}(
        _mapped_identity(mapping, field.name), field.values, field.origin, field.spacing,
        field.boundaries, field.interpolation, field.semantic_time,
        field.synchronization_epoch)
end

function _scope_declaration(component::Chemotaxis{T, R, M},
        fragment::ModelFragment, mapping) where {T, R, M}
    entries = Tuple(Binding{CellType, T}(
        _scope_biological(entry.key, mapping), entry.value)
        for entry in component.sensitivity)
    return Chemotaxis{T, R, M}(
        _mapped_identity(mapping, component.name),
        _mapped_identity(mapping, component.field),
        component.dimensions,
        BindingTable{CellType, T}(entries), component.response, component.mode)
end

function _scope_declaration(rule::PropertyUpdate{T, S, G},
        fragment::ModelFragment, mapping) where {T, S, G}
    return PropertyUpdate{T, S, G}(
        _mapped_identity(mapping, rule.name), _mapped_identity(mapping, rule.source),
        rule.role, Tuple(_scope_biological(value, mapping) for value in rule.cell_types),
        rule.amount, rule.schedule, rule.trigger)
end

function _scope_declaration(rule::Transition{S, G},
        fragment::ModelFragment, mapping) where {S, G}
    return Transition{S, G}(_mapped_identity(mapping, rule.name),
        Tuple(_scope_biological(value, mapping) for value in rule.cell_types),
        _scope_biological(rule.destination, mapping), rule.schedule, rule.trigger,
        rule.priority)
end

function _scope_declaration(rule::Division{S, G, D},
        fragment::ModelFragment, mapping) where {S, G, D}
    return Division{S, G, D}(_mapped_identity(mapping, rule.name),
        Tuple(_scope_biological(value, mapping) for value in rule.cell_types),
        rule.geometry, rule.schedule, rule.trigger, rule.priority)
end

function _scope_declaration(rule::ShrinkDeath{T, S, G},
        fragment::ModelFragment, mapping) where {T, S, G}
    return ShrinkDeath{T, S, G}(_mapped_identity(mapping, rule.name),
        _mapped_identity(mapping, rule.source),
        Tuple(_scope_biological(value, mapping) for value in rule.cell_types),
        rule.decrement, rule.schedule, rule.trigger, rule.priority)
end

function _scope_declaration(rule::ImmediateDeath{S, G},
        fragment::ModelFragment, mapping) where {S, G}
    return ImmediateDeath{S, G}(_mapped_identity(mapping, rule.name),
        Tuple(_scope_biological(value, mapping) for value in rule.cell_types),
        _scope_biological(rule.medium, mapping), rule.schedule, rule.trigger,
        rule.priority)
end


function _scope_declaration(property::CellProperty{T, I, D, X, R},
        fragment::ModelFragment, mapping) where {T, I, D, X, R}
    return CellProperty{T, I, D, X, R}(
        _mapped_identity(mapping, property.name),
        Tuple(_scope_biological(value, mapping) for value in property.cell_types),
        property.initial, property.invariant, property.mutability, property.division,
        property.transition, property.retirement, property.visibility,
        property.persistence, property.optionality)
end

function _scope_declaration(component::NamedCoreComponent,
        fragment::ModelFragment, mapping)
    return NamedCoreComponent(_mapped_identity(mapping, component.name), component.component)
end

function _scope_declaration(child::ModelFragment, fragment::ModelFragment, mapping)
    name = _mapped_identity(mapping, child.name)
    requirements = Tuple(_mapped_identity(mapping, value) for value in child.requirements)
    return ModelFragment(name, child.declarations, requirements, child.exports)
end

function _scope_declaration(component, fragment::ModelFragment, mapping)
    original = semantic_identity(component)
    scoped = _mapped_identity(mapping, original)
    return scoped == original ? component : NamedCoreComponent(scoped, component)
end

function _scoped_fragment_declarations(fragment::ModelFragment)
    mapping = _identity_mapping(fragment)
    return Tuple(_scope_declaration(declaration, fragment, mapping)
        for declaration in fragment.declarations)
end

"""Persistent Julia-native Level 2 biological model."""
struct PottsModel{N <: CorePotts.NumericalPolicy}
    declarations::Tuple
    numerics::N
end

function PottsModel(declarations...;
        numerics::CorePotts.NumericalPolicy = CorePotts.NumericalPolicy(Float32))
    return PottsModel(Tuple(declarations), numerics)
end

Base.length(model::PottsModel) = length(model.declarations)
Base.isempty(model::PottsModel) = isempty(model.declarations)
Base.iterate(model::PottsModel, state...) = iterate(model.declarations, state...)

function Base.show(io::IO, model::PottsModel)
    print(io, "PottsToolkit.PottsModel(", length(model.declarations),
        " declarations; real=", CorePotts.real_type(model.numerics), ")")
end

function _declaration_identity(declaration)
    return semantic_identity(declaration)
end

"""Return a new model with one declaration appended; the original remains unchanged."""
function add(model::PottsModel, declaration)
    return PottsModel((model.declarations..., declaration), model.numerics)
end

"""Return a new model without the declaration of `identity`."""
function remove(model::PottsModel, identity::SemanticName)
    kept = Tuple(declaration for declaration in model.declarations
        if _declaration_identity(declaration) != identity)
    length(kept) == length(model.declarations) && throw(KeyError(identity))
    return PottsModel(kept, model.numerics)
end

remove(model::PottsModel, declaration) = remove(model, _declaration_identity(declaration))

"""Replace exactly one declaration by semantic identity."""
function replace(model::PottsModel, identity::SemanticName, replacement)
    count = 0
    declarations = map(model.declarations) do declaration
        if _declaration_identity(declaration) == identity
            count += 1
            replacement
        else
            declaration
        end
    end
    count == 1 || throw(ArgumentError(
        count == 0 ? "no declaration matches $identity" :
        "replacement identity $identity is ambiguous"))
    return PottsModel(Tuple(declarations), model.numerics)
end

replace(model::PottsModel, pair::Pair) =
    replace(model, _declaration_identity(first(pair)), last(pair))

"""Compose declarations or fragments without assigning precedence to argument order."""
_compose_value(model::PottsModel, fragment::ModelFragment) =
    add(model, fragment)
_compose_value(model::PottsModel, value) = add(model, value)

function compose(model::PottsModel, values...)
    result = model
    for value in values
        result = _compose_value(result, value)
    end
    return result
end

function SciMLBase.remake(model::PottsModel;
        declarations = model.declarations, numerics = model.numerics)
    return PottsModel(Tuple(declarations), numerics)
end
