module PottsToolkit

using Reexport

@reexport using CorePotts

include("system.jl")
include("problem.jl")
include("TestProblems.jl")

using .System
using .Problem
using .TestProblems

export CellType, PottsSystem, AbstractComponent
export VolumeComponent, AdhesionComponent, HSTVolumeComponent, SurfaceAreaComponent,
       LengthComponent, ChemotaxisComponent
export PottsProblem, compile_component
export TestProblems

end
