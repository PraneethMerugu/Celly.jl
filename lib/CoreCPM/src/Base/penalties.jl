import Adapt

abstract type AbstractPenalty end
abstract type AbstractNeuralPenalty <: AbstractPenalty end

@inline evaluate_all_penalties(::Tuple{}, ctx) = 0.0
@inline evaluate_all_penalties(penalties::Tuple, ctx) = evaluate_penalty(penalties[1], ctx) + evaluate_all_penalties(Base.tail(penalties), ctx)

# Global Energy evaluation interface for EBM training
compute_global_energy(::Tuple{}, u, params) = 0.0
compute_global_energy(penalties::Tuple, u, params) = compute_global_energy(penalties[1], u, params) + compute_global_energy(Base.tail(penalties), u, params)

# Phase 2 Global Update Hook (Fallback does nothing)
@inline update_step_auxiliary!(item::Any, u::AbstractCPMState, p::CPMParameters, cache::CPMCache, T, dt=1.0) = nothing
@inline update_sweep_auxiliary!(item::Any, u::AbstractCPMState, p::CPMParameters, cache::CPMCache, T, dt=1.0) = nothing

include("penalties/neural.jl")
include("penalties/volume.jl")
include("penalties/surface_area.jl")
include("penalties/focal_point.jl")
include("penalties/adhesion.jl")
include("penalties/length.jl")
include("penalties/chemotaxis.jl")
