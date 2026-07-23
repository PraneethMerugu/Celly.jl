module TransitionEmpirical

using LinearAlgebra: dot

export TransitionSamplingPlan, EmpiricalRowResult,
       total_variation_radius, absolute_probability_radius,
       evaluate_empirical_row, integrated_autocorrelation_time,
       effective_sample_size

struct TransitionSamplingPlan
    replicas::Int
    alpha_per_row::Float64
    total_variation_margin::Float64
    maximum_absolute_margin::Float64
    self_transition_margin::Float64
    maximum_support::Int

    function TransitionSamplingPlan(; replicas::Integer = 262_144,
            alpha_per_row::Real = 0.01 / 144,
            total_variation_margin::Real = 0.03,
            maximum_absolute_margin::Real = 0.015,
            self_transition_margin::Real = 0.015,
            maximum_support::Integer = 64)
        replicas > 0 || throw(ArgumentError("replicas must be positive"))
        0 < alpha_per_row < 1 || throw(ArgumentError(
            "alpha_per_row must lie strictly between zero and one"))
        all(>(0), (total_variation_margin, maximum_absolute_margin,
            self_transition_margin)) || throw(ArgumentError(
            "transition margins must be positive"))
        maximum_support >= 2 || throw(ArgumentError(
            "maximum support must be at least two"))
        return new(Int(replicas), Float64(alpha_per_row),
            Float64(total_variation_margin), Float64(maximum_absolute_margin),
            Float64(self_transition_margin), Int(maximum_support))
    end
end

function total_variation_radius(support::Integer, plan::TransitionSamplingPlan)
    2 <= support <= plan.maximum_support || throw(ArgumentError(
        "support must lie in 2:$(plan.maximum_support)"))
    log_support_factor = support * log(2) + log1p(-exp2(1 - support))
    return sqrt((log_support_factor + log(inv(plan.alpha_per_row))) /
                (2plan.replicas))
end

function absolute_probability_radius(support::Integer,
        plan::TransitionSamplingPlan)
    1 <= support <= plan.maximum_support || throw(ArgumentError(
        "support must lie in 1:$(plan.maximum_support)"))
    return sqrt(log(2support / plan.alpha_per_row) / (2plan.replicas))
end

struct EmpiricalRowResult
    passed::Bool
    empirical::Vector{Float64}
    absolute_residuals::Vector{Float64}
    total_variation::Float64
    maximum_absolute_residual::Float64
    self_transition_residual::Float64
    total_variation_radius::Float64
    absolute_probability_radius::Float64
    impossible_destinations::Vector{Int}
    failed_criteria::Vector{String}
end

function evaluate_empirical_row(oracle::AbstractVector, counts::AbstractVector,
        source::Integer; plan::TransitionSamplingPlan = TransitionSamplingPlan())
    length(oracle) == length(counts) || throw(DimensionMismatch(
        "oracle row and count vector lengths differ"))
    source in eachindex(oracle) || throw(BoundsError(eachindex(oracle), source))
    all(probability -> isfinite(probability) && probability >= 0, oracle) ||
        throw(ArgumentError("oracle probabilities must be finite and nonnegative"))
    abs(sum(oracle) - 1) <= 1e-12 || throw(ArgumentError(
        "oracle probabilities must sum to one"))
    all(count -> count isa Integer && count >= 0, counts) || throw(ArgumentError(
        "empirical counts must be nonnegative integers"))
    sum(counts) == plan.replicas || throw(ArgumentError(
        "empirical counts must sum to $(plan.replicas)"))

    support = count(>(0), oracle)
    support <= plan.maximum_support || throw(ArgumentError(
        "oracle support $support exceeds the registered cap $(plan.maximum_support)"))
    empirical = Float64.(counts) ./ plan.replicas
    oracle64 = Float64.(oracle)
    residuals = abs.(empirical .- oracle64)
    tv = sum(residuals) / 2
    maximum_residual = maximum(residuals)
    self_residual = residuals[source]
    impossible = findall(index -> iszero(oracle64[index]) && counts[index] > 0,
        eachindex(oracle64))
    tv_radius = support == 1 ? 0.0 : total_variation_radius(support, plan)
    absolute_radius = absolute_probability_radius(max(support, 1), plan)
    failures = String[]
    isempty(impossible) || push!(failures, "observed destination outside oracle support")
    tv + tv_radius <= plan.total_variation_margin || push!(failures,
        "total-variation bound exceeds registered margin")
    maximum_residual + absolute_radius <= plan.maximum_absolute_margin || push!(failures,
        "maximum absolute-probability bound exceeds registered margin")
    self_residual + absolute_radius <= plan.self_transition_margin || push!(failures,
        "self-transition bound exceeds registered margin")
    return EmpiricalRowResult(isempty(failures), empirical, residuals, tv,
        maximum_residual, self_residual, tv_radius, absolute_radius,
        impossible, failures)
end

"""Initial-positive-sequence integrated autocorrelation-time estimate."""
function integrated_autocorrelation_time(values::AbstractVector{<:Real};
        maximum_lag::Integer = min(1000, length(values) - 1))
    length(values) >= 4 || throw(ArgumentError(
        "autocorrelation estimation requires at least four observations"))
    1 <= maximum_lag < length(values) || throw(ArgumentError(
        "maximum_lag must lie in 1:length(values)-1"))
    centered = Float64.(values) .- sum(values) / length(values)
    variance = sum(abs2, centered) / length(centered)
    iszero(variance) && return 1.0
    correlations = Float64[]
    for lag in 1:maximum_lag
        last = length(centered)
        covariance = dot(view(centered, 1:(last - lag)),
            view(centered, (1 + lag):last)) / (last - lag)
        push!(correlations, covariance / variance)
    end
    total = 0.0
    pair = 1
    while pair <= length(correlations)
        pair_sum = correlations[pair] +
                   (pair < length(correlations) ? correlations[pair + 1] : 0.0)
        pair_sum > 0 || break
        total += pair_sum
        pair += 2
    end
    return max(1.0, 1 + 2total)
end

effective_sample_size(values::AbstractVector{<:Real}; kwargs...) =
    length(values) / integrated_autocorrelation_time(values; kwargs...)

end
