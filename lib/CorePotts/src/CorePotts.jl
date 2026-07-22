module CorePotts

using KernelIntrinsics
using AcceleratedKernels
using KernelAbstractions
using StructArrays
using StaticArrays
using Adapt
using ConstructionBase
using Random
using Serialization
using SciMLBase
using LinearAlgebra: issymmetric, eigen, Symmetric
using SHA
import Atomix
import SciMLBase: solve, savevalues!

export solve, savevalues!, fmap

const DEFAULT_BLOCK_SIZE = 256

include("topology/topology.jl")
include("proposals/samplers.jl")
include("state/semantics.jl")
include("state/types.jl")
include("state/logical.jl")
include("spatial/cartesian.jl")
include("state/lifecycle.jl")
include("lifecycle/scientific.jl")
include("execution/dispatch.jl")
include("rng/semantic.jl")
include("execution/contracts.jl")

include("components/trackers/trackers.jl")
include("components/components.jl")
include("components/training.jl")
include("protocols/scientific.jl")
include("components/scientific_components.jl")
include("lifecycle/reference.jl")
include("components/scientific_trackers.jl")
include("components/scientific_fields.jl")
include("components/scientific_queries.jl")
include("components/scientific_focal_points.jl")
include("components/scientific_elongation.jl")
include("components/scientific_inner_loop.jl")
include("components/scientific_mechanics.jl")
include("lifecycle/compiled.jl")
include("algorithms/sequential.jl")
include("algorithms/checkerboard.jl")
include("algorithms/tiled_checkerboard.jl")
include("algorithms/tiled_checkerboard_device.jl")
include("algorithms/lottery.jl")
include("persistence/scientific.jl")
include("reference/engine.jl")

include("initialization/initialization.jl")
include("initialization/logical.jl")
include("lifecycle/events.jl")

include("kernels/metropolis.jl")
include("kernels/intrinsics.jl")
include("sciml/simulator.jl")
include("sciml/interface.jl")

# ==============================================================================
# UNIFIED USER API EXPORTS
# ==============================================================================

# From Base
export AbstractTopology, VonNeumannTopology, MooreTopology, NoFluxVonNeumannTopology,
       NoFluxMooreTopology, ExtendedVonNeumannTopology, ExtendedMooreTopology,
       NoFluxExtendedVonNeumannTopology, NoFluxExtendedMooreTopology
export AbstractBoundaryCondition, PeriodicBoundary, ClosedBoundary, FixedExterior,
       AxisBoundary, CartesianDomain, CartesianDomainDescriptor,
       CompiledCartesianDomainStorage,
       CompiledCartesianDomain, compile_domain, mutable_site_count, immutable_owner,
       AbstractSpatialRole, ProposalRole, ContactRole, SurfaceRole, ConnectivityRole,
       SpatialQueryRole, FieldDiscretizationRole, ConflictRole,
       RelationCanonicalizationVersion, StaticCartesianRelation,
       static_relation, first_shell_relation, direction_count, relation_offset,
       relation_weight, normalized_kernel_relation,
       opposite_direction, canonicalization_version, NeighborKind, MutableNeighbor,
       FixedNeighbor,
       ExteriorNeighbor, AbsentNeighbor, InvalidNeighbor, RealizedNeighbor,
       realize_neighbor, fixed_owner,
       validate_relation_domain, domain_storage_valid, domain_semantics_report,
       relation_semantics_report
export AbstractPottsProblem, AbstractPottsAlgorithm, PottsModel, PottsProblem,
       PottsIntegrator, PottsSolution
export default_parameters, realize_components, proposal_relation, boundary_tracker,
       moment_tracker, lifecycle_events, lifecycle_resolver, observable_symbols,
       AbstractInitialStateOwnership, CopyInitialState, AliasInitialState, DeviceInitialState,
       AbstractReproducibilityProfile, StrictReproducibility, StatisticalReproducibility,
       AbstractPottsExecutionPolicy, DefaultPottsExecution,
       AbstractSnapshotPolicy, BackendSnapshotPolicy, HostSnapshotPolicy,
       ObservableSnapshotPolicy, SavedPottsState, PottsStats,
       AbstractPottsDeviceCallback, AbstractPottsDeviceCallbackEffect,
       DeviceObservationEffect, device_callback_requirements,
       device_callback_effects, device_callback_priority, device_callback_due,
       execute_device_callback!, validate_device_callback,
       PottsParameterHandle, PottsObservableHandle, parameter_name, observable_name,
       PottsCompilationCache, PottsCompatibilityReport, PottsCompilationReport,
       compatibility_report, compilation_report, set_parameter!,
       InvalidPottsProblemError, UnsupportedSolverOptionError,
       IntegratorTerminatedError, UnsavedTimeError, UnsavedObservableError,
       PottsCallbackConflictError, UnsafePottsSerializationError,
       execution_adaptor, AbstractEnsembleSeedPolicy, EnsembleSeedDerivationV1,
       UserManagedEnsembleSeeds, ensemble_seed
