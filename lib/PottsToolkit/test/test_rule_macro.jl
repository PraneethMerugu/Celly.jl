using Test
using PottsToolkit
using CorePotts

@testset "Rule Macro AST Parsing" begin
    # Test simple constant
    r1 = @rule 5
    @test r1 isa CorePotts.RuleBuilder
    @test isempty(r1.spatial_deps)
    @test r1.closure(nothing, 1, nothing, nothing) == 5

    # Test spatial rules extraction
    r9 = @rule contact(1)
    @test r9 isa CorePotts.RuleBuilder
    @test length(r9.spatial_deps) == 1
    @test r9.spatial_deps[1] isa CorePotts.ContactArea
    @test r9.spatial_deps[1].type_id == 1
    @test r9.spatial_deps[1].buffer_index == 1

    r10 = @rule medium_contact()
    @test length(r10.spatial_deps) == 1
    @test r10.spatial_deps[1] isa CorePotts.ContactArea
    @test r10.spatial_deps[1].type_id == 0

    r11 = @rule neighbor_count(2)
    @test length(r11.spatial_deps) == 1
    @test r11.spatial_deps[1] isa CorePotts.NeighborCount
    @test r11.spatial_deps[1].type_id == 2

    r12 = @rule neighbor_sum(:volumes, 2)
    @test length(r12.spatial_deps) == 1
    @test r12.spatial_deps[1] isa CorePotts.NeighborSum{:volumes}
    @test r12.spatial_deps[1].type_id == 2

    # Test multiple spatial rules extraction
    r_multi = @rule contact(1) + neighbor_count(2)
    @test length(r_multi.spatial_deps) == 2
    @test r_multi.spatial_deps[1] isa CorePotts.ContactArea
    @test r_multi.spatial_deps[2] isa CorePotts.NeighborCount
    @test r_multi.spatial_deps[1].buffer_index == 1
    @test r_multi.spatial_deps[2].buffer_index == 2

    # Test closure execution with spatial buffer
    ctx = CorePotts.UpdateContext(10, nothing, nothing, UInt32(0), (5, 10, 15, 20)) # spatial_buffer = (5, 10, 15, 20)

    # Mock cell_data 
    mutable struct MockCellData
        volumes::Vector{Int}
    end
    Base.getproperty(x::MockCellData, sym::Symbol) = getfield(x, sym)
    cd = MockCellData([10, 20])

    val = r_multi.closure(cd, 1, ctx, nothing)
    @test val == 20 # ctx.spatial_buffer[1] + ctx.spatial_buffer[3] = 5 + 15

    r_time = @rule time()
    @test r_time.closure(cd, 1, ctx, nothing) == 10
end
