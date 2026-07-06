"""
    LocalNeuralPenalty{M, W, S}

A Neural Penalty that evaluates an allocation-free Neural Network (e.g. from SimpleChains.jl)
over a localized spatial patch.
"""
struct LocalNeuralPenalty{FlexType <: FlexibilityTrait, M, W, S} <: AbstractNeuralPenalty{FlexType}
    model::M
    weights::W
    state::S
end

LocalNeuralPenalty{Rigid}(m, w, s) = LocalNeuralPenalty{Rigid, typeof(m), typeof(w), typeof(s)}(m, w, s)
LocalNeuralPenalty(m, w, s) = LocalNeuralPenalty{Rigid}(m, w, s)
LocalNeuralPenalty{Flex}(m, w, s) = LocalNeuralPenalty{Flex, typeof(m), typeof(w), typeof(s)}(m, w, s)
