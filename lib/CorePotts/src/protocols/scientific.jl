"""Scientific category for conservative Hamiltonian terms."""
abstract type AbstractEnergy end
"""Scientific category for nonconservative proposal drives."""
abstract type AbstractDrive end
"""Scientific category for pure hard admissibility constraints."""
abstract type AbstractHardConstraint end
"""Scientific category for non-Hamiltonian transition-rate modifiers."""
abstract type AbstractKineticModifier end

"""Typed backend- and dimension-level scientific capability declaration."""
struct ScientificCapabilities{D <: Tuple}
    dimensions::D
    portable::Bool
end

function ScientificCapabilities(; dimensions = (2, 3), portable::Bool = true)
    ScientificCapabilities(Tuple(Int.(dimensions)), portable)
end

"""
    CopyProposal

Immutable complete local ownership-copy proposal. `recipient` is overwritten by `gaining`; `donor`
is the neighboring site carrying that owner. It is intentionally independent of backend storage.
"""
struct CopyProposal
    recipient::Int
    donor::Int
    losing::OwnerRef
    gaining::OwnerRef
    direction::UInt32
    mcs::UInt64
    semantic_id::UInt64
    forward_multiplicity::UInt32
    reverse_multiplicity::UInt32

    function CopyProposal(
            recipient::Integer, donor::Integer, losing::OwnerRef, gaining::OwnerRef;
            direction::Integer = 0, mcs::Integer = 0, semantic_id::Integer = 0,
            forward_multiplicity::Integer = 1, reverse_multiplicity::Integer = 1)
        recipient > 0 || throw(ArgumentError("proposal recipient must be positive"))
        donor > 0 || throw(ArgumentError("proposal donor must be positive"))
        losing != gaining ||
            throw(ArgumentError("same-owner selections are no-op attempts, not CopyProposal values"))
        direction >= 0 || throw(ArgumentError("proposal direction must be non-negative"))
        mcs >= 0 || throw(ArgumentError("proposal MCS must be non-negative"))
        semantic_id >= 0 ||
            throw(ArgumentError("proposal semantic ID must be non-negative"))
        0 < forward_multiplicity <= typemax(UInt32) || throw(ArgumentError(
            "forward proposal multiplicity must be positive and fit UInt32"))
        0 <= reverse_multiplicity <= typemax(UInt32) || throw(ArgumentError(
            "reverse proposal multiplicity must be non-negative and fit UInt32"))
        new(Int(recipient), Int(donor), losing, gaining, UInt32(direction), UInt64(mcs),
            UInt64(semantic_id), UInt32(forward_multiplicity), UInt32(reverse_multiplicity))
    end

    function CopyProposal(recipient::Int, donor::Int, losing::OwnerRef, gaining::OwnerRef,
            direction::UInt32, mcs::UInt64, semantic_id::UInt64,
            forward_multiplicity::UInt32, reverse_multiplicity::UInt32, ::Val{:unchecked})
        return new(recipient, donor, losing, gaining, direction, mcs, semantic_id,
            forward_multiplicity, reverse_multiplicity)
    end
end

@inline function _copy_proposal_unchecked(recipient::UInt32, donor::UInt32,
        losing::OwnerRef, gaining::OwnerRef, direction::UInt32, mcs::UInt64,
        semantic_id::UInt64, forward::UInt32, reverse::UInt32)
    return CopyProposal(Int(recipient), Int(donor), losing, gaining, direction, mcs,
        semantic_id, forward, reverse, Val(:unchecked))
end

@enum CopyAttemptOutcome::UInt8 begin
    ActionableCopy = 1
    SameOwnerAttempt = 2
    BoundaryNullAttempt = 3
    ImmutableRecipientAttempt = 4
end

"""Union-free result of recipient/direction selection, including proposal-budget no-ops."""
struct CopyAttempt
    outcome::CopyAttemptOutcome
    recipient::UInt32
    donor::UInt32
    losing::OwnerRef
    gaining::OwnerRef
    direction::UInt32
    mcs::UInt64
    semantic_id::UInt64
    forward_multiplicity::UInt32
    reverse_multiplicity::UInt32
