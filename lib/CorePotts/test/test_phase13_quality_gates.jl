using Aqua

@testset "Phase 13 CorePotts package-quality gates" begin
    Aqua.test_all(CorePotts)
    @test isempty(Test.detect_ambiguities(CorePotts; recursive = true))
end
