
@kernel function _kernel_property_update!(cell_data, rules, N_cells, target_type_id, ctx)
    i = @index(Global, Linear)
    if i <= N_cells[1]
        if target_type_id == UInt8(0) || cell_data.cell_types[i] == target_type_id
            evaluate_and_assign_rules!(cell_data, UInt32(i), ctx, rules)
        end
    end
end

@kernel function _extract_spatial_edges!(grid, dims, topology, edge_list, edge_count,
        spatial_rules, spatial_buffer, cell_data, needs_reduce)
    idx = @index(Global, Linear)
    if idx <= length(grid)
        cell_id = grid[idx]
        if cell_id > 0
            n_dirs = length(CorePotts.offsets(topology))
            for d in 1:n_dirs
                n_idx = CorePotts.get_neighbor_by_dir(topology, UInt32(idx), UInt32(d), dims)
                if n_idx > 0
                    n_cell_id = grid[n_idx]
                    if n_cell_id != cell_id
                        n_type = n_cell_id == 0 ? UInt8(0) : cell_data.cell_types[n_cell_id]
                        # Extract ContactArea rules immediately without deduplication
                        evaluate_map_rules!(spatial_rules, cell_id, n_cell_id,
                            n_type, spatial_buffer, cell_data)
                        if needs_reduce
                            # Pack edge: higher 32 bits = cell_id, lower 32 bits = n_cell_id
                            packed_edge = (UInt64(cell_id) << 32) | UInt64(n_cell_id)
                            pos = Atomix.@atomic edge_count[1] += UInt32(1)
                            edge_list[pos] = packed_edge
                        end
                    end
                end
            end
        end
    end
end

@kernel function _reduce_spatial_edges!(
        edge_list, edge_count, spatial_rules, spatial_buffer, cell_data)
    i = @index(Global, Linear)
    if i <= edge_count[1]
        # Only process if this is the first occurrence of this edge (deduplication)
        # edge_list is sorted, so duplicates are adjacent.
        is_unique = (i == 1) || (edge_list[i] != edge_list[i - 1])
        if is_unique
            packed_edge = edge_list[i]
            cell_id = UInt32(packed_edge >> 32)
            n_cell_id = UInt32(packed_edge & 0xFFFFFFFF)
            n_type = n_cell_id == 0 ? UInt8(0) : cell_data.cell_types[n_cell_id]

            # Evaluate reduce-based spatial rules for this unique edge
            evaluate_reduce_rules!(
                spatial_rules, cell_id, n_cell_id, n_type, spatial_buffer, cell_data)
        end
    end
end

@generated function evaluate_reduce_rules!(
        rules::Tuple, cell_id::UInt32, n_cell_id::UInt32,
        n_type::UInt8, spatial_buffer, cell_data)
    N = length(rules.parameters)
    ex = Expr(:block)
    for i in 1:N
        push!(ex.args,
            :(evaluate_reduce_rule!(
                rules[$i], cell_id, n_cell_id, n_type, spatial_buffer, cell_data)))
    end
    return ex
end
@inline evaluate_reduce_rules!(
    ::Tuple{}, cell_id, n_cell_id, n_type, spatial_buffer, cell_data) = nothing

@generated function evaluate_map_rules!(rules::Tuple, cell_id::UInt32, n_cell_id::UInt32,
        n_type::UInt8, spatial_buffer, cell_data)
    N = length(rules.parameters)
    ex = Expr(:block)
    for i in 1:N
        push!(ex.args, :(evaluate_map_rule!(
            rules[$i], cell_id, n_cell_id, n_type, spatial_buffer, cell_data)))
    end
    return ex
end
@inline evaluate_map_rules!(
    ::Tuple{}, cell_id, n_cell_id, n_type, spatial_buffer, cell_data) = nothing

# Fallbacks
@inline evaluate_reduce_rule!(
    rule, cell_id, n_cell_id, n_type, spatial_buffer, cell_data) = nothing
@inline evaluate_map_rule!(
    rule, cell_id, n_cell_id, n_type, spatial_buffer, cell_data) = nothing