end

is_actionable(attempt::CopyAttempt) = attempt.outcome === ActionableCopy

function actionable_proposal(attempt::CopyAttempt)
    is_actionable(attempt) ||
        throw(ArgumentError("a null copy attempt has no actionable proposal"))
    return _copy_proposal_unchecked(attempt.recipient, attempt.donor, attempt.losing,
        attempt.gaining, attempt.direction, attempt.mcs, attempt.semantic_id,
        attempt.forward_multiplicity, attempt.reverse_multiplicity)
end

_proposal_dims(domain::CartesianDomain) = domain.dims
_proposal_dims(domain::CompiledCartesianDomain) = domain.descriptor.dims
_proposal_mutable(domain::CartesianDomain, site) = domain.mutable_mask[site]
function _proposal_mutable(domain::CompiledCartesianDomain, site)
    domain.storage.mutable_mask[site] != 0
end
_proposal_owner_at(state::LogicalPottsState, site) = owner_at(state, site)
function _proposal_owner_at(state::CompiledPottsState, site)
    owner_at(state.storage.ownership, site)
end
_proposal_state_dims(state::LogicalPottsState) = lattice_size(state)
_proposal_state_dims(state::CompiledPottsState) = state.descriptor.lattice_dims

function _owner_multiplicity(state, domain, relation, recipient, owner)
    multiplicity = UInt32(0)
    for candidate_direction in 1:direction_count(relation)
        neighbor = realize_neighbor(domain, relation, recipient, candidate_direction)
        if neighbor.site != 0 && _proposal_owner_at(state, neighbor.site) == owner
            multiplicity += UInt32(1)
        end
    end
    return multiplicity
end

"""
    construct_copy_attempt(state, domain, proposal_relation, recipient, direction; mcs, semantic_id)

Construct one conventional neighbor-site attempt. Exact transition multiplicities are counted
around the recipient so Metropolis-Hastings receives complete forward/reverse proposal support.
"""
function construct_copy_attempt(state,
        domain::Union{CartesianDomain, CompiledCartesianDomain},
        relation::StaticCartesianRelation{<:ProposalRole}, recipient::Integer,
        direction::Integer; mcs::Integer = 0, semantic_id::Integer = 0)
    _proposal_state_dims(state) == _proposal_dims(domain) || throw(ArgumentError(
        "proposal state and Cartesian domain dimensions must match"))
    1 <= recipient <= prod(_proposal_dims(domain)) || throw(BoundsError(
        1:prod(_proposal_dims(domain)), recipient))
    1 <= direction <= direction_count(relation) || throw(BoundsError(
        relation.offsets, direction))
    mcs >= 0 || throw(ArgumentError("proposal MCS must be non-negative"))
    semantic_id >= 0 || throw(ArgumentError("proposal semantic ID must be non-negative"))
    losing = _proposal_owner_at(state, recipient)
    if !_proposal_mutable(domain, recipient)
        return CopyAttempt(ImmutableRecipientAttempt, UInt32(recipient), UInt32(recipient),
            losing, losing, UInt32(direction), UInt64(mcs), UInt64(semantic_id), 0, 0)
    end
    neighbor = realize_neighbor(domain, relation, recipient, direction)
    if neighbor.site == 0
        return CopyAttempt(BoundaryNullAttempt, UInt32(recipient), UInt32(recipient),
            losing, losing, UInt32(direction), UInt64(mcs), UInt64(semantic_id), 0, 0)
    end
    gaining = _proposal_owner_at(state, neighbor.site)
    if gaining == losing
        return CopyAttempt(SameOwnerAttempt, UInt32(recipient), neighbor.site,
            losing, gaining, UInt32(direction), UInt64(mcs), UInt64(semantic_id), 0, 0)
    end
    forward = _owner_multiplicity(state, domain, relation, recipient, gaining)
    forward > 0 || error("constructed proposal has zero forward multiplicity")
    reverse = _owner_multiplicity(state, domain, relation, recipient, losing)
    return CopyAttempt(ActionableCopy, UInt32(recipient), neighbor.site,
        losing, gaining, UInt32(direction), UInt64(mcs), UInt64(semantic_id), forward, reverse)
