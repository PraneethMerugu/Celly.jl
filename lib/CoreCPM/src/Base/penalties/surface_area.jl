"""
    HSTSurfaceAreaPenalty(lambdas; eta=1.0f0)

A hydrostatic formulation of the surface area constraint using fluctuating membrane tensions.
Prevents cells from fragmenting or infinitely stretching.
"""
struct HSTSurfaceAreaPenalty{FlexType <: FlexibilityTrait, FloatT <: AbstractVector, FType} <: AbstractHSTPenalty{FlexType}
    lambdas::FloatT
    eta::FType
end

function HSTSurfaceAreaPenalty{Rigid}(lambdas; eta=1.0)
    F = eltype(lambdas)
    return HSTSurfaceAreaPenalty{Rigid, typeof(lambdas), F}(lambdas, convert(F, eta))
end
function HSTSurfaceAreaPenalty(lambdas; eta=1.0)
    return HSTSurfaceAreaPenalty{Rigid}(lambdas; eta=eta)
end
function HSTSurfaceAreaPenalty{Flex}(; eta=1.0, FloatType=Float32)
    F = convert(FloatType, eta)
    return HSTSurfaceAreaPenalty{Flex, Vector{FloatType}, typeof(F)}(FloatType[], F)
end

lambda_field(::HSTSurfaceAreaPenalty) = Val{:surface_area_lambdas}()
hst_state_field(::HSTSurfaceAreaPenalty) = Val{:tensions}()
hst_value_field(::HSTSurfaceAreaPenalty) = Val{:surface_areas}()
hst_target_field(::HSTSurfaceAreaPenalty) = Val{:target_surface_areas}()



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

# Generic update_step_auxiliary! handles HST tension updates via AbstractHSTPenalty.
