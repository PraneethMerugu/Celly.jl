module Layouts

using CorePotts
using Random
using ..System: CellType

export AbstractLayout, RandomLayout, HypersphereLayout, RectangleLayout, CompositeLayout
export LayoutContext, build_layout!

abstract type AbstractLayout end

mutable struct LayoutContext{N}
    grid::Array{Int32, N}
    cell_type_map::Dict{Int32, UInt8}
    next_cell_id::Int32
    type_to_id::Dict{CellType, UInt8}
end

function LayoutContext(grid_size::Tuple, type_to_id::Dict{CellType, UInt8})
    return LayoutContext(
        zeros(Int32, grid_size...),
        Dict{Int32, UInt8}(0 => 0), # Background is cell ID 0, type ID 0
        Int32(1),
        type_to_id
    )
end

"""
    build_layout!(layout::AbstractLayout, ctx::LayoutContext)

Modifies `ctx.grid` and registers cell types in `ctx.cell_type_map`.
"""
function build_layout! end

# ==============================================================================
# RandomLayout
# ==============================================================================
struct RandomLayout <: AbstractLayout
    counts::Dict{CellType, Int}
end

function build_layout!(layout::RandomLayout, ctx::LayoutContext)
    # Find all currently empty spaces (ID == 0)
    empty_indices = findall(==(0), ctx.grid)
    shuffle!(empty_indices)
    
    idx_counter = 1
    for (ct, count) in layout.counts
        if ct.is_background
            continue # Background is already 0
        end
        type_id = ctx.type_to_id[ct]
        for _ in 1:count
            if idx_counter > length(empty_indices)
                error("Grid is too small to fit the requested RandomLayout cells.")
            end
            linear_idx = empty_indices[idx_counter]
            idx_counter += 1
            
            cell_id = ctx.next_cell_id
            ctx.next_cell_id += 1
            
            ctx.grid[linear_idx] = cell_id
            ctx.cell_type_map[cell_id] = type_id
        end
    end
end

# ==============================================================================
# HypersphereLayout
# ==============================================================================
struct HypersphereLayout{N} <: AbstractLayout
    cell_type::CellType
    center::NTuple{N, Int}
    radius::Int
end

function build_layout!(layout::HypersphereLayout{N}, ctx::LayoutContext{N}) where N
    type_id = ctx.type_to_id[layout.cell_type]
    cell_id = ctx.next_cell_id
    ctx.next_cell_id += 1
    
    CorePotts.spawn_hypersphere!(ctx.grid, size(ctx.grid), layout.center, layout.radius, UInt32(cell_id))
    ctx.cell_type_map[cell_id] = type_id
end

# ==============================================================================
# RectangleLayout
# ==============================================================================
struct RectangleLayout{N} <: AbstractLayout
    cell_type::CellType
    top_left::NTuple{N, Int}
    bottom_right::NTuple{N, Int}
end

function build_layout!(layout::RectangleLayout{N}, ctx::LayoutContext{N}) where N
    type_id = ctx.type_to_id[layout.cell_type]
    cell_id = ctx.next_cell_id
    ctx.next_cell_id += 1
    
    ranges = ntuple(i -> layout.top_left[i]:layout.bottom_right[i], N)
    
    # Safely clamp ranges to grid boundaries
    safe_ranges = ntuple(i -> max(1, ranges[i][1]):min(size(ctx.grid, i), ranges[i][end]), N)
    
    ctx.grid[safe_ranges...] .= cell_id
    ctx.cell_type_map[cell_id] = type_id
end

# ==============================================================================
# CompositeLayout
# ==============================================================================
struct CompositeLayout <: AbstractLayout
    layouts::Vector{AbstractLayout}
end

function CompositeLayout(layouts::AbstractLayout...)
    return CompositeLayout(collect(layouts))
end

function build_layout!(layout::CompositeLayout, ctx::LayoutContext)
    for l in layout.layouts
        build_layout!(l, ctx)
    end
end

end # module
