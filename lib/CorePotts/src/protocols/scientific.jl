"""Scientific category for conservative Hamiltonian terms."""
abstract type AbstractEnergy end
"""Scientific category for nonconservative proposal drives."""
abstract type AbstractDrive end
"""Scientific category for pure hard admissibility constraints."""
abstract type AbstractHardConstraint end

"""Typed backend- and dimension-level scientific capability declaration."""
struct ScientificCapabilities{D <: Tuple}
    dimensions::D
    portable::Bool
end

ScientificCapabilities(; dimensions = (2, 3), portable::Bool = true) =
    ScientificCapabilities(Tuple(Int.(dimensions)), portable)

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

    function CopyProposal(recipient::Integer, donor::Integer, losing::OwnerRef, gaining::OwnerRef;
            direction::Integer = 0, mcs::Integer = 0, semantic_id::Integer = 0)
        recipient > 0 || throw(ArgumentError("proposal recipient must be positive"))
        donor > 0 || throw(ArgumentError("proposal donor must be positive"))
        losing != gaining || throw(ArgumentError("same-owner selections are no-op attempts, not CopyProposal values"))
        direction >= 0 || throw(ArgumentError("proposal direction must be non-negative"))
        mcs >= 0 || throw(ArgumentError("proposal MCS must be non-negative"))
        semantic_id >= 0 || throw(ArgumentError("proposal semantic ID must be non-negative"))
        new(Int(recipient), Int(donor), losing, gaining, UInt32(direction), UInt64(mcs), UInt64(semantic_id))
    end
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
    hasmethod(component_identity, Tuple{typeof(component)}) || push!(missing, :component_identity)
    for function_name in essential
        function_value = getfield(@__MODULE__, function_name)
        any(method -> typeof(component) <: method.sig.parameters[2], methods(function_value)) ||
            push!(missing, function_name)
    end
    isempty(missing) || throw(ScientificInterfaceError(category, typeof(component), missing))
    identity = component_identity(component)
    identity isa ComponentIdentity || throw(ArgumentError("component_identity must return ComponentIdentity"))
    required_properties(component) isa PropertySchema || throw(ArgumentError(
        "required_properties must return PropertySchema"))
    capabilities(component) isa ScientificCapabilities || throw(ArgumentError(
        "capabilities must return ScientificCapabilities"))
    return ScientificInterfaceReport(category, identity, capabilities(component))
end

validate_energy_component(component::AbstractEnergy) = _interface_report(:energy, component, (:energy_change,))
validate_drive_component(component::AbstractDrive) = _interface_report(:drive, component, (:drive_log_bias,))
validate_constraint_component(component::AbstractHardConstraint) = _interface_report(:constraint, component, (:is_allowed,))
validate_tracker_component(component::AbstractTracker) = _interface_report(:tracker, component, (:rebuild_tracker,))
validate_event_component(component::AbstractEvent) = _interface_report(:event, component, (:event_effects,))
validate_algorithm_component(component::AbstractPottsAlgorithm) = _interface_report(:algorithm, component, (:algorithm_guarantees,))
validate_topology_component(component::AbstractTopology) = _interface_report(:topology, component, (:topology_dimensions,))

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
