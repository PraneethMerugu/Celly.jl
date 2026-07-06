import Atomix
import AcceleratedKernels
import Adapt
import Functors

abstract type AbstractTracker end

function Functors.functor(::Type{<:AbstractTracker}, x)
    props = propertynames(x)
    children = NamedTuple{props}(getproperty.(Ref(x), props))
    reconstruct(children) = Base.typename(typeof(x)).wrapper(values(children)...)
    return children, reconstruct
end

function Adapt.adapt_structure(to, x::AbstractTracker)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

@inline tx_delta_type(::AbstractTracker) = error("Not implemented")
@inline compute_tx_deltas(::AbstractTracker, ctx) = error("Not implemented")
@inline commit_direct!(::AbstractTracker, cell_data, cell_id, delta) = error("Not implemented")
function initialize_metrics!(::AbstractTracker, cell_data, grid, topo, dims) error("Not implemented") end

# --- Volume Tracker ---
"""
    VolumeTracker

A global state tracker that automatically tracks the volume (number of grid sites) 
belonging to each cell without requiring `O(N)` recalculations per step.
"""
struct VolumeTracker <: AbstractTracker end
const VolumeFlexTracker = VolumeTracker
@inline tx_delta_type(::VolumeTracker) = Int32

@inline function compute_tx_deltas(::VolumeTracker, ctx)
    return (Int32(-1), Int32(1))
end

@inline function commit_direct!(::VolumeTracker, cell_data, cell_id, delta)
    Atomix.@atomic cell_data.volumes[cell_id] += delta
end

function initialize_metrics!(::VolumeTracker, cell_data, grid, topo, dims)
    fill!(cell_data.volumes, Int32(0))
    AcceleratedKernels.foreachindex(grid; block_size=DEFAULT_BLOCK_SIZE) do I
        cell_id = grid[I]
        if cell_id > 0
            Atomix.@atomic cell_data.volumes[cell_id] += Int32(1)
        end
    end
end

# --- Surface Area Tracker ---
"""
    SurfaceAreaTracker

A global state tracker that automatically tracks the surface area (number of dissimilar neighbor interactions) 
for each cell dynamically as the grid is updated.
"""
struct SurfaceAreaTracker <: AbstractTracker end
const SurfaceAreaFlexTracker = SurfaceAreaTracker
@inline tx_delta_type(::SurfaceAreaTracker) = Int32

@inline function compute_tx_deltas(::SurfaceAreaTracker, ctx)
    N_dirs = length(ctx.neighbors)
    dsa_s = Int32(2) * ctx.n_src - Int32(N_dirs)
    dsa_t = Int32(N_dirs) - Int32(2) * ctx.n_tgt
    return (dsa_s, dsa_t)
end

@inline function commit_direct!(::SurfaceAreaTracker, cell_data, cell_id, delta)
    Atomix.@atomic cell_data.surface_areas[cell_id] += delta
end

function initialize_metrics!(::SurfaceAreaTracker, cell_data, grid, topo, dims)
    N_dirs_val = num_dirs(topo)
    N_dirs_int = get_val(N_dirs_val)
    fill!(cell_data.surface_areas, Int32(0))
    AcceleratedKernels.foreachindex(grid; block_size=DEFAULT_BLOCK_SIZE) do I
        cell_id = grid[I]
        if cell_id > 0
            n_other = Int32(0)
            coords = idx_to_coord(UInt32(I), dims)
            for d in 1:N_dirs_int
                n_idx = get_neighbor_by_coord(topo, coords, UInt32(d), dims)
                if grid[n_idx] != cell_id
                    n_other += Int32(1)
                end
            end
            Atomix.@atomic cell_data.surface_areas[cell_id] += n_other
        end
    end
end

# --- Length & Adhesion Flex Trackers (Dummy Trackers) ---
# Used strictly as signals in the Problem compilation step
struct LengthFlexTracker <: AbstractTracker end
struct AdhesionFlexTracker <: AbstractTracker end

