import Adapt
import Functors
import ConstructionBase

abstract type AbstractPenalty{Trait <: FlexibilityTrait} end
abstract type AbstractNeuralPenalty{Trait} <: AbstractPenalty{Trait} end
abstract type AbstractHSTPenalty{Trait} <: AbstractPenalty{Trait} end

# Holy Trait interfaces for extensible parameters and fields
lambda_field(::AbstractPenalty) = error("Not implemented")
hst_state_field(::AbstractHSTPenalty) = error("Not implemented")
hst_value_field(::AbstractHSTPenalty) = error("Not implemented")
hst_target_field(::AbstractHSTPenalty) = error("Not implemented")

# Universal get_lambda for generic parameter scaling
@inline function get_lambda(p::AbstractPenalty{Rigid}, ctx, cell_id)
    c_type = ctx.cell_data.cell_types[cell_id]
    return eltype(p.lambdas)(p.lambdas[c_type + 1])
end

@inline function get_lambda(p::AbstractPenalty{Flex}, ctx, cell_id)
    return _get_flex_lambda(lambda_field(p), ctx.cell_data, cell_id)
end

@inline _get_flex_lambda(::Val{F}, cell_data, cell_id) where {F} = getproperty(cell_data, F)[cell_id]

function Functors.functor(::Type{<:AbstractPenalty}, x)
    props = propertynames(x)
    children = NamedTuple{props}(getproperty.(Ref(x), props))
    reconstruct(children) = ConstructionBase.constructorof(typeof(x))(values(children)...)
    return children, reconstruct
end

function Adapt.adapt_structure(to, x::AbstractPenalty)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

@inline evaluate_all_penalties(::Tuple{}, ctx) = 0.0f0
@inline evaluate_all_penalties(penalties::Tuple, ctx) = evaluate_penalty(penalties[1], ctx) +
                                                        evaluate_all_penalties(Base.tail(penalties), ctx)

# Global Energy evaluation interface for EBM training
compute_global_energy(::Tuple{}, u, params) = 0.0f0
function compute_global_energy(penalties::Tuple, u, params)
    compute_global_energy(penalties[1], u, params) +
    compute_global_energy(Base.tail(penalties), u, params)
end

# Phase 2 Global Update Hook (Fallback does nothing)
@inline update_step_auxiliary!(item::Any, u::AbstractPottsState, p::PottsParameters,
    cache::PottsCache, T, dt = 1.0) = nothing
@inline update_sweep_auxiliary!(item::Any, u::AbstractPottsState, p::PottsParameters,
    cache::PottsCache, T, dt = 1.0) = nothing

include("penalties/neural.jl")
include("penalties/volume.jl")
include("penalties/surface_area.jl")
include("penalties/focal_point.jl")
include("penalties/adhesion.jl")
include("penalties/length.jl")
include("penalties/chemotaxis.jl")
include("penalties/connectivity.jl")
