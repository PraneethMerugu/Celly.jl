module CorePotts

using AcceleratedKernels
using KernelAbstractions
using StructArrays
using Adapt
using Random
using Test
using SciMLBase
import SciMLBase: solve

export solve, fmap

const DEFAULT_BLOCK_SIZE = 256

using StructArrays
using Adapt
using SciMLBase
using AcceleratedKernels
using KernelAbstractions
import Atomix

include("Base/topology.jl")
include("Base/samplers.jl")
include("Base/types.jl")

include("Base/trackers.jl")
include("Base/penalties.jl")
include("Base/training.jl")

include("Tools/initialization.jl")
include("Tools/events.jl")

include("engine.jl")
include("simulator.jl")

# ==============================================================================
# UNIFIED USER API EXPORTS
# ==============================================================================

# From Base
export AbstractTopology, VonNeumannTopology, MooreTopology, NoFluxVonNeumannTopology,
       NoFluxMooreTopology, ExtendedVonNeumannTopology, ExtendedMooreTopology,
       NoFluxExtendedVonNeumannTopology, NoFluxExtendedMooreTopology
export num_dirs, offsets, lottery_offsets, idx_to_coord, coord_to_idx, get_neighbor_by_dir,
       get_neighbor_by_coord, get_val, is_noflux, checkerboard_colors, checkerboard_color
export AbstractSampler, MetropolisSampler, evaluate_acceptance
export pcg_hash
export AbstractPottsProblem, AbstractPottsAlgorithm, PottsProblem, ParallelMetropolis,
       CheckerboardMetropolis, SequentialMetropolis, SparseLotteryMetropolis,
       PottsIntegrator,
       PottsSolution, PottsState, PottsParameters, PottsCache
export AbstractPottsState, FlexibilityTrait, Rigid, Flex
export AbstractTracker, VolumeTracker, SurfaceAreaTracker, VolumeFlexTracker,
       SurfaceAreaFlexTracker, LengthFlexTracker, AdhesionFlexTracker, get_tracker_delta,
       evaluate_all_trackers, tx_delta_type, compute_tx_deltas, commit_direct!,
       initialize_metrics!, initialize_all_metrics!, update_local_all_metrics!,
       apply_tx_deltas_direct!
export AbstractPenalty, AbstractNeuralPenalty, AbstractHSTPenalty, LocalNeuralPenalty,
       compute_global_energy, VolumePenalty, HSTVolumePenalty, HSTSurfaceAreaPenalty,
       AdhesionPenalty, FocalPointSpringPenalty, HSTFocalPointPenalty, HSTLengthPenalty,
       ChemotaxisPenalty, ConnectivityConstraint, evaluate_all_penalties, evaluate_penalty,
       update_step_auxiliary!,
       update_sweep_auxiliary!, initialize_com_anchors!
export lambda_field, hst_state_field, hst_value_field, hst_target_field
export PottsTrainingCache, potts_loss
export AbstractOutputBackend, MemoryBackend, ZarrBackend, HDF5Backend, initialize_backend,
       save_state!
export DEFAULT_BLOCK_SIZE

# From Tools & Engine
export PottsComponent
function PottsComponent end
export execute_step!, spawn_hypersphere!, sync_cell_data!, build_cell_data
export process_mitosis_events!, process_death_events!, MitosisCallback, DeathCallback
export recalculate_all_metrics!, MitosisWorkspace
export reset_hst_fields_after_division!
export VolumeThresholdTrigger, LinearGrowthCallback, required_fields
export DivisionOrientation, RandomOrientation, MajorAxisOrientation, MinorAxisOrientation,
       VectorOrientation
export InheritanceRule, Clone, Split

end