@inline function evaluate_reduce_rule!(
        rule::NeighborCount, cell_id, n_cell_id, n_type, spatial_buffer, cell_data)
    if rule.type_id == n_type
        buf_idx = (rule.buffer_index - 1) * length(cell_data.volumes) + cell_id
        Atomix.@atomic spatial_buffer[buf_idx] += 1.0f0
    end
end

@inline function evaluate_reduce_rule!(rule::NeighborSum{Prop}, cell_id, n_cell_id,
        n_type, spatial_buffer, cell_data) where {Prop}
    if rule.type_id == n_type && n_cell_id > 0
        prop_val = getproperty(cell_data, Prop)[n_cell_id]
        buf_idx = (rule.buffer_index - 1) * length(cell_data.volumes) + cell_id
        Atomix.@atomic spatial_buffer[buf_idx] += Float32(prop_val)
    end
end

@inline function evaluate_map_rule!(
        rule::ContactArea, cell_id, n_cell_id, n_type, spatial_buffer, cell_data)
    if rule.type_id == n_type
        buf_idx = (rule.buffer_index - 1) * length(cell_data.volumes) + cell_id
        Atomix.@atomic spatial_buffer[buf_idx] += UInt32(1)
    end
end

@generated function has_reduce_rules(rules::Tuple)
    has_reduce = false
    for T in rules.parameters
        if !(T <: ContactArea)
            has_reduce = true
        end
    end
    return :($has_reduce)
end

@kernel function _fill_kernel!(buffer, val)
    i = @index(Global)
    buffer[i] = val
end

function populate_spatial_buffer!(u, topology, cache, spatial_rules, deps)
    backend = KernelAbstractions.get_backend(u.grid)
    grid = u.grid
    N_grid = length(grid)
    N_cells = length(u.cell_data.volumes)
    num_rules = length(spatial_rules)

    # 1. Prepare buffers
    buf_size = N_cells * num_rules
    if !haskey(cache.scratch, :spatial_buffer) ||
       length(cache.scratch[:spatial_buffer]) < buf_size
        cache.scratch[:spatial_buffer] = similar(grid, UInt32, buf_size)
    end
    spatial_buffer = cache.scratch[:spatial_buffer]
    k_fill = _fill_kernel!(backend, cache.block_size)
    ev_fill_buf = dispatch_kernel!(
        k_fill, spatial_buffer, UInt32(0); ndrange = buf_size, dependencies = deps)

    needs_reduce = has_reduce_rules(spatial_rules)

    # 2. Setup edge buffers for reduce rules (always setup to avoid type instability in kernel signature)
    max_edges = N_grid * length(CorePotts.offsets(topology))
    if !haskey(cache.scratch, :edge_list) || length(cache.scratch[:edge_list]) < max_edges
        cache.scratch[:edge_list] = similar(grid, UInt64, max_edges)
        cache.scratch[:edge_count] = similar(grid, UInt32, 1)
    end
    edge_list = cache.scratch[:edge_list]
    edge_count = cache.scratch[:edge_count]
    ev_fill_count = dispatch_kernel!(
        k_fill, edge_count, UInt32(0); ndrange = 1, dependencies = deps)

    dims = size(grid)
    k_extract = _extract_spatial_edges!(backend, cache.block_size)

    deps_extract = (ev_fill_buf !== nothing && ev_fill_count !== nothing) ?
                   (ev_fill_buf, ev_fill_count) :
                   (ev_fill_buf !== nothing ? (ev_fill_buf,) :
                    (ev_fill_count !== nothing ? (ev_fill_count,) : ()))

    if !needs_reduce
        # If we don't need to reduce, we can skip edge collection entirely
        ev_spatial = dispatch_kernel!(
            k_extract, grid, dims, topology, edge_list, edge_count,
            spatial_rules, spatial_buffer, u.cell_data, needs_reduce;
            ndrange = N_grid, dependencies = deps_extract)
        return spatial_buffer, ev_spatial
    end

    ev_extract = dispatch_kernel!(k_extract, grid, dims, topology, edge_list, edge_count,
        spatial_rules, spatial_buffer, u.cell_data, needs_reduce;
        ndrange = N_grid, dependencies = deps_extract)

    # We still need CPU synchronization for the sort! call if needs_reduce is true.
    # We only synchronize if ev_extract is not nothing (though Metal naturally serializes).
    KernelAbstractions.synchronize(backend)

    # 3. Deduplicate edges and evaluate reduce rules
    total_edges = Array(edge_count)[1]
    ev_spatial = ev_extract

    if total_edges > 0
        active_edges = view(edge_list, 1:total_edges)
        # AcceleratedKernels.sort! works on the GPU arrays directly
        ev_sort = AcceleratedKernels.sort!(active_edges)
        KernelAbstractions.synchronize(backend)

        k_reduce = _reduce_spatial_edges!(backend, cache.block_size)
        ev_spatial = dispatch_kernel!(k_reduce, active_edges, edge_count, spatial_rules,
            spatial_buffer, u.cell_data; ndrange = total_edges)
    end

    return spatial_buffer, ev_spatial