export AbstractPottsState, FlexibilityTrait, Rigid, Flex
export lattice_storage
export AbstractEvent
export AbstractScientificID, CellID, CellTypeID, MediumID, CellSlot, CellGeneration,
       CellCapacity,
       value, nslots, NumericalPolicy, real_type, accumulation_type,
       portable_numerical_policy,
       AbstractMathMode, AccurateMath, QualifiedFastMath,
       AbstractReductionMode, DeterministicReductions, TolerantReductions,
       AbstractOverflowMode, CheckedModelBounds, QualifiedUncheckedBounds,
       PropertyKind, BiologicalProperty, DerivedProperty, AuxiliaryProperty,
       TransientProperty,
       PropertyMutability, ReadOnlyProperty, MutableProperty,
       AbstractDivisionPolicy, CloneOnDivision, SplitOnDivision, ResetChildOnDivision,
       ResetBothOnDivision, AsymmetricResetOnDivision, UnsupportedDivision,
       AbstractMechanicalDivisionPolicy, ConstitutiveResetAfterDivision,
       PreserveMechanicalOnDivision, StationaryRedrawAfterDivision,
       AbstractTransitionPolicy, PreserveOnTransition, ResetOnTransition,
       RecomputeOnTransition, UnsupportedTransition,
       AbstractRetirementPolicy, ResetOnRetirement,
       DivisionPropertyContext, DivisionPropertyUpdate, TransitionPropertyContext,
       division_property_update, transition_property_value, retired_property_value,
       ComponentIdentity, ConstantInitializer, AbstractPropertyDescriptor,
       PropertyDescriptor,
       PropertySchema, PropertySchemaConflictError, property_keys, property_descriptor,
       property_requesters, value_type, merge_property_schemas
export OwnerRef, CellOwner, MediumOwner, is_cell_owner, is_medium_owner, cell_id, medium_id,
       PropertyStore, property_values, OccupancyDerivedState, LogicalPottsState,
       CompiledOwnership, compile_ownership,
       LogicalStateInvariantError, capacity, n_cells, active_cell_ids, reusable_cell_slots,
       medium_ids, generation, is_active, cell_type, owner_at, lattice_size, derived_state,
       finite_volume, medium_occupancy, state_invariant_errors, assert_valid_state,
       rebuild_derived_state!, property_value, set_cell_property!
export DivisionRequest, LogicalDivisionResult, LogicalRetirementResult,
       apply_division_batch,
       retire_zero_volume, release_retired_slots, immediately_remove_cell,
       transition_cell_type
export AbstractMCSSchedule, EveryMCS, OnceAtMCS, AtMCS, PeriodicMCS, is_due,
       AbstractLifecycleTarget, ActiveCellsTarget, GlobalModelTarget,
       PreLifecycleSnapshot, AbstractLifecycleTrigger, AbstractLifecycleEffect,
       CellTypeIn, AllLifecycleTriggers,
       lifecycle_triggered, plan_lifecycle_effect, LifecycleEvent,
       LifecycleConflictClaim, AbstractLifecycleConflictResolver,
       RejectLifecycleConflicts, StableLifecyclePriority, LifecycleConflictError,
       resolve_lifecycle_conflicts,
       AbstractDivisionGeometry, DivisionSiteContext, division_region,
       BinaryPartitionReport, validate_binary_partition
