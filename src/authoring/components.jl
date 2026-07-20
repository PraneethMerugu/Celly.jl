"""Target and strength values used by volume constraint declarations."""
struct VolumeParameters{T <: AbstractFloat}
    target::T
    strength::T

    function VolumeParameters(target::T, strength::T) where {T <: AbstractFloat}
        isfinite(target) && target >= zero(T) || throw(ArgumentError(
            "volume target must be finite and non-negative"))
        isfinite(strength) && strength >= zero(T) || throw(ArgumentError(
            "volume strength must be finite and non-negative"))
        return new{T}(target, strength)
    end
end

function VolumeParameters(target::Real, strength::Real)
    T = float(promote_type(typeof(target), typeof(strength)))
    return VolumeParameters(T(target), T(strength))
end

function _volume_bindings(pairs::Tuple)
    isempty(pairs) && throw(ArgumentError("a volume constraint must bind at least one cell type"))
    all(pair -> first(pair) isa CellType && last(pair) isa NamedTuple &&
        haskey(last(pair), :target) && (haskey(last(pair), :strength) || haskey(last(pair), :λ)),
        pairs) || throw(ArgumentError(
        "volume entries must be `CellType => (target=..., strength=...)`"))
    numeric_types = map(pairs) do pair
        values = last(pair)
        strength = haskey(values, :strength) ? values.strength : values.λ
        promote_type(typeof(values.target), typeof(strength))
    end
    T = float(promote_type(numeric_types...))
    entries = map(pairs) do pair
        values = last(pair)
        strength = haskey(values, :strength) ? values.strength : values.λ
        Binding{CellType, VolumeParameters{T}}(
            first(pair), VolumeParameters(T(values.target), T(strength)))
    end
    return BindingTable{CellType, VolumeParameters{T}}(Tuple(entries))
end

"""Conservative quadratic finite-cell volume Hamiltonian declaration."""
struct VolumeConstraint{T <: AbstractFloat}
    name::SemanticName
    bindings::BindingTable{CellType, VolumeParameters{T}}
end

function VolumeConstraint(pairs::Pair...; name::Symbol = :volume,
        namespace::Namespace = Namespace())
    bindings = _volume_bindings(pairs)
    T = typeof(first(bindings).value.target)
    return VolumeConstraint{T}(SemanticName(name; namespace), bindings)
end

semantic_identity(component::VolumeConstraint) = component.name

"""First-class fluctuating-volume mechanical declaration, distinct from the exact constraint."""
struct FluctuatingVolumeConstraint{T <: AbstractFloat, N, D}
    name::SemanticName
    bindings::BindingTable{CellType, VolumeParameters{T}}
    eta::T
    noise::N
    initialization::CorePotts.MechanicalInitialization
    division::D
end

function FluctuatingVolumeConstraint(pairs::Pair...; name::Symbol = :fluctuating_volume,
        namespace::Namespace = Namespace(), eta::Real = 1.0,
        noise = CorePotts.AlgorithmTemperatureNoise(),
        initialization::CorePotts.MechanicalInitialization =
            CorePotts.ConstitutiveMeanInitialization,
        division = CorePotts.ConstitutiveResetAfterDivision())
    bindings = _volume_bindings(pairs)
    T = typeof(first(bindings).value.target)
    rate = T(eta)
    isfinite(rate) && rate > zero(T) || throw(ArgumentError(
        "fluctuating-volume eta must be finite and positive"))
    return FluctuatingVolumeConstraint{T, typeof(noise), typeof(division)}(
        SemanticName(name; namespace), bindings, rate, noise, initialization, division)
end

semantic_identity(component::FluctuatingVolumeConstraint) = component.name

"""Unordered contact/adhesion Hamiltonian declaration."""
struct Adhesion{T <: AbstractFloat}
    name::SemanticName
    law::PairwiseLaw{T}
end

function Adhesion(pairs::Pair...; name::Symbol = :adhesion,
        namespace::Namespace = Namespace(), default = nothing)
    law = PairwiseLaw(pairs...; name, namespace, symmetric = true, default)
    return Adhesion(law.name, law)
end

semantic_identity(component::Adhesion) = component.name

"""One simultaneous per-cell property addition at an integer-MCS lifecycle boundary."""
struct PropertyUpdate{T, S, G}
    name::SemanticName
    source::SemanticName
    role::Symbol
    cell_types::Tuple
    amount::T
    schedule::S
    trigger::G
end


function PropertyUpdate(source, cell_types::CellType...;
        name::Symbol = :property_update, namespace::Namespace = Namespace(),
        role::Symbol = :target, amount::Real,
        schedule::CorePotts.AbstractMCSSchedule = CorePotts.EveryMCS(),
        trigger::CorePotts.AbstractLifecycleTrigger = CorePotts.AlwaysLifecycleTrigger())
    isempty(cell_types) && throw(ArgumentError(
        "a property update must target at least one cell type"))
    role in (:value, :target, :strength) || throw(ArgumentError(
        "property updates support :value, :target, or :strength roles"))
    T = float(typeof(amount))
    value = T(amount)
    isfinite(value) || throw(ArgumentError("a property update amount must be finite"))
    return PropertyUpdate(SemanticName(name; namespace), semantic_identity(source), role,
        Tuple(sort!(unique!(collect(cell_types)); by = _identity_text)), value,
        schedule, trigger)
end


function StochasticPropertyUpdate(source, cell_types::CellType...;
        name::Symbol = :stochastic_property_update, namespace::Namespace = Namespace(),
        role::Symbol = :target, amount::Real,
        schedule::CorePotts.AbstractMCSSchedule = CorePotts.EveryMCS(),
        probability::Real, draw::Symbol = :activation)
    T = float(promote_type(typeof(amount), typeof(probability)))
    operation = _semantic_rng_code(
        SemanticName(name; namespace), draw, UInt16(0x03ff))
    trigger = CorePotts.BernoulliCellTrigger(T(probability), operation)
    return PropertyUpdate(source, cell_types...; name, namespace, role,
        amount = T(amount), schedule, trigger)
end


semantic_identity(rule::PropertyUpdate) = rule.name

function _semantic_rng_code(identity::SemanticName, role::Symbol, maximum::UInt16)
    payload = string(_identity_text(identity), '|', role)
    digest = SHA.sha256(codeunits(payload))
    value = (UInt16(digest[1]) << 8) | UInt16(digest[2])
    return Int(mod(value, maximum + UInt16(1)))
end

"""Explicitly name a direct CorePotts component when more than one instance is composed."""
struct NamedCoreComponent{C}
    name::SemanticName
    component::C
end


NamedCoreComponent(name::Symbol, component; namespace::Namespace = Namespace()) =
    NamedCoreComponent(SemanticName(name; namespace), component)

semantic_identity(component::NamedCoreComponent) = component.name

function _core_semantic_identity(component)
    identity = try
        CorePotts.component_identity(component)
    catch
        return nothing
    end
    return SemanticName(identity.key)
end

function semantic_identity(component)
    identity = _core_semantic_identity(component)
    identity === nothing && throw(ArgumentError(
        "$(typeof(component)) does not provide a semantic identity"))
    return identity
end
