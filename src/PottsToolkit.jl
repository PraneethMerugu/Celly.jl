module PottsToolkit

using Reexport

@reexport using CorePotts
using CorePotts: AbstractSampler, MetropolisSampler, PottsState, PottsParameters,
                 PottsCache, ParallelMetropolis, CheckerboardMetropolis,
                 SequentialMetropolis, IntrinsicCheckerboardMetropolis

include("models.jl")
include("domains.jl")
include("rules/events.jl")
include("problems.jl")
include("models/test_problems.jl")
include("rules/macros.jl")

# Phase 10 replacement authoring foundation. It remains namespaced until the qualified vertical
# slice passes and the frozen historical surface is deleted in one migration gate.
include("authoring/Authoring.jl")

using .System
using .Layouts
using .Events
using .Problem
using .TestProblems
using .RuleMacros

export CellType, PottsSystem, AbstractComponent
export VolumeComponent, AdhesionComponent, HSTVolumeComponent, SurfaceAreaComponent,
       LengthComponent, ChemotaxisComponent
export AbstractLayout, RandomLayout, HypersphereLayout, ScatterSpheresLayout, RectangleLayout, CompositeLayout
export PottsProblem, compile_component, reference_integrator
export PottsToolkitEvent, AbstractTrigger, AbstractAction, VolumeRatioTrigger, AgeTrigger,
       ProbabilityTrigger, CustomTrigger
export MitosisEvent, ApoptosisEvent, TransitionEvent
export TestProblems
export @rule

# Temporary Phase 7 compatibility surface. CorePotts no longer exports these historical engine
# names; Phase 10 removes this explicit Toolkit bridge when the typed compiler and DSL migrate.
export AbstractSampler, MetropolisSampler, PottsState, PottsParameters, PottsCache,
       ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis,
       IntrinsicCheckerboardMetropolis

end
