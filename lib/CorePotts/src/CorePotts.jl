module CorePotts

using KernelIntrinsics
using AcceleratedKernels
using KernelAbstractions
using StructArrays
using Adapt
using Random
using SciMLBase
import Atomix
import SciMLBase: solve

export solve, fmap

const DEFAULT_BLOCK_SIZE = 256

include("Base/topology.jl")
include("Base/samplers.jl")
include("Base/types.jl")
include("Base/dispatch.jl")

include("Base/trackers.jl")
include("Base/penalties.jl")
include("Base/training.jl")

include("Tools/initialization.jl")
include("Events/Events.jl")

include("engine.jl")
include("engine_intrinsics.jl")
include("simulator.jl")

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