end

@kernel function _kernel_check_generic_triggers!(
        dev_parents, dev_division_count, N_cells, cell_data, trigger, max_capacity)
    i = @index(Global, Linear)
    if i <= N_cells
        if trigger(i, cell_data)
            idx = Atomix.@atomic dev_division_count[1] += UInt32(1)
            if idx <= max_capacity
                dev_parents[idx] = UInt32(i)
            end
        end
    end
end

@kernel function _kernel_find_dead_cells!(
        volumes, target_volumes, cell_types, free_list, free_list_count)
    i = @index(Global, Linear)
    if i <= length(volumes)
        if volumes[i] == 0 && target_volumes[i] == 0 && cell_types[i] > 0
            # Atomix.@atomic returns the old value for += but wait... 
            # Atomix.@atomic x += 1 returns the NEW value in our test. 
            # So if old was 0, it returns 1. We want to write to index 1.
            idx = Atomix.@atomic free_list_count[1] += Int32(1)
            free_list[idx] = UInt32(i)
            cell_types[i] = UInt32(0)
        end
    end
end

"""
    process_death_events!(engine)

Scans the grid for any cells whose `target_volume` is less than or equal to 0. 
These cells are killed (removed from the grid) and their IDs are recycled for future use.
"""
function process_death_events!(u::AbstractPottsState, cache::PottsCache, ws::MitosisWorkspace)
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    current_N = Array(u.N_cells)[1]

    k_dead = _kernel_find_dead_cells!(backend, cache.block_size)
    k_dead(u.cell_data.volumes, u.cell_data.target_volumes, u.cell_data.cell_types,
        u.free_list, u.free_list_count, ndrange = current_N)
    KernelAbstractions.synchronize(backend)
end

"""
    reset_hst_fields_after_division!(engine, pen::AbstractHSTPenalty)

Resets the stochastic auxiliary field for all live cells to its thermodynamic mean
immediately after a mitosis event, preventing O(1/η) MCS transients.
"""
@kernel function _kernel_reset_hst_fields!(
        states, values, targets, ctypes, lambdas, p_lambdas, is_flex, N_cells)
    i = @index(Global, Linear)
    if i <= N_cells
        ct = ctypes[i]
        if ct > 0 && values[i] > 0
            F = eltype(states)
            val = F(values[i])
            tgt = F(targets[i])
            lam = is_flex ? F(lambdas[i]) : F(p_lambdas[ct + 1])
            states[i] = F(2.0) * lam * (val - tgt)
        end
    end
end

function reset_hst_fields_after_division!(u::AbstractPottsState, cache::PottsCache,
        pen::AbstractHSTPenalty{FlexType}) where {FlexType}
    state_val = hst_state_field(pen)
    val_val = hst_value_field(pen)
    tgt_val = hst_target_field(pen)
    lam_val = lambda_field(pen)

    _reset_hst_fields_inner!(
        u, cache, pen, FlexType === Flex, state_val, val_val, tgt_val, lam_val)
