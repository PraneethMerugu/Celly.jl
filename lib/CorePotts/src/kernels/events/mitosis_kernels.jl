struct MitosisWorkspace{ArrayUInt32, ArrayInt32, ArrayFloat32, ArrayBool}
    dev_parents::ArrayUInt32
    dev_children::ArrayUInt32
    dev_division_count::ArrayUInt32

    dev_dead_cells::ArrayUInt32
    dev_dead_count::ArrayUInt32

    dev_is_dividing::ArrayBool
    dev_is_modified::ArrayBool

    acc_count::ArrayInt32
    acc_sin::ArrayFloat32
    acc_cos::ArrayFloat32
    acc_cov::ArrayFloat32

    dev_centroids::ArrayFloat32
    dev_normals::ArrayFloat32
    dev_child_map::ArrayUInt32
end

function MitosisWorkspace(grid::AbstractArray{T, N}, max_cells::Int) where {T, N}
    cov_elements = div(N * (N + 1), 2)
    return MitosisWorkspace(
        similar(grid, UInt32, max_cells),
        similar(grid, UInt32, max_cells),
        similar(grid, UInt32, 1),
        similar(grid, UInt32, max_cells),
        similar(grid, UInt32, 1),
        similar(grid, Bool, max_cells),
        similar(grid, Bool, max_cells),
        similar(grid, Int32, max_cells),
        similar(grid, Float32, N * max_cells),
        similar(grid, Float32, N * max_cells),
        similar(grid, Float32, cov_elements * max_cells),
        similar(grid, Float32, N * max_cells),
        similar(grid, Float32, N * max_cells),
        similar(grid, UInt32, max_cells)
    )
end

# --- Mitosis GPU Kernels ---



