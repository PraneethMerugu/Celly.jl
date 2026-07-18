import AcceleratedKernels
import StructArrays

"""
    build_cell_data(grid, N_cells; custom_fields...)

Allocates and constructs a `StructArray` on the same backend as `grid` (CPU or GPU) 
to hold macroscopic cell properties like `:volumes`, `:target_volumes`, `:cell_types`, 
`:pressures`, etc. 
"""
@inline _extract_reqs(comp::Tuple) = merge(_extract_reqs(comp[1]), _extract_reqs(Base.tail(comp)))
@inline _extract_reqs(::Tuple{}) = (;)
@inline _extract_reqs(comp) = required_variables(comp)

function build_cell_data(grid::AbstractArray, N_cells::Int, components...; FloatType = Float32,
        IntType = Int32, custom_fields...)
    alloc_zero(T, sz) = fill!(similar(grid, T, sz), zero(T))

    base_fields = (
        volumes = alloc_zero(IntType, N_cells),
        target_volumes = alloc_zero(IntType, N_cells),
        cell_types = alloc_zero(UInt8, N_cells),
    )

    reqs = _extract_reqs(components)
    unique_reqs = Base.structdiff(reqs, base_fields)

    comp_fields = map(unique_reqs) do type_sym
        T = type_sym === Float32 ? FloatType : (type_sym === Int32 ? IntType : type_sym)
        alloc_zero(T, N_cells)
    end

    all_fields = merge(base_fields, comp_fields, (; custom_fields...))
    return StructArrays.StructArray(all_fields)
end


"""
    spawn_hypersphere!(grid, grid_dims, center, radius, cell_id)

Paints a spherical cluster of `cell_id` onto the `grid` centered at `center` with `radius`.
Works in both 2D and 3D.
"""
function spawn_hypersphere!(
        grid, grid_dims, center::NTuple{N, Int}, radius::Int, cell_id::UInt32) where {N}
    r2 = radius^2
    AcceleratedKernels.foreachindex(grid; block_size = DEFAULT_BLOCK_SIZE) do I
        coords = idx_to_coord(UInt32(I), grid_dims)
        dist_sq = 0
        for i in 1:N
            # coords are 0-indexed, center is 1-indexed
            dist_sq += (Int(coords[i]) + 1 - center[i])^2
        end

        # Overwrite space with the new cell
        if dist_sq <= r2
            grid[I] = cell_id
        end
    end
    return nothing
end

"""
    sync_cell_data!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache, num_cells::Int; set_targets::Bool=true)

Scans the grid and calculates the actual volumes and centroids for all cells from `1` to `num_cells`.
If `set_targets` is true, sets `target_volume` to match the initial volume.
"""
function sync_cell_data!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache,
        num_cells::Integer; set_targets::Bool = true)
    # 1. Use existing trackers to physically count the pixels currently on the grid
    grid = u.grid
    initialize_all_metrics!(p.trackers, u.cell_data, grid, p.topology, cache.grid_dims)

    # 2. Use reflection to safely sync target arrays if they exist in the StructArray
    if set_targets && num_cells > 0
        if hasproperty(u.cell_data, :target_volumes) && hasproperty(u.cell_data, :volumes)
            copyto!(u.cell_data.target_volumes, 1, u.cell_data.volumes, 1, num_cells)
        end
        if hasproperty(u.cell_data, :target_surface_areas) &&
           hasproperty(u.cell_data, :surface_areas)
            copyto!(u.cell_data.target_surface_areas, 1,
                u.cell_data.surface_areas, 1, num_cells)
        end
    end

    # Update global cell count
    u.N_cells[] = num_cells

    # 3. Initialize COM anchors if they exist
    if hasproperty(u.cell_data, :com_acc_sin_x)
        # Note: initialize_com_anchors! might need u, p, cache now.
        initialize_com_anchors!(u, p, cache)
    end

    return nothing
end

"""
    sync_cell_data!(grid, cell_data, num_cells)

A utility to manually count cell volumes from the `grid` and set them in `cell_data`.
Sets both `volumes` and `target_volumes` to the counted value.
"""
function sync_cell_data!(grid::AbstractArray{T, N}, cell_data::StructArray,
        num_cells::Integer; set_targets::Bool = true) where {T, N}
    volumes = zeros(eltype(cell_data.volumes), num_cells)
    grid_cpu = Array(grid)
    for I in CartesianIndices(grid_cpu)
        id = grid_cpu[I]
        if id > 0 && id <= num_cells
            volumes[id] += 1
        end
    end
    for i in 1:num_cells
        cell_data.volumes[i] = volumes[i]
        cell_data.target_volumes[i] = volumes[i]
    end
end
