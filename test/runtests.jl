using Test
using Potts
using CorePotts
using PottsToolkit
using SciMLBase

include("TestBackend.jl")
using .TestBackend: BACKEND, BACKEND_GROUP, backend_array, backend_zeros, @skip_if_no_gpu

@info "Running Potts.jl Test Suite" backend=BACKEND_GROUP

if BACKEND_GROUP in ("CUDA", "Metal")
    const INTRINSIC_ALGORITHMS = (IntrinsicCheckerboardMetropolis,)
else
    const INTRINSIC_ALGORITHMS = ()
    @info "Skipping IntrinsicCheckerboardMetropolis: not supported on $(BACKEND_GROUP)"
end

const TEST_ALGORITHMS = (ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis, INTRINSIC_ALGORITHMS...)

@testset "Potts.jl Integrated Test Suite [$(BACKEND_GROUP)]" begin
    include("test_thermodynamics.jl")
    include("test_biophysics.jl")
    include("test_events.jl")
    include("integration_connectivity.jl")
    include("test_ecosystem_fixes.jl")

    # Include all tests from CorePotts that were previously disconnected
    @testset "CorePotts Base & Engine Tests" begin
        include("../lib/CorePotts/test/closures_test.jl")
        include("../lib/CorePotts/test/test_checkerboard.jl")
        include("../lib/CorePotts/test/test_edgecases.jl")
        include("../lib/CorePotts/test/test_hst_detailed_balance.jl")
        
        @testset "HST Focal Point Penalty Test" begin
            include("../lib/CorePotts/test/test_hst_focal_point.jl")
            include("../lib/CorePotts/test/test_focal_point_3d.jl")
        end
        
        @testset "HST Length Penalty Test" begin
            include("../lib/CorePotts/test/test_hst_length.jl")
        end
        
        @testset "Chemotaxis Penalty Test" begin
            include("../lib/CorePotts/test/test_chemotaxis.jl")
        end
        
        include("../lib/CorePotts/test/test_topology_abstractions.jl")
        include("../lib/CorePotts/test/test_event_gpu_sync.jl")
        include("../lib/CorePotts/test/test_length_3d.jl")
        
        @testset "Events" begin
            include("../lib/CorePotts/test/test_mitosis_overhaul.jl")
            include("../lib/CorePotts/test/test_inheritance_rules.jl")
            include("../lib/CorePotts/test/test_property_updates.jl")
        end
        
        @testset "Connectivity" begin
            include("../lib/CorePotts/test/test_connectivity.jl")
        end
        
        include("../lib/CorePotts/test/test_ooc_backends.jl")
        include("../lib/CorePotts/test/test_mermaid_integration.jl")
    end
end
