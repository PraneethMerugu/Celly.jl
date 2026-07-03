"""
    HSTVolumePenalty(lambdas; eta=1.0f0)

A hydrostatic formulation of the volume constraint. Uses a fluctuating internal pressure
`p` for each cell instead of a rigid quadratic constraint, allowing for thermodynamic detailed balance.
"""
struct HSTVolumePenalty{FloatT <: AbstractVector, FType} <: AbstractPenalty
    lambdas::FloatT
    eta::FType
end
import Adapt
Adapt.@adapt_structure HSTVolumePenalty
HSTVolumePenalty(lambdas; eta=1.0) = HSTVolumePenalty(lambdas, eta)



@inline function evaluate_penalty(p::HSTVolumePenalty, ctx)
    F = eltype(p.lambdas)
    dH = zero(F)
    if ctx.src != 0
        dH -= F(ctx.cell_data.pressures[ctx.src])
    end
    if ctx.tgt != 0
        dH += F(ctx.cell_data.pressures[ctx.tgt])
    end
    return dH
end

@kernel function _update_hst_vol_kernel!(pressures, vols, tgts, ctypes, lambdas, eta, T_val, seed, dt)
    i = @index(Global, Linear)
    if i <= length(vols)
        c_type = ctypes[i]
        if c_type > 0
            F = eltype(pressures)
            v_true = F(vols[i])
            if v_true > zero(F)
                lam = F(lambdas[c_type + 1])
                mean_p = F(2.0) * lam * (v_true - F(tgts[i]))
                alpha = F(exp(-eta * dt))
                noise_std = sqrt(max(zero(F), F(2.0) * lam * F(T_val) * (one(F) - alpha^2)))
                noise = noise_std * F(randn_pcg(seed + UInt64(i), seed + UInt64(i + 12345)))
                pressures[i] = alpha * pressures[i] + (one(F) - alpha) * mean_p + noise
            else
                pressures[i] = zero(F)
            end
        end
    end
end

function update_step_auxiliary!(pen::HSTVolumePenalty, u::AbstractCPMState, p::CPMParameters, cache::CPMCache, T_val, dt)
    cache.noise_counter[] += UInt64(1)
    backend = KernelAbstractions.get_backend(u.cell_data.volumes)
    seed = pcg_hash(cache.noise_counter[])
    kernel = _update_hst_vol_kernel!(backend, cache.block_size)
    kernel(u.cell_data.pressures, u.cell_data.volumes, u.cell_data.target_volumes, u.cell_data.cell_types, pen.lambdas, pen.eta, T_val, seed, dt, ndrange=length(u.cell_data.volumes))
    KernelAbstractions.synchronize(backend)
end

"""
    VolumePenalty(lambdas)

The classic cellular volume constraint. Acts as a harmonic spring, penalizing deviations
from a cell's `target_volume` according to its type-specific `lambda`.
"""
struct VolumePenalty{FloatT <: AbstractVector} <: AbstractPenalty
    lambdas::FloatT
end
Adapt.@adapt_structure VolumePenalty

@inline function evaluate_penalty(p::VolumePenalty, ctx)
    F = eltype(p.lambdas)
    dH = zero(F)
    if ctx.src != 0
        c_type = ctx.cell_data.cell_types[ctx.src]
        lam = F(p.lambdas[c_type + 1])
        v = F(ctx.cell_data.volumes[ctx.src])
        tgt = F(ctx.cell_data.target_volumes[ctx.src])
        dH += lam * (one(F) - F(2.0) * (v - tgt))
    end
    if ctx.tgt != 0
        c_type = ctx.cell_data.cell_types[ctx.tgt]
        lam = F(p.lambdas[c_type + 1])
        v = F(ctx.cell_data.volumes[ctx.tgt])
        tgt = F(ctx.cell_data.target_volumes[ctx.tgt])
        dH += lam * (one(F) + F(2.0) * (v - tgt))
    end
    return dH
end

function compute_global_energy(p::VolumePenalty, u, params)
    F = eltype(p.lambdas)
    E_arr = [begin
        v = F(u.cell_data.volumes[i])
        if v > zero(F)
            c_type = u.cell_data.cell_types[i]
            lam = F(p.lambdas[c_type + 1])
            tgt = F(u.cell_data.target_volumes[i])
            lam * (v - tgt)^2
        else
            zero(F)
        end
    end for i in 1:length(u.cell_data.volumes)]
    return sum(E_arr)
end
