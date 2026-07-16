const FOCAL_POINT_MIN_DIST = 1.0f-4

"""
    FocalPointSpringPenalty(lambdas, target_lengths, connectivity)

Models strong mechanical junctions (springs) between the centers of mass of specific cells.
Useful for modeling epithelial sheets or rigid tissue structures.
"""
struct FocalPointSpringPenalty{FloatT <: AbstractVector, MatrixT <: AbstractMatrix} <:
       AbstractPenalty{Rigid}
    lambdas::FloatT
    target_lengths::FloatT
    connectivity::MatrixT
end

"""
    HSTFocalPointPenalty(lambdas, connectivity)

A thermodynamically consistent (fluctuating force) version of the focal point spring.
"""
struct HSTFocalPointPenalty{FloatT <: AbstractVector, IntT <: AbstractMatrix, FType} <:
       AbstractPenalty{Rigid}
    lambdas::FloatT
    target_lengths::FloatT
    connectivity::IntT
    eta::FType
end
function HSTFocalPointPenalty(lambdas, target_lengths, connectivity; eta = 1.0)
    F = eltype(lambdas)
    return HSTFocalPointPenalty(lambdas, target_lengths, connectivity, convert(F, eta))
end

"""
    evaluate_penalty(p::Union{FocalPointSpringPenalty, HSTFocalPointPenalty}, ctx)

Evaluates the focal point spring penalty. 

Note: To avoid the severe performance penalty of calculating the exact quadratic center-of-mass shift 
and resolving `atan2` circular statistics for every proposed pixel flip on periodic boundaries, 
this function evaluates the energy using the *linearized auxiliary field approximation* 
(`Force * Δx`). The exact forces (and any HST stochastic noise) are computed once per cell 
during the sweep auxiliary step.
"""
@inline function evaluate_penalty(p::Union{FocalPointSpringPenalty, HSTFocalPointPenalty}, ctx)
    return _eval_focal_point(p, ctx, Val(length(ctx.grid_dims)))
end

@inline function _eval_focal_point(p, ctx, ::Val{2})
    F = eltype(p.lambdas)
    dH = zero(F)
    x, y = F(ctx.spatial_coords[1]), F(ctx.spatial_coords[2])
    W, H = F(ctx.grid_dims[1]), F(ctx.grid_dims[2])

    if ctx.tgt != 0
        Fx, Fy = F(ctx.cell_data.force_x[ctx.tgt]), F(ctx.cell_data.force_y[ctx.tgt])
        ax, ay = F(ctx.cell_data.anchor_x[ctx.tgt]), F(ctx.cell_data.anchor_y[ctx.tgt])
        V = F(ctx.cell_data.volumes[ctx.tgt])
        dx = F(shortest_vector(ctx.topology, x - ax, W))
        dy = F(shortest_vector(ctx.topology, y - ay, H))
        
        force_dot_dist = Fx * dx + Fy * dy
        dH -= -force_dot_dist / (V + one(F))
    end
    if ctx.src != 0
        Fx, Fy = F(ctx.cell_data.force_x[ctx.src]), F(ctx.cell_data.force_y[ctx.src])
        ax, ay = F(ctx.cell_data.anchor_x[ctx.src]), F(ctx.cell_data.anchor_y[ctx.src])
        V = F(ctx.cell_data.volumes[ctx.src])
        dx = F(shortest_vector(ctx.topology, x - ax, W))
        dy = F(shortest_vector(ctx.topology, y - ay, H))
        
        force_dot_dist = Fx * dx + Fy * dy
        dH += -force_dot_dist / (V + one(F))
    end
    return dH
end

