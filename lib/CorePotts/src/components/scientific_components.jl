"""A compile-time cell-property reference with no device-side `Symbol` field."""
struct CellPropertyRef{K} end

CellPropertyRef(key::Symbol) = CellPropertyRef{key}()
property_key(::CellPropertyRef{K}) where {K} = K

@inline _property_column(state::LogicalPottsState, ::CellPropertyRef{K}) where {K} = getproperty(
    state.properties.columns, K)
@inline _property_column(state::CompiledPottsState, ::CellPropertyRef{K}) where {K} = getproperty(
    state.storage.properties, K)

"""Finite static mapping from conceptual medium owner IDs to cell-type IDs."""
struct MediumTypeTable{N}
    owner_ids::NTuple{N, UInt32}
    type_ids::NTuple{N, UInt32}
end

function MediumTypeTable(entries)
    pairs = sort!(collect(entries); by = entry -> value(first(entry)))
    all(
        entry -> entry isa Pair && first(entry) isa MediumID &&
                 last(entry) isa CellTypeID, pairs) || throw(ArgumentError(
        "medium type entries must be `MediumID => CellTypeID` pairs"))
    ids = Tuple(value(first(entry)) for entry in pairs)
    length(unique(ids)) == length(ids) || throw(ArgumentError(
        "each medium owner must have exactly one type"))
    types = Tuple(value(last(entry)) for entry in pairs)
    return MediumTypeTable(ids, types)
end

MediumTypeTable(entries::Pair...) = MediumTypeTable(entries)

@inline function _medium_type(table::MediumTypeTable, owner::OwnerRef)
    @inbounds for index in eachindex(table.owner_ids)
        table.owner_ids[index] == owner.value && return table.type_ids[index]
    end
    throw(ArgumentError("medium owner has no declared type"))
end

@inline function owner_type(state::LogicalPottsState, table::MediumTypeTable,
        owner::OwnerRef)
    return is_cell_owner(owner) ? value(cell_type(state, cell_id(owner))) :
           _medium_type(table, owner)
end

@inline function owner_type(state::CompiledPottsState, table::MediumTypeTable,
        owner::OwnerRef)
    return is_cell_owner(owner) ? @inbounds(state.storage.cell_types[Int(owner.value)]) :
           _medium_type(table, owner)
end

"""Native conservative finite-cell volume Hamiltonian `lambda * (V - target)^2`."""
struct QuadraticVolumeHamiltonian{TargetKey, StrengthKey, T <: AbstractFloat} <:
       AbstractEnergy end

function QuadraticVolumeHamiltonian(; target::Symbol = :target_volume,
        strength::Symbol = :volume_strength, number_type::Type{T} = Float64) where {T <:
                                                                                    AbstractFloat}
    QuadraticVolumeHamiltonian{target, strength, T}()
end

_volume_target(::QuadraticVolumeHamiltonian{T}) where {T} = CellPropertyRef(T)
_volume_strength(::QuadraticVolumeHamiltonian{T, S}) where {T, S} = CellPropertyRef(S)

function component_identity(::QuadraticVolumeHamiltonian)
    ComponentIdentity(:quadratic_volume, v"1.0.0", :energy)
end

function required_properties(component::QuadraticVolumeHamiltonian)
    requester = component_identity(component)
    T = typeof(component).parameters[3]
    return PropertySchema(
        PropertyDescriptor(property_key(_volume_target(component)), T,
            ConstantInitializer(zero(T)); requester, kind = BiologicalProperty),
        PropertyDescriptor(property_key(_volume_strength(component)), T,
            ConstantInitializer(zero(T)); requester, kind = BiologicalProperty)
    )
end

function global_energy(component::QuadraticVolumeHamiltonian, state::LogicalPottsState)
    targets = _property_column(state, _volume_target(component))
    strengths = _property_column(state, _volume_strength(component))
    T = float(promote_type(eltype(targets), eltype(strengths)))
    result = zero(T)
    for id in active_cell_ids(state)
        index = Int(value(id))
        result += T(strengths[index]) * (T(finite_volume(state, id)) - T(targets[index]))^2
    end
    return result
end

