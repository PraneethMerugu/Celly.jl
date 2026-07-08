import Atomix
import KernelAbstractions
using KernelAbstractions: @kernel, @index, @localmem, @synchronize
using ArgCheck

@inline function get_lottery_neighbor_idx(
        topo::AbstractTopology{N}, coords::NTuple{N, UInt32},
        dir::Int, dims::NTuple{N, Int}) where {N}
    offs = lottery_offsets(topo)[dir]
    new_coords = ntuple(Val(N)) do i
        Base.@_inline_meta
        c = Int32(coords[i])
        d = Int32(dims[i])
        dx = Int32(offs[i])
        c_new = c + dx
        c_new = c_new < 0 ? c_new + d : (c_new >= d ? c_new - d : c_new)
        UInt32(c_new)
    end
    return coord_to_idx(new_coords, dims)
end

@inline function get_lottery_neighbor_idx(
        topo::Union{NoFluxVonNeumannTopology{N}, NoFluxMooreTopology{N}},
        coords::NTuple{N, UInt32}, dir::Int, dims::NTuple{N, Int}) where {N}
    offs = lottery_offsets(topo)[dir]
    new_coords = ntuple(Val(N)) do i
        Base.@_inline_meta
        c = Int32(coords[i])
        d = Int32(dims[i])
        dx = Int32(offs[i])
        UInt32(clamp(c + dx, 0, d - 1))
    end
    return coord_to_idx(new_coords, dims)
end

