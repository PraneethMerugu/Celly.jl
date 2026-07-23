using Aqua

@testset "Phase 13 PottsToolkit package-quality gates" begin
    Aqua.test_all(PottsToolkit)
    @test isempty(Test.detect_ambiguities(PottsToolkit; recursive = true))
end