@inline function _eval_focal_point(p, ctx, ::Val{3})
    F = eltype(p.lambdas)
    dH = zero(F)
    x, y, z = F(ctx.spatial_coords[1]), F(ctx.spatial_coords[2]), F(ctx.spatial_coords[3])
    W, H, D = F(ctx.grid_dims[1]), F(ctx.grid_dims[2]), F(ctx.grid_dims[3])

    if ctx.tgt != 0
        Fx, Fy, Fz = F(ctx.cell_data.force_x[ctx.tgt]), F(ctx.cell_data.force_y[ctx.tgt]), F(ctx.cell_data.force_z[ctx.tgt])
        ax, ay, az = F(ctx.cell_data.anchor_x[ctx.tgt]), F(ctx.cell_data.anchor_y[ctx.tgt]), F(ctx.cell_data.anchor_z[ctx.tgt])
        V = F(ctx.cell_data.volumes[ctx.tgt])
        dx = F(shortest_vector(ctx.topology, x - ax, W))
        dy = F(shortest_vector(ctx.topology, y - ay, H))
        dz = F(shortest_vector(ctx.topology, z - az, D))
        
        force_dot_dist = Fx * dx + Fy * dy + Fz * dz
        
        dH += -force_dot_dist / (V + one(F))
    end
    if ctx.src != 0
        Fx, Fy = F(ctx.cell_data.force_x[ctx.src]), F(ctx.cell_data.force_y[ctx.src])
        ax, ay = F(ctx.cell_data.anchor_x[ctx.src]), F(ctx.cell_data.anchor_y[ctx.src])
        V = F(ctx.cell_data.volumes[ctx.src])
        dx = F(shortest_vector(ctx.topology, x - ax, W))
        dy = F(shortest_vector(ctx.topology, y - ay, H))
        
        force_dot_dist = Fx * dx + Fy * dy
        dH += -force_dot_dist / (V + one(F))
    end
    if ctx.src != 0
        Fx, Fy, Fz = F(ctx.cell_data.force_x[ctx.src]), F(ctx.cell_data.force_y[ctx.src]), F(ctx.cell_data.force_z[ctx.src])
        ax, ay, az = F(ctx.cell_data.anchor_x[ctx.src]), F(ctx.cell_data.anchor_y[ctx.src]), F(ctx.cell_data.anchor_z[ctx.src])
        V = F(ctx.cell_data.volumes[ctx.src])
        dx = F(shortest_vector(ctx.topology, x - ax, W))
        dy = F(shortest_vector(ctx.topology, y - ay, H))
        dz = F(shortest_vector(ctx.topology, z - az, D))
        
        force_dot_dist = Fx * dx + Fy * dy + Fz * dz
        
        dH -= -force_dot_dist / (V + one(F))
    end
    return dH
end

@kernel function _grid_accumulate_com_kernel!(
        grid, grid_dims, acc_sin_x, acc_cos_x, acc_sin_y, acc_cos_y, acc_sin_z,
        acc_cos_z, sin_luts, cos_luts)
    idx = @index(Global, Linear)
    if idx <= length(grid)
        cell_id = grid[idx]
        if cell_id > 0
            F = eltype(acc_sin_x)
            W, H = F(grid_dims[1]), F(grid_dims[2])
            coords = idx_to_coord(UInt32(idx), grid_dims)
            c_x = F(coords[1])
            c_y = F(coords[2])

            Atomix.@atomic acc_sin_x[cell_id] += sin_luts[1][Int(c_x) + 1]
            Atomix.@atomic acc_cos_x[cell_id] += cos_luts[1][Int(c_x) + 1]
            Atomix.@atomic acc_sin_y[cell_id] += sin_luts[2][Int(c_y) + 1]
            Atomix.@atomic acc_cos_y[cell_id] += cos_luts[2][Int(c_y) + 1]

            if length(grid_dims) == 3
                D = F(grid_dims[3])
                c_z = F(coords[3])
                Atomix.@atomic acc_sin_z[cell_id] += sin_luts[3][Int(c_z) + 1]
                Atomix.@atomic acc_cos_z[cell_id] += cos_luts[3][Int(c_z) + 1]
            end
        end
    end
end

@kernel function _cell_normalize_com_kernel!(
        anchors_x, anchors_y, anchors_z, acc_sin_x, acc_cos_x,
        acc_sin_y, acc_cos_y, acc_sin_z, acc_cos_z, vols, grid_dims)
    my_cell_id = @index(Global, Linear)
    if my_cell_id <= length(vols)
        F = eltype(anchors_x)
        V = F(vols[my_cell_id])
        if V > zero(F)
            W, H = F(grid_dims[1]), F(grid_dims[2])
            ax = (W / (F(2.0) * F(pi))) * atan(acc_sin_x[my_cell_id], acc_cos_x[my_cell_id])
            ay = (H / (F(2.0) * F(pi))) * atan(acc_sin_y[my_cell_id], acc_cos_y[my_cell_id])

            ax = ax < zero(F) ? ax + W : ax
            ay = ay < zero(F) ? ay + H : ay

            anchors_x[my_cell_id] = ax
            anchors_y[my_cell_id] = ay

            if length(grid_dims) == 3
                D = F(grid_dims[3])
                az = (D / (F(2.0) * F(pi))) *
                     atan(acc_sin_z[my_cell_id], acc_cos_z[my_cell_id])
                az = az < zero(F) ? az + D : az
                anchors_z[my_cell_id] = az
            end
        end
    end
end

