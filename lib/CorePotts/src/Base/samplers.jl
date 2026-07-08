abstract type AbstractSampler end

# 1. Define Traits
abstract type AcceptanceStyle end
struct MetropolisStyle <: AcceptanceStyle end
struct CustomStyle <: AcceptanceStyle end

# 2. Define Base Samplers and map to Traits
using ArgCheck

struct MetropolisSampler <: AbstractSampler
    active_fraction::Float32
    function MetropolisSampler(active_fraction::Float32 = 1.0f0)
        @argcheck 0.0f0 <= active_fraction <= 1.0f0 "active_fraction must be between 0.0 and 1.0"
        new(active_fraction)
    end
end
@inline AcceptanceStyle(::Type{MetropolisSampler}) = MetropolisStyle()

# Fallback trait map
@inline AcceptanceStyle(::Type{T}) where {T <: AbstractSampler} = CustomStyle()

# 3. Dispatch Boundary 
@inline function evaluate_acceptance(sampler::AbstractSampler, dH, ratio, prob, T)
    return _evaluate_acceptance(
        AcceptanceStyle(typeof(sampler)), sampler, dH, ratio, prob, T)
end

# 4. The Exact Existing Metropolis Math
@inline function _evaluate_acceptance(::MetropolisStyle, sampler, dH, ratio, prob, T)
    F = typeof(T)
    if T == zero(F)
        if dH < zero(F)
            return ratio > zero(F)
        elseif dH == zero(F)
            return prob < ratio
        end
        return false
    else
        # Cap the total acceptance probability at 1.0 to prevent over-acceptance
        # when hastings_ratio >> 1 (e.g. n_tgt=0 branch). The MH ratio must
        # always satisfy A(x→y) ≤ 1 by definition.
        boltzmann = min(one(F), F(ratio) * exp(-F(dH) / T))
        return (dH <= zero(F) && ratio >= one(F)) || F(prob) < boltzmann
    end
end
