using Test
using MakiePotts

@testset "MakiePotts" begin
    @test isdefined(MakiePotts, :pottsplot)
    @test isdefined(MakiePotts, :explore_potts)
    @test isdefined(MakiePotts, :record_potts)
end
