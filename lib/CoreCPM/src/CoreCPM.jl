module CoreCPM

using AcceleratedKernels
using KernelAbstractions
using StructArrays
using Adapt
using Random
using Test
using SciMLBase
import SciMLBase: solve

export solve

# ==============================================================================
# 1. BASE SUBMODULE
# Defines all core types, abstractions, interfaces, macros, trackers, etc.
# ==============================================================================
module CoreCPMBase
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

    # Export internal APIs that the Engine and Tools will need to function
    export AbstractTopology, VonNeumannTopology, MooreTopology, NoFluxVonNeumannTopology, NoFluxMooreTopology, ExtendedVonNeumannTopology, ExtendedMooreTopology, NoFluxExtendedVonNeumannTopology, NoFluxExtendedMooreTopology
    export num_dirs, offsets, lottery_offsets, idx_to_coord, coord_to_idx, get_neighbor_by_dir, get_neighbor_by_coord, get_val, is_noflux, checkerboard_colors, checkerboard_color
    export AbstractSampler, MetropolisSampler, evaluate_acceptance
    export pcg_hash
    export AbstractCPMProblem, AbstractCPMAlgorithm, CPMProblem, ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis, SparseLotteryMetropolis, CPMIntegrator, CPMSolution, CPMState, CPMParameters, CPMCache
    export AbstractCPMState
    export AbstractTracker, VolumeTracker, SurfaceAreaTracker, get_tracker_delta, evaluate_all_trackers, tx_delta_type, compute_tx_deltas, commit_direct!, initialize_metrics!, initialize_all_metrics!, update_local_all_metrics!, apply_tx_deltas_direct!
    export AbstractPenalty, AbstractNeuralPenalty, LocalNeuralPenalty, compute_global_energy, VolumePenalty, HSTVolumePenalty, HSTSurfaceAreaPenalty, AdhesionPenalty, FocalPointSpringPenalty, HSTFocalPointPenalty, HSTLengthPenalty, ChemotaxisPenalty, evaluate_all_penalties, evaluate_penalty, update_step_auxiliary!, update_sweep_auxiliary!, initialize_com_anchors!
    export CPMTrainingCache, cpm_loss
    export AbstractOutputBackend, MemoryBackend, ZarrBackend, HDF5Backend, initialize_backend, save_state!
    export DEFAULT_BLOCK_SIZE
end

# ==============================================================================
# 2. TOOLS SUBMODULE
# Utilities for initialization, spatial manipulation, and biological events.
# ==============================================================================
module CoreCPMTools
    using ..CoreCPMBase # Depend explicitly on the Base submodule
    
    using StructArrays
    using Random
    import Atomix
    import AcceleratedKernels

    include("Tools/initialization.jl")
    include("Tools/events.jl")

    # Export Tools API
    export build_cell_data, spawn_hypersphere!, sync_cell_data!
    export process_mitosis_events!, process_death_events!, recalculate_all_metrics!, MitosisWorkspace, MitosisCallback, DeathCallback
    export reset_hst_pressures_after_division!, reset_hst_tensions_after_division!
    export VolumeThresholdTrigger, LinearGrowthCallback, required_fields
    export DivisionOrientation, RandomOrientation, MajorAxisOrientation, MinorAxisOrientation, VectorOrientation
    export InheritanceRule, Clone, Split
end

# ==============================================================================
# 3. MAIN ENGINE & ORCHESTRATOR
# ==============================================================================
# Bring the submodules into the main namespace. 
# This automatically brings all the exports from Base and Tools into scope for the Engine.
using .CoreCPMBase
using .CoreCPMTools

import Atomix

include("engine.jl")
include("simulator.jl")

# ==============================================================================
# 4. UNIFIED USER API RE-EXPORTS
# Re-exporting from Base and Tools so the end-user experience remains identical.
# (Notice how we intentionally DO NOT export `coord_to_idx`, `Transaction`, etc. 
#  so the user's namespace stays clean!)
# ==============================================================================

# From Base
export AbstractTopology, VonNeumannTopology, MooreTopology, NoFluxVonNeumannTopology, NoFluxMooreTopology, ExtendedVonNeumannTopology, ExtendedMooreTopology, NoFluxExtendedVonNeumannTopology, NoFluxExtendedMooreTopology
export AbstractSampler, MetropolisSampler, evaluate_acceptance
export AbstractPenalty, AbstractNeuralPenalty, LocalNeuralPenalty, compute_global_energy, VolumePenalty, HSTVolumePenalty, HSTSurfaceAreaPenalty, AdhesionPenalty, FocalPointSpringPenalty, HSTFocalPointPenalty, HSTLengthPenalty, ChemotaxisPenalty, evaluate_all_penalties, evaluate_penalty
export CPMTrainingCache, cpm_loss
export AbstractTracker, VolumeTracker, SurfaceAreaTracker
export AbstractCPMProblem, AbstractCPMAlgorithm, CPMProblem, ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis, SparseLotteryMetropolis
export CPMState, CPMParameters, CPMCache
export CPMIntegrator, CPMSolution
export AbstractOutputBackend, MemoryBackend, ZarrBackend, HDF5Backend

# From Tools & Engine
export execute_step!, spawn_hypersphere!, sync_cell_data!, build_cell_data
export process_mitosis_events!, process_death_events!, MitosisCallback, DeathCallback
export reset_hst_pressures_after_division!, reset_hst_tensions_after_division!
export VolumeThresholdTrigger, LinearGrowthCallback, required_fields
export DivisionOrientation, RandomOrientation, MajorAxisOrientation, MinorAxisOrientation, VectorOrientation
export InheritanceRule, Clone, Split

end
