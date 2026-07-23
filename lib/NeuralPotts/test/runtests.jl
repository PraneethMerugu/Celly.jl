using Test
using NeuralPotts
using Aqua

include("test_lux.jl")

@testset "Phase 13 NeuralPotts package-quality gates" begin
    Aqua.test_all(NeuralPotts; persistent_tasks = false)
    @test isempty(Test.detect_ambiguities(NeuralPotts; recursive = true))
end
