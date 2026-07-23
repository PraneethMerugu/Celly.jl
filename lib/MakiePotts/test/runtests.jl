using Test
using MakiePotts
using Aqua

@testset "MakiePotts" begin
    @test isdefined(MakiePotts, :pottsplot)
    @test isdefined(MakiePotts, :explore_potts)
    @test isdefined(MakiePotts, :record_potts)
end

@testset "Phase 13 MakiePotts package-quality gates" begin
    # Makie owns long-lived rendering tasks; its package cannot satisfy Aqua's
    # process-level persistent-task probe without treating Makie's runtime as a leak.
    Aqua.test_all(MakiePotts; persistent_tasks = false)
    @test isempty(Test.detect_ambiguities(MakiePotts; recursive = true))
end