end

function proposal_probabilities(proposal::Union{CopyProposal, CopyAttempt},
        mutable_sites::Integer, directions::Integer, ::Type{T} = Float64) where {T <:
                                                                                 AbstractFloat}
    mutable_sites > 0 || throw(ArgumentError("proposal probability requires mutable sites"))
    directions > 0 || throw(ArgumentError("proposal probability requires directions"))
    denominator = T(mutable_sites) * T(directions)
    return (
        q_forward = T(proposal.forward_multiplicity) / denominator,
        q_reverse = T(proposal.reverse_multiplicity) / denominator
    )
end

abstract type AbstractAcceptanceLaw end
struct ConventionalMetropolis <: AbstractAcceptanceLaw end
struct MetropolisHastings <: AbstractAcceptanceLaw end

"""Pure, structured inputs to a named acceptance law."""
struct AcceptanceInputs{T <: AbstractFloat}
    delta_h::T
    drive_log_bias::T
    kinetic_modifier::T
    yield_barrier::T
    forward_multiplicity::UInt32
    reverse_multiplicity::UInt32
    constraints_allowed::Bool
end

function AcceptanceInputs(delta_h::Real; drive_log_bias::Real = 0,
        kinetic_modifier::Real = 0, yield_barrier::Real = 0,
        forward_multiplicity::Integer = 1,
        reverse_multiplicity::Integer = 1, constraints_allowed::Bool = true)
    T = float(promote_type(
        typeof(delta_h), typeof(drive_log_bias), typeof(kinetic_modifier),
        typeof(yield_barrier)))
    values = T(delta_h), T(drive_log_bias), T(kinetic_modifier), T(yield_barrier)
    all(isfinite, values) || throw(ArgumentError("acceptance inputs must be finite"))
    values[4] >= zero(T) || throw(ArgumentError("yield barriers must be non-negative"))
    0 < forward_multiplicity <= typemax(UInt32) || throw(ArgumentError(
        "forward multiplicity must be positive and fit UInt32"))
    0 <= reverse_multiplicity <= typemax(UInt32) || throw(ArgumentError(
        "reverse multiplicity must be non-negative and fit UInt32"))
    return AcceptanceInputs(values..., UInt32(forward_multiplicity),
        UInt32(reverse_multiplicity), constraints_allowed)
end

function AcceptanceInputs(delta_h::Real, proposal::CopyProposal; kwargs...)
    return AcceptanceInputs(delta_h; forward_multiplicity = proposal.forward_multiplicity,
        reverse_multiplicity = proposal.reverse_multiplicity, kwargs...)
end

function _validate_temperature(temperature::Real)
    isfinite(temperature) && temperature >= zero(temperature) || throw(ArgumentError(
        "acceptance temperature must be finite and non-negative"))
    return temperature
end

function _zero_temperature_bias_check(inputs::AcceptanceInputs)
    iszero(inputs.drive_log_bias) && iszero(inputs.kinetic_modifier) || throw(ArgumentError(
        "nonconservative drives and kinetic modifiers require an explicit zero-temperature law"))
end

function acceptance_probability(::ConventionalMetropolis, inputs::AcceptanceInputs,
        temperature::Real)
    _validate_temperature(temperature)
    inputs.constraints_allowed || return zero(float(temperature))
    if iszero(temperature)
        _zero_temperature_bias_check(inputs)
        effective_delta = inputs.delta_h + inputs.yield_barrier
        return effective_delta <= zero(effective_delta) ? one(float(temperature)) :
               zero(float(temperature))
    end
    T = float(promote_type(typeof(temperature), typeof(inputs.delta_h)))
    log_ratio = -T(inputs.delta_h + inputs.yield_barrier) / T(temperature) +
                T(inputs.drive_log_bias) +
                T(inputs.kinetic_modifier)
    return log_ratio >= zero(T) ? one(T) : exp(log_ratio)
