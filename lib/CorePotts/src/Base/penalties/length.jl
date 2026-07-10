"""
    HSTLengthPenalty(lambdas)

Constrains the major axis length of a cell, inducing elongation and polarity.
"""
struct HSTLengthPenalty{FlexType <: FlexibilityTrait, FloatT <: AbstractVector, FType} <:
       AbstractHSTPenalty{FlexType}
    lambdas::FloatT
    eta::FType
end
function HSTLengthPenalty{Rigid}(lambdas; eta = 1.0)
    F = eltype(lambdas)
    return HSTLengthPenalty{Rigid, typeof(lambdas), F}(lambdas, convert(F, eta))
end
function HSTLengthPenalty{Rigid}(lambdas, eta)
    return HSTLengthPenalty{Rigid}(lambdas; eta = eta)
end
function HSTLengthPenalty(lambdas; eta = 1.0)
    return HSTLengthPenalty{Rigid}(lambdas; eta = eta)
end
function HSTLengthPenalty(lambdas, eta)
    return HSTLengthPenalty{Rigid}(lambdas; eta = eta)
end
function HSTLengthPenalty{Flex}(; eta = 1.0, FloatType = Float32)
    F = convert(FloatType, eta)
    return HSTLengthPenalty{Flex, Vector{FloatType}, typeof(F)}(FloatType[], F)
end

# ConstructionBase Overloads
function ConstructionBase.constructorof(::Type{<:HSTLengthPenalty{Trait}}) where {Trait}
    HSTLengthPenalty{Trait}
end
function HSTLengthPenalty{Trait}(lambdas, eta) where {Trait}
    HSTLengthPenalty{Trait, typeof(lambdas), typeof(eta)}(lambdas, eta)
end

function HSTLengthPenalty{Flex}(eta)
    return HSTLengthPenalty{Flex}(; eta = eta)
end

lambda_field(::HSTLengthPenalty) = Val{:length_lambdas}()
hst_state_field(::HSTLengthPenalty) = Val{:length_pressures}()
hst_value_field(::HSTLengthPenalty) = Val{:current_lengths}()
hst_target_field(::HSTLengthPenalty) = Val{:target_lengths}()

