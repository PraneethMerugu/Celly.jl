"""
    HSTSurfaceAreaPenalty(lambdas; eta=1.0f0)

A hydrostatic formulation of the surface area constraint using fluctuating membrane tensions.
Prevents cells from fragmenting or infinitely stretching.
"""
struct HSTSurfaceAreaPenalty{FloatT <: AbstractVector, FType} <: AbstractPenalty
    lambdas::FloatT
    eta::FType
end
Adapt.@adapt_structure HSTSurfaceAreaPenalty
HSTSurfaceAreaPenalty(lambdas; eta=1.0) = HSTSurfaceAreaPenalty(lambdas, eta)



@inline function evaluate_penalty(penalty::HSTSurfaceAreaPenalty, ctx)
    F = eltype(penalty.lambdas)
    dH = zero(F)
    dsa_tup = get_tracker_delta(SurfaceAreaTracker, ctx.trackers, ctx.tx_deltas)
    dsa_src = F(dsa_tup[1])
    dsa_tgt = F(dsa_tup[2])

    if ctx.src > 0
        dH += F(ctx.cell_data.tensions[ctx.src]) * dsa_src
    end
    if ctx.tgt > 0
        dH += F(ctx.cell_data.tensions[ctx.tgt]) * dsa_tgt
    end
    return dH
end

@kernel function _update_hst_sa_kernel!(tensions, sas, tgts, ctypes, lambdas, eta, T_val, seed, dt)
    i = @index(Global, Linear)
    if i <= length(sas)
        c_type = ctypes[i]
        if c_type > 0
            F = eltype(tensions)
            sa_true = F(sas[i])
            if sa_true > zero(F)
                lam = F(lambdas[c_type + 1])
                mean_t = F(2.0) * lam * (sa_true - F(tgts[i]))
                alpha = F(exp(-eta * dt))
                noise_std = sqrt(max(zero(F), F(2.0) * lam * F(T_val) * (one(F) - alpha^2)))
                noise = noise_std * F(randn_pcg(seed + UInt64(i), seed + UInt64(i + 67890)))
                tensions[i] = alpha * tensions[i] + (one(F) - alpha) * mean_t + noise
            else
                tensions[i] = zero(F)
            end
        end
    end
end

function update_step_auxiliary!(pen::HSTSurfaceAreaPenalty, u::AbstractCPMState, p::CPMParameters, cache::CPMCache, T_val, dt)
    cache.noise_counter[] += UInt64(1)
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    seed = pcg_hash(cache.noise_counter[])
    kernel = _update_hst_sa_kernel!(backend, cache.block_size)
    kernel(u.cell_data.tensions, u.cell_data.surface_areas, u.cell_data.target_surface_areas, u.cell_data.cell_types, pen.lambdas, pen.eta, T_val, seed, dt, ndrange=length(u.cell_data.volumes))
    KernelAbstractions.synchronize(backend)
end
