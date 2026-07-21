using Test
using PottsToolkit
using CorePotts

@testset "PottsToolkit" begin
    include("test_level2_authoring.jl")
    include("test_level1_authoring.jl")
    include("test_phase11_inventory.jl")
end