@inline function evaluate_penalty(p::HSTLengthPenalty, ctx)
    F = eltype(p.lambdas)
    dH = zero(F)
    N = length(ctx.grid_dims)

    if N == 2
        x, y = F(ctx.spatial_coords[1]), F(ctx.spatial_coords[2])
        W, H = F(ctx.grid_dims[1]), F(ctx.grid_dims[2])

        if ctx.tgt != 0
            lam = get_lambda(p, ctx, ctx.tgt)
            lp = F(ctx.cell_data.length_pressures[ctx.tgt])
            ax, ay = F(ctx.cell_data.anchor_x[ctx.tgt]), F(ctx.cell_data.anchor_y[ctx.tgt])
            vx, vy = F(ctx.cell_data.major_axis_x[ctx.tgt]),
            F(ctx.cell_data.major_axis_y[ctx.tgt])
            L = F(ctx.cell_data.current_lengths[ctx.tgt])
            V = F(ctx.cell_data.volumes[ctx.tgt])
            if L > zero(F) && V > zero(F)
                dx = F(shortest_vector(ctx.topology, x - ax, W))
                dy = F(shortest_vector(ctx.topology, y - ay, H))
                r_par = dx * vx + dy * vy
                dL = (r_par^2 - L^2) / (F(2.0) * L * (V + one(F)))
                dH += lp * dL
            end
        end
        if ctx.src != 0
            lam = get_lambda(p, ctx, ctx.src)
            lp = F(ctx.cell_data.length_pressures[ctx.src])
            ax, ay = F(ctx.cell_data.anchor_x[ctx.src]), F(ctx.cell_data.anchor_y[ctx.src])
            vx, vy = F(ctx.cell_data.major_axis_x[ctx.src]),
            F(ctx.cell_data.major_axis_y[ctx.src])
            L = F(ctx.cell_data.current_lengths[ctx.src])
            V = F(ctx.cell_data.volumes[ctx.src])
            if L > zero(F) && V > zero(F)
                dx = F(shortest_vector(ctx.topology, x - ax, W))
                dy = F(shortest_vector(ctx.topology, y - ay, H))
                r_par = dx * vx + dy * vy
                dL = (r_par^2 - L^2) / (F(2.0) * L * V)
                dH -= lp * dL
            end
        end
    elseif N == 3
        x, y, z = F(ctx.spatial_coords[1]), F(ctx.spatial_coords[2]),
        F(ctx.spatial_coords[3])
        W, H, D = F(ctx.grid_dims[1]), F(ctx.grid_dims[2]), F(ctx.grid_dims[3])

        if ctx.tgt != 0
            lam = get_lambda(p, ctx, ctx.tgt)
            lp = F(ctx.cell_data.length_pressures[ctx.tgt])
            ax, ay, az = F(ctx.cell_data.anchor_x[ctx.tgt]),
            F(ctx.cell_data.anchor_y[ctx.tgt]), F(ctx.cell_data.anchor_z[ctx.tgt])
            vx, vy, vz = F(ctx.cell_data.major_axis_x[ctx.tgt]),
            F(ctx.cell_data.major_axis_y[ctx.tgt]), F(ctx.cell_data.major_axis_z[ctx.tgt])
            L = F(ctx.cell_data.current_lengths[ctx.tgt])
            V = F(ctx.cell_data.volumes[ctx.tgt])
            if L > zero(F) && V > zero(F)
                dx = F(shortest_vector(ctx.topology, x - ax, W))
                dy = F(shortest_vector(ctx.topology, y - ay, H))
                dz = F(shortest_vector(ctx.topology, z - az, D))
                r_par = dx * vx + dy * vy + dz * vz
                dL = (r_par^2 - L^2) / (F(2.0) * L * (V + one(F)))
                dH += lp * dL
            end
        end
        if ctx.src != 0
            lam = get_lambda(p, ctx, ctx.src)
            lp = F(ctx.cell_data.length_pressures[ctx.src])
            ax, ay, az = F(ctx.cell_data.anchor_x[ctx.src]),
            F(ctx.cell_data.anchor_y[ctx.src]), F(ctx.cell_data.anchor_z[ctx.src])
            vx, vy, vz = F(ctx.cell_data.major_axis_x[ctx.src]),
            F(ctx.cell_data.major_axis_y[ctx.src]), F(ctx.cell_data.major_axis_z[ctx.src])
            L = F(ctx.cell_data.current_lengths[ctx.src])
            V = F(ctx.cell_data.volumes[ctx.src])
            if L > zero(F) && V > zero(F)
                dx = F(shortest_vector(ctx.topology, x - ax, W))
                dy = F(shortest_vector(ctx.topology, y - ay, H))
                dz = F(shortest_vector(ctx.topology, z - az, D))
                r_par = dx * vx + dy * vy + dz * vz
                dL = (r_par^2 - L^2) / (F(2.0) * L * V)
                dH -= lp * dL
            end
        end
    end
    return dH
end

@kernel function _grid_accumulate_inertia_kernel!(
        grid, grid_dims, anchors_x, anchors_y, anchors_z, inertia_xx,
        inertia_yy, inertia_zz, inertia_xy, inertia_xz, inertia_yz, topo)
    idx = @index(Global, Linear)
    if idx <= length(grid)
        cell_id = grid[idx]
        if cell_id > 0
            F = eltype(inertia_xx)
            W, H = F(grid_dims[1]), F(grid_dims[2])
            c_x = F((idx - 1) % grid_dims[1])
            c_y = F(((idx - 1) ÷ grid_dims[1]) % grid_dims[2])

            cx = F(anchors_x[cell_id])
            cy = F(anchors_y[cell_id])

            dx = F(shortest_vector(topo, c_x - cx, W))
            dy = F(shortest_vector(topo, c_y - cy, H))

            Atomix.@atomic inertia_xx[cell_id] += dx^2
            Atomix.@atomic inertia_yy[cell_id] += dy^2
            Atomix.@atomic inertia_xy[cell_id] += dx * dy

            if length(grid_dims) == 3
                D = F(grid_dims[3])
                c_z = F((idx - 1) ÷ (grid_dims[1] * grid_dims[2]))
                cz = F(anchors_z[cell_id])
                dz = F(shortest_vector(topo, c_z - cz, D))

                Atomix.@atomic inertia_zz[cell_id] += dz^2
                Atomix.@atomic inertia_xz[cell_id] += dx * dz
                Atomix.@atomic inertia_yz[cell_id] += dy * dz
            end
        end
    end