function energy_change(component::QuadraticVolumeHamiltonian, proposal::CopyProposal,
        state::LogicalPottsState)
    targets = _property_column(state, _volume_target(component))
    strengths = _property_column(state, _volume_strength(component))
    T = float(promote_type(eltype(targets), eltype(strengths)))
    delta = zero(T)
    if is_cell_owner(proposal.losing)
        index = Int(proposal.losing.value)
        volume = finite_volume(state, CellID(proposal.losing.value))
        old = T(strengths[index]) * (T(volume) - T(targets[index]))^2
        delta += volume == 1 ? -old :
                 T(strengths[index]) * (T(volume - 1) - T(targets[index]))^2 - old
    end
    if is_cell_owner(proposal.gaining)
        index = Int(proposal.gaining.value)
        volume = finite_volume(state, CellID(proposal.gaining.value))
        delta += T(strengths[index]) * (
            (T(volume + 1) - T(targets[index]))^2 -
            (T(volume) - T(targets[index]))^2)
    end
    return delta
end

@enum MechanicalInitialization::UInt8 begin
    ConstitutiveMeanInitialization = 1
    StationaryMechanicalInitialization = 2
    PreserveMechanicalInitialization = 3
end

"""Use the selected CPM algorithm temperature as a visible mechanical-noise default."""
struct AlgorithmTemperatureNoise end

"""Mechanical-noise scale independent of the CPM acceptance temperature."""
struct FixedMechanicalNoise{T <: AbstractFloat}
    value::T

    function FixedMechanicalNoise(value::T) where {T <: AbstractFloat}
        isfinite(value) && value >= zero(T) || throw(ArgumentError(
            "mechanical noise scale must be finite and non-negative"))
        return new{T}(value)
    end
end

FixedMechanicalNoise(value::Real) = FixedMechanicalNoise(float(value))

"""Non-equilibrium per-cell pressure with an exact frozen-volume OU transition."""
struct FluctuatingVolumePressure{TargetKey, StrengthKey, StateKey,
    T <: AbstractFloat, N} <: AbstractMechanicalComponent
    eta::T
    noise::N
    initialization::MechanicalInitialization
    instance_id::UInt16
end

function FluctuatingVolumePressure(; target::Symbol = :target_volume,
        strength::Symbol = :volume_strength, state::Symbol = :volume_pressure,
        eta::Real = 1.0f0, noise = AlgorithmTemperatureNoise(),
        initialization::MechanicalInitialization = ConstitutiveMeanInitialization,
        instance_id::Integer = 1, number_type::Type{T} = Float32) where {
        T <: AbstractFloat}
    rate = T(eta)
    isfinite(rate) && rate > zero(T) || throw(ArgumentError(
        "volume-pressure relaxation rate must be finite and positive"))
    noise isa Union{AlgorithmTemperatureNoise, FixedMechanicalNoise} ||
        throw(ArgumentError("unsupported mechanical-noise declaration"))
    0 < instance_id <= typemax(UInt16) || throw(ArgumentError(
        "mechanical component instance ID must be positive and fit UInt16"))
    length(unique((target, strength, state))) == 3 || throw(ArgumentError(
        "volume-pressure target, strength, and state properties must be distinct"))
    return FluctuatingVolumePressure{
        target, strength, state, T, typeof(noise)}(
        rate, noise, initialization, UInt16(instance_id))
end

_mechanical_target(::FluctuatingVolumePressure{T}) where {T} = CellPropertyRef(T)
_mechanical_strength(::FluctuatingVolumePressure{T, S}) where {T, S} = CellPropertyRef(S)
_mechanical_state(::FluctuatingVolumePressure{T, S, Q}) where {T, S, Q} = CellPropertyRef(Q)

component_identity(::FluctuatingVolumePressure) =
    ComponentIdentity(:fluctuating_volume_pressure, v"1.0.0", :mechanical)

function required_properties(component::FluctuatingVolumePressure)
    requester = component_identity(component)
    T = typeof(component).parameters[4]
    return PropertySchema(
        PropertyDescriptor(property_key(_mechanical_target(component)), T,
            ConstantInitializer(zero(T)); requester, kind = BiologicalProperty),
        PropertyDescriptor(property_key(_mechanical_strength(component)), T,
            ConstantInitializer(zero(T)); requester, kind = BiologicalProperty),
        PropertyDescriptor(property_key(_mechanical_state(component)), T,
            ConstantInitializer(zero(T)); requester, mutability = MutableProperty,
            division = TransformOnDivision, transition = InvalidTransition,
            kind = AuxiliaryProperty)
    )
end

