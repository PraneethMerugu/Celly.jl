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

@kernel function _kernel_check_mitosis_triggers!(
        dev_parents, dev_division_count, N_cells, cell_volumes, cell_targets, multiplier)
    i = @index(Global, Linear)
    if i <= N_cells
        vol = cell_volumes[i]
        tgt = cell_targets[i]
        if tgt > 0 && vol >= ctx.tgt * multiplier && vol > 0
            idx = Atomix.@atomic dev_division_count[1] += UInt32(1)
            dev_parents[idx] = UInt32(i)
        end
    end
end

@kernel function _kernel_mark_is_dividing!(dev_is_dividing, dev_parents, count)
    i = @index(Global, Linear)
    if i <= count
        dev_is_dividing[dev_parents[i]] = true
    end
end

@kernel function _kernel_allocate_mitosis_ids!(
        dev_children, free_list, free_list_count, N_cells, count)
    i = @index(Global, Linear)
    if i <= count
        # Attempt to get an ID from the free list (new_count is the value AFTER subtraction)
        new_count = Atomix.@atomic free_list_count[1] -= Int32(1)
        if new_count >= 0
            # We successfully claimed a slot
            dev_children[i] = free_list[new_count + 1]
        else
            # We must restore the count (since it went negative) and get a new ID from N_cells
            Atomix.@atomic free_list_count[1] += Int32(1)
            new_id = Atomix.@atomic N_cells[1] += Int32(1)
            dev_children[i] = UInt32(new_id)
        end
    end
end

@kernel function _kernel_mark_is_modified!(dev_is_modified, dev_parents, dev_children, count)
    i = @index(Global, Linear)
    if i <= count
        dev_is_modified[dev_parents[i]] = true
        dev_is_modified[dev_children[i]] = true
    end
end

@kernel function _kernel_inherit_clone!(array, dev_parents, dev_children, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]
        array[c] = array[p]
    end
end

@inline safe_convert(::Type{T}, x::Float32) where {T <: Signed} = Core.Intrinsics.fptosi(T, x +
                                                                                            0.5f0)
@inline safe_convert(::Type{T}, x::Float32) where {T <: Unsigned} = Core.Intrinsics.fptoui(
    T, x + 0.5f0)
@inline safe_convert(::Type{T}, x::Float32) where {T <: AbstractFloat} = T(x)
@inline safe_convert(::Type{T}, x::T) where {T} = x
@inline safe_convert(::Type{T}, x) where {T} = T(x)

@kernel function _kernel_inherit_split!(array, dev_parents, dev_children, fraction, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]
        val = Float32(array[p])
        array[c] = safe_convert(eltype(array), val * fraction)
        array[p] = safe_convert(eltype(array), val * (1.0f0 - fraction))
    end
end

@kernel function _kernel_inherit_reset!(array, dev_parents, dev_children, value, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]
        val = safe_convert(eltype(array), Float32(value))
        array[p] = val
        array[c] = val
    end
end

@kernel function _kernel_inherit_asymmetric_reset!(
        array, dev_parents, dev_children, p_val, c_val, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]
        array[p] = safe_convert(eltype(array), Float32(p_val))
        array[c] = safe_convert(eltype(array), Float32(c_val))
    end
end

@kernel function _kernel_inherit_reset_child!(
        array, dev_parents, dev_children, value, count)
    i = @index(Global, Linear)
    if i <= count
        c = dev_children[i]
        array[c] = safe_convert(eltype(array), Float32(value))
    end
end

@kernel function _kernel_inherit_add!(array, dev_parents, dev_children, value, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]
        val = Float32(value)
        array[p] = safe_convert(eltype(array), Float32(array[p]) + val)
        array[c] = safe_convert(eltype(array), Float32(array[c]) + val)
    end
end

@kernel function _kernel_inherit_multiply!(array, dev_parents, dev_children, value, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]
        val = Float32(value)
        array[p] = safe_convert(eltype(array), Float32(array[p]) * val)
        array[c] = safe_convert(eltype(array), Float32(array[c]) * val)
    end
end