end

@kernel function _cell_normalize_inertia_and_hst_length_kernel!(
        major_x, major_y, major_z, lengths, target_lengths,
        length_pressures, inertia_xx, inertia_yy, inertia_zz, inertia_xy,
        inertia_xz, inertia_yz, vols, ctypes, lambdas, T_val, seed, dims)
    my_cell_id = @index(Global, Linear)

    if my_cell_id <= length(vols)
        F = eltype(lengths)
        V = F(vols[my_cell_id])
        if V > one(F)
            Ixx = F(inertia_xx[my_cell_id]) / V
            Iyy = F(inertia_yy[my_cell_id]) / V
            Ixy = F(inertia_xy[my_cell_id]) / V

            N = length(dims)

            if N == 2
                # Eigenvalues of 2x2 matrix
                trace = Ixx + Iyy
                det = Ixx * Iyy - Ixy^2
                gap = sqrt(max(zero(F), trace^2 - F(4.0) * det))
                lambda_max = (trace + gap) / F(2.0)

                L = sqrt(max(zero(F), lambda_max))
                lengths[my_cell_id] = L

                # Eigenvector for lambda_max
                if Ixy != zero(F)
                    vx = lambda_max - Iyy
                    vy = Ixy
                    norm = sqrt(vx^2 + vy^2)
                    if norm > zero(F)
                        major_x[my_cell_id] = vx / norm
                        major_y[my_cell_id] = vy / norm
                    else
                        major_x[my_cell_id] = one(F)
                        major_y[my_cell_id] = zero(F)
                    end
                else
                    major_x[my_cell_id] = Ixx > Iyy ? one(F) : zero(F)
                    major_y[my_cell_id] = Ixx > Iyy ? zero(F) : one(F)
                end
            elseif N == 3
                Izz = F(inertia_zz[my_cell_id]) / V
                Ixz = F(inertia_xz[my_cell_id]) / V
                Iyz = F(inertia_yz[my_cell_id]) / V

                q = (Ixx + Iyy + Izz) / F(3.0)
                p1 = Ixy^2 + Ixz^2 + Iyz^2

                if p1 < F(1.0f-6)
                    # Diagonal matrix
                    L = sqrt(max(zero(F), max(Ixx, max(Iyy, Izz))))
                    lengths[my_cell_id] = L

                    if Ixx >= Iyy && Ixx >= Izz
                        major_x[my_cell_id] = one(F);
                        major_y[my_cell_id] = zero(F);
                        major_z[my_cell_id] = zero(F)
                    elseif Iyy >= Ixx && Iyy >= Izz
                        major_x[my_cell_id] = zero(F);
                        major_y[my_cell_id] = one(F);
                        major_z[my_cell_id] = zero(F)
                    else
                        major_x[my_cell_id] = zero(F);
                        major_y[my_cell_id] = zero(F);
                        major_z[my_cell_id] = one(F)
                    end
                else
                    p2 = (Ixx - q)^2 + (Iyy - q)^2 + (Izz - q)^2 + F(2.0) * p1
                    p_val = sqrt(p2 / F(6.0))

                    B11 = (Ixx - q) / p_val;
                    B12 = Ixy / p_val;
                    B13 = Ixz / p_val
                    B22 = (Iyy - q) / p_val;
                    B23 = Iyz / p_val
                    B33 = (Izz - q) / p_val

                    detB = B11*(B22*B33 - B23^2) - B12*(B12*B33 - B23*B13) +
                           B13*(B12*B23 - B22*B13)
                    r = detB / F(2.0)

                    phi = r <= -one(F) ? F(pi) / F(3.0) :
                          (r >= one(F) ? zero(F) : acos(r) / F(3.0))
                    lambda_max = q + F(2.0) * p_val * cos(phi)

                    L = sqrt(max(zero(F), lambda_max))
                    lengths[my_cell_id] = L

                    # Power iteration to find eigenvector
                    vx, vy, vz = one(F), one(F), one(F)
                    for _ in 1:4
                        nx = Ixx * vx + Ixy * vy + Ixz * vz
                        ny = Ixy * vx + Iyy * vy + Iyz * vz
                        nz = Ixz * vx + Iyz * vy + Izz * vz
                        norm = sqrt(nx^2 + ny^2 + nz^2)
                        if norm > zero(F)
                            vx, vy, vz = nx/norm, ny/norm, nz/norm
                        end
                    end
                    major_x[my_cell_id] = vx
                    major_y[my_cell_id] = vy
                    major_z[my_cell_id] = vz
                end
            end

            # SDE Integration for Length Pressure
            my_type = ctypes[my_cell_id]
            lam = F(lambdas[my_type + 1])
            mean_lp = F(2.0) * lam * (L - F(target_lengths[my_cell_id]))

            # Use deterministic seeded hash based on step and cell
            hash_base = pcg_hash(seed + UInt64(my_cell_id) + UInt64(33333))
            u1 = F((hash_base & 0x00FFFFFF)) / F(0x01000000)
            u2 = F((pcg_hash(hash_base) & 0x00FFFFFF)) / F(0x01000000)
            noise_pcg = sqrt(F(-2.0) * log(max(F(1.0f-7), u1))) * cos(F(2.0) * F(pi) * u2)

            noise_std = sqrt(max(zero(F), F(2.0) * lam * F(T_val)))
            noise = noise_std * noise_pcg

            length_pressures[my_cell_id] = mean_lp + noise
        else
            lengths[my_cell_id] = zero(F)
            length_pressures[my_cell_id] = zero(F)
        end
    end