end

function acceptance_probability(::MetropolisHastings, inputs::AcceptanceInputs,
        temperature::Real)
    _validate_temperature(temperature)
    inputs.constraints_allowed || return zero(float(temperature))
    inputs.reverse_multiplicity == 0 && return zero(float(temperature))
    T = float(promote_type(typeof(temperature), typeof(inputs.delta_h)))
    proposal_ratio = T(inputs.reverse_multiplicity) / T(inputs.forward_multiplicity)
    if iszero(temperature)
        _zero_temperature_bias_check(inputs)
        effective_delta = inputs.delta_h + inputs.yield_barrier
        effective_delta < zero(effective_delta) && return one(T)
        effective_delta > zero(effective_delta) && return zero(T)
        return min(one(T), proposal_ratio)
    end
    log_ratio = -T(inputs.delta_h + inputs.yield_barrier) / T(temperature) +
                log(proposal_ratio) +
                T(inputs.drive_log_bias) + T(inputs.kinetic_modifier)
    return log_ratio >= zero(T) ? one(T) : exp(log_ratio)
end

function acceptance_decision(law::AbstractAcceptanceLaw, inputs::AcceptanceInputs,
        temperature::Real, draw::Real)
    zero(draw) < draw < one(draw) || throw(ArgumentError(
        "acceptance draws must lie strictly inside (0, 1)"))
    return draw < acceptance_probability(law, inputs, temperature)
end

"""Result of one logical ownership-copy transaction."""
struct LogicalCopyResult{S <: LogicalPottsState}
    state::S
    accepted::Bool
    retired::Vector{CellID}
end

logical_state(result::LogicalCopyResult) = result.state

"""
    commit_copy_proposal(state, proposal; accepted=true, constraints=())

Apply one accepted typed ownership-copy proposal to a private logical-state candidate. The lattice is
authoritative; derived occupancy is rebuilt and any extinct finite owner is retired immediately,
while the resulting slot remains unavailable for reuse until the lifecycle boundary releases it.
"""
function commit_copy_proposal(state::LogicalPottsState, proposal::CopyProposal;
        accepted::Bool = true, constraints::Tuple = ())
    accepted || return LogicalCopyResult(state, false, CellID[])
    all(constraint -> is_allowed(constraint, proposal, state), constraints) ||
        return LogicalCopyResult(state, false, CellID[])
    checkbounds(Bool, state._owners, proposal.recipient) || throw(ArgumentError(
        "proposal recipient lies outside the logical lattice"))
    checkbounds(Bool, state._owners, proposal.donor) || throw(ArgumentError(
        "proposal donor lies outside the logical lattice"))
    state._owners[proposal.recipient] == proposal.losing || throw(ArgumentError(
        "proposal losing owner does not match the recipient snapshot owner"))
    state._owners[proposal.donor] == proposal.gaining || throw(ArgumentError(
        "proposal gaining owner does not match the donor snapshot owner"))
    candidate = _copy_logical_state(state)
    candidate._owners[proposal.recipient] = proposal.gaining
    rebuild_derived_state!(candidate)
    retirement = retire_zero_volume(candidate)
    return LogicalCopyResult(logical_state(retirement), true, retirement.retired)
end

"""Stable diagnostic for one incomplete scientific extension."""
struct ScientificInterfaceError <: Exception
    category::Symbol
    component_type::DataType
    missing::Vector{Symbol}
end

function Base.showerror(io::IO, error::ScientificInterfaceError)
    print(io, "incomplete ", error.category, " extension ", error.component_type,
        ": missing ", join(string.(error.missing), ", "))