@kernel function _compute_forces_kernel!(
        anchors_x, anchors_y, anchors_z, forces_x, forces_y, forces_z, vols, ctypes,
        connectivity, lambdas, target_lengths, grid_dims, topo)
    my_cell_id = @index(Global, Linear)

    if my_cell_id <= length(vols)
        F = eltype(forces_x)
        V = F(vols[my_cell_id])
        if V > zero(F)
            W, H = F(grid_dims[1]), F(grid_dims[2])
            is_3d = length(grid_dims) == 3
            D = is_3d ? F(grid_dims[3]) : zero(F)
            my_type = ctypes[my_cell_id]
            ax = anchors_x[my_cell_id]
            ay = anchors_y[my_cell_id]
            az = is_3d ? anchors_z[my_cell_id] : zero(F)

            Fx, Fy, Fz = zero(F), zero(F), zero(F)

            for other_id in 1:size(connectivity, 2)
                if connectivity[my_cell_id, other_id] > 0
                    if vols[other_id] > 0
                        o_ax = anchors_x[other_id]
                        o_ay = anchors_y[other_id]

                        dx = F(shortest_vector(topo, o_ax - ax, W))
                        dy = F(shortest_vector(topo, o_ay - ay, H))
                        
                        dist_sq = dx^2 + dy^2
                        dz = zero(F)
                        if is_3d
                            o_az = anchors_z[other_id]
                            dz = F(shortest_vector(topo, o_az - az, D))
                            dist_sq += dz^2
                        end

                        dist = sqrt(dist_sq)

                        if dist > FOCAL_POINT_MIN_DIST
                            mag = F(lambdas[my_type + 1]) *
                                  (dist - F(target_lengths[my_type + 1]))
                            Fx += mag * (dx / dist)
                            Fy += mag * (dy / dist)
                            if is_3d
                                Fz += mag * (dz / dist)
                            end
                        end
                    end
                end
            end
            forces_x[my_cell_id] = Fx
            forces_y[my_cell_id] = Fy
            if is_3d
                forces_z[my_cell_id] = Fz
            end
        end
    end
end

function update_sweep_auxiliary!(pen::FocalPointSpringPenalty, u::AbstractPottsState,
        p::PottsParameters, cache::PottsCache, T_val, dt)
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    N = length(u.cell_data.volumes)

    F = eltype(u.cell_data.com_acc_sin_x)
    fill!(u.cell_data.com_acc_sin_x, zero(F))
    fill!(u.cell_data.com_acc_cos_x, zero(F))
    fill!(u.cell_data.com_acc_sin_y, zero(F))
    fill!(u.cell_data.com_acc_cos_y, zero(F))
    fill!(u.cell_data.com_acc_sin_z, zero(F))
    fill!(u.cell_data.com_acc_cos_z, zero(F))

    k_grid = _grid_accumulate_com_kernel!(backend, cache.block_size)
    k_grid(u.grid, cache.grid_dims, u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y, u.cell_data.com_acc_sin_z,
        u.cell_data.com_acc_cos_z, cache.sin_luts, cache.cos_luts, ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)

    k_cell = _cell_normalize_com_kernel!(backend, cache.block_size)
    k_cell(u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y, u.cell_data.com_acc_sin_z,
        u.cell_data.com_acc_cos_z, u.cell_data.volumes, cache.grid_dims, ndrange = N)
    KernelAbstractions.synchronize(backend)

    k2 = _compute_forces_kernel!(backend, cache.block_size)
    k2(u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.force_x, u.cell_data.force_y, u.cell_data.force_z,
        u.cell_data.volumes, u.cell_data.cell_types, pen.connectivity,
        pen.lambdas, pen.target_lengths, cache.grid_dims, p.topology, ndrange = N)
    KernelAbstractions.synchronize(backend)
end