end

"""
    initialize_com_anchors!(u, p, cache)

Runs the two Center-of-Mass kernels sequentially to pre-initialize the anchor
coordinates. This is called exactly once per simulation during `sync_cell_data!`
so that the fused `HSTLengthPenalty` kernel has valid previous-step anchors
on its very first sweep.
"""
function initialize_com_anchors!(u::AbstractPottsState, p::PottsParameters, cache::PottsCache)
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    N = length(u.cell_data.volumes)

    # 1. Zero accumulators
    for arr in (u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y,
        u.cell_data.com_acc_sin_z, u.cell_data.com_acc_cos_z)
        F = eltype(arr)
        fill!(arr, zero(F))
    end

    # 2. Accumulate COM sin/cos
    k_grid_com = _grid_accumulate_com_kernel!(backend, cache.block_size)
    k_grid_com(u.grid, cache.grid_dims,
        u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y,
        u.cell_data.com_acc_sin_z, u.cell_data.com_acc_cos_z,
        cache.sin_lut_x, cache.cos_lut_x, cache.sin_lut_y,
        cache.cos_lut_y, cache.sin_lut_z, cache.cos_lut_z,
        ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)

    # 3. Normalize and write to anchors
    k_cell_com = _cell_normalize_com_kernel!(backend, cache.block_size)
    k_cell_com(u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y,
        u.cell_data.com_acc_sin_z, u.cell_data.com_acc_cos_z,
        u.cell_data.volumes, cache.grid_dims, ndrange = N)
    KernelAbstractions.synchronize(backend)
end