end

"""Report returned by the public category conformance helpers."""
struct ScientificInterfaceReport
    category::Symbol
    identity::ComponentIdentity
    capabilities::ScientificCapabilities
end

# Optional requirement categories have empty, typed defaults. Essential behavior has no fallback:
# missing `energy_change`, `drive_log_bias`, `is_allowed`, or tracker/event behavior remains a clear
# Julia MethodError until a category validator reports it before execution.
function component_identity end
required_properties(::Any) = PropertySchema()
required_observables(::Any) = ()
required_relations(::Any) = ()
capabilities(::Any) = ScientificCapabilities()

function _interface_report(category::Symbol, component, essential::Tuple)
    missing = Symbol[]
    hasmethod(component_identity, Tuple{typeof(component)}) ||
        push!(missing, :component_identity)
    for function_name in essential
        function_value = getfield(@__MODULE__, function_name)
        any(method -> typeof(component) <: method.sig.parameters[2], methods(function_value)) ||
            push!(missing, function_name)
    end
    isempty(missing) ||
        throw(ScientificInterfaceError(category, typeof(component), missing))
    identity = component_identity(component)
    identity isa ComponentIdentity ||
        throw(ArgumentError("component_identity must return ComponentIdentity"))
    required_properties(component) isa PropertySchema || throw(ArgumentError(
        "required_properties must return PropertySchema"))
    capabilities(component) isa ScientificCapabilities || throw(ArgumentError(
        "capabilities must return ScientificCapabilities"))
    return ScientificInterfaceReport(category, identity, capabilities(component))
end

function validate_energy_component(component::AbstractEnergy)
    _interface_report(:energy, component, (:energy_change,))
end
function validate_drive_component(component::AbstractDrive)
    _interface_report(:drive, component, (:drive_log_bias,))
end
function validate_constraint_component(component::AbstractHardConstraint)
    _interface_report(:constraint, component, (:is_allowed,))
end
function validate_tracker_component(component::AbstractTracker)
    _interface_report(:tracker, component, (:rebuild_tracker,))
end
function validate_event_component(component::AbstractEvent)
    _interface_report(:event, component, (:event_effects,))
end
function validate_algorithm_component(component::AbstractPottsAlgorithm)
    _interface_report(:algorithm, component, (:algorithm_guarantees,))
end
function validate_topology_component(component::AbstractTopology)
    _interface_report(:topology, component, (:topology_dimensions,))
end

"""Conservative local energy difference; extensions implement this pure method."""
function energy_change end
"""Dimensionless nonconservative log bias; extensions implement this pure method."""
function drive_log_bias end
"""Pure hard-constraint predicate; extensions implement this method."""
function is_allowed end
"""Complete tracker reconstruction from authoritative ownership; extensions implement this method."""
function rebuild_tracker end
"""Typed effects emitted from one event-phase snapshot; extensions implement this method."""
function event_effects end
"""Inspectable scientific algorithm guarantee profile; extensions implement this method."""
function algorithm_guarantees end
"""Supported Cartesian dimensions of a topology; extensions implement this method."""
function topology_dimensions end

"""Minimal public energy conformance helper with representative method validation."""
function test_energy_component(component::AbstractEnergy, proposal::CopyProposal, state::LogicalPottsState)
    report = validate_energy_component(component)
    result = energy_change(component, proposal, state)
    result isa Real || throw(ArgumentError("energy_change must return a real scalar"))
    isfinite(result) || throw(ArgumentError("energy_change must return a finite scalar"))
    return report
end

function test_tracker(component::AbstractTracker, state::LogicalPottsState)
    report = validate_tracker_component(component)
    rebuild_tracker(component, state)
    return report
end

test_event(component::AbstractEvent) = validate_event_component(component)
test_algorithm(component::AbstractPottsAlgorithm) = validate_algorithm_component(component)
test_topology(component::AbstractTopology) = validate_topology_component(component)
