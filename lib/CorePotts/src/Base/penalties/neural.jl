"""
    LocalNeuralPenalty{M, W, S}

A Neural Penalty that evaluates an allocation-free Neural Network (e.g. from SimpleChains.jl)
over a localized spatial patch.
"""
struct LocalNeuralPenalty{FlexType <: FlexibilityTrait, M, W, S} <:
       AbstractNeuralPenalty{FlexType}
    model::M
    weights::W
    state::S
end

function LocalNeuralPenalty{Rigid}(m, w, s)
    LocalNeuralPenalty{Rigid, typeof(m), typeof(w), typeof(s)}(m, w, s)
end
LocalNeuralPenalty(m, w, s) = LocalNeuralPenalty{Rigid}(m, w, s)
function LocalNeuralPenalty{Flex}(m, w, s)
    LocalNeuralPenalty{Flex, typeof(m), typeof(w), typeof(s)}(m, w, s)
end

# ConstructionBase Overloads
function ConstructionBase.constructorof(::Type{<:LocalNeuralPenalty{Trait}}) where {Trait}
    LocalNeuralPenalty{Trait}
end