# ---------------------------------------------------------------------------
# Fused kernels for HSTLengthPenalty
# ---------------------------------------------------------------------------
# Grid kernel: accumulate COM sin/cos AND inertia tensor in a single grid pass.
# Uses `anchor_x/y/z` from the PREVIOUS step (1-MCS lag) for the inertia dx/dy.
# This lag is physically negligible (~1 pixel displacement per sweep).
@kernel function _grid_accumulate_com_and_inertia_kernel!(
        grid, grid_dims,
        acc_sin_x, acc_cos_x, acc_sin_y, acc_cos_y, acc_sin_z, acc_cos_z,
        anchor_x, anchor_y, anchor_z,
        inertia_xx, inertia_yy, inertia_zz, inertia_xy, inertia_xz, inertia_yz,
        sin_lut_x, cos_lut_x, sin_lut_y, cos_lut_y, sin_lut_z, cos_lut_z,
        topo)
    idx = @index(Global, Linear)
    if idx <= length(grid)
        cell_id = grid[idx]
        if cell_id > 0
            F = eltype(inertia_xx)
            W = F(grid_dims[1])
            H = F(grid_dims[2])
            c_x = F((idx - 1) % grid_dims[1])
            c_y = F(((idx - 1) ÷ grid_dims[1]) % grid_dims[2])

            # ---- COM accumulation (circular mean) ----
            Atomix.@atomic acc_sin_x[cell_id] += sin_lut_x[Int(c_x) + 1]
            Atomix.@atomic acc_cos_x[cell_id] += cos_lut_x[Int(c_x) + 1]
            Atomix.@atomic acc_sin_y[cell_id] += sin_lut_y[Int(c_y) + 1]
            Atomix.@atomic acc_cos_y[cell_id] += cos_lut_y[Int(c_y) + 1]

            # ---- Inertia accumulation (uses previous-step anchors) ----
            cx = F(anchor_x[cell_id])
            cy = F(anchor_y[cell_id])
            dx = F(shortest_vector(topo, c_x - cx, W))
            dy = F(shortest_vector(topo, c_y - cy, H))
            Atomix.@atomic inertia_xx[cell_id] += dx^2
            Atomix.@atomic inertia_yy[cell_id] += dy^2
            Atomix.@atomic inertia_xy[cell_id] += dx * dy

            if length(grid_dims) == 3
                D = F(grid_dims[3])
                c_z = F((idx - 1) ÷ (grid_dims[1] * grid_dims[2]))
                Atomix.@atomic acc_sin_z[cell_id] += sin_lut_z[Int(c_z) + 1]
                Atomix.@atomic acc_cos_z[cell_id] += cos_lut_z[Int(c_z) + 1]
                cz = F(anchor_z[cell_id])
                dz = F(shortest_vector(topo, c_z - cz, D))
                Atomix.@atomic inertia_zz[cell_id] += dz^2
                Atomix.@atomic inertia_xz[cell_id] += dx * dz
                Atomix.@atomic inertia_yz[cell_id] += dy * dz
            end
        end
    end
end

