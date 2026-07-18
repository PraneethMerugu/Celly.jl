module CorePotts

using KernelIntrinsics
using AcceleratedKernels
using KernelAbstractions
using StructArrays
using Adapt
using Random
using SciMLBase
using LinearAlgebra: issymmetric
import Atomix
import SciMLBase: solve

export solve, fmap

const DEFAULT_BLOCK_SIZE = 256

include("topology/topology.jl")
include("proposals/samplers.jl")
include("state/semantics.jl")
include("state/types.jl")
include("state/logical.jl")
include("state/lifecycle.jl")
include("execution/dispatch.jl")
include("rng/semantic.jl")
include("execution/contracts.jl")

include("components/trackers/trackers.jl")
include("components/components.jl")
include("components/training.jl")
include("protocols/scientific.jl")
include("reference/engine.jl")

include("initialization/initialization.jl")
include("initialization/logical.jl")
include("lifecycle/events.jl")

include("kernels/metropolis.jl")
include("kernels/intrinsics.jl")
include("sciml/simulator.jl")

# ==============================================================================
# UNIFIED USER API EXPORTS
# ==============================================================================

# From Base
export AbstractTopology, VonNeumannTopology, MooreTopology, NoFluxVonNeumannTopology,
       NoFluxMooreTopology, ExtendedVonNeumannTopology, ExtendedMooreTopology,
       NoFluxExtendedVonNeumannTopology, NoFluxExtendedMooreTopology
export AbstractSampler, MetropolisSampler
export AbstractPottsProblem, AbstractPottsAlgorithm, PottsProblem, ParallelMetropolis,
       CheckerboardMetropolis, SequentialMetropolis,
       IntrinsicCheckerboardMetropolis,
       PottsIntegrator,
       PottsSolution, PottsState, PottsParameters, PottsCache
export AbstractPottsState, FlexibilityTrait, Rigid, Flex
export lattice_storage
export AbstractEvent
export AbstractScientificID, CellID, CellTypeID, MediumID, CellSlot, CellGeneration, CellCapacity,
       value, nslots, NumericalPolicy, real_type, accumulation_type, portable_numerical_policy,
       AbstractMathMode, AccurateMath, QualifiedFastMath,
       AbstractReductionMode, DeterministicReductions, TolerantReductions,
       AbstractOverflowMode, CheckedModelBounds, QualifiedUncheckedBounds,
       PropertyKind, BiologicalProperty, DerivedProperty, AuxiliaryProperty, TransientProperty,
       PropertyMutability, ReadOnlyProperty, MutableProperty,
       DivisionPolicy, CloneOnDivision, SplitOnDivision, ResetChildOnDivision,
       ResetBothOnDivision, AsymmetricResetOnDivision, TransformOnDivision,
       TransitionPolicy, PreserveOnTransition, ResetOnTransition, TransformOnTransition,
       RecomputeOnTransition, InvalidTransition, RetirementPolicy, ResetOnRetirement,
       ComponentIdentity, ConstantInitializer, AbstractPropertyDescriptor, PropertyDescriptor,
       PropertySchema, PropertySchemaConflictError, property_keys, property_descriptor,
       property_requesters, value_type, merge_property_schemas
export OwnerRef, CellOwner, MediumOwner, is_cell_owner, is_medium_owner, cell_id, medium_id,
       PropertyStore, property_values, OccupancyDerivedState, LogicalPottsState,
       CompiledOwnership, compile_ownership,
       LogicalStateInvariantError, capacity, n_cells, active_cell_ids, reusable_cell_slots,
       medium_ids, generation, is_active, cell_type, owner_at, lattice_size, derived_state,
       finite_volume, medium_occupancy, state_invariant_errors, assert_valid_state,
       rebuild_derived_state!, property_value, set_cell_property!
export DivisionRequest, LogicalDivisionResult, LogicalRetirementResult, apply_division_batch,
       retire_zero_volume, release_retired_slots, immediately_remove_cell, transition_cell_type