@inline function mechanical_work(component::FluctuatingVolumePressure,
        proposal::CopyProposal, state, transaction)
    values = _property_column(state, _mechanical_state(component))
    T = eltype(values)
    result = zero(T)
    is_cell_owner(proposal.losing) &&
        (result -= @inbounds values[Int(proposal.losing.value)])
    is_cell_owner(proposal.gaining) &&
        (result += @inbounds values[Int(proposal.gaining.value)])
    return result
end

"""Symmetric unordered contact Hamiltonian over one explicit contact relation."""
struct UnorderedContactHamiltonian{T <: AbstractFloat, N, A <: SMatrix{N, N, T},
    M <: MediumTypeTable,
    R <: StaticCartesianRelation{<:ContactRole}} <: AbstractEnergy
    interactions::A
    medium_types::M
    relation::R
end

function UnorderedContactHamiltonian(interactions::AbstractMatrix{<:Real},
        medium_types::MediumTypeTable, relation::StaticCartesianRelation{<:ContactRole})
    size(interactions, 1) == size(interactions, 2) || throw(ArgumentError(
        "contact interactions must form a square matrix"))
    size(interactions, 1) > 0 || throw(ArgumentError(
        "contact interactions must not be empty"))
    all(isfinite, interactions) || throw(ArgumentError(
        "contact interactions must be finite"))
    issymmetric(interactions) || throw(ArgumentError(
        "unordered contact interactions must be symmetric"))
    N = size(interactions, 1)
    all(type_id -> 1 <= type_id <= N, medium_types.type_ids) || throw(ArgumentError(
        "a medium type lies outside the interaction matrix"))
    T = float(eltype(interactions))
    matrix = SMatrix{N, N, T, N * N}(T.(interactions))
    return UnorderedContactHamiltonian(matrix, medium_types, relation)
end

function component_identity(::UnorderedContactHamiltonian)
    ComponentIdentity(:unordered_contact, v"1.0.0", :energy)
end
required_relations(::UnorderedContactHamiltonian) = (:contact,)

@inline function _contact_value(component::UnorderedContactHamiltonian, left::UInt32,
        right::UInt32)
    @boundscheck 1 <= left <= size(component.interactions, 1) &&
                 1 <= right <= size(component.interactions, 2) || throw(ArgumentError(
        "an owner type lies outside the contact interaction matrix"))
    return @inbounds component.interactions[Int(left), Int(right)]
end

@inline function _realized_owner(state, neighbor::RealizedNeighbor)
    return neighbor.kind === MutableNeighbor ? _proposal_owner_at(state, neighbor.site) :
           _fixed_owner_unchecked(neighbor)
end

@inline _metric_edge_weight(::Nothing, relation, direction) = relation_weight(relation, direction)

function energy_change(component::UnorderedContactHamiltonian, proposal::CopyProposal,
        state, domain::Union{CartesianDomain, CompiledCartesianDomain})
    losing_type = owner_type(state, component.medium_types, proposal.losing)
    gaining_type = owner_type(state, component.medium_types, proposal.gaining)
    T = eltype(component.interactions)
    delta = zero(T)
    for direction in 1:direction_count(component.relation)
        neighbor = realize_neighbor(domain, component.relation, proposal.recipient, direction)
        neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
        neighbor_owner = _realized_owner(state, neighbor)
        neighbor_type = owner_type(state, component.medium_types, neighbor_owner)
        weight = T(relation_weight(component.relation, direction))
        proposal.losing != neighbor_owner &&
            (delta -= weight * _contact_value(component, losing_type, neighbor_type))
        proposal.gaining != neighbor_owner &&
            (delta += weight * _contact_value(component, gaining_type, neighbor_type))
    end
    return delta
end