export LifecycleRNGContext, AlwaysLifecycleTrigger, PropertyAtLeast,
       BernoulliCellTrigger,
       AbstractLifecyclePlan, AbstractPropertyLifecyclePlan,
       AbstractTransitionLifecyclePlan, AbstractDivisionLifecyclePlan,
       AbstractDeathLifecyclePlan,
       AddCellProperty, TransitionCell, DivideCell, InitiateShrinkDeath,
       AbstractRemovalCause, ProgrammedImmediateDeath, StochasticExtinction,
       RemoveCellImmediately,
       AddCellPropertyPlan, TransitionCellPlan, DivideCellPlan, ShrinkDeathPlan,
       RemoveCellPlan,
       VectorDivision, RandomOrientationDivision, MajorAxisDivision, MinorAxisDivision,
       prepare_division_geometry, division_sites, identity_target,
       validate_lifecycle_plan, commit_property_plan!, repair_division_state!, LifecyclePhaseReport,
       apply_lifecycle_phase
export NoCompiledLifecycle, CompiledPropertyLifecycle, CompiledLifecycleDescriptor,
       CompiledLifecycleWorkspace, CompiledLifecycle, compile_lifecycle,
       compiled_lifecycle_bytes, run_compiled_lifecycle!,
       AbstractCompiledEffectCategory, CompiledPropertyEffect,
       CompiledStagedPropertyEffect, NoCompiledEffectWorkspace,
       CompiledStagedEffectWorkspace,
       CompiledTransitionEffect, CompiledDivisionEffect, CompiledDeathEffect,
       CompiledCustomEffect, compiled_effect_category, compiled_schedule_due,
       compiled_effect_workspace, compiled_effect_workspace_bytes,
       compiled_effect_stages, compiled_effect_stage_workspaces,
       compiled_prepare_effect_stage!, compiled_evaluate_effect_stage!,
       compiled_commit_effect_stage!,
       compiled_identity_change, compiled_is_division, compiled_effect_phase,
       compiled_target_applies, compiled_lifecycle_triggered,
       compiled_lifecycle_rng_address,
       compiled_prepare_division_geometry, compiled_division_region,
       compiled_division_property_update, compiled_transition_property_value,
       compiled_retired_property_value, compiled_apply_effect!,
       compiled_prepare_derived_division!, compiled_accumulate_derived_division!,
       compiled_retire_derived!,
       CompiledLifecycleError, current_lifecycle_report
export AbstractEnergy, AbstractDrive, AbstractHardConstraint, AbstractKineticModifier,
       AbstractMechanicalComponent,
       AbstractProposalLaw, NeighborCopyProposal, proposal_law,
       construct_proposal_attempt,
       ScientificCapabilities, AlgorithmGuaranteeProfile, CopyProposal,
       CopyAttemptOutcome, ActionableCopy, SameOwnerAttempt, BoundaryNullAttempt,
       ImmutableRecipientAttempt, CopyAttempt, is_actionable, actionable_proposal,
       construct_copy_attempt, proposal_probabilities, AbstractAcceptanceLaw,
       ConventionalMetropolis, MetropolisHastings, acceptance_law, AcceptanceInputs,
       acceptance_probability, acceptance_decision,
       ScientificInterfaceError, ScientificInterfaceReport, component_identity,
       required_properties, provided_properties, required_observables, required_relations,
       component_effects, component_rng_streams, component_semantic_data, component_metadata,
       capabilities, component_supports_dimension, component_supports_backend,
       algorithm_component_compatibility,
       UnsupportedScientificAccess, SnapshotScientificAccess, scientific_access,
       UnsupportedTiledScientificAccess, TiledReconciliationMode,
       ExactAdditiveTiledReconciliation, BoundedStateTiledReconciliation,
       TiledSnapshotAccess, tiled_scientific_access,
       energy_change, drive_log_bias, is_allowed, rebuild_tracker, event_effects,
       proposal_energy_change, proposal_drive_log_bias, proposal_constraint_allowed,
       proposal_modifier_contribution, proposal_mechanical_work, validate_proposal_component,
       LogicalCopyResult, commit_copy_proposal,
       algorithm_guarantees, topology_dimensions, validate_energy_component,
       validate_drive_component, validate_constraint_component, validate_tracker_component,
       validate_mechanical_component, validate_kinetic_modifier_component,
       validate_event_component, validate_algorithm_component, validate_topology_component,
       test_energy_component, test_tracker, test_event, test_algorithm, test_topology
