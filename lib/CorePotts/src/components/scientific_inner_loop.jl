"""Typed scientific component bundle lowered once and passed unchanged to hot kernels."""
struct ScientificComponentSet{E <: Tuple, D <: Tuple, C <: Tuple, K <: Tuple}
    energies::E
    drives::D
    constraints::C
    kinetic_modifiers::K
end

function ScientificComponentSet(; energies::Tuple = (), drives::Tuple = (),
        constraints::Tuple = (), kinetic_modifiers::Tuple = ())
    all(component -> component isa AbstractEnergy, energies) || throw(ArgumentError(
        "every energy component must subtype AbstractEnergy"))
    all(component -> component isa AbstractDrive, drives) || throw(ArgumentError(
        "every drive component must subtype AbstractDrive"))
    all(component -> component isa AbstractHardConstraint, constraints) ||
        throw(ArgumentError(
            "every constraint component must subtype AbstractHardConstraint"))
    all(component -> component isa AbstractKineticModifier, kinetic_modifiers) ||
        throw(ArgumentError(
            "every kinetic modifier must subtype AbstractKineticModifier"))
    return ScientificComponentSet(energies, drives, constraints, kinetic_modifiers)
end

function Adapt.adapt_structure(to, components::ScientificComponentSet)
    adapt_tuple(values) = map(value -> Adapt.adapt(to, value), values)
    return ScientificComponentSet(
        adapt_tuple(components.energies),
        adapt_tuple(components.drives),
        adapt_tuple(components.constraints),
        adapt_tuple(components.kinetic_modifiers)
    )
end

"""Zero-storage marker for models without an exact connectivity constraint."""
struct NoConnectivityWorkspace end

"""One immutable pre-copy view shared by every component in a proposal evaluation."""
struct ScientificProposalContext{S <: ScientificExecutionState,
    T <: StagedCopyTransaction, W}
    state::S
    transaction::T
    connectivity_workspace::W
    workspace_epoch::UInt32
end

function ScientificProposalContext(state::CompiledScientificState,
        transaction::StagedCopyTransaction;
        connectivity_workspace = NoConnectivityWorkspace(), workspace_epoch::Integer = 1)
    return ScientificProposalContext(
        scientific_execution(state), transaction; connectivity_workspace, workspace_epoch)
end

function ScientificProposalContext(state::ScientificExecutionState,
        transaction::StagedCopyTransaction;
        connectivity_workspace = NoConnectivityWorkspace(), workspace_epoch::Integer = 1)
    0 < workspace_epoch <= typemax(UInt32) || throw(ArgumentError(
        "proposal workspace epoch must be positive and fit UInt32"))
    connectivity_workspace isa ConnectivityWorkspace &&
        validate_workspace(connectivity_workspace, state)
    return ScientificProposalContext(
        state, transaction, connectivity_workspace, UInt32(workspace_epoch))
end

function Adapt.adapt_structure(to, context::ScientificProposalContext)
    return ScientificProposalContext(
        Adapt.adapt(to, context.state), context.transaction,
        Adapt.adapt(to, context.connectivity_workspace), context.workspace_epoch)
end

@inline _copy_energy_delta(component::QuadraticVolumeHamiltonian,
    proposal, context) = energy_change(component, proposal, context.state)
@inline _copy_energy_delta(component::UnorderedContactHamiltonian,
    proposal, context) = energy_change(component, proposal, context.state, context.state.domain)
@inline _copy_energy_delta(component::QuadraticBoundaryHamiltonian,
    proposal, context) = energy_change(component, proposal, context.state)
@inline _copy_energy_delta(component::ExternalFieldOccupancyHamiltonian,
    proposal, context) = energy_change(component, proposal, context.state, context.state.domain)
@inline _copy_energy_delta(component::FocalPointSpringHamiltonian,
    proposal, context) = energy_change(component, proposal, context.state, context.transaction)

@inline _copy_drive_bias(component::ChemotaxisDrive,
    proposal, context) = drive_log_bias(component, proposal, context.state, context.state.domain)