@kernel function _kernel_inherit_random_uniform!(
        array, dev_parents, dev_children, min_val, max_val, step, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]

        s_p = step + UInt64(p)
        r_p = Float32(pcg_hash(s_p) >> 32) * 2.3283064f-10
        val_p = Float32(min_val) + r_p * Float32(max_val - min_val)

        s_c = step + UInt64(c)
        r_c = Float32(pcg_hash(s_c) >> 32) * 2.3283064f-10
        val_c = Float32(min_val) + r_c * Float32(max_val - min_val)

        array[p] = safe_convert(eltype(array), val_p)
        array[c] = safe_convert(eltype(array), val_c)
    end
end

@kernel function _kernel_inherit_random_normal!(
        array, dev_parents, dev_children, mean_val, std_val, step, count)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        c = dev_children[i]

        s_p1 = step + UInt64(p)
        s_p2 = s_p1 + 9999991
        u1_p = Float32(pcg_hash(s_p1) >> 32) * 2.3283064f-10 + 1.0f-7
        u2_p = Float32(pcg_hash(s_p2) >> 32) * 2.3283064f-10
        z_p = sqrt(-2.0f0 * log(u1_p)) * cos(2.0f0 * 3.14159265f0 * u2_p)
        val_p = Float32(mean_val) + z_p * Float32(std_val)

        s_c1 = step + UInt64(c)
        s_c2 = s_c1 + 9999991
        u1_c = Float32(pcg_hash(s_c1) >> 32) * 2.3283064f-10 + 1.0f-7
        u2_c = Float32(pcg_hash(s_c2) >> 32) * 2.3283064f-10
        z_c = sqrt(-2.0f0 * log(u1_c)) * cos(2.0f0 * 3.14159265f0 * u2_c)
        val_c = Float32(mean_val) + z_c * Float32(std_val)

        array[p] = safe_convert(eltype(array), val_p)
        array[c] = safe_convert(eltype(array), val_c)
    end
end

