using Test
using CoreCPM

@testset "Topology Abstractions Shortest Vector" begin
    # Test periodic boundary (Moore/VonNeumann)
    topo = MooreTopology{2}()
    W = 100.0f0
    
    # Simple no-wrap distance
    @test CoreCPM.shortest_vector(topo, 10.0f0, W) == 10.0f0
    @test CoreCPM.shortest_vector(topo, -10.0f0, W) == -10.0f0
    
    # Wrap around W
    @test CoreCPM.shortest_vector(topo, 90.0f0, W) == -10.0f0
    @test CoreCPM.shortest_vector(topo, -90.0f0, W) == 10.0f0
    
    # Exact half boundaries
    @test CoreCPM.shortest_vector(topo, 50.0f0, W) == -50.0f0 || CoreCPM.shortest_vector(topo, 50.0f0, W) == 50.0f0
    
    # NoFlux topologies
    noflux_topo = NoFluxMooreTopology{2}()
    @test CoreCPM.shortest_vector(noflux_topo, 10.0f0, W) == 10.0f0
    @test CoreCPM.shortest_vector(noflux_topo, 90.0f0, W) == 90.0f0
    @test CoreCPM.shortest_vector(noflux_topo, -90.0f0, W) == -90.0f0
end