@inline _copy_constraint_allowed(component::PreserveConnectedCells,
    proposal, context::ScientificProposalContext{S, T, <:ConnectivityWorkspace}) where {
    S, T} = is_allowed(component, proposal, context.state, context.connectivity_workspace,
    context.workspace_epoch)
@inline _copy_constraint_allowed(component::FixedFocalEndpointConstraint,
    proposal, context) = is_allowed(component, proposal, context.state)

@inline _copy_modifier_contribution(component::PositiveYield, proposal, context) = (
    kinetic = zero(component.barrier),
    yield = kinetic_barrier(
        component, proposal, context.state))

@inline _fold_energies(::Tuple{}, proposal, context, result) = result
@inline function _fold_energies(components::Tuple, proposal, context, result)
    updated = result + _copy_energy_delta(first(components), proposal, context)
    return _fold_energies(Base.tail(components), proposal, context, updated)
end

@inline _fold_drives(::Tuple{}, proposal, context, result) = result
@inline function _fold_drives(components::Tuple, proposal, context, result)
    updated = result + _copy_drive_bias(first(components), proposal, context)
    return _fold_drives(Base.tail(components), proposal, context, updated)
end

@inline _fold_constraints(::Tuple{}, proposal, context, result) = result
@inline function _fold_constraints(components::Tuple, proposal, context, result)
    updated = result && _copy_constraint_allowed(first(components), proposal, context)
    return _fold_constraints(Base.tail(components), proposal, context, updated)
end

@inline _fold_modifiers(::Tuple{}, proposal, context, kinetic, yield) = (kinetic, yield)
@inline function _fold_modifiers(components::Tuple, proposal, context, kinetic, yield)
    contribution = _copy_modifier_contribution(first(components), proposal, context)
    return _fold_modifiers(Base.tail(components), proposal, context,
        kinetic + contribution.kinetic, yield + contribution.yield)
end

"""Category-preserving scalar result consumed by a separately selected acceptance law."""
struct ScientificCopyEvaluation{T <: AbstractFloat}
    delta_h::T
    drive_log_bias::T
    kinetic_modifier::T
    yield_barrier::T
    forward_multiplicity::UInt32
    reverse_multiplicity::UInt32
    constraints_allowed::Bool
end

"""Evaluate every declared component against exactly one shared pre-copy snapshot."""
@inline function evaluate_copy(components::ScientificComponentSet, proposal::CopyProposal,
        context::ScientificProposalContext, ::Type{T}) where {T <: AbstractFloat}
    delta_h = T(_fold_energies(components.energies, proposal, context, zero(T)))
    drive_bias = T(_fold_drives(components.drives, proposal, context, zero(T)))
    constraints_allowed = _fold_constraints(
        components.constraints, proposal, context, true)
    kinetic, yield = _fold_modifiers(
        components.kinetic_modifiers, proposal, context, zero(T), zero(T))
    return ScientificCopyEvaluation(delta_h, T(drive_bias), T(kinetic), T(yield),
        proposal.forward_multiplicity, proposal.reverse_multiplicity,
        constraints_allowed)
end

function evaluate_copy(components::ScientificComponentSet, proposal::CopyProposal,
        context::ScientificProposalContext; number_type::Type{T} = Float64) where {
        T <: AbstractFloat}
    return evaluate_copy(components, proposal, context, T)
end

function acceptance_inputs(evaluation::ScientificCopyEvaluation)
    return AcceptanceInputs(evaluation.delta_h;
        drive_log_bias = evaluation.drive_log_bias,
        kinetic_modifier = evaluation.kinetic_modifier,
        yield_barrier = evaluation.yield_barrier,
        forward_multiplicity = evaluation.forward_multiplicity,
        reverse_multiplicity = evaluation.reverse_multiplicity,
        constraints_allowed = evaluation.constraints_allowed)
end

function scientific_components_report(components::ScientificComponentSet)
    identities(values) = map(component_identity, values)
    return (
        energies = identities(components.energies),
        drives = identities(components.drives),
        constraints = identities(components.constraints),
        kinetic_modifiers = identities(components.kinetic_modifiers)
    )
end