# Cell kernel: normalise COM → update anchors, then immediately do inertia
# eigendecomposition + HST OU integration.  Both are cell-indexed with no
# inter-cell dependency, so they fuse cleanly.
@kernel function _cell_normalize_com_and_hst_length_kernel!(
        anchors_x, anchors_y, anchors_z,
        acc_sin_x, acc_cos_x, acc_sin_y, acc_cos_y, acc_sin_z, acc_cos_z,
        major_x, major_y, major_z, lengths, target_lengths, length_pressures,
        inertia_xx, inertia_yy, inertia_zz, inertia_xy, inertia_xz, inertia_yz,
        vols, ctypes, llambdas, p_lambdas, is_flex, eta, T_val, seed, dt, dims)
    my_cell_id = @index(Global, Linear)
    if my_cell_id <= length(vols)
        F = eltype(lengths)
        V = F(vols[my_cell_id])
        if V > one(F)
            N = length(dims)
            W = F(dims[1])
            H = F(dims[2])

            # ---- Phase A: COM normalisation (update anchors) ----
            ax = (W / (F(2.0) * F(pi))) *
                 atan(acc_sin_x[my_cell_id], acc_cos_x[my_cell_id])
            ay = (H / (F(2.0) * F(pi))) *
                 atan(acc_sin_y[my_cell_id], acc_cos_y[my_cell_id])
            ax = ax < zero(F) ? ax + W : ax
            ay = ay < zero(F) ? ay + H : ay
            anchors_x[my_cell_id] = ax
            anchors_y[my_cell_id] = ay
            if N == 3
                D = F(dims[3])
                az = (D / (F(2.0) * F(pi))) *
                     atan(acc_sin_z[my_cell_id], acc_cos_z[my_cell_id])
                az = az < zero(F) ? az + D : az
                anchors_z[my_cell_id] = az
            end

            # ---- Phase B: Inertia eigendecomposition + HST SDE ----
            Ixx = F(inertia_xx[my_cell_id]) / V
            Iyy = F(inertia_yy[my_cell_id]) / V
            Ixy = F(inertia_xy[my_cell_id]) / V

            L = zero(F)

            if N == 2
                trace = Ixx + Iyy
                det = Ixx * Iyy - Ixy^2
                gap = sqrt(max(zero(F), trace^2 - F(4.0) * det))
                lambda_max = (trace + gap) / F(2.0)
                L = sqrt(max(zero(F), lambda_max))
                lengths[my_cell_id] = L
                if Ixy != zero(F)
                    vx = lambda_max - Iyy
                    vy = Ixy
                    norm = sqrt(vx^2 + vy^2)
                    if norm > zero(F)
                        major_x[my_cell_id] = vx / norm
                        major_y[my_cell_id] = vy / norm
                    else
                        major_x[my_cell_id] = one(F)
                        major_y[my_cell_id] = zero(F)
                    end
                else
                    major_x[my_cell_id] = Ixx > Iyy ? one(F) : zero(F)
                    major_y[my_cell_id] = Ixx > Iyy ? zero(F) : one(F)
                end
            elseif N == 3
                Izz = F(inertia_zz[my_cell_id]) / V
                Ixz = F(inertia_xz[my_cell_id]) / V
                Iyz = F(inertia_yz[my_cell_id]) / V
                q = (Ixx + Iyy + Izz) / F(3.0)
                p1 = Ixy^2 + Ixz^2 + Iyz^2
                if p1 < F(1.0f-6)
                    L = sqrt(max(zero(F), max(Ixx, max(Iyy, Izz))))
                    lengths[my_cell_id] = L
                    if Ixx >= Iyy && Ixx >= Izz
                        major_x[my_cell_id] = one(F);
                        major_y[my_cell_id] = zero(F);
                        major_z[my_cell_id] = zero(F)
                    elseif Iyy >= Ixx && Iyy >= Izz
                        major_x[my_cell_id] = zero(F);
                        major_y[my_cell_id] = one(F);
                        major_z[my_cell_id] = zero(F)
                    else
                        major_x[my_cell_id] = zero(F);
                        major_y[my_cell_id] = zero(F);
                        major_z[my_cell_id] = one(F)
                    end
                else
                    p2 = (Ixx - q)^2 + (Iyy - q)^2 + (Izz - q)^2 + F(2.0) * p1
                    p_val = sqrt(p2 / F(6.0))
                    B11 = (Ixx - q) / p_val;
                    B12 = Ixy / p_val;
                    B13 = Ixz / p_val
                    B22 = (Iyy - q) / p_val;
                    B23 = Iyz / p_val
                    B33 = (Izz - q) / p_val
                    detB = B11*(B22*B33 - B23^2) - B12*(B12*B33 - B23*B13) +
                           B13*(B12*B23 - B22*B13)
                    r = detB / F(2.0)
                    phi = r <= -one(F) ? F(pi) / F(3.0) :
                          (r >= one(F) ? zero(F) : acos(r) / F(3.0))
                    lambda_max = q + F(2.0) * p_val * cos(phi)
                    L = sqrt(max(zero(F), lambda_max))
                    lengths[my_cell_id] = L
                    vx_p, vy_p, vz_p = one(F), one(F), one(F)
                    for _ in 1:4
                        nx = Ixx * vx_p + Ixy * vy_p + Ixz * vz_p
                        ny = Ixy * vx_p + Iyy * vy_p + Iyz * vz_p
                        nz = Ixz * vx_p + Iyz * vy_p + Izz * vz_p
                        nm = sqrt(nx^2 + ny^2 + nz^2)
                        if nm > zero(F)
                            vx_p, vy_p, vz_p = nx/nm, ny/nm, nz/nm
                        end
                    end
                    major_x[my_cell_id] = vx_p
                    major_y[my_cell_id] = vy_p
                    major_z[my_cell_id] = vz_p
                end
            end

            # ---- SDE Integration (Ornstein-Uhlenbeck) ----
            my_type = ctypes[my_cell_id]
            lam = is_flex ? F(llambdas[my_cell_id]) : F(p_lambdas[my_type + 1])
            alpha = exp(-eta * dt)
            mean_lp = F(2.0) * lam * (L - F(target_lengths[my_cell_id]))
            hash_base = pcg_hash(seed + UInt64(my_cell_id) + UInt64(33333))
            u1 = F((hash_base & 0x00FFFFFF)) / F(0x01000000)
            u2 = F((pcg_hash(hash_base) & 0x00FFFFFF)) / F(0x01000000)
            noise_pcg = sqrt(F(-2.0) * log(max(F(1.0f-7), u1))) * cos(F(2.0) * F(pi) * u2)
            noise_std = sqrt(max(zero(F), F(2.0) * lam * F(T_val) * (one(F) - alpha^2)))
            noise = noise_std * noise_pcg
            length_pressures[my_cell_id] = alpha * length_pressures[my_cell_id] +
                                           (one(F) - alpha) * mean_lp + noise
        else
            lengths[my_cell_id] = zero(F)
            length_pressures[my_cell_id] = zero(F)
        end
    end
