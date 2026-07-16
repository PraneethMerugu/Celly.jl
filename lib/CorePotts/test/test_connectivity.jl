using Test
using CorePotts

@testset "Connectivity Constraint Tests" begin
    # Mock context
    # ctx requires: topology, src, neighbors
    struct MockContext
        topology::Any
        src::UInt32
        neighbors::Tuple
    end

    topo = MooreTopology{2}()
    penalty = ConnectivityConstraint()

    # Test 1: Medium fragmentation (should always accept)
    ctx1 = MockContext(topo, 0, (1, 0, 1, 0, 1, 0, 1, 0))
    @test CorePotts.evaluate_penalty(penalty, ctx1) == 0.0f0

    # Test 2: Flat Wall
    # e.g., E, NE, SE are cell 1, rest are 0
    # CCW order: E, NE, N, NW, W, SW, S, SE
    # So 1, 1, 0, 0, 0, 0, 0, 1
    ctx2 = MockContext(topo, 1, (1, 1, 0, 0, 0, 0, 0, 1))
    @test CorePotts.evaluate_penalty(penalty, ctx2) == 0.0f0

    # Test 3: Corner
    # E=1, NE=1, N=1
    ctx3 = MockContext(topo, 1, (1, 1, 1, 0, 0, 0, 0, 0))
    @test CorePotts.evaluate_penalty(penalty, ctx3) == 0.0f0

    # Test 4: Line break
    # E=1, W=1
    ctx4 = MockContext(topo, 1, (1, 0, 0, 0, 1, 0, 0, 0))
    @test CorePotts.evaluate_penalty(penalty, ctx4) == typemax(Float32)

    # Test 5: Diagonal break
    # NE=1, SW=1
    ctx5 = MockContext(topo, 1, (0, 1, 0, 0, 0, 1, 0, 0))
    @test CorePotts.evaluate_penalty(penalty, ctx5) == typemax(Float32)

    # Test 6: Creating a hole (interior pixel)
    # All 8 neighbors are 1
    ctx6 = MockContext(topo, 1, (1, 1, 1, 1, 1, 1, 1, 1))
    @test CorePotts.evaluate_penalty(penalty, ctx6) == typemax(Float32)

    # Test 7: Isolated pixel dying
    # All 8 neighbors are 0
    ctx7 = MockContext(topo, 1, (0, 0, 0, 0, 0, 0, 0, 0))
    @test CorePotts.evaluate_penalty(penalty, ctx7) == 0.0f0

    # Test 8: Non-Moore/3D Topology should throw ArgumentError in PottsParameters
    # We test that the system constructor throws eagerly
    @test_throws ArgumentError CorePotts.PottsParameters(
        VonNeumannTopology{2}(), (ConnectivityConstraint(),), (), ()
    )
    @test_throws ArgumentError CorePotts.PottsParameters(
        MooreTopology{3}(), (ConnectivityConstraint(),), (), ()
    )
end
