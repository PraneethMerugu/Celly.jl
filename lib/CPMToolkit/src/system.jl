module System

export CellType, CPMSystem, AbstractComponent
export VolumeComponent, AdhesionComponent, HSTVolumeComponent, SurfaceAreaComponent, LengthComponent, ChemotaxisComponent

"""
    CellType(name::Symbol)

Abstract representation of a cell's identity.
"""
struct CellType
    name::Symbol
end

# To allow using CellTypes as Dict keys cleanly
Base.hash(c::CellType, h::UInt) = hash(c.name, h)
Base.:(==)(a::CellType, b::CellType) = a.name == b.name

abstract type AbstractComponent end

"""
    VolumeComponent(mappings::Pair{CellType, <:NamedTuple}...)

Maps a `CellType` to its `(target, λ)` volume parameters for a standard harmonic spring penalty.
"""
struct VolumeComponent <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
end

function VolumeComponent(pairs::Pair{CellType, <:NamedTuple}...)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target=Float32(vals.target), λ=Float32(vals.λ))
    end
    return VolumeComponent(dict)
end

"""
    HSTVolumeComponent(mappings::Pair{CellType, <:NamedTuple}...; eta=1.0)

Maps a `CellType` to its hydrostatic `(target, λ)` volume parameters.
"""
struct HSTVolumeComponent <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
    eta::Float32
end

function HSTVolumeComponent(pairs::Pair{CellType, <:NamedTuple}...; eta=1.0)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target=Float32(vals.target), λ=Float32(vals.λ))
    end
    return HSTVolumeComponent(dict, Float32(eta))
end

"""
    SurfaceAreaComponent(mappings::Pair{CellType, <:NamedTuple}...; eta=1.0)

Maps a `CellType` to its `(target, λ)` surface area parameters (hydrostatic formulation).
"""
struct SurfaceAreaComponent <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
    eta::Float32
end

function SurfaceAreaComponent(pairs::Pair{CellType, <:NamedTuple}...; eta=1.0)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target=Float32(vals.target), λ=Float32(vals.λ))
    end
    return SurfaceAreaComponent(dict, Float32(eta))
end

"""
    LengthComponent(mappings::Pair{CellType, <:NamedTuple}...; eta=1.0)

Maps a `CellType` to its hydrostatic `(target, λ)` major-axis length parameters for cell elongation.
"""
struct LengthComponent <: AbstractComponent
    mappings::Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}
    eta::Float32
end

function LengthComponent(pairs::Pair{CellType, <:NamedTuple}...; eta=1.0)
    dict = Dict{CellType, NamedTuple{(:target, :λ), Tuple{Float32, Float32}}}()
    for (ct, vals) in pairs
        dict[ct] = (target=Float32(vals.target), λ=Float32(vals.λ))
    end
    return LengthComponent(dict, Float32(eta))
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
struct AdhesionComponent <: AbstractComponent
    mappings::Dict{Tuple{CellType, CellType}, Float32}
end

function AdhesionComponent(pairs::Pair{Tuple{CellType, CellType}, <:Real}...)
    dict = Dict{Tuple{CellType, CellType}, Float32}()
    for (types, val) in pairs
        # Adhesion is symmetric, store canonical ordering
        t1, t2 = types
        # sort by name string to ensure canonical key
        canonical_key = string(t1.name) < string(t2.name) ? (t1, t2) : (t2, t1)
        dict[canonical_key] = Float32(val)
    end
    return AdhesionComponent(dict)
end

"""
    CPMSystem(; cell_types::Vector{CellType}, penalties::Vector{Any})

Collects the abstract logical rules and components defining a Cellular Potts Model.
"""
Base.@kwdef struct CPMSystem
    cell_types::Vector{CellType}
    penalties::Vector{Any}
end

end