# Utilities
@inline evaluate_all_trackers(::Tuple{}, ctx) = ()
@inline evaluate_all_trackers(trackers::Tuple, ctx) = (compute_tx_deltas(trackers[1], ctx), evaluate_all_trackers(Base.tail(trackers), ctx)...)

@inline get_tracker_delta(::Type{T}, trackers::Tuple, tx_deltas::Tuple) where T = _get_tracker_delta(T, trackers, tx_deltas)

@inline _get_tracker_delta(::Type{T}, ::Tuple{}, ::Tuple{}) where T = nothing
@inline function _get_tracker_delta(::Type{T}, trackers::Tuple, tx_deltas::Tuple) where T
    if trackers[1] isa T
        return tx_deltas[1]
    else
        return _get_tracker_delta(T, Base.tail(trackers), Base.tail(tx_deltas))
    end
end

@inline apply_tx_deltas_direct!(src, tgt, ::Tuple{}, ::Tuple{}, cell_data) = nothing
@inline function apply_tx_deltas_direct!(src, tgt, tx_deltas::Tuple, trackers::Tuple, cell_data)
    delta_src, delta_tgt = tx_deltas[1]
    t = trackers[1]
    if src > 0
        commit_direct!(t, cell_data, src, delta_src)
    end
    if tgt > 0
        commit_direct!(t, cell_data, tgt, delta_tgt)
    end
    apply_tx_deltas_direct!(src, tgt, Base.tail(tx_deltas), Base.tail(trackers), cell_data)
end

function initialize_all_metrics!(trackers::Tuple, cell_data, grid, topo, dims)
    _initialize_metrics!(trackers, cell_data, grid, topo, dims, Val(1))
end
function _initialize_metrics!(trackers::Tuple, cell_data, grid, topo, dims, ::Val{I}) where {I}
    if I <= length(trackers)
        initialize_metrics!(trackers[I], cell_data, grid, topo, dims)
        _initialize_metrics!(trackers, cell_data, grid, topo, dims, Val(I+1))
    end
end

function update_local_metrics!(::AbstractTracker, cell_data, grid, topo, dims, dev_is_modified) 
    # Fallback/do nothing for unknown trackers
end

function update_local_metrics!(::VolumeTracker, cell_data, grid, topo, dims, dev_is_modified)
    AcceleratedKernels.foreachindex(grid; block_size=DEFAULT_BLOCK_SIZE) do I
        cell_id = grid[I]
        if cell_id > 0 && dev_is_modified[cell_id]
            Atomix.@atomic cell_data.volumes[cell_id] += Int32(1)
        end
    end
end

function update_local_metrics!(::SurfaceAreaTracker, cell_data, grid, topo, dims, dev_is_modified)
    N_dirs_val = num_dirs(topo)
    N_dirs_int = get_val(N_dirs_val)
    AcceleratedKernels.foreachindex(grid; block_size=DEFAULT_BLOCK_SIZE) do I
        cell_id = grid[I]
        if cell_id > 0 && dev_is_modified[cell_id]
            n_other = Int32(0)
            coords = idx_to_coord(UInt32(I), dims)
            for d in 1:N_dirs_int
                n_idx = get_neighbor_by_coord(topo, coords, UInt32(d), dims)
                if grid[n_idx] != cell_id
                    n_other += Int32(1)
                end
            end
            Atomix.@atomic cell_data.surface_areas[cell_id] += n_other
        end
    end
end

function update_local_all_metrics!(trackers::Tuple, cell_data, grid, topo, dims, dev_is_modified)
    _update_local_metrics!(trackers, cell_data, grid, topo, dims, dev_is_modified, Val(1))
end

function _update_local_metrics!(trackers::Tuple, cell_data, grid, topo, dims, dev_is_modified, ::Val{I}) where {I}
    if I <= length(trackers)
        update_local_metrics!(trackers[I], cell_data, grid, topo, dims, dev_is_modified)
        _update_local_metrics!(trackers, cell_data, grid, topo, dims, dev_is_modified, Val(I+1))
    end
end
