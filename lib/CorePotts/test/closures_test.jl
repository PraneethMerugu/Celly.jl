using CorePotts
using Test

@testset "CompiledRule" begin
    # Mock some data
    mutable struct MockCellData
        volumes::Vector{Int}
        target_volumes::Vector{Float32}
        cell_types::Vector{Int}
    end
    Base.getproperty(x::MockCellData, sym::Symbol) = getfield(x, sym)

    cd = MockCellData([10, 20], [10.0f0, 20.0f0], [1, 2])
    ctx = CorePotts.UpdateContext(0, nothing, nothing, UInt32(0), nothing, ())

    rule1 = CompiledRule((cell_data, cell_id, ctx, dt) -> cell_data.volumes[cell_id] * 2.0f0)
    rule2 = CompiledRule((cell_data, cell_id, ctx, dt) -> cell_data.target_volumes[cell_id] +
                                                      5.0f0)

    rules = (target_volumes = rule1, volumes = rule2)

    CorePotts.evaluate_and_assign_rules!(cd, 1, ctx, rules)

    @test cd.target_volumes[1] == 20.0f0 # 10 * 2.0f0
    @test cd.volumes[1] == 25 # 20.0f0 + 5.0f0, converted to Int
end