function global_energy(component::UnorderedContactHamiltonian, state,
        domain::Union{CartesianDomain, CompiledCartesianDomain})
    T = eltype(component.interactions)
    result = zero(T)
    mutable_sites = domain isa CartesianDomain ? findall(vec(domain.mutable_mask)) :
                    domain.storage.mutable_sites
    for site_value in mutable_sites
        site = Int(site_value)
        owner = _proposal_owner_at(state, site)
        owner_type_id = owner_type(state, component.medium_types, owner)
        for direction in 1:direction_count(component.relation)
            neighbor = realize_neighbor(domain, component.relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            if neighbor.kind === MutableNeighbor &&
               direction > opposite_direction(component.relation, direction)
                continue
            end
            neighbor_owner = _realized_owner(state, neighbor)
            owner == neighbor_owner && continue
            neighbor_type_id = owner_type(state, component.medium_types, neighbor_owner)
            result += T(relation_weight(component.relation, direction)) *
                      _contact_value(component, owner_type_id, neighbor_type_id)
        end
    end
    return result
end

abstract type AbstractBoundaryMetric end
"""Exact number of outward unlike-owner incidences."""
struct BoundaryEdgeCount <: AbstractBoundaryMetric end
"""Sum of explicit relation weights over outward unlike-owner incidences."""
struct WeightedBoundaryCount <: AbstractBoundaryMetric end

"""Published axis-calibrated correction table from Magno et al., version 1."""
struct MagnoAxisCalibrationV1 end

"""Physical boundary estimate from the square-order-4 or cubic-order-6 raw kernel."""
struct NormalizedKernelMeasure{N, T <: AbstractFloat, C} <: AbstractBoundaryMetric
    neighborhood_order::UInt8
    correction_factor::T
    site_spacing::T
    incidence_scale::T
    calibration::C
end

function NormalizedKernelMeasure(domain::CartesianDomain{N},
        relation::StaticCartesianRelation{<:SurfaceRole, N};
        calibration::MagnoAxisCalibrationV1 = MagnoAxisCalibrationV1()) where {N}
    N in (2, 3) || throw(ArgumentError(
        "normalized Cartesian surface measures support two or three dimensions"))
    all(==(first(domain.spacing)), domain.spacing) || throw(ArgumentError(
        "axis-calibrated normalized kernels require isotropic site spacing"))
    reference = normalized_kernel_relation(Val(N); spacing = domain.spacing)
    relation.offsets == reference.offsets || throw(ArgumentError(
        "normalized-kernel relation does not match the published neighborhood order"))
    relation.symmetric || throw(ArgumentError(
        "normalized-kernel surface relations must be symmetric"))
    T = eltype(relation.weights)
    order = N == 2 ? UInt8(4) : UInt8(6)
    correction = T(N == 2 ? 11 : 39)
    spacing = T(first(domain.spacing))
    scale = spacing^(N - 1) / correction
    return NormalizedKernelMeasure{
        N, T, typeof(calibration)}(order, correction, spacing, scale, calibration)
end

@inline _boundary_weight(::BoundaryEdgeCount, relation, direction) = 1
@inline _boundary_weight(::WeightedBoundaryCount, relation, direction) = relation_weight(relation, direction)
@inline _boundary_weight(metric::NormalizedKernelMeasure, relation, direction) = metric.incidence_scale

@inline _identity_mix(value::UInt64, word::UInt64) = xor(value, word) *
                                                     UInt64(0x00000100000001b3)
@inline _identity_word(value::Bool) = UInt64(value)
@inline _identity_word(value::UInt8) = UInt64(value)
@inline _identity_word(value::UInt16) = UInt64(value)
@inline _identity_word(value::Int32) = UInt64(reinterpret(UInt32, value))
@inline _identity_word(value::Float32) = UInt64(reinterpret(UInt32, value))
@inline _identity_word(value::Float64) = reinterpret(UInt64, value)

@inline _metric_identity_words(::BoundaryEdgeCount) = (UInt64(1),)
@inline _metric_identity_words(::WeightedBoundaryCount) = (UInt64(2),)
@inline function _metric_identity_words(metric::NormalizedKernelMeasure)
    return (UInt64(3), UInt64(metric.neighborhood_order),
        _identity_word(metric.correction_factor), _identity_word(metric.site_spacing),
        _identity_word(metric.incidence_scale), UInt64(1))
end

function _boundary_tracker_identity(metric::AbstractBoundaryMetric,
        relation::StaticCartesianRelation{<:SurfaceRole})
    hash1 = UInt64(0xcbf29ce484222325)
    hash2 = UInt64(0x84222325cbf29ce4)
    for word in _metric_identity_words(metric)
        hash1 = _identity_mix(hash1, word)
        hash2 = _identity_mix(hash2, xor(word, UInt64(0x9e3779b97f4a7c15)))
    end
    hash1 = _identity_mix(hash1, UInt64(direction_count(relation)))
    hash2 = _identity_mix(hash2, UInt64(length(first(relation.offsets))))
    for direction in 1:direction_count(relation)
        for coordinate in relation.offsets[direction]
            word = _identity_word(coordinate)
            hash1 = _identity_mix(hash1, word)
            hash2 = _identity_mix(hash2, xor(word, UInt64(direction)))
        end
        for word in (_identity_word(relation.weights[direction]),
            _identity_word(relation.opposite[direction]))
            hash1 = _identity_mix(hash1, word)
            hash2 = _identity_mix(hash2, xor(word, UInt64(0x517cc1b727220a95)))
        end
    end
    for word in (_identity_word(relation.symmetric), UInt64(relation.version.major),
        UInt64(relation.version.minor), UInt64(relation.version.patch))
        hash1 = _identity_mix(hash1, word)
        hash2 = _identity_mix(hash2, xor(word, UInt64(0x94d049bb133111eb)))
    end
    return (hash1, hash2)
end

function boundary_measure(state, domain::Union{CartesianDomain, CompiledCartesianDomain},
        relation::StaticCartesianRelation{<:SurfaceRole}, owner::OwnerRef,
        metric::AbstractBoundaryMetric)
    T = metric isa BoundaryEdgeCount ? Int64 : eltype(relation.weights)
    result = zero(T)
    mutable_sites = domain isa CartesianDomain ? findall(vec(domain.mutable_mask)) :
                    domain.storage.mutable_sites
    for site_value in mutable_sites
        site = Int(site_value)
        _proposal_owner_at(state, site) == owner || continue
        for direction in 1:direction_count(relation)
            neighbor = realize_neighbor(domain, relation, site, direction)
            neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
            _realized_owner(state, neighbor) != owner &&
                (result += T(_boundary_weight(metric, relation, direction)))
        end
    end
    return result
end

function boundary_measure_change(
        state, domain, relation::StaticCartesianRelation{<:SurfaceRole},
        proposal::CopyProposal, metric::AbstractBoundaryMetric)
    return _boundary_measure_change(
        realize_neighbor, state, domain, relation, proposal, metric)
end

@inline function _boundary_measure_change_unchecked(
        state, domain, relation::StaticCartesianRelation{<:SurfaceRole},
        proposal::CopyProposal, metric::AbstractBoundaryMetric)
    return _boundary_measure_change(
        _realize_neighbor_unchecked, state, domain, relation, proposal, metric)
end

@inline function _boundary_measure_change(realize, state, domain,
        relation::StaticCartesianRelation{<:SurfaceRole}, proposal::CopyProposal,
        metric::AbstractBoundaryMetric)
    T = metric isa BoundaryEdgeCount ? Int64 : eltype(relation.weights)
    losing_delta = zero(T)
    gaining_delta = zero(T)
    for direction in 1:direction_count(relation)
        neighbor = realize(domain, relation, proposal.recipient, direction)
        neighbor.kind in (AbsentNeighbor, InvalidNeighbor) && continue
        owner = _realized_owner(state, neighbor)
        weight = T(_boundary_weight(metric, relation, direction))
        losing_delta += owner == proposal.losing ? weight : -weight
        gaining_delta += owner == proposal.gaining ? -weight : weight
    end
    return (losing = losing_delta, gaining = gaining_delta)
end

"""Ordinary conservative finite-cell boundary Hamiltonian."""
struct QuadraticBoundaryHamiltonian{TargetKey, StrengthKey,
    T <: AbstractFloat, M <: AbstractBoundaryMetric,
    R <: StaticCartesianRelation{<:SurfaceRole}} <: AbstractEnergy
    metric::M
    relation::R
    tracker_identity::NTuple{2, UInt64}
end

function QuadraticBoundaryHamiltonian(metric::AbstractBoundaryMetric,
        relation::StaticCartesianRelation{<:SurfaceRole};
        target::Symbol = :target_boundary, strength::Symbol = :boundary_strength,
        number_type::Type{T} = Float64) where {T <: AbstractFloat}
    return QuadraticBoundaryHamiltonian{
        target, strength, T, typeof(metric), typeof(relation)}(
        metric, relation, _boundary_tracker_identity(metric, relation))
end

_boundary_target(::QuadraticBoundaryHamiltonian{T}) where {T} = CellPropertyRef(T)
_boundary_strength(::QuadraticBoundaryHamiltonian{T, S}) where {T, S} = CellPropertyRef(S)

function component_identity(::QuadraticBoundaryHamiltonian)
    ComponentIdentity(:quadratic_boundary, v"1.0.0", :energy)
end
required_relations(::QuadraticBoundaryHamiltonian) = (:surface,)

function required_properties(component::QuadraticBoundaryHamiltonian)
    requester = component_identity(component)
    number_type = typeof(component).parameters[3]
    target_type = component.metric isa BoundaryEdgeCount ? Int64 : number_type
    target_default = zero(target_type)
    return PropertySchema(
        PropertyDescriptor(property_key(_boundary_target(component)), target_type,
            ConstantInitializer(target_default); requester, kind = BiologicalProperty),
        PropertyDescriptor(property_key(_boundary_strength(component)), number_type,
            ConstantInitializer(zero(number_type)); requester, kind = BiologicalProperty)
    )
end

function global_energy(component::QuadraticBoundaryHamiltonian, state::LogicalPottsState,
        domain::Union{CartesianDomain, CompiledCartesianDomain})
    targets = _property_column(state, _boundary_target(component))
    strengths = _property_column(state, _boundary_strength(component))
    T = float(promote_type(eltype(targets), eltype(strengths), eltype(component.relation.weights)))
    result = zero(T)
    for id in active_cell_ids(state)
        index = Int(value(id))
        measure = boundary_measure(
            state, domain, component.relation, CellOwner(id), component.metric)
        result += T(strengths[index]) * (T(measure) - T(targets[index]))^2
    end
    return result
end

function energy_change(component::QuadraticBoundaryHamiltonian, proposal::CopyProposal,
        state::LogicalPottsState, domain::Union{CartesianDomain, CompiledCartesianDomain})
    targets = _property_column(state, _boundary_target(component))
    strengths = _property_column(state, _boundary_strength(component))
    T = float(promote_type(eltype(targets), eltype(strengths), eltype(component.relation.weights)))
    deltas = boundary_measure_change(
        state, domain, component.relation, proposal, component.metric)
    result = zero(T)
    if is_cell_owner(proposal.losing)
        index = Int(proposal.losing.value)
        measure = boundary_measure(state, domain, component.relation,
            proposal.losing, component.metric)
        old = T(strengths[index]) * (T(measure) - T(targets[index]))^2
        result += finite_volume(state, CellID(proposal.losing.value)) == 1 ? -old :
                  T(strengths[index]) *
                  (T(measure + deltas.losing) - T(targets[index]))^2 - old
    end
    if is_cell_owner(proposal.gaining)
        index = Int(proposal.gaining.value)
        measure = boundary_measure(state, domain, component.relation,
            proposal.gaining, component.metric)
        result += T(strengths[index]) * (
            (T(measure + deltas.gaining) - T(targets[index]))^2 -
            (T(measure) - T(targets[index]))^2)
    end
    return result
end

"""Non-equilibrium per-cell tension with an exact frozen-surface OU transition."""
struct FluctuatingSurfaceTension{TargetKey, StrengthKey, StateKey,
    T <: AbstractFloat, N, M <: AbstractBoundaryMetric,
    R <: StaticCartesianRelation{<:SurfaceRole}} <: AbstractMechanicalComponent
    eta::T
    noise::N
    initialization::MechanicalInitialization
    instance_id::UInt16
    metric::M
    relation::R
    tracker_identity::NTuple{2, UInt64}
end

function FluctuatingSurfaceTension(metric::AbstractBoundaryMetric,
        relation::StaticCartesianRelation{<:SurfaceRole};
        target::Symbol = :target_boundary, strength::Symbol = :boundary_strength,
        state::Symbol = :surface_tension, eta::Real = 1.0f0,
        noise = AlgorithmTemperatureNoise(),
        initialization::MechanicalInitialization = ConstitutiveMeanInitialization,
        instance_id::Integer = 1, number_type::Type{T} = Float32) where {
        T <: AbstractFloat}
    rate = T(eta)
    isfinite(rate) && rate > zero(T) || throw(ArgumentError(
        "surface-tension relaxation rate must be finite and positive"))
    noise isa Union{AlgorithmTemperatureNoise, FixedMechanicalNoise} ||
        throw(ArgumentError("unsupported mechanical-noise declaration"))
    0 < instance_id <= typemax(UInt16) || throw(ArgumentError(
        "mechanical component instance ID must be positive and fit UInt16"))
    length(unique((target, strength, state))) == 3 || throw(ArgumentError(
        "surface-tension target, strength, and state properties must be distinct"))
    return FluctuatingSurfaceTension{
        target, strength, state, T, typeof(noise), typeof(metric), typeof(relation)}(
        rate, noise, initialization, UInt16(instance_id), metric, relation,
        _boundary_tracker_identity(metric, relation))
end

_mechanical_target(::FluctuatingSurfaceTension{T}) where {T} = CellPropertyRef(T)
_mechanical_strength(::FluctuatingSurfaceTension{T, S}) where {T, S} = CellPropertyRef(S)
_mechanical_state(::FluctuatingSurfaceTension{T, S, Q}) where {T, S, Q} = CellPropertyRef(Q)

component_identity(::FluctuatingSurfaceTension) =
    ComponentIdentity(:fluctuating_surface_tension, v"1.0.0", :mechanical)
required_relations(::FluctuatingSurfaceTension) = (:surface,)

function required_properties(component::FluctuatingSurfaceTension)
    requester = component_identity(component)
    T = typeof(component).parameters[4]
    target_type = component.metric isa BoundaryEdgeCount ? Int64 : T
    return PropertySchema(
        PropertyDescriptor(property_key(_mechanical_target(component)), target_type,
            ConstantInitializer(zero(target_type)); requester, kind = BiologicalProperty),
        PropertyDescriptor(property_key(_mechanical_strength(component)), T,
            ConstantInitializer(zero(T)); requester, kind = BiologicalProperty),
        PropertyDescriptor(property_key(_mechanical_state(component)), T,
            ConstantInitializer(zero(T)); requester, mutability = MutableProperty,
            division = TransformOnDivision, transition = InvalidTransition,
            kind = AuxiliaryProperty)
    )
end

@inline function mechanical_work(component::FluctuatingSurfaceTension,
        proposal::CopyProposal, state, transaction)
    values = _property_column(state, _mechanical_state(component))
    T = eltype(values)
    delta = transaction.trackers
    result = zero(T)
    is_cell_owner(proposal.losing) &&
        (result += @inbounds values[Int(proposal.losing.value)] * T(delta.losing_boundary))
    is_cell_owner(proposal.gaining) &&
        (result += @inbounds values[Int(proposal.gaining.value)] * T(delta.gaining_boundary))
    return result
end

_boundary_metric_name(::BoundaryEdgeCount) = :boundary_edge_count
_boundary_metric_name(::WeightedBoundaryCount) = :weighted_boundary_count
_boundary_metric_name(::NormalizedKernelMeasure) = :normalized_kernel_measure

function _boundary_metric_semantics(::BoundaryEdgeCount)
    (
        family = :raw_outward_incidence_count,
        calibration = :exact_integer
    )
end
function _boundary_metric_semantics(::WeightedBoundaryCount)
    (
        family = :declared_weighted_outward_incidence_sum,
        calibration = :relation_weights
    )
end
function _boundary_metric_semantics(metric::NormalizedKernelMeasure{N}) where {N}
    return (
        family = :published_normalized_kernel,
        dimension = N,
        neighborhood_order = Int(metric.neighborhood_order),
        correction_factor = metric.correction_factor,
        site_spacing = metric.site_spacing,
        incidence_scale = metric.incidence_scale,
        calibration = nameof(typeof(metric.calibration)),
        calibration_version = v"1.0.0",
        isotropy_claim = :not_claimed
    )
end

"""Complete host report for the ordinary boundary Hamiltonian and its cached measure."""
function surface_semantics_report(component::QuadraticBoundaryHamiltonian,
        domain::CartesianDomain)
    target_type = component.metric isa BoundaryEdgeCount ? Int64 :
                  typeof(component).parameters[3]
    return (
        component = component_identity(component),
        category = :hamiltonian,
        law = :quadratic_target_boundary,
        metric = _boundary_metric_name(component.metric),
        metric_descriptor = _boundary_metric_semantics(component.metric),
        accumulator_type = component.metric isa BoundaryEdgeCount ? Int64 :
                           eltype(component.relation.weights),
        target_type,
        target_property = property_key(_boundary_target(component)),
        strength_property = property_key(_boundary_strength(component)),
        relation = relation_semantics_report(component.relation),
        domain = domain_semantics_report(domain)
    )
end
