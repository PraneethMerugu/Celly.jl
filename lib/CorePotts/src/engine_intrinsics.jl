import Atomix
import KernelAbstractions
using KernelAbstractions: @kernel, @index

@inline function _intrinsic_site_eval!(
        coords, grid, grid_dims, topology, cell_data, penalties,
        trackers, sampler, T_val, active_fraction, rng_state)
    idx = coord_to_idx(coords, grid_dims)
    target_val = grid[idx]

    N_dirs_val = num_dirs(topology)
    N_dirs = get_val(N_dirs_val)

    dir = UInt32(rng_state % N_dirs) + UInt32(1)
    rng_state = pcg_hash(rng_state)

    src_idx = get_neighbor_by_coord(topology, coords, dir, grid_dims)
    src_val = grid[src_idx]

    if src_val != target_val
        offs_src = offsets(topology)[dir]
        source_coords = ntuple(Val(length(coords))) do i
            Base.@_inline_meta
            c = Int32(coords[i])
            d = Int32(grid_dims[i])
            dx = Int32(offs_src[i])
            if is_noflux(topology)
                UInt32(clamp(c + dx, 0, d - 1))
            else
                c_new = c + dx
                c_new = c_new < 0 ? c_new + d : (c_new >= d ? c_new - d : c_new)
                UInt32(c_new)
            end
        end
        neighbors = ntuple(N_dirs_val) do d
            grid[get_neighbor_by_coord(topology, coords, UInt32(d), grid_dims)]
        end

        n_src = Int32(0)
        n_tgt = Int32(0)
        for d in 1:N_dirs
            n_val = neighbors[d]
            if n_val == target_val # target_val is the loser (ctx.src)
                n_src += Int32(1)
            elseif n_val == src_val # src_val is the winner (ctx.tgt)
                n_tgt += Int32(1)
            end
        end

        ctx = (; grid = grid, grid_dims = grid_dims, topology = topology,
            cell_data = cell_data, trackers = trackers,
            idx = UInt32(idx), src = target_val, tgt = src_val, T = T_val,
            spatial_coords = coords, source_coords = source_coords,
            neighbors = neighbors, n_src = n_src, n_tgt = n_tgt)

        tx_deltas = evaluate_all_trackers(trackers, ctx)
        ctx_with_deltas = (;
            grid = ctx.grid, grid_dims = ctx.grid_dims, topology = ctx.topology,
            cell_data = ctx.cell_data, trackers = ctx.trackers, idx = ctx.idx,
            src = ctx.src, tgt = ctx.tgt, T = ctx.T, spatial_coords = ctx.spatial_coords,
            source_coords = ctx.source_coords, neighbors = ctx.neighbors,
            n_src = ctx.n_src, n_tgt = ctx.n_tgt, tx_deltas = tx_deltas)
        dH = evaluate_all_penalties(penalties, ctx_with_deltas)

        hastings_ratio = n_tgt == Int32(0) ?
                         typeof(T_val)(n_src) :
                         typeof(T_val)(n_src) / typeof(T_val)(n_tgt)
        prob = typeof(T_val)(rng_state & 0x00FFFFFF) / typeof(T_val)(0x01000000)
        accept = evaluate_acceptance(sampler, dH, hastings_ratio, prob, T_val)

        return accept, target_val, src_val, tx_deltas
    else
        # Return dummy tuple for type stability if src_val == target_val
        dummy_ctx = (; grid = grid, grid_dims = grid_dims, topology = topology,
            cell_data = cell_data, trackers = trackers,
            idx = UInt32(idx), src = target_val, tgt = src_val, T = T_val,
            spatial_coords = coords, source_coords = coords,
            neighbors = ntuple(d -> Int32(0), N_dirs_val), n_src = Int32(0), n_tgt = Int32(0))
        dummy_deltas = evaluate_all_trackers(trackers, dummy_ctx)
        return false, Int32(0), Int32(0), dummy_deltas
    end
end

@kernel function _intrinsic_checkerboard_sweep_kernel!(
        grid, grid_dims, topology, cell_data, penalties, trackers, sampler, T_val,
        active_fraction, global_seed, color_indices, color_offset, num_active_pixels)
    i = @index(Global, Linear)
    lane = KernelIntrinsics.@laneid()

    is_active_thread = i <= num_active_pixels

    # Defaults
    accept = false
    target_val = Int32(0)
    src_val = Int32(0)

    # We must compute a dummy delta for type stability even if thread is inactive
    dummy_ctx = (; grid = grid, grid_dims = grid_dims, topology = topology,
        cell_data = cell_data, trackers = trackers,
        idx = UInt32(1), src = Int32(0), tgt = Int32(0), T = T_val,
        spatial_coords = ntuple(d -> UInt32(0), Val(length(grid_dims))),
        source_coords = ntuple(d -> UInt32(0), Val(length(grid_dims))),
        neighbors = ntuple(d -> Int32(0), num_dirs(topology)), n_src = Int32(0), n_tgt = Int32(0))
    tx_deltas = evaluate_all_trackers(trackers, dummy_ctx)

    if is_active_thread
        idx = color_indices[color_offset + i - 1]
        coords = idx_to_coord(UInt32(idx), grid_dims)

        my_ticket = pcg_hash(global_seed + UInt64(idx))

        prob_active = typeof(active_fraction)(my_ticket & 0x00FFFFFF) /
                      typeof(active_fraction)(0x01000000)
        if prob_active <= active_fraction
            rng_state = pcg_hash(my_ticket)
            accept, target_val, src_val, tx_deltas = _intrinsic_site_eval!(
                coords, grid, grid_dims, topology, cell_data, penalties,
                trackers, sampler, T_val, active_fraction, rng_state)

            if accept
                grid[idx] = src_val
            end
        end
    end

    # Phase 3: Subgroup Reduction by Key (Quarantine Architecture)
    active_mask = KernelIntrinsics.@vote(KernelIntrinsics.Ballot, is_active_thread)
    apply_warp_reductions!(
        lane, active_mask, accept, target_val, src_val, tx_deltas, trackers, cell_data)
end

function execute_step!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache,
        alg::IntrinsicCheckerboardMetropolis, prev_event = nothing)
    grid = u.grid
    grid_dims = size(grid)
    backend = KernelAbstractions.get_backend(grid)
    cache.step_counter[1] += UInt64(1)
    global_seed = pcg_hash(cache.step_counter[1])

    active_fraction = alg.active_fraction
    sampler = alg.sampler
    T_val = alg.T

    num_colors = checkerboard_colors(p.topology)
    for color_pass in 1:num_colors
        offset = cache.color_offsets[color_pass]
        next_offset = cache.color_offsets[color_pass + 1]
        num_pixels = next_offset - offset

        if num_pixels > 0
            ndrange = num_pixels
            _intrinsic_checkerboard_sweep_kernel!(backend, cache.block_size)(
                grid, grid_dims, p.topology, u.cell_data, p.penalties, p.trackers,
                sampler, T_val, active_fraction, global_seed,
                cache.color_indices, offset, num_pixels,
                ndrange = ndrange
            )
        end
        global_seed = pcg_hash(global_seed)
    end
    KernelAbstractions.synchronize(backend)
    return nothing
end