end

function _reset_hst_fields_inner!(
        u, cache, pen, is_flex, ::Val{S}, ::Val{V}, ::Val{T}, ::Val{L}) where {S, V, T, L}
    if !hasproperty(u.cell_data, S)
        return
    end
    states = getproperty(u.cell_data, S)
    values = getproperty(u.cell_data, V)
    targets = getproperty(u.cell_data, T)
    lambdas = is_flex ? getproperty(u.cell_data, L) : pen.lambdas

    backend = KernelAbstractions.get_backend(u.grid)
    N = Int(Array(u.N_cells)[])
    k = _kernel_reset_hst_fields!(backend, cache.block_size)
    k(states, values, targets, u.cell_data.cell_types, lambdas,
        pen.lambdas, is_flex, UInt32(N), ndrange = N)
    KernelAbstractions.synchronize(backend)
    return nothing
end

@kernel function _update_hst_generic_kernel!(
        states, values, tgts, ctypes, vlambdas, p_lambdas, is_flex, eta, T_val, seed, dt)
    i = @index(Global, Linear)
    if i <= length(values)
        c_type = ctypes[i]
        if c_type > 0
            F = eltype(states)
            v_true = F(values[i])
            if v_true > zero(F)
                lam = is_flex ? F(vlambdas[i]) : F(p_lambdas[c_type + 1])
                mean_p = F(2.0) * lam * (v_true - F(tgts[i]))
                alpha = exp(-eta * dt)
                noise_std = sqrt(max(zero(F), F(2.0) * lam * F(T_val) * (one(F) - alpha^2)))
                noise = noise_std * F(randn_pcg(seed + UInt64(i), seed + UInt64(i + 12345)))
                states[i] = alpha * states[i] + (one(F) - alpha) * mean_p + noise
            else
                states[i] = zero(F)
            end
        end
    end
end

function update_sweep_auxiliary!(pen::AbstractHSTPenalty{FlexType}, u::AbstractPottsState,
        p::PottsParameters, cache::PottsCache, T_val, dt) where {FlexType}
    state_val = hst_state_field(pen)
    val_val = hst_value_field(pen)
    tgt_val = hst_target_field(pen)
    lam_val = lambda_field(pen)

    _update_hst_inner!(
        u, cache, pen, FlexType === Flex, T_val, dt, state_val, val_val, tgt_val, lam_val)
end

function _update_hst_inner!(u, cache, pen, is_flex, T_val, dt, ::Val{S},
        ::Val{V}, ::Val{T}, ::Val{L}) where {S, V, T, L}
    if !hasproperty(u.cell_data, S)
        return
    end
    states = getproperty(u.cell_data, S)
    values = getproperty(u.cell_data, V)
    targets = getproperty(u.cell_data, T)
    lambdas = is_flex ? getproperty(u.cell_data, L) : pen.lambdas

    cache.noise_counter[] += UInt64(1)
    backend = KernelAbstractions.get_backend(states)
    seed = pcg_hash(cache.noise_counter[])

    kernel = _update_hst_generic_kernel!(backend, cache.block_size)
    kernel(states, values, targets, u.cell_data.cell_types, lambdas, pen.lambdas,
        is_flex, pen.eta, T_val, seed, dt, ndrange = length(states))
    KernelAbstractions.synchronize(backend)
end

import SciMLBase

function DeathCallback(; max_cells = nothing)
    ws_ref = Ref{MitosisWorkspace}()
    condition(u, t, integrator) = true
    function affect!(integrator)
        if !isassigned(ws_ref)
            max_c = max_cells === nothing ? length(integrator.u.cell_data.volumes) :
                    max_cells
            ws_ref[] = MitosisWorkspace(integrator.u.grid, max_c)
        end
        process_death_events!(integrator.u, integrator.cache, ws_ref[])
    end
    return SciMLBase.DiscreteCallback(condition, affect!)
end
