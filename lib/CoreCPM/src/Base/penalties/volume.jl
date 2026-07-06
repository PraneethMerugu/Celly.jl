"""
    HSTVolumePenalty(lambdas; eta=1.0f0)

A hydrostatic formulation of the volume constraint. Uses a fluctuating internal pressure
`p` for each cell instead of a rigid quadratic constraint, allowing for thermodynamic detailed balance.
"""
struct HSTVolumePenalty{FlexType <: FlexibilityTrait, FloatT <: AbstractVector, FType} <: AbstractHSTPenalty{FlexType}
    lambdas::FloatT
    eta::FType
end
function HSTVolumePenalty{Rigid}(lambdas; eta=1.0)
    F = eltype(lambdas)
    return HSTVolumePenalty{Rigid, typeof(lambdas), F}(lambdas, convert(F, eta))
end
function HSTVolumePenalty(lambdas; eta=1.0)
    return HSTVolumePenalty{Rigid}(lambdas; eta=eta)
end
function HSTVolumePenalty{Flex}(; eta=1.0, FloatType=Float32)
    F = convert(FloatType, eta)
    return HSTVolumePenalty{Flex, Vector{FloatType}, typeof(F)}(FloatType[], F)
end

lambda_field(::HSTVolumePenalty) = Val{:volume_lambdas}()
hst_state_field(::HSTVolumePenalty) = Val{:pressures}()
hst_value_field(::HSTVolumePenalty) = Val{:volumes}()
hst_target_field(::HSTVolumePenalty) = Val{:target_volumes}()



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

# Generic update_step_auxiliary! handles HST pressure updates via AbstractHSTPenalty.

"""
    VolumePenalty(lambdas)

The classic cellular volume constraint. Acts as a harmonic spring, penalizing deviations
from a cell's `target_volume` according to its type-specific `lambda`.
"""
struct VolumePenalty{FlexType <: FlexibilityTrait, FloatT <: AbstractVector} <: AbstractPenalty{FlexType}
    lambdas::FloatT
end

VolumePenalty{Rigid}(lambdas) = VolumePenalty{Rigid, typeof(lambdas)}(lambdas)
VolumePenalty(lambdas) = VolumePenalty{Rigid}(lambdas)
VolumePenalty{Flex}(; FloatType=Float32) = VolumePenalty{Flex, Vector{FloatType}}(FloatType[])

lambda_field(::VolumePenalty) = Val{:volume_lambdas}()

@inline function evaluate_penalty(p::VolumePenalty, ctx)
    F = eltype(p.lambdas)
    dH = zero(F)
    if ctx.src != 0
        lam = F(get_lambda(p, ctx, ctx.src))
        v = F(ctx.cell_data.volumes[ctx.src])
        tgt = F(ctx.cell_data.target_volumes[ctx.src])
        dH += lam * (one(F) - F(2.0) * (v - tgt))
    end
    if ctx.tgt != 0
        lam = F(get_lambda(p, ctx, ctx.tgt))
        v = F(ctx.cell_data.volumes[ctx.tgt])
        tgt = F(ctx.cell_data.target_volumes[ctx.tgt])
        dH += lam * (one(F) + F(2.0) * (v - tgt))
    end
    return dH
end

function compute_global_energy(p::VolumePenalty{FlexType}, u, params) where {FlexType}
    F = eltype(p.lambdas)
    vols = u.cell_data.volumes
    tgts = u.cell_data.target_volumes
    c_types = u.cell_data.cell_types
    
    if FlexType === Flex
        lams = u.cell_data.volume_lambdas
    else
        lams = p.lambdas[c_types .+ 1]
    end
    
    E_arr = (vols .> zero(F)) .* lams .* (vols .- tgts).^2
    return sum(E_arr)
end
