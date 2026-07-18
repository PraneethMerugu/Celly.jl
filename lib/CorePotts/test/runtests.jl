using Test
using CorePotts

@testset "CorePotts" begin
    include("closures_test.jl")
    include("test_checkerboard.jl")
    include("test_chemotaxis.jl")
    include("test_connectivity.jl")
    include("test_edgecases.jl")
    include("test_event_gpu_sync.jl")
    include("test_focal_point_3d.jl")
    include("test_hst_detailed_balance.jl")
    include("test_hst_focal_point.jl")
    include("test_hst_length.jl")
    include("test_inheritance_rules.jl")
    include("test_length_3d.jl")
    include("test_mass_conservation.jl")
    include("test_mermaid_integration.jl")
    include("test_mitosis_overhaul.jl")
    include("test_ooc_backends.jl")
    include("test_property_updates.jl")
    include("test_sciml_saving.jl")
    include("test_topology_abstractions.jl")
end
