module System

export CellType, PottsSystem, AbstractComponent
export VolumeComponent, AdhesionComponent, HSTVolumeComponent, SurfaceAreaComponent,
       LengthComponent, ChemotaxisComponent
export required_variables

"""
    required_variables(obj)

Returns a NamedTuple of required variables (and their types) for a component or trigger.
Fallback returns `nothing` or empty NamedTuple.
"""
function required_variables end
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
end

function ChemotaxisComponent(pairs::Pair{CellType, <:Real}...; chemical_field::AbstractArray)
    dict = Dict{CellType, Float32}()
    for (ct, val) in pairs
        dict[ct] = Float32(val)
    end
    return ChemotaxisComponent(dict, chemical_field)
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
struct PottsSystem{E <: Tuple}
    cell_types::Vector{CellType}
    penalties::Vector{Any}
    events::E
    check_interval::Int

    function PottsSystem(cell_types::Vector{CellType}, penalties::Vector,
            events::E, check_interval::Int) where {E <: Tuple}
        new{E}(cell_types, Any[p for p in penalties], events, check_interval)
    end
end

function PottsSystem(args...; events = (), check_interval = 10, kwargs...)
    # Convert Vector of events to Tuple if user passes a Vector
    if events isa Vector
        events = Tuple(events)
    end

    types = CellType[]
    pens = Any[]
    for arg in args
        if arg isa CellType
            push!(types, arg)
        else
            push!(pens, arg)
        end
    end

    if haskey(kwargs, :cell_types)
        types = kwargs[:cell_types]
    end
    if haskey(kwargs, :penalties)
        pens = kwargs[:penalties]
    end

    if haskey(kwargs, :check_interval)
        check_interval = kwargs[:check_interval]
    end

    return PottsSystem(types, pens, events, check_interval)
end

function PottsSystem(types::Vector{CellType}, pens::Vector; events = (), check_interval = 10, kwargs...)
    if events isa Vector
        events = Tuple(events)
    end
    return PottsSystem(types, pens, events, check_interval)
end

end
