using Test
using PottsToolkit

@testset "PottsToolkit" begin
    include("test_flex_traits.jl")
    include("test_layouts.jl")
    include("test_events.jl")
    include("test_gpu_closures.jl")
    include("test_rule_macro.jl")
    include("test_macros.jl")
    include("test_dynamic_celldata.jl")
    include("test_reference_compilation.jl")
end
