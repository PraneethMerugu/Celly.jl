using Test
using CorePotts
using StructArrays

@testset "AST Math and Neighborhood Reductions" begin
    # Setup cell data mock
    cell_data = StructArray(
        volumes = Int32[10, 20, 30],
        target_volumes = Int32[20, 20, 20],
        surface_areas = Int32[100, 100, 100],
        cell_types = UInt8[1, 1, 2]
    )

    ctx = CorePotts.UpdateContext(0, nothing, nothing, UInt32(0), zeros(Float32, 3, 2))

    @testset "Native Math Operations" begin
        # Test Operator Overloads
        rule1 = Read(:volumes) + 5
        @test rule1 isa Add{Read{:volumes}, Constant{Int}}
        @test CorePotts.evaluate_update_rule(rule1, cell_data, 1, ctx, Val{:volumes}()) ==
              15

        rule2 = Read(:volumes) - Read(:target_volumes)
        @test rule2 isa Subtract{Read{:volumes}, Read{:target_volumes}}
        @test CorePotts.evaluate_update_rule(rule2, cell_data, 1, ctx, Val{:volumes}()) ==
              -10

        rule3 = Read(:volumes) * 2.0
        @test rule3 isa Multiply{Read{:volumes}, Constant{Float64}}
        @test CorePotts.evaluate_update_rule(rule3, cell_data, 2, ctx, Val{:volumes}()) ==
              40.0

        rule4 = Read(:volumes) / 2
        @test rule4 isa Divide{Read{:volumes}, Constant{Int}}
        @test CorePotts.evaluate_update_rule(rule4, cell_data, 2, ctx, Val{:volumes}()) ==
              10

        rule5 = Read(:volumes) > Constant(15)
        @test rule5 isa GreaterThan{Read{:volumes}, Constant{Int}}
        @test CorePotts.evaluate_update_rule(rule5, cell_data, 2, ctx, Val{:volumes}()) ==
              true
        @test CorePotts.evaluate_update_rule(rule5, cell_data, 1, ctx, Val{:volumes}()) ==
              false

        rule6 = Read(:volumes) < Read(:target_volumes)
        @test rule6 isa LessThan{Read{:volumes}, Read{:target_volumes}}
        @test CorePotts.evaluate_update_rule(rule6, cell_data, 1, ctx, Val{:volumes}()) ==
              true
        @test CorePotts.evaluate_update_rule(rule6, cell_data, 3, ctx, Val{:volumes}()) ==
              false
    end

    @testset "NeighborReduce" begin
        rule_max = NeighborReduce(max, :volumes, 1, 0.0f0)
        @test rule_max isa NeighborReduce{typeof(max), :volumes, Float32}

        rule_sum = NeighborReduce(+, :target_volumes, 2, 0.0f0)
        @test rule_sum isa NeighborReduce{typeof(+), :target_volumes, Float32}

        # _evaluate_spatial_reduce! test
        buf = zeros(Float32, 3, 2)
        rule_sum_assigned = CorePotts.NeighborReduce{typeof(+), :volumes, Float32}(UInt8(1), 1)

        CorePotts._evaluate_spatial_reduce!(
            rule_sum_assigned, UInt32(2), cell_data, UInt32(1), buf)
        @test buf[1, 1] == 20.0f0 # cell 2 volume is 20, type is 1

        CorePotts._evaluate_spatial_reduce!(
            rule_sum_assigned, UInt32(3), cell_data, UInt32(1), buf)
        @test buf[1, 1] == 20.0f0 # cell 3 type is 2 (not matched), so buf remains 20
    end
end
