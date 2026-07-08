using Test
using Celly
using CoreCPM
using CPMToolkit
using SciMLBase

const TEST_ALGORITHMS = (ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis)

@testset "Celly.jl Integrated Test Suite" begin
    include("test_thermodynamics.jl")
    include("test_biophysics.jl")
end
