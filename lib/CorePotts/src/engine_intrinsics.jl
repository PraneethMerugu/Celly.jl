
using KernelAbstractions: @kernel, @index


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
            accept, target_val, src_val, tx_deltas = _compute_site_proposal(
                idx, coords, grid, grid_dims, topology, cell_data, penalties,
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