@kernel function _compute_hst_forces_kernel!(
        anchors_x, anchors_y, anchors_z, forces_x, forces_y, forces_z, vols, ctypes, connectivity,
        lambdas, target_lengths, eta, T_val, seed, dt, grid_dims, topo)
    my_cell_id = @index(Global, Linear)

    if my_cell_id <= length(vols)
        F = eltype(forces_x)
        V = F(vols[my_cell_id])
        if V > zero(F)
            W, H = F(grid_dims[1]), F(grid_dims[2])
            is_3d = length(grid_dims) == 3
            D = is_3d ? F(grid_dims[3]) : zero(F)
            my_type = ctypes[my_cell_id]
            ax = anchors_x[my_cell_id]
            ay = anchors_y[my_cell_id]
            az = is_3d ? anchors_z[my_cell_id] : zero(F)

            mean_Fx, mean_Fy, mean_Fz = zero(F), zero(F), zero(F)

            for other_id in 1:size(connectivity, 2)
                if connectivity[my_cell_id, other_id] > 0
                    if vols[other_id] > 0
                        o_ax = anchors_x[other_id]
                        o_ay = anchors_y[other_id]

                        dx = F(shortest_vector(topo, o_ax - ax, W))
                        dy = F(shortest_vector(topo, o_ay - ay, H))
                        
                        dist_sq = dx^2 + dy^2
                        dz = zero(F)
                        if is_3d
                            o_az = anchors_z[other_id]
                            dz = F(shortest_vector(topo, o_az - az, D))
                            dist_sq += dz^2
                        end

                        dist = sqrt(dist_sq)

                        if dist > F(0.0001)
                            mag = F(lambdas[my_type + 1]) *
                                  (dist - F(target_lengths[my_type + 1]))
                            
                            mean_Fx += mag * (dx / dist)
                            mean_Fy += mag * (dy / dist)
                            if is_3d
                                mean_Fz += mag * (dz / dist)
                            end
                        end
                    end
                end
            end

            # SDE Integration (Ornstein-Uhlenbeck)
            lam = F(lambdas[my_type + 1])
            alpha = exp(-eta * dt)
            noise_std = sqrt(max(zero(F), F(2.0) * lam * F(T_val) * (one(F) - alpha^2)))

            # Generate independent noise
            noise_x = noise_std * F(randn_pcg(seed + UInt64(my_cell_id), seed +
                                                             UInt64(my_cell_id + 11111)))
            noise_y = noise_std * F(randn_pcg(seed + UInt64(my_cell_id), seed +
                                                             UInt64(my_cell_id + 22222)))

            forces_x[my_cell_id] = alpha * forces_x[my_cell_id] +
                                   (one(F) - alpha) * mean_Fx + noise_x
            forces_y[my_cell_id] = alpha * forces_y[my_cell_id] +
                                   (one(F) - alpha) * mean_Fy + noise_y
                                   
            if is_3d
                noise_z = noise_std * F(randn_pcg(seed + UInt64(my_cell_id), seed +
                                                                 UInt64(my_cell_id + 33333)))
                forces_z[my_cell_id] = alpha * forces_z[my_cell_id] +
                                       (one(F) - alpha) * mean_Fz + noise_z
            end
        end
    end
end

function update_sweep_auxiliary!(pen::HSTFocalPointPenalty, u::AbstractPottsState,
        p::PottsParameters, cache::PottsCache, T_val, dt)
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    N = length(u.cell_data.volumes)
    seed = pcg_hash(cache.step_counter[] + UInt64(54321))

    F = eltype(u.cell_data.com_acc_sin_x)
    fill!(u.cell_data.com_acc_sin_x, zero(F))
    fill!(u.cell_data.com_acc_cos_x, zero(F))
    fill!(u.cell_data.com_acc_sin_y, zero(F))
    fill!(u.cell_data.com_acc_cos_y, zero(F))
    fill!(u.cell_data.com_acc_sin_z, zero(F))
    fill!(u.cell_data.com_acc_cos_z, zero(F))

    k_grid = _grid_accumulate_com_kernel!(backend, cache.block_size)
    k_grid(u.grid, cache.grid_dims, u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y, u.cell_data.com_acc_sin_z,
        u.cell_data.com_acc_cos_z, cache.sin_luts, cache.cos_luts, ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)

    k_cell = _cell_normalize_com_kernel!(backend, cache.block_size)
    k_cell(u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y, u.cell_data.com_acc_sin_z,
        u.cell_data.com_acc_cos_z, u.cell_data.volumes, cache.grid_dims, ndrange = N)
    KernelAbstractions.synchronize(backend)

    k2 = _compute_hst_forces_kernel!(backend, cache.block_size)
    k2(u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.force_x, u.cell_data.force_y, u.cell_data.force_z,
        u.cell_data.volumes, u.cell_data.cell_types,
        pen.connectivity, pen.lambdas, pen.target_lengths, pen.eta,
        T_val, seed, dt, cache.grid_dims, p.topology, ndrange = N)
    KernelAbstractions.synchronize(backend)
end

required_variables(::FocalPointSpringPenalty) = (
    force_x = Float32, force_y = Float32, force_z = Float32,
    anchor_x = Float32, anchor_y = Float32, anchor_z = Float32,
    com_acc_sin_x = Float32, com_acc_cos_x = Float32,
    com_acc_sin_y = Float32, com_acc_cos_y = Float32,
    com_acc_sin_z = Float32, com_acc_cos_z = Float32
)

required_variables(::HSTFocalPointPenalty) = (
    force_x = Float32, force_y = Float32, force_z = Float32,
    anchor_x = Float32, anchor_y = Float32, anchor_z = Float32,
    com_acc_sin_x = Float32, com_acc_cos_x = Float32,
    com_acc_sin_y = Float32, com_acc_cos_y = Float32,
    com_acc_sin_z = Float32, com_acc_cos_z = Float32
)
