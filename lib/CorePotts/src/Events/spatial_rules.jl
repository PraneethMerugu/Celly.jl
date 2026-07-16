# Spatial Rules & AST Traversal

abstract type AbstractSpatialRule <: AbstractRule end

struct ContactArea <: AbstractSpatialRule
    type_id::UInt8
    buffer_index::Int
end
ContactArea(type_id::Integer) = ContactArea(UInt8(type_id), 0)
ContactArea(type_id::Integer, idx::Integer) = ContactArea(UInt8(type_id), Int(idx))

struct NeighborCount <: AbstractSpatialRule
    type_id::UInt8
    buffer_index::Int
end
NeighborCount(type_id::Integer) = NeighborCount(UInt8(type_id), 0)
NeighborCount(type_id::Integer, idx::Integer) = NeighborCount(UInt8(type_id), Int(idx))

struct NeighborSum{Prop} <: AbstractSpatialRule
    type_id::UInt8
    buffer_index::Int
end
NeighborSum(prop::Symbol, type_id::Integer) = NeighborSum{prop}(UInt8(type_id), 0)
function NeighborSum(prop::Symbol, type_id::Integer, idx::Integer)
    NeighborSum{prop}(UInt8(type_id), Int(idx))
end



requires_edge_reduction(::AbstractSpatialRule) = true
requires_edge_reduction(::ContactArea) = false
