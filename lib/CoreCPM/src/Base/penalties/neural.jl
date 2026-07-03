"""
    LocalNeuralPenalty{M, W, S}

A Neural Penalty that evaluates an allocation-free Neural Network (e.g. from SimpleChains.jl)
over a localized spatial patch.
"""
struct LocalNeuralPenalty{M, W, S} <: AbstractNeuralPenalty
    model::M
    weights::W
    state::S
end
Adapt.@adapt_structure LocalNeuralPenalty
