using Test
using Potts
using CorePotts
using PottsToolkit
using SciMLBase

const TEST_ALGORITHMS = (ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis)

@testset "Potts.jl Integrated Test Suite" begin
    include("test_thermodynamics.jl")
    include("test_biophysics.jl")
end