export CellPropertyRef, property_key, MediumTypeTable, owner_type,
       QuadraticVolumeHamiltonian, UnorderedContactHamiltonian,
       AbstractBoundaryMetric, BoundaryEdgeCount, WeightedBoundaryCount,
       MagnoAxisCalibrationV1, NormalizedKernelMeasure,
       boundary_measure, boundary_measure_change, QuadraticBoundaryHamiltonian,
       global_energy, surface_semantics_report,
       MechanicalInitialization, ConstitutiveMeanInitialization,
       StationaryMechanicalInitialization, PreserveMechanicalInitialization,
       AlgorithmTemperatureNoise, FixedMechanicalNoise,
       FluctuatingVolumePressure, FluctuatingSurfaceTension, mechanical_work,
       mechanical_ou_transition
export OwnershipVolumeTracker, BoundaryMeasureTracker, NoMomentStorage, NoMomentDelta,
       compile_derived_observable, derived_observable_arrays,
       stage_derived_observable_delta, apply_derived_observable_delta!,
       ScientificTrackerStorage, ScientificExecutionState, scientific_execution,
       CompiledScientificState, compile_scientific_state, scientific_storage_valid,
       scientific_state_bytes, ScientificTrackerDelta, StagedCopyTransaction,
       stage_copy_transaction, commit_staged!, launch_staged_commit!,
       tracker_conformance_errors
export AbstractFieldBoundary, PeriodicFieldBoundary, ZeroNeumannFieldBoundary,
       DirichletFieldBoundary, AxisFieldBoundary, AbstractFieldInterpolation,
       NearestFieldInterpolation, MultilinearFieldInterpolation, CellCenteredField,
       sample_field,
       AbstractFieldResponse, LinearResponse, MichaelisMentenResponse,
       SaturationLinearResponse, field_response, OwnerScalarCoupling, owner_scalar,
       ExternalFieldOccupancyHamiltonian, AbstractChemotaxisMode, ExtensionChemotaxis,
       RetractionChemotaxis, ReciprocalChemotaxis, ChemotaxisDrive, PositiveYield,
       kinetic_barrier, field_semantics_report
export AbstractOwnerFilter, AnyFiniteCell, CellIdentityFilter, CellTypeFilter,
       MediumDomainFilter, AnyMediumDomain, contact_edge_count, contact_measure,
       boundary_site_count, global_interface_measure, neighbor_cells,
       compiled_cell_owner, owners_are_neighbors,
       DistinctNeighborWorkspace, neighbor_cells!, neighbor_cell_count,
       neighbor_property_sum, neighbor_property_mean, PreserveConnectedCells,
       ConnectivityWorkspace, validate_workspace
export UnwrappedMomentTracker, UnwrappedMomentStorage, UnwrappedMomentDelta,
       moment_is_tracked, unwrapped_center, unwrapped_covariance,
       FocalPointLink, FocalPointSpringHamiltonian,
       FixedFocalEndpointConstraint
export major_axis_rms_length, QuadraticElongationHamiltonian
export ScientificComponentSet, NoConnectivityWorkspace, ScientificProposalContext,
       ScientificCopyEvaluation, evaluate_copy, acceptance_inputs,
       scientific_components_report
export AbstractSequentialCPMAlgorithm, SequentialCPM, SequentialEquilibrium,
       CheckerboardSweepCPM, TiledCheckerboardCPM, TiledSharedMemoryMode,
       TiledSharedMemoryAuto, TiledSharedMemoryRequired, TiledSharedMemoryDisabled,
       TiledLayout, tiled_layout, tiled_color, tiled_tile_sites, tiled_color_order,
       tiled_rng_address, tiled_reference_energy_change, TiledReferenceIntegrator,
       init_tiled_reference, step_tiled_reference!, LotteryCPM,
       ScientificPottsIntegrator,
       ScientificMCSReport, init_scientific, initialize_scientific_algorithm,
       perform_scientific_mcs!, current_mcs_report
export ScientificAnalysisSnapshot, ExactContinuationProfile,
       CanonicalPropertyColumn, CanonicalCheckpoint,
       CheckpointIntegrityError, CheckpointCompatibilityError,
       IncompleteCheckpointError, LogicalImportReport,
       analysis_snapshot, capture_checkpoint, validate_checkpoint,
       checkpoint_logical_state, scientific_model_fingerprint,
       restore_checkpoint, import_checkpoint,
       AbstractCheckpointStore, MemoryCheckpointStore,
       HDF5CheckpointStore, ZarrCheckpointStore,
       write_checkpoint!, read_checkpoint,
       checkpoint_storage_payload, checkpoint_from_storage_payload