end

function update_step_auxiliary!(p::HSTLengthPenalty{FlexType}, u::AbstractPottsState,
        p_sys::PottsParameters, cache::PottsCache, T_val, dt) where {FlexType}
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    N = length(u.cell_data.volumes)
    seed = pcg_hash(cache.step_counter[] + UInt64(12345))

    # 1. Zero out accumulators
    for arr in (u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y,
        u.cell_data.com_acc_sin_z, u.cell_data.com_acc_cos_z,
        u.cell_data.inertia_xx, u.cell_data.inertia_yy,
        u.cell_data.inertia_zz, u.cell_data.inertia_xy,
        u.cell_data.inertia_xz, u.cell_data.inertia_yz)
        F = eltype(arr)
        fill!(arr, zero(F))
    end

    # 2. Grid-level Accumulation Pass
    k_grid = _grid_accumulate_com_and_inertia_kernel!(backend, cache.block_size)
    k_grid(u.grid, cache.grid_dims,
        u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y,
        u.cell_data.com_acc_sin_z, u.cell_data.com_acc_cos_z,
        u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.inertia_xx, u.cell_data.inertia_yy,
        u.cell_data.inertia_zz, u.cell_data.inertia_xy,
        u.cell_data.inertia_xz, u.cell_data.inertia_yz,
        cache.sin_lut_x, cache.cos_lut_x, cache.sin_lut_y,
        cache.cos_lut_y, cache.sin_lut_z, cache.cos_lut_z,
        p_sys.topology, ndrange = length(u.grid))
    KernelAbstractions.synchronize(backend)

    # 3. Cell-level Normalization & Pressure Assignment Pass
    k_cell = _cell_normalize_com_and_hst_length_kernel!(backend, cache.block_size)
    k_cell(u.cell_data.anchor_x, u.cell_data.anchor_y, u.cell_data.anchor_z,
        u.cell_data.com_acc_sin_x, u.cell_data.com_acc_cos_x,
        u.cell_data.com_acc_sin_y, u.cell_data.com_acc_cos_y,
        u.cell_data.com_acc_sin_z, u.cell_data.com_acc_cos_z,
        u.cell_data.major_axis_x, u.cell_data.major_axis_y, u.cell_data.major_axis_z,
        u.cell_data.current_lengths, u.cell_data.target_lengths,
        u.cell_data.length_pressures,
        u.cell_data.inertia_xx, u.cell_data.inertia_yy,
        u.cell_data.inertia_zz, u.cell_data.inertia_xy,
        u.cell_data.inertia_xz, u.cell_data.inertia_yz,
        u.cell_data.volumes, u.cell_data.cell_types,
        u.cell_data.length_lambdas, p.lambdas, FlexType === Flex, p.eta, T_val, seed, dt, cache.grid_dims,
        ndrange = N)
    KernelAbstractions.synchronize(backend)
end