function apply_inheritance_rule!(rule::Clone, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_clone!(backend, cache.block_size)
    k_inh(array, ws.dev_parents, ws.dev_children, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::Split, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_split!(backend, cache.block_size)
    k_inh(array, ws.dev_parents, ws.dev_children,
        rule.fraction, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::Reset, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_reset!(backend, cache.block_size)
    k_inh(
        array, ws.dev_parents, ws.dev_children, rule.value, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::AsymmetricReset, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_asymmetric_reset!(backend, cache.block_size)
    k_inh(array, ws.dev_parents, ws.dev_children, rule.parent_value,
        rule.child_value, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::ResetChild, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_reset_child!(backend, cache.block_size)
    k_inh(
        array, ws.dev_parents, ws.dev_children, rule.value, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::InheritAdd, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_add!(backend, cache.block_size)
    k_inh(
        array, ws.dev_parents, ws.dev_children, rule.value, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::InheritMultiply, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_multiply!(backend, cache.block_size)
    k_inh(
        array, ws.dev_parents, ws.dev_children, rule.value, UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::RandomUniform, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_random_uniform!(backend, cache.block_size)
    k_inh(array, ws.dev_parents, ws.dev_children, rule.min, rule.max,
        cache.step_counter[], UInt32(count), ndrange = count)
end

function apply_inheritance_rule!(rule::RandomNormal, array, ws, count, backend, cache)
    k_inh = _kernel_inherit_random_normal!(backend, cache.block_size)
    k_inh(array, ws.dev_parents, ws.dev_children, rule.mean, rule.std,
        cache.step_counter[], UInt32(count), ndrange = count)
end

function populate_dividing_parents!(u::AbstractPottsState, cache::PottsCache, trigger, ws)
    fill!(ws.dev_division_count, UInt32(0))
    backend = KernelAbstractions.get_backend(u.grid)
    kernel = _kernel_check_generic_triggers!(backend, cache.block_size)
    max_cap = UInt32(length(ws.dev_parents))
    N = Int(Array(u.N_cells)[])
    kernel(ws.dev_parents, ws.dev_division_count, UInt32(N),
        u.cell_data, trigger, max_cap, ndrange = N)
    KernelAbstractions.synchronize(backend)

    count_arr = Array(ws.dev_division_count)
    return min(Int(count_arr[1]), Int(max_cap))
end

@kernel function _kernel_accumulate_centroids_cov!(
        grid, dims, dev_is_dividing, acc_count, acc_sin, acc_cos,
        acc_cov, dev_centroids, do_cov, topo, max_capacity)
    I = @index(Global, Linear)
    cell_id = grid[I]

    if cell_id > 0 && cell_id <= max_capacity && dev_is_dividing[cell_id]
        coords = idx_to_coord(UInt32(I), dims)
        N = length(dims)

        Atomix.@atomic acc_count[cell_id] += Int32(1)

        for d in 1:N
            theta = (Float32(coords[d]) / Float32(dims[d])) * 2.0f0 * Float32(pi)
            sin_val = sin(theta)
            cos_val = cos(theta)

            idx = (cell_id - UInt32(1)) * UInt32(N) + UInt32(d)
            Atomix.@atomic acc_sin[idx] += sin_val
            Atomix.@atomic acc_cos[idx] += cos_val
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
        dev_centroids, acc_count, acc_sin, acc_cos, dev_parents, count, dims)
    i = @index(Global, Linear)
    if i <= count
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

@kernel function _kernel_compute_mitosis_normals_2d!(
        dev_normals, acc_cov, dev_parents, count, orientation_type)
    i = @index(Global, Linear)
    if i <= count
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

        vx_maj, vy_maj = 0.0f0, 0.0f0
        if abs(cxy) > 1.0f-6
            vx_maj = l1 - cyy
            vy_maj = cxy
        else
            if cxx >= cyy
                vx_maj = 1.0f0;
                vy_maj = 0.0f0
            else
                vx_maj = 0.0f0;
                vy_maj = 1.0f0
            end
        end

        vx_min, vy_min = 0.0f0, 0.0f0
        if abs(cxy) > 1.0f-6
            vx_min = l2 - cyy
            vy_min = cxy
        else
            if cxx < cyy
                vx_min = 1.0f0;
                vy_min = 0.0f0
            else
                vx_min = 0.0f0;
                vy_min = 1.0f0
            end
        end

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
        dev_normals, acc_cov, dev_parents, count, orientation_type)
    i = @index(Global, Linear)
    if i <= count
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
        dev_normals, dev_parents, count, dims, step_counter)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]
        N = length(dims)

        # Use pcg_hash for deterministic random numbers on GPU
        seed = step_counter + UInt64(p)

        if N == 2
            v1 = randn_pcg(seed, seed + UInt64(1))
            v2 = randn_pcg(seed + UInt64(2), seed + UInt64(3))

            mag = max(1.0f-12, sqrt(v1^2 + v2^2))

            idx_x = (p - UInt32(1)) * UInt32(2) + UInt32(1)
            idx_y = (p - UInt32(1)) * UInt32(2) + UInt32(2)

            dev_normals[idx_x] = v1 / mag
            dev_normals[idx_y] = v2 / mag
        else
            v1 = randn_pcg(seed, seed + UInt64(1))
            v2 = randn_pcg(seed + UInt64(2), seed + UInt64(3))
            v3 = randn_pcg(seed + UInt64(4), seed + UInt64(5))

            mag = max(1.0f-12, sqrt(v1^2 + v2^2 + v3^2))

            idx_x = (p - UInt32(1)) * UInt32(3) + UInt32(1)
            idx_y = (p - UInt32(1)) * UInt32(3) + UInt32(2)
            idx_z = (p - UInt32(1)) * UInt32(3) + UInt32(3)

            dev_normals[idx_x] = v1 / mag
            dev_normals[idx_y] = v2 / mag
            dev_normals[idx_z] = v3 / mag
        end
    end
end

@kernel function _kernel_compute_mitosis_normals_vector!(
        dev_normals, dev_parents, count, v_tuple, N)
    i = @index(Global, Linear)
    if i <= count
        p = dev_parents[i]

        mag_sq = 0.0f0
        for d in 1:N
            mag_sq += v_tuple[d]^2
        end
        mag = max(1.0f-12, sqrt(mag_sq))

        for d in 1:N
            idx = (p - UInt32(1)) * UInt32(N) + UInt32(d)
            dev_normals[idx] = v_tuple[d] / mag
        end
    end
end

@kernel function _kernel_populate_child_map!(dev_child_map, dev_parents, dev_children, count)
    i = @index(Global, Linear)
    if i <= count
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

@kernel function _kernel_zero_modified_volumes!(volumes, dev_is_modified, count)
    i = @index(Global, Linear)
    if i <= count && dev_is_modified[i]
        volumes[i] = Int32(0)
    end
end

@kernel function _kernel_zero_modified_surface_areas!(surface_areas, dev_is_modified, count)
    i = @index(Global, Linear)
    if i <= count && dev_is_modified[i]
        surface_areas[i] = Int32(0)
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
        inheritance_rules::NamedTuple = NamedTuple())
    N = length(cache.grid_dims)
    backend = KernelAbstractions.get_backend(u.grid)

    num_divisions = populate_dividing_parents!(u, cache, trigger, ws)
    if num_divisions == 0
        return
    end

    current_free = Array(u.free_list_count)[1]
    current_N = Array(u.N_cells)[1]
    available_slots = current_free + (length(u.cell_data.volumes) - current_N)
    if available_slots < num_divisions
        error("Capacity exceeded! Max cells reached. Pre-allocate a larger cell_data array.")
    end

    k_alloc = _kernel_allocate_mitosis_ids!(backend, cache.block_size)
    k_alloc(ws.dev_children, u.free_list, u.free_list_count,
        u.N_cells, UInt32(num_divisions), ndrange = num_divisions)
    KernelAbstractions.synchronize(backend)

    # Run Inherit Kernels
    for field in propertynames(u.cell_data)
        array = getproperty(u.cell_data, field)
        default_rule = field === :volumes ? Split(0.5f0) : Clone()
        rule = haskey(inheritance_rules, field) ? inheritance_rules[field] : default_rule

        apply_inheritance_rule!(rule, array, ws, num_divisions, backend, cache)
    end
    KernelAbstractions.synchronize(backend)

    # Mark is_dividing
    fill!(ws.dev_is_dividing, false)
    k_div = _kernel_mark_is_dividing!(backend, cache.block_size)
    k_div(ws.dev_is_dividing, ws.dev_parents, UInt32(num_divisions), ndrange = num_divisions)

    fill!(ws.acc_count, Int32(0))
    fill!(ws.acc_sin, 0.0f0)
    fill!(ws.acc_cos, 0.0f0)

    orientation_type = 0 # Random or Vector
    if orientation isa MajorAxisOrientation
        orientation_type = 1
    elseif orientation isa MinorAxisOrientation
        orientation_type = 2
    end
    do_cov = orientation_type > 0
    if do_cov
        fill!(ws.acc_cov, 0.0f0)
    end

    # Pass 1: Accumulate Centroids
    max_cap = UInt32(length(ws.dev_parents))
    k_acc = _kernel_accumulate_centroids_cov!(backend, cache.block_size)
    k_acc(
        u.grid, cache.grid_dims, ws.dev_is_dividing, ws.acc_count, ws.acc_sin, ws.acc_cos,
        ws.acc_cov, ws.dev_centroids, false, p.topology, max_cap, ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)

    # Pass 1.5: Compute Centroids
    k_cen = _kernel_compute_centroids!(backend, cache.block_size)
    k_cen(ws.dev_centroids, ws.acc_count, ws.acc_sin, ws.acc_cos, ws.dev_parents,
        UInt32(num_divisions), cache.grid_dims, ndrange = num_divisions)
    KernelAbstractions.synchronize(backend)

    if do_cov
        # Run accumulator again just for covariance now that centroids are exact
        k_acc(u.grid, cache.grid_dims, ws.dev_is_dividing, ws.acc_count,
            ws.acc_sin, ws.acc_cos, ws.acc_cov, ws.dev_centroids,
            true, p.topology, max_cap, ndrange = length(u.grid))
        KernelAbstractions.synchronize(backend)

        # Run eigen
        if N == 2
            k_ang = _kernel_compute_mitosis_normals_2d!(backend, cache.block_size)
        else
            k_ang = _kernel_compute_mitosis_normals_3d!(backend, cache.block_size)
        end
        k_ang(ws.dev_normals, ws.acc_cov, ws.dev_parents,
            UInt32(num_divisions), orientation_type, ndrange = num_divisions)
        KernelAbstractions.synchronize(backend)
    elseif orientation isa RandomOrientation
        k_rand_norm = _kernel_compute_mitosis_normals_random!(backend, cache.block_size)
        k_rand_norm(ws.dev_normals, ws.dev_parents, UInt32(num_divisions),
            cache.grid_dims, cache.step_counter[], ndrange = num_divisions)
        KernelAbstractions.synchronize(backend)
    elseif orientation isa VectorOrientation
        k_vec_norm = _kernel_compute_mitosis_normals_vector!(backend, cache.block_size)
        v_tuple = Tuple(Float32(x) for x in orientation.v)
        k_vec_norm(ws.dev_normals, ws.dev_parents, UInt32(num_divisions),
            v_tuple, N, ndrange = num_divisions)
        KernelAbstractions.synchronize(backend)
    end

    # Populate dev_child_map using preallocated workspace and GPU kernel
    fill!(ws.dev_child_map, UInt32(0))
    k_child_map = _kernel_populate_child_map!(backend, cache.block_size)
    k_child_map(ws.dev_child_map, ws.dev_parents, ws.dev_children,
        UInt32(num_divisions), ndrange = num_divisions)
    KernelAbstractions.synchronize(backend)

    # Pass 2: Split Grid
    k_split = _kernel_split_grid!(backend, cache.block_size)
    k_split(u.grid, cache.grid_dims, ws.dev_is_dividing, ws.dev_centroids, ws.dev_normals,
        ws.dev_is_modified, ws.dev_child_map, p.topology, ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)

    # Mark modified cells
    fill!(ws.dev_is_modified, false)
    k_mod = _kernel_mark_is_modified!(backend, cache.block_size)
    k_mod(ws.dev_is_modified, ws.dev_parents, ws.dev_children,
        UInt32(num_divisions), ndrange = num_divisions)
    KernelAbstractions.synchronize(backend)

    # Local targeted recalculation!
    # Zero out parents and children
    if hasproperty(u.cell_data, :volumes)
        k_zv = _kernel_zero_modified_volumes!(backend, cache.block_size)
        k_zv(u.cell_data.volumes, ws.dev_is_modified,
            UInt32(length(ws.dev_is_modified)), ndrange = length(ws.dev_is_modified))
    end
    if hasproperty(u.cell_data, :surface_areas)
        k_zsa = _kernel_zero_modified_surface_areas!(backend, cache.block_size)
        k_zsa(u.cell_data.surface_areas, ws.dev_is_modified,
            UInt32(length(ws.dev_is_modified)), ndrange = length(ws.dev_is_modified))
    end
    KernelAbstractions.synchronize(backend)

    update_local_all_metrics!(
        p.trackers, u.cell_data, u.grid, p.topology, cache.grid_dims, ws.dev_is_modified)
end

function MitosisCallback(
        trigger = VolumeThresholdTrigger(); orientation = RandomOrientation(),
        inheritance_rules = NamedTuple(), max_cells = nothing)
    ws_ref = Ref{MitosisWorkspace}()

    condition(u, t, integrator) = true
    function affect!(integrator)
        if !isassigned(ws_ref)
            max_c = max_cells === nothing ? length(integrator.u.cell_data.volumes) :
                    max_cells
            ws_ref[] = MitosisWorkspace(integrator.u.grid, max_c)
        end
        process_mitosis_events!(
            integrator.u, integrator.p, integrator.cache, ws_ref[]; trigger = ctx.trigger,
            orientation = orientation, inheritance_rules = inheritance_rules)
    end

    return SciMLBase.DiscreteCallback(condition, affect!)
end