@inline function _local_site_update!(
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

        # src=loser, tgt=winner
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

        if accept
            grid[idx] = src_val
            apply_tx_deltas_direct!(target_val, src_val, tx_deltas, trackers, cell_data)
        end
    end
end

@kernel function _local_lottery_sweep_kernel!(
        grid, grid_dims, topology, cell_data, penalties,
        trackers, sampler, T_val, active_fraction, global_seed)
    idx = @index(Global, Linear)

    if idx <= length(grid)
        my_ticket = pcg_hash(global_seed + UInt64(idx))

        prob_active = typeof(active_fraction)(my_ticket & 0x00FFFFFF) /
                      typeof(active_fraction)(0x01000000)
        N_moore = length(lottery_offsets(topology))
        target_prob = active_fraction * typeof(active_fraction)(N_moore + 1)
        if prob_active <= target_prob
            coords = idx_to_coord(UInt32(idx), grid_dims)
            target_val = grid[idx]

            won_lottery = true
            for dir in 1:N_moore
                n_idx = get_lottery_neighbor_idx(topology, coords, dir, grid_dims)
                if n_idx != idx
                    neighbor_ticket = pcg_hash(global_seed + UInt64(n_idx))
                    if neighbor_ticket > my_ticket ||
                       (neighbor_ticket == my_ticket && n_idx > idx)
                        won_lottery = false
                        break
                    end
                end
            end

            if won_lottery
                rng_state = pcg_hash(my_ticket)
                _local_site_update!(
                    coords, grid, grid_dims, topology, cell_data, penalties,
                    trackers, sampler, T_val, active_fraction, rng_state)
            end
        end
    end
end

@kernel function _checkerboard_sweep_kernel!(
        grid, grid_dims, topology, cell_data, penalties, trackers, sampler, T_val,
        active_fraction, global_seed, color_indices, color_offset, num_active_pixels)
    i = @index(Global, Linear)

    if i <= num_active_pixels
        idx = color_indices[color_offset + i - 1]
        coords = idx_to_coord(UInt32(idx), grid_dims)

        my_ticket = pcg_hash(global_seed + UInt64(idx))

        prob_active = typeof(active_fraction)(my_ticket & 0x00FFFFFF) /
                      typeof(active_fraction)(0x01000000)
        if prob_active <= active_fraction
            rng_state = pcg_hash(my_ticket)
            _local_site_update!(coords, grid, grid_dims, topology, cell_data, penalties,
                trackers, sampler, T_val, active_fraction, rng_state)
        end
    end
end

"""
    execute_step!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache, alg::CheckerboardMetropolis)

Executes a single Monte Carlo Sweep (MCS) across the grid using a deterministic checkerboard algorithm.
"""
function execute_step!(u::AbstractPottsState, p::PottsParameters,
        cache::PottsCache, alg::CheckerboardMetropolis)
    T = alg.T
    active_fraction = alg.active_fraction
    sampler = alg.sampler

    @argcheck T >= zero(typeof(T)) "Temperature (T) must be non-negative"
    @argcheck zero(typeof(active_fraction)) <= active_fraction <=
              one(typeof(active_fraction)) "active_fraction must be between 0.0 and 1.0"

    cache.step_counter[] += UInt64(1)
    global_seed = pcg_hash(cache.step_counter[])

    backend = KernelAbstractions.get_backend(u.grid)
    kernel = _checkerboard_sweep_kernel!(backend, cache.block_size)

    num_colors = checkerboard_colors(p.topology)

    for color_pass in 1:num_colors
        offset = cache.color_offsets[color_pass]
        next_offset = cache.color_offsets[color_pass + 1]
        num_active_pixels = next_offset - offset

        if num_active_pixels > 0
            kernel(
                u.grid, cache.grid_dims, p.topology, u.cell_data,
                p.penalties, p.trackers, sampler, T, active_fraction, global_seed,
                cache.color_indices, offset, num_active_pixels,
                ndrange = num_active_pixels
            )
            KernelAbstractions.synchronize(backend)
        end
    end

    return nothing
end

"""
    execute_step!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache, alg::ParallelMetropolis)

Executes a single Monte Carlo Sweep (MCS) across the grid using the stochastic lottery algorithm.
"""
function execute_step!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache, alg::ParallelMetropolis)
    T = alg.T
    active_fraction = alg.active_fraction
    sampler = alg.sampler

    @argcheck T >= zero(typeof(T)) "Temperature (T) must be non-negative"
    @argcheck zero(typeof(active_fraction)) <= active_fraction <=
              one(typeof(active_fraction)) "active_fraction must be between 0.0 and 1.0"

    cache.step_counter[] += UInt64(1)
    global_seed = pcg_hash(cache.step_counter[])

    backend = KernelAbstractions.get_backend(u.grid)
    kernel = _local_lottery_sweep_kernel!(backend, cache.block_size)

    kernel(
        u.grid, cache.grid_dims, p.topology, u.cell_data,
        p.penalties, p.trackers, sampler, T, active_fraction, global_seed,
        ndrange = length(u.grid)
    )
    return nothing
end

"""
    execute_step!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache, alg::SequentialMetropolis)

Executes a single Monte Carlo Sweep (MCS) sequentially on the CPU without atomic locks.
"""
function execute_step!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache, alg::SequentialMetropolis)
    T = alg.T
    active_fraction = alg.active_fraction
    sampler = alg.sampler

    @argcheck T >= zero(typeof(T)) "Temperature (T) must be non-negative"
    @argcheck zero(typeof(active_fraction)) <= active_fraction <=
              one(typeof(active_fraction)) "active_fraction must be between 0.0 and 1.0"

    cache.step_counter[] += UInt64(1)
    global_seed = pcg_hash(cache.step_counter[])

    N = length(u.grid)
    num_updates = round(Int, N * active_fraction)

    # We execute this entirely sequentially on a single thread.
    for i in 1:num_updates
        # Deterministically generate random index
        idx_hash = pcg_hash(global_seed + UInt64(i))
        idx = (idx_hash % UInt64(N)) + 1
        coords = idx_to_coord(UInt32(idx), cache.grid_dims)

        # Unique seed for the local update acceptance
        step_seed = pcg_hash(global_seed + UInt64(i + num_updates))

        _local_site_update!(
            coords, u.grid, cache.grid_dims, p.topology,
            u.cell_data, p.penalties, p.trackers,
            sampler, T, active_fraction, step_seed
        )
    end

    return nothing
end