export AbstractEnergy, AbstractDrive, AbstractHardConstraint, ScientificCapabilities, CopyProposal,
       ScientificInterfaceError, ScientificInterfaceReport, component_identity,
       required_properties, required_observables, required_relations, capabilities,
       energy_change, drive_log_bias, is_allowed, rebuild_tracker, event_effects,
       LogicalCopyResult, commit_copy_proposal,
       algorithm_guarantees, topology_dimensions, validate_energy_component,
       validate_drive_component, validate_constraint_component, validate_tracker_component,
       validate_event_component, validate_algorithm_component, validate_topology_component,
       test_energy_component, test_tracker, test_event, test_algorithm, test_topology
export ReferenceVolumeEnergy, ReferenceContactEnergy, ReferenceModel, SequentialReference,
       ReferenceIntegrator, ReferenceMCSReport, reference_energy, init_reference,
       step_reference!, reference_rng_version
export AbstractRNGContract, Philox4x32x10V1, RNGStream, RNGEntityKind, RNGAddress,
       LayoutPlacementStream, LayoutPermutationStream, ProposalRecipientStream,
       ProposalDirectionStream, AcceptanceStream, LotteryActivationStream,
       LotteryPriorityStream, CheckerboardOrderStream, HSTStream, RuleStream,
       EventStream, DivisionOrientationStream, PropertyInheritanceStream,
       StochasticRoundingStream, TypeTransitionStream, EnsembleStream,
       GlobalEntity, SiteEntity, CellEntity, EnsembleEntity,
       rng_contract_version, rng_counter_key, philox4x32_10, rng_words, rng_word,
       uniform_open01, bounded_uint, bernoulli, normal_box_muller,
       poisson_inversion, poisson_normal_approx, CategoricalTable, categorical_index,
       small_permutation!, distribution_profile
export BackendFamily, CPUFamily, CUDAFamily, AMDGPUFamily, MetalFamily,
       BackendCapabilities, UnsupportedBackendCapability, UnsupportedBackendType, backend_capabilities,
       require_capability, CompiledStateDescriptor, CompiledStateStorage,
       CompiledPottsState, compile_state, execution_storage, adapt_execution,
       device_storage_valid, logical_snapshot, WorkspaceRequirements, workspace_bytes,
       ExecutionWorkspace, allocate_workspace, TransactionRequirements, TransactionWorkspace,
       transaction_workspace_bytes, allocate_transaction_workspace, OrderedAsynchronousLaunches,
       ExplicitObservationSynchronization, ExecutionMetrics, ExecutionPlan, launch!,
       synchronize_observation!, record_transfer!, record_allocation!
export LayoutOverlapPolicy, ErrorOnOverlap, ReplaceOnOverlap, PreserveOnOverlap,
       AbstractInitialLayout, InitialCellLayout, InitialMediumLayout, InitialLayoutOverlapError,
       LogicalInitializationReport, InitializedLogicalState, logical_state, initialization_report,
       finalize_initial_state, CellCapacityError
export AbstractTracker, VolumeTracker, SurfaceAreaTracker, VolumeFlexTracker,
       SurfaceAreaFlexTracker
export AbstractPenalty, AbstractNeuralPenalty, AbstractHSTPenalty, LocalNeuralPenalty,
       compute_global_energy, VolumePenalty, HSTVolumePenalty, HSTSurfaceAreaPenalty,
       AdhesionPenalty, FocalPointSpringPenalty, HSTFocalPointPenalty, HSTLengthPenalty,
       ChemotaxisPenalty, ConnectivityConstraint
export PottsTrainingCache, potts_loss
export AbstractOutputBackend, MemoryBackend, ZarrBackend, HDF5Backend, initialize_backend,
       save_state!
export DEFAULT_BLOCK_SIZE

# From Tools & Engine
export PottsComponent
function PottsComponent end
export spawn_hypersphere!, build_cell_data
export process_mitosis_events!, process_death_events!, MitosisCallback, DeathCallback, MitosisWorkspace
export VolumeThresholdTrigger, LinearGrowthCallback, required_fields
export DivisionOrientation, RandomOrientation, MajorAxisOrientation, MinorAxisOrientation,
       VectorOrientation
export InheritanceRule, Clone, Split
export Reset, ResetChild, AsymmetricReset, InheritAdd, InheritMultiply, RandomUniform,
       RandomNormal, RandomPoisson
export PropertyUpdateEvent

end
