using Test
using CorePotts
using PottsToolkit

@testset "Dynamic Cell Data Allocation" begin
    # Test 1: Minimum properties
    ct1 = CellType(:Cell, is_background=false)
    sys1 = PottsSystem(
        cell_types = [ct1],
        penalties = [VolumeComponent(ct1 => (target=100.0, λ=5.0))]
    )
    prob1 = PottsProblem(sys1, Dict(sys1.cell_types[1] => 10), (50, 50))
    
    @test hasproperty(prob1.u0.cell_data, :volumes)
    @test hasproperty(prob1.u0.cell_data, :target_volumes)
    @test hasproperty(prob1.u0.cell_data, :cell_types)
    @test !hasproperty(prob1.u0.cell_data, :surface_areas)
    @test !hasproperty(prob1.u0.cell_data, :pressures)
    @test !hasproperty(prob1.u0.cell_data, :anchor_x)
    @test !hasproperty(prob1.u0.cell_data, :current_lengths)

    # Test 2: Add SurfaceAreaPenalty
    ct2 = CellType(:Cell, is_background=false)
    sys2 = PottsSystem(
        cell_types = [ct2],
        penalties = [
            VolumeComponent(ct2 => (target=100.0, λ=5.0)),
            SurfaceAreaComponent(ct2 => (target=30.0, λ=2.0))
        ]
    )
    prob2 = PottsProblem(sys2, Dict(sys2.cell_types[1] => 10), (50, 50))
    
    @test hasproperty(prob2.u0.cell_data, :volumes)
    @test hasproperty(prob2.u0.cell_data, :surface_areas)
    @test hasproperty(prob2.u0.cell_data, :target_surface_areas)
    @test !hasproperty(prob2.u0.cell_data, :pressures)

    # Test 3: Add LengthFlexTracker (via LengthComponent with Flex)
    ct3 = CellType(:Cell, is_background=false)
    sys3 = PottsSystem(
        cell_types = [ct3],
        penalties = [
            VolumeComponent(ct3 => (target=100.0, λ=5.0)),
            LengthComponent(ct3 => (target=20.0, λ=3.0); flex=true)
        ]
    )
    prob3 = PottsProblem(sys3, Dict(sys3.cell_types[1] => 10), (50, 50))
    
    @test hasproperty(prob3.u0.cell_data, :current_lengths)
    @test hasproperty(prob3.u0.cell_data, :target_lengths)
    @test hasproperty(prob3.u0.cell_data, :length_lambdas)
    @test hasproperty(prob3.u0.cell_data, :anchor_x)
    @test hasproperty(prob3.u0.cell_data, :major_axis_y)
    @test hasproperty(prob3.u0.cell_data, :inertia_xy)
    @test !hasproperty(prob3.u0.cell_data, :surface_areas)
end