export ReferenceVolumeEnergy, ReferenceContactEnergy, ReferenceModel, SequentialReference,
       ReferenceIntegrator, ReferenceMCSReport, reference_energy, init_reference,
       step_reference!, reference_rng_version
export AbstractRNGContract, Philox4x32x10V1, RNGStream, RNGEntityKind, RNGAddress,
       RNGNamespaceIdentity, RNGNamespaceCollisionError, extension_rng_operation,
       extension_rng_seed, extension_rng_address, compile_rng_namespaces,
       LayoutPlacementStream, LayoutPermutationStream, ProposalRecipientStream,
       ProposalDirectionStream, AcceptanceStream, LotteryActivationStream,
       LotteryPriorityStream, CheckerboardOrderStream, AuxiliaryEvolutionStream, RuleStream,
       CheckerboardPriorityStream,
       AuxiliaryInitializationStream, TiledOrderStream, TiledProposalStream,
       EventStream, DivisionOrientationStream, PropertyInheritanceStream,
       StochasticRoundingStream, TypeTransitionStream, EnsembleStream,
       GlobalEntity, SiteEntity, CellEntity, EnsembleEntity,
       rng_contract_version, rng_counter_key, philox4x32_10, rng_words, rng_word,
       uniform_open01, bounded_uint, bernoulli, normal_box_muller,
       poisson_inversion, poisson_normal_approx, CategoricalTable, categorical_index,
       small_permutation!, distribution_profile
export BackendFamily, CPUFamily, CUDAFamily, AMDGPUFamily, MetalFamily,
       BackendContractStatus, QualifiedBackend, DeferredBackend, BackendCapabilities,
       AbstractBackendCapability, QualifiedBackendCapability,
       FunctionalBackendCapability, OrderedLaunchCapability,
       DeviceFloat64Capability, SubgroupIntrinsicCapability, SemanticRNGCapability,
       UnsupportedBackendCapability, UnsupportedBackendType, backend_capabilities,
       supports, require_capability, CompiledStateDescriptor, CompiledStateStorage,
       CompiledPottsState, compile_state, execution_storage, adapt_execution,
       device_storage_valid, logical_snapshot, WorkspaceRequirements, workspace_bytes,
       ExecutionWorkspace, allocate_workspace, TransactionRequirements,
       TransactionWorkspace,
       transaction_workspace_bytes, allocate_transaction_workspace,
       OrderedAsynchronousLaunches,
       ExplicitObservationSynchronization, ExecutionMetrics, ExecutionPlan, launch!,
       synchronize_observation!, record_transfer!, record_allocation!
export AbstractInitialOverlapPolicy, RejectInitialOverlap, StableInitialPriority,
       ProvisionalCellID, AbstractInitialLayout, InitialLayoutRequirements,
       initial_layout_requirements, emit_initial_claims!,
       InitialCellLayout, InitialMediumLayout, CoordinateCellLayout,
       InitialCellProperties,
       DenseCellLabels, AbstractLatticeShape, LatticeBall, LatticeBox,
       shape_extent, shape_contains, ShapeCellLayout,
       UniformSiteSeeds, SequentialRejectionPlacement, InitialPlacementError,
       ProvisionalCellDeclaration, InitialClaimCollector,
       declare_initial_cell!, emit_initial_cell_claim!, emit_initial_medium_claim!,
       InitialLayoutOverlapError,
       LogicalInitializationReport, InitializedLogicalState, logical_state,
       initialization_report,
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
export process_mitosis_events!, process_death_events!, MitosisCallback, DeathCallback,
       MitosisWorkspace
export VolumeThresholdTrigger, LinearGrowthCallback, required_fields
export DivisionOrientation, RandomOrientation, MajorAxisOrientation, MinorAxisOrientation,
       VectorOrientation
export InheritanceRule, Clone, Split
export Reset, ResetChild, AsymmetricReset, InheritAdd, InheritMultiply, RandomUniform,
       RandomNormal, RandomPoisson
export PropertyUpdateEvent

end
