module System

export CellType, PottsSystem, AbstractComponent
export VolumeComponent, AdhesionComponent, HSTVolumeComponent, SurfaceAreaComponent,
       LengthComponent, ChemotaxisComponent
export required_variables
import CorePotts: required_variables, AbstractPenalty
using CorePotts: FlexibilityTrait, Rigid, Flex

"""
    CellType(name::Symbol; is_background::Bool=false)

Abstract representation of a cell's identity.
"""
struct CellType
    name::Symbol
    is_background::Bool
end

function CellType(name::Symbol; is_background::Bool = false)
    return CellType(name, is_background)
end

# To allow using CellTypes as Dict keys cleanly
Base.hash(c::CellType, h::UInt) = hash((c.name, c.is_background), h)
function Base.:(==)(a::CellType, b::CellType)
    a.name == b.name && a.is_background == b.is_background
end

abstract type AbstractComponent end

"""
    VolumeComponent(mappings::Pair{CellType, <:NamedTuple}...)

Maps a `CellType` to its `(target, λ)` volume parameters for a standard harmonic spring penalty.
"""
struct VolumeComponent{FlexType <: FlexibilityTrait} <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
end

function VolumeComponent(pairs::Pair{CellType, <:NamedTuple}...; flex::Bool = false)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target = Float32(vals.target), λ = Float32(vals.λ))
    end
    FlexType = flex ? Flex : Rigid
    return VolumeComponent{FlexType}(dict)
end

"""
    HSTVolumeComponent(mappings::Pair{CellType, <:NamedTuple}...; eta=1.0)

Maps a `CellType` to its hydrostatic `(target, λ)` volume parameters.
"""
struct HSTVolumeComponent{FlexType <: FlexibilityTrait} <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
    eta::Float32
end

function HSTVolumeComponent(pairs::Pair{CellType, <:NamedTuple}...; eta = 1.0, flex::Bool = false)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target = Float32(vals.target), λ = Float32(vals.λ))
    end
    FlexType = flex ? Flex : Rigid
    return HSTVolumeComponent{FlexType}(dict, Float32(eta))
end

"""
    SurfaceAreaComponent(mappings::Pair{CellType, <:NamedTuple}...; eta=1.0)

Maps a `CellType` to its `(target, λ)` surface area parameters (hydrostatic formulation).
"""
struct SurfaceAreaComponent{FlexType <: FlexibilityTrait} <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
    eta::Float32
end

function SurfaceAreaComponent(pairs::Pair{CellType, <:NamedTuple}...; eta = 1.0, flex::Bool = false)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target = Float32(vals.target), λ = Float32(vals.λ))
    end
    FlexType = flex ? Flex : Rigid
    return SurfaceAreaComponent{FlexType}(dict, Float32(eta))
end

"""
    LengthComponent(mappings::Pair{CellType, <:NamedTuple}...; eta=1.0)

Maps a `CellType` to its hydrostatic `(target, λ)` major-axis length parameters for cell elongation.
"""
struct LengthComponent{FlexType <: FlexibilityTrait} <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
    eta::Float32
end

function LengthComponent(pairs::Pair{CellType, <:NamedTuple}...; eta = 1.0, flex::Bool = false)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target = Float32(vals.target), λ = Float32(vals.λ))
    end
    FlexType = flex ? Flex : Rigid
    return LengthComponent{FlexType}(dict, Float32(eta))
end

"""
    ChemotaxisComponent(mappings::Pair{CellType, <:Real}...; chemical_field)

Maps a `CellType` to its chemotactic sensitivity `λ` across a given `chemical_field`.
"""
struct ChemotaxisComponent{ArrayT <: AbstractArray} <: AbstractComponent
    mappings::Dict{CellType, Float32}
    chemical_field::ArrayT
    saturation::Float32
end

function ChemotaxisComponent(pairs::Pair{CellType, <:Real}...; chemical_field::AbstractArray, saturation = 0.0f0)
    dict = Dict{CellType, Float32}()
    for (ct, val) in pairs
        dict[ct] = Float32(val)
    end
    return ChemotaxisComponent(dict, chemical_field, Float32(saturation))
end

"""
    AdhesionComponent(mappings::Pair{Tuple{CellType, CellType}, Float32}...)

Maps a pair of `CellType`s to their adhesion penalty (J-value).
"""
struct AdhesionComponent{FlexType <: FlexibilityTrait, Isotropic} <: AbstractComponent
    mappings::Dict{Tuple{CellType, CellType}, Float32}
end

function AdhesionComponent(pairs::Pair{Tuple{CellType, CellType}, <:Real}...;
        flex::Bool = false, isotropic::Bool = false)
    dict = Dict{Tuple{CellType, CellType}, Float32}()
    for (types, val) in pairs
        # Adhesion is symmetric, store canonical ordering
        t1, t2 = types
        canonical_key = hash(t1) < hash(t2) ? (t1, t2) : (t2, t1)
        dict[canonical_key] = Float32(val)
    end
    FlexType = flex ? Flex : Rigid
    return AdhesionComponent{FlexType, isotropic}(dict)
end

"""
    PottsSystem(; cell_types::Vector{CellType}, penalties::Vector{Any})
    PottsSystem(args...)

Collects the abstract logical rules and components defining a Cellular Potts Model.
The varargs constructor separates `CellType` instances from penalty components automatically.
"""
struct PottsSystem{P <: Tuple, E <: Tuple}
    cell_types::Vector{CellType}
    penalties::P
    events::E
    check_interval::Int

    function PottsSystem(cell_types::Vector{CellType}, penalties::P,
            events::E, check_interval::Int) where {P <: Tuple, E <: Tuple}
        new{P, E}(cell_types, penalties, events, check_interval)
    end
end

@inline _extract_components() = ()
@inline _extract_components(x::Union{AbstractComponent, AbstractPenalty}, rest...) = (x, _extract_components(rest...)...)
@inline _extract_components(x, rest...) = _extract_components(rest...)

function PottsSystem(args...; 
        cell_types = nothing, 
        penalties = nothing, 
        events = (), 
        check_interval = 10)
    
    events_tuple = events isa Vector ? Tuple(events) : events

    # If the user passed exact positional vectors (Legacy Method 3):
    if length(args) == 2 && args[1] isa Vector{CellType} && args[2] isa Union{Vector, Tuple}
        types = args[1]
        pens = Tuple(args[2])
    else
        types = CellType[arg for arg in args if arg isa CellType]
        pens = _extract_components(args...)
        
        for arg in args
            if !(arg isa CellType || arg isa AbstractComponent || arg isa AbstractPenalty)
                throw(ArgumentError("Invalid argument passed to PottsSystem: $(typeof(arg)). Expected CellType, AbstractComponent, or AbstractPenalty."))
            end
        end
    end

    # Override with kwargs if provided
    final_types = isnothing(cell_types) ? types : cell_types
    final_pens = isnothing(penalties) ? pens : Tuple(penalties)

    return PottsSystem(Vector{CellType}(final_types), final_pens, events_tuple, check_interval)
end

end