@kernel function _kernel_mark_is_dividing!(dev_is_dividing, dev_parents, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        dev_is_dividing[dev_parents[i]] = true
    end
end

@kernel function _kernel_allocate_mitosis_ids!(
        dev_children, free_list, free_list_count, N_cells, dev_division_count, max_capacity)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        # Fast capacity check on GPU
        if N_cells[1] - free_list_count[1] < max_capacity
            # Attempt to get an ID from the free list (new_count is the value AFTER subtraction)
            new_count = Atomix.@atomic free_list_count[1] -= Int32(1)
            if new_count >= 0
                # We successfully claimed a slot
                dev_children[i] = free_list[new_count + 1]
            else
                # We must restore the count (since it went negative) and get a new ID from N_cells
                Atomix.@atomic free_list_count[1] += Int32(1)
                new_id = Atomix.@atomic N_cells[1] += Int32(1)
                if new_id <= max_capacity
                    dev_children[i] = UInt32(new_id)
                else
                    dev_children[i] = UInt32(0)
                end
            end
        else
            dev_children[i] = UInt32(0) # Out of capacity
        end
    end
end

@kernel function _kernel_mark_is_modified!(dev_is_modified, dev_parents, dev_children, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        dev_is_modified[dev_parents[i]] = true
        if dev_children[i] > 0
            dev_is_modified[dev_children[i]] = true
        end
    end
end

@kernel function _kernel_inherit_clone!(array, dev_parents, dev_children, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]
        array[c] = array[p]
    end
end

@inline safe_convert(::Type{T}, x::Float32) where {T <: Signed} = trunc(T, x + 0.5f0)
@inline safe_convert(::Type{T}, x::Float32) where {T <: Unsigned} = trunc(T, max(0.0f0, x + 0.5f0))
@inline safe_convert(::Type{T}, x::Float32) where {T <: AbstractFloat} = T(x)
@inline safe_convert(::Type{T}, x::T) where {T} = x
@inline safe_convert(::Type{T}, x) where {T} = T(x)

@kernel function _kernel_inherit_split!(array, dev_parents, dev_children, fraction, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]
        val = Float32(array[p])
        array[c] = safe_convert(eltype(array), val * fraction)
        array[p] = safe_convert(eltype(array), val * (1.0f0 - fraction))
    end
end

@kernel function _kernel_inherit_reset!(array, dev_parents, dev_children, value, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]
        val = safe_convert(eltype(array), Float32(value))
        array[p] = val
        array[c] = val
    end
end

@kernel function _kernel_inherit_asymmetric_reset!(
        array, dev_parents, dev_children, p_val, c_val, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]
        array[p] = safe_convert(eltype(array), Float32(p_val))
        array[c] = safe_convert(eltype(array), Float32(c_val))
    end
end

@kernel function _kernel_inherit_reset_child!(
        array, dev_parents, dev_children, value, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        c = dev_children[i]
        array[c] = safe_convert(eltype(array), Float32(value))
    end
end

@kernel function _kernel_inherit_add!(array, dev_parents, dev_children, value, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]
        val = Float32(value)
        array[p] = safe_convert(eltype(array), Float32(array[p]) + val)
        array[c] = safe_convert(eltype(array), Float32(array[c]) + val)
    end
end

@kernel function _kernel_inherit_multiply!(array, dev_parents, dev_children, value, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]
        val = Float32(value)
        array[p] = safe_convert(eltype(array), Float32(array[p]) * val)
        array[c] = safe_convert(eltype(array), Float32(array[c]) * val)
    end
end

@kernel function _kernel_inherit_random_uniform!(
        array, dev_parents, dev_children, min_val, max_val, step, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]

        s_p = step + UInt64(p)
        r_p = Float32(pcg_hash(s_p) >> 32) * UINT32_TO_FLOAT32
        val_p = Float32(min_val) + r_p * Float32(max_val - min_val)

        s_c = step + UInt64(c)
        r_c = Float32(pcg_hash(s_c) >> 32) * UINT32_TO_FLOAT32
        val_c = Float32(min_val) + r_c * Float32(max_val - min_val)

        array[p] = safe_convert(eltype(array), val_p)
        array[c] = safe_convert(eltype(array), val_c)
    end
end

@kernel function _kernel_inherit_random_normal!(
        array, dev_parents, dev_children, mean_val, std_val, step, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]

        s_p1 = step + UInt64(p)
        s_p2 = s_p1 + MITOSIS_SEED_OFFSET
        z_p = randn_pcg(s_p1, s_p2)
        val_p = Float32(mean_val) + z_p * Float32(std_val)

        s_c1 = step + UInt64(c)
        s_c2 = s_c1 + MITOSIS_SEED_OFFSET
        z_c = randn_pcg(s_c1, s_c2)
        val_c = Float32(mean_val) + z_c * Float32(std_val)

        array[p] = safe_convert(eltype(array), val_p)
        array[c] = safe_convert(eltype(array), val_c)
    end
end

function apply_inheritance_rule!(rule::Clone, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_clone!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children,
        ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::Split, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_split!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children,
        rule.fraction, ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::Reset, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_reset!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children,
        rule.value, ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::AsymmetricReset, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_asymmetric_reset!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children, rule.parent_value,
        rule.child_value, ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::ResetChild, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_reset_child!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children,
        rule.value, ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::InheritAdd, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_add!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children,
        rule.value, ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::InheritMultiply, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_multiply!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children,
        rule.value, ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::RandomUniform, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_random_uniform!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children, rule.min, rule.max,
        cache.step_counter[], ws.dev_division_count; ndrange = nd_cap)
end

function apply_inheritance_rule!(rule::RandomNormal, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_random_normal!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children, rule.mean, rule.std,
        cache.step_counter[], ws.dev_division_count; ndrange = nd_cap)
end

@kernel function _kernel_inherit_random_poisson!(
        array, dev_parents, dev_children, lambda, step, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        p = dev_parents[i]
        c = dev_children[i]

        val_p = gpu_rand_poisson(p, step, 0x00000000, Float32(lambda))
        val_c = gpu_rand_poisson(c, step, 0x00000000, Float32(lambda))

        array[p] = safe_convert(eltype(array), val_p)
        array[c] = safe_convert(eltype(array), val_c)
    end
end

function apply_inheritance_rule!(rule::RandomPoisson, array, ws, nd_cap, backend, cache, deps)
    k_inh = _kernel_inherit_random_poisson!(backend, cache.block_size)
    return dispatch_kernel!(backend, k_inh, array, ws.dev_parents, ws.dev_children, rule.lambda,
        cache.step_counter[], ws.dev_division_count; ndrange = nd_cap)
end


@kernel function _kernel_check_generic_triggers!(
        dev_parents, dev_division_count, cell_data, trigger, step, max_capacity)
    i = @index(Global, Linear)
    if i <= length(cell_data.volumes)
        if cell_data.cell_types[i] > 0 && trigger(i, cell_data, step)
            idx = Atomix.@atomic dev_division_count[1] += UInt32(1)
            if idx <= max_capacity
                dev_parents[idx] = UInt32(i)
            end
        end
    end
end

function populate_dividing_parents!(u::AbstractPottsState, cache::PottsCache, trigger, ws, deps)
    backend = KernelAbstractions.get_backend(u.grid)
    k_fill = _fill_kernel!(backend, cache.block_size)
    ev_fill = dispatch_kernel!(backend, k_fill, ws.dev_division_count, UInt32(0); ndrange = 1)

    kernel = _kernel_check_generic_triggers!(backend, cache.block_size)
    max_cap = UInt32(length(ws.dev_parents))
    nd_cap = length(u.cell_data.volumes)
    ev_pop = dispatch_kernel!(backend, kernel, ws.dev_parents, ws.dev_division_count, u.cell_data,
        trigger, cache.step_counter[], max_cap; ndrange = nd_cap)
    return ev_pop
end

@kernel function _kernel_accumulate_centroids_cov!(
        grid, dims, dev_is_dividing, acc_count, acc_sin, acc_cos,
        acc_cov, dev_centroids, do_cov, topo, max_capacity,
        sin_luts, cos_luts)
    I = @index(Global, Linear)
    cell_id = grid[I]

    if cell_id > 0 && cell_id <= max_capacity && dev_is_dividing[cell_id]
        coords = idx_to_coord(UInt32(I), dims)
        N = length(dims)

        Atomix.@atomic acc_count[cell_id] += Int32(1)

        for d in 1:N
            c_d = Int(coords[d]) + 1
            idx_d = (cell_id - UInt32(1)) * UInt32(N) + UInt32(d)
            Atomix.@atomic acc_sin[idx_d] += sin_luts[d][c_d]
            Atomix.@atomic acc_cos[idx_d] += cos_luts[d][c_d]
        end

        if do_cov
            dist = MArray{Tuple{N}, Float32}(undef)
            for d in 1:N
                idx = (cell_id - UInt32(1)) * UInt32(N) + UInt32(d)
                delta = Float32(coords[d]) - dev_centroids[idx]
                dist[d] = shortest_vector(topo, delta, Float32(dims[d]))
            end

            cov_elements = div(N * (N + 1), 2)
            cov_idx = (cell_id - UInt32(1)) * UInt32(cov_elements)
            offset = 1
            for i in 1:N
                for j in i:N
                    Atomix.@atomic acc_cov[cov_idx + UInt32(offset)] += dist[i] * dist[j]
                    offset += 1
                end
            end
        end
    end
end

@kernel function _kernel_compute_centroids!(
        dev_centroids, acc_count, acc_sin, acc_cos, dev_parents, dev_division_count, dims)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        p = dev_parents[i]
        c_count = acc_count[p]
        N = length(dims)
        if c_count > 0
            for d in 1:N
                idx = (p - UInt32(1)) * UInt32(N) + UInt32(d)
                mean_sin = acc_sin[idx] / Float32(c_count)
                mean_cos = acc_cos[idx] / Float32(c_count)
                angle = atan(mean_sin, mean_cos)
                if angle < 0
                    angle += 2.0f0 * Float32(pi)
                end
                dev_centroids[idx] = (angle / (2.0f0 * Float32(pi))) * Float32(dims[d])
            end
        end
    end
end

@inline function _compute_eigenvector_2d(lambda, cxx, cyy, cxy, is_x_dom::Bool)
    if abs(cxy) > 1.0f-6
        return lambda - cyy, cxy
    else
        return is_x_dom ? (1.0f0, 0.0f0) : (0.0f0, 1.0f0)
    end
end

@kernel function _kernel_compute_mitosis_normals_2d!(
        dev_normals, acc_cov, dev_parents, dev_division_count, orientation_type)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        p = dev_parents[i]
        cov_idx = (p - UInt32(1)) * UInt32(3)
        cxx = acc_cov[cov_idx + UInt32(1)]
        cxy = acc_cov[cov_idx + UInt32(2)]
        cyy = acc_cov[cov_idx + UInt32(3)]

        trace = cxx + cyy
        det = cxx * cyy - cxy * cxy
        gap = sqrt(max(0.0f0, trace * trace - 4.0f0 * det))

        l1 = (trace + gap) / 2.0f0
        l2 = (trace - gap) / 2.0f0

        vx_maj, vy_maj = _compute_eigenvector_2d(l1, cxx, cyy, cxy, cxx >= cyy)
        vx_min, vy_min = _compute_eigenvector_2d(l2, cxx, cyy, cxy, cxx < cyy)

        mag_maj = max(1.0f-12, sqrt(vx_maj^2 + vy_maj^2))
        mag_min = max(1.0f-12, sqrt(vx_min^2 + vy_min^2))

        idx_x = (p - UInt32(1)) * UInt32(2) + UInt32(1)
        idx_y = (p - UInt32(1)) * UInt32(2) + UInt32(2)

        if orientation_type == 1 # MajorAxis: normal is minor axis
            dev_normals[idx_x] = vx_min / mag_min
            dev_normals[idx_y] = vy_min / mag_min
        else
            dev_normals[idx_x] = vx_maj / mag_maj
            dev_normals[idx_y] = vy_maj / mag_maj
        end
    end
end

@kernel function _kernel_compute_mitosis_normals_3d!(
        dev_normals, acc_cov, dev_parents, dev_division_count, orientation_type)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        p = dev_parents[i]
        cov_idx = (p - UInt32(1)) * UInt32(6)
        cxx = acc_cov[cov_idx + UInt32(1)]
        cxy = acc_cov[cov_idx + UInt32(2)]
        cxz = acc_cov[cov_idx + UInt32(3)]
        cyy = acc_cov[cov_idx + UInt32(4)]
        cyz = acc_cov[cov_idx + UInt32(5)]
        czz = acc_cov[cov_idx + UInt32(6)]

        p1 = cxy^2 + cxz^2 + cyz^2
        if p1 < 1.0f-6
            vals = (cxx, cyy, czz)
            evecs = ((1.0f0, 0.0f0, 0.0f0), (0.0f0, 1.0f0, 0.0f0), (0.0f0, 0.0f0, 1.0f0))

            if orientation_type == 1
                idx_min = vals[1] <= vals[2] ? (vals[1] <= vals[3] ? 1 : 3) :
                          (vals[2] <= vals[3] ? 2 : 3)
                nx, ny, nz = evecs[idx_min]
            else
                idx_max = vals[1] >= vals[2] ? (vals[1] >= vals[3] ? 1 : 3) :
                          (vals[2] >= vals[3] ? 2 : 3)
                nx, ny, nz = evecs[idx_max]
            end
        else
            q = (cxx + cyy + czz) / 3.0f0
            p2 = (cxx - q)^2 + (cyy - q)^2 + (czz - q)^2 + 2.0f0 * p1
            p_val = sqrt(p2 / 6.0f0)

            B11 = (cxx - q) / p_val;
            B12 = cxy / p_val;
            B13 = cxz / p_val
            B22 = (cyy - q) / p_val;
            B23 = cyz / p_val
            B33 = (czz - q) / p_val

            r = B11 * (B22 * B33 - B23^2) - B12 * (B12 * B33 - B23 * B13) +
                B13 * (B12 * B23 - B22 * B13)
            r = clamp(r / 2.0f0, -1.0f0, 1.0f0)

            phi = acos(r) / 3.0f0

            l1 = q + 2.0f0 * p_val * cos(phi)
            l3 = q + 2.0f0 * p_val * cos(phi + (2.0f0*Float32(pi)/3.0f0))

            target_l = orientation_type == 1 ? l3 : l1

            M11 = cxx - target_l;
            M12 = cxy;
            M13 = cxz
            M22 = cyy - target_l;
            M23 = cyz
            M33 = czz - target_l

            v1x = M12 * M33 - M13 * M23;
            v1y = M13 * M12 - M11 * M33;
            v1z = M11 * M23 - M12 * M12
            v2x = M22 * M33 - M23 * M23;
            v2y = M23 * M13 - M12 * M33;
            v2z = M12 * M23 - M22 * M13
            v3x = M23 * M23 - M33 * M22;
            v3y = M33 * M12 - M13 * M23;
            v3z = M13 * M22 - M12 * M23

            m1 = v1x^2 + v1y^2 + v1z^2
            m2 = v2x^2 + v2y^2 + v2z^2
            m3 = v3x^2 + v3y^2 + v3z^2

            nx, ny, nz = 0.0f0, 0.0f0, 0.0f0
            if m1 >= m2 && m1 >= m3
                mag = max(1.0f-12, sqrt(m1))
                nx, ny, nz = v1x/mag, v1y/mag, v1z/mag
            elseif m2 >= m1 && m2 >= m3
                mag = max(1.0f-12, sqrt(m2))
                nx, ny, nz = v2x/mag, v2y/mag, v2z/mag
            else
                mag = max(1.0f-12, sqrt(m3))
                nx, ny, nz = v3x/mag, v3y/mag, v3z/mag
            end
        end

        idx_x = (p - UInt32(1)) * UInt32(3) + UInt32(1)
        idx_y = (p - UInt32(1)) * UInt32(3) + UInt32(2)
        idx_z = (p - UInt32(1)) * UInt32(3) + UInt32(3)

        dev_normals[idx_x] = nx
        dev_normals[idx_y] = ny
        dev_normals[idx_z] = nz
    end
end

@kernel function _kernel_compute_mitosis_normals_random!(
        dev_normals, dev_parents, dev_division_count, dims, step_counter)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        p = dev_parents[i]
        s = step_counter + UInt64(p)
        N = length(dims)

        if N == 2
            u1 = Float32(pcg_hash(s) >> 32) * UINT32_TO_FLOAT32
            theta = 2.0f0 * 3.14159265f0 * u1
            idx_x = (p - UInt32(1)) * UInt32(2) + UInt32(1)
            idx_y = (p - UInt32(1)) * UInt32(2) + UInt32(2)
            dev_normals[idx_x] = cos(theta)
            dev_normals[idx_y] = sin(theta)
        else
            u1 = Float32(pcg_hash(s) >> 32) * UINT32_TO_FLOAT32
            u2 = Float32(pcg_hash(s + UInt64(MITOSIS_SEED_OFFSET)) >> 32) * UINT32_TO_FLOAT32
            theta = 2.0f0 * 3.14159265f0 * u1
            phi = acos(1.0f0 - 2.0f0 * u2)

            idx_x = (p - UInt32(1)) * UInt32(3) + UInt32(1)
            idx_y = (p - UInt32(1)) * UInt32(3) + UInt32(2)
            idx_z = (p - UInt32(1)) * UInt32(3) + UInt32(3)
            dev_normals[idx_x] = sin(phi) * cos(theta)
            dev_normals[idx_y] = sin(phi) * sin(theta)
            dev_normals[idx_z] = cos(phi)
        end
    end
end

@kernel function _kernel_compute_mitosis_normals_vector!(
        dev_normals, dev_parents, dev_division_count, v_tuple, N)
    i = @index(Global, Linear)
    if i <= dev_division_count[1]
        p = dev_parents[i]
        for d in 1:N
            idx = (p - UInt32(1)) * UInt32(N) + UInt32(d)
            dev_normals[idx] = v_tuple[d]
        end
    end
end

@kernel function _kernel_populate_child_map!(dev_child_map, dev_parents, dev_children, dev_division_count)
    i = @index(Global, Linear)
    if i <= dev_division_count[1] && dev_children[i] > 0
        dev_child_map[dev_parents[i]] = dev_children[i]
    end
end

@kernel function _kernel_split_grid!(grid, dims, dev_is_dividing, dev_centroids,
        dev_normals, dev_is_modified, dev_child_map, topo)
    I = @index(Global, Linear)
    cell_id = grid[I]

    if cell_id > 0 && dev_is_dividing[cell_id]
        N = length(dims)
        coords = idx_to_coord(UInt32(I), dims)

        dot_val = 0.0f0
        for d in 1:N
            idx = (cell_id - UInt32(1)) * UInt32(N) + UInt32(d)

            dist = Float32(coords[d]) - dev_centroids[idx]
            dist = shortest_vector(topo, dist, Float32(dims[d]))
            dot_val += dist * dev_normals[idx]
        end

        if dot_val > 0.0f0
            grid[I] = dev_child_map[cell_id]
        end
    end
end

@kernel function _kernel_zero_modified_volumes!(volumes, dev_is_modified, dev_division_count)
    i = @index(Global, Linear)
    if i <= length(dev_is_modified)
        if dev_is_modified[i]
            volumes[i] = 0
        end
    end
end

@kernel function _kernel_zero_modified_surface_areas!(surface_areas, dev_is_modified, dev_division_count)
    i = @index(Global, Linear)
    if i <= length(dev_is_modified)
        if dev_is_modified[i]
            surface_areas[i] = 0
        end
    end
end

"""
    process_mitosis_events!(engine; trigger=VolumeThresholdTrigger(), orientation=RandomOrientation(), inheritance_rules)

Evaluates the `trigger` for all active cells. For any cell where the trigger is true, the cell 
is divided in half according to the geometric `orientation`. Properties are inherited by the new 
daughter cell according to `inheritance_rules`.
"""
function process_mitosis_events!(
        u::AbstractPottsState, p::PottsParameters, cache::PottsCache,
        ws::MitosisWorkspace; trigger = VolumeThresholdTrigger(),
        orientation::DivisionOrientation = RandomOrientation(),
        inheritance_rules::NamedTuple = NamedTuple(), deps = ())
    N = length(cache.grid_dims)
    backend = KernelAbstractions.get_backend(u.grid)
    max_cap = length(u.cell_data.volumes)

    ev_pop = populate_dividing_parents!(u, cache, trigger, ws, deps)

    k_alloc = _kernel_allocate_mitosis_ids!(backend, cache.block_size)
    ev_alloc = dispatch_kernel!(backend, k_alloc, ws.dev_children, u.free_list, u.free_list_count,
        u.N_cells, ws.dev_division_count, UInt32(max_cap); ndrange = max_cap)

    # Run Inherit Kernels
    ev_inh = ev_alloc
    for field in propertynames(u.cell_data)
        needs_inherit = haskey(inheritance_rules, field) || 
                        field in (:volumes, :target_volumes, :surface_areas, :target_surface_areas, :cell_types)
        if !needs_inherit
            continue
        end

        array = getproperty(u.cell_data, field)
        default_rule = field === :volumes ? Split(0.5f0) : Clone()
        rule = haskey(inheritance_rules, field) ? inheritance_rules[field] : default_rule

        ev_inh = apply_inheritance_rule!(rule, array, ws, max_cap, backend, cache, (ev_inh,))
    end

    k_fill = _fill_kernel!(backend, cache.block_size)
    ev_fdiv = dispatch_kernel!(backend, k_fill, ws.dev_is_dividing, false; ndrange = max_cap)
    
    k_div = _kernel_mark_is_dividing!(backend, cache.block_size)
    ev_div = dispatch_kernel!(backend, k_div, ws.dev_is_dividing, ws.dev_parents,
        ws.dev_division_count; ndrange = max_cap)

    ev_fcount = dispatch_kernel!(backend, k_fill, ws.acc_count, Int32(0); ndrange = max_cap)
    ev_fsin = dispatch_kernel!(backend, k_fill, ws.acc_sin, 0.0f0; ndrange = N * max_cap)
    ev_fcos = dispatch_kernel!(backend, k_fill, ws.acc_cos, 0.0f0; ndrange = N * max_cap)
    
    orientation_type = 0 # Random or Vector
    if orientation isa MajorAxisOrientation
        orientation_type = 1
    elseif orientation isa MinorAxisOrientation
        orientation_type = 2
    end
    do_cov = orientation_type > 0
    
    ev_prep = ev_fcos
    if do_cov
        cov_elements = div(N * (N + 1), 2)
        ev_prep = dispatch_kernel!(backend, k_fill, ws.acc_cov, 0.0f0;
            ndrange = cov_elements * max_cap)
    end

    # Pass 1: Accumulate Centroids
    k_acc = _kernel_accumulate_centroids_cov!(backend, cache.block_size)
    ev_acc = dispatch_kernel!(backend, k_acc, u.grid, cache.grid_dims, ws.dev_is_dividing, ws.acc_count, ws.acc_sin, ws.acc_cos,
        ws.acc_cov, ws.dev_centroids, false, p.topology, UInt32(max_cap),
        cache.sin_luts, cache.cos_luts;
        ndrange = length(u.grid))

    # Pass 1.5: Compute Centroids
    k_cen = _kernel_compute_centroids!(backend, cache.block_size)
    ev_cen = dispatch_kernel!(backend, k_cen, ws.dev_centroids, ws.acc_count, ws.acc_sin, ws.acc_cos, ws.dev_parents,
        ws.dev_division_count, cache.grid_dims; ndrange = max_cap)

    ev_norm = ev_cen
    if do_cov
        # Run accumulator again just for covariance now that centroids are exact
        ev_acc2 = dispatch_kernel!(backend, k_acc, u.grid, cache.grid_dims, ws.dev_is_dividing, ws.acc_count,
            ws.acc_sin, ws.acc_cos, ws.acc_cov, ws.dev_centroids,
            true, p.topology, UInt32(max_cap),
            cache.sin_luts, cache.cos_luts;
            ndrange = length(u.grid))

        # Run eigen
        if N == 2
            k_ang = _kernel_compute_mitosis_normals_2d!(backend, cache.block_size)
        else
            k_ang = _kernel_compute_mitosis_normals_3d!(backend, cache.block_size)
        end
        ev_norm = dispatch_kernel!(backend, k_ang, ws.dev_normals, ws.acc_cov, ws.dev_parents,
            ws.dev_division_count, orientation_type; ndrange = max_cap)
    elseif orientation isa RandomOrientation
        k_rand_norm = _kernel_compute_mitosis_normals_random!(backend, cache.block_size)
        ev_norm = dispatch_kernel!(backend, k_rand_norm, ws.dev_normals, ws.dev_parents, ws.dev_division_count,
            cache.grid_dims, cache.step_counter[]; ndrange = max_cap)
    elseif orientation isa VectorOrientation
        k_vec_norm = _kernel_compute_mitosis_normals_vector!(backend, cache.block_size)
        v_tuple = Tuple(Float32(x) for x in orientation.v)
        ev_norm = dispatch_kernel!(backend, k_vec_norm, ws.dev_normals, ws.dev_parents, ws.dev_division_count,
            v_tuple, N; ndrange = max_cap)
    end

    ev_fchild = dispatch_kernel!(backend, k_fill, ws.dev_child_map, UInt32(0); ndrange = max_cap)
    k_child_map = _kernel_populate_child_map!(backend, cache.block_size)
    ev_cmap = dispatch_kernel!(backend, k_child_map, ws.dev_child_map, ws.dev_parents, ws.dev_children,
        ws.dev_division_count; ndrange = max_cap)

    # Pass 2: Split Grid
    k_split = _kernel_split_grid!(backend, cache.block_size)
    ev_split = dispatch_kernel!(backend, k_split, u.grid, cache.grid_dims, ws.dev_is_dividing, ws.dev_centroids, ws.dev_normals,
        ws.dev_is_modified, ws.dev_child_map, p.topology; ndrange = length(u.grid))

    ev_fmod = dispatch_kernel!(backend, k_fill, ws.dev_is_modified, false; ndrange = max_cap)
    k_mod = _kernel_mark_is_modified!(backend, cache.block_size)
    ev_mod = dispatch_kernel!(backend, k_mod, ws.dev_is_modified, ws.dev_parents, ws.dev_children,
        ws.dev_division_count; ndrange = max_cap)

    ev_zero = ev_mod
    if hasproperty(u.cell_data, :volumes)
        k_zv = _kernel_zero_modified_volumes!(backend, cache.block_size)
        ev_zero = dispatch_kernel!(backend, k_zv, u.cell_data.volumes, ws.dev_is_modified,
            ws.dev_division_count; ndrange = max_cap)
    end
    if hasproperty(u.cell_data, :surface_areas)
        k_zsa = _kernel_zero_modified_surface_areas!(backend, cache.block_size)
        ev_zero = dispatch_kernel!(backend, k_zsa, u.cell_data.surface_areas,
            ws.dev_is_modified, ws.dev_division_count; ndrange = max_cap)
    end

    # Thread the final event into local metrics without a hard CPU synchronize stall
    update_local_all_metrics!(
        p.trackers, u.cell_data, u.grid, p.topology, cache.grid_dims, ws.dev_is_modified, ev_zero)
    return ev_zero
end
