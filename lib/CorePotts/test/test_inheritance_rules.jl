using Test
using CorePotts
using KernelAbstractions

@testset "Inheritance Rules" begin
    backend = CPU()
    # mock ws
    max_cells = 10
    grid = zeros(Int32, 10, 10)
    ws = CorePotts.MitosisWorkspace(grid, max_cells)

    ws.dev_parents[1:2] .= [1, 2]
    ws.dev_children[1:2] .= [3, 4]

    count = 2

    # mock cache with block_size
    cache = (block_size = 256, step_counter = Ref(UInt64(1)))

    @testset "Reset" begin
        array = Float32[10.0, 20.0, 0.0, 0.0, 0.0]
        rule = Reset(30.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test array[1] == 30.0f0
        @test array[2] == 30.0f0
        @test array[3] == 30.0f0
        @test array[4] == 30.0f0
    end

    @testset "ResetChild" begin
        array = Float32[10.0, 20.0, 0.0, 0.0, 0.0]
        rule = ResetChild(30.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test array[1] == 10.0f0
        @test array[2] == 20.0f0
        @test array[3] == 30.0f0
        @test array[4] == 30.0f0
    end

    @testset "AsymmetricReset" begin
        array = Float32[10.0, 20.0, 0.0, 0.0, 0.0]
        rule = AsymmetricReset(50.0f0, 60.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test array[1] == 50.0f0
        @test array[2] == 50.0f0
        @test array[3] == 60.0f0
        @test array[4] == 60.0f0
    end

    @testset "InheritAdd" begin
        array = Float32[10.0, 20.0, 0.0, 0.0, 0.0]
        rule = InheritAdd(5.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test array[1] == 15.0f0
        @test array[2] == 25.0f0
        @test array[3] == 5.0f0
        @test array[4] == 5.0f0
    end

    @testset "InheritMultiply" begin
        array = Float32[10.0, 20.0, 2.0, 3.0, 0.0]
        rule = InheritMultiply(2.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test array[1] == 20.0f0
        @test array[2] == 40.0f0
        @test array[3] == 4.0f0
        @test array[4] == 6.0f0
    end

    @testset "RandomUniform" begin
        array = Float32[10.0, 20.0, 0.0, 0.0, 0.0]
        rule = RandomUniform(10.0f0, 20.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test 10.0f0 <= array[1] <= 20.0f0
        @test 10.0f0 <= array[2] <= 20.0f0
        @test 10.0f0 <= array[3] <= 20.0f0
        @test 10.0f0 <= array[4] <= 20.0f0
    end

    @testset "RandomNormal" begin
        array = Float32[10.0, 20.0, 0.0, 0.0, 0.0]
        rule = RandomNormal(10.0f0, 2.0f0)
        CorePotts.apply_inheritance_rule!(rule, array, ws, count, backend, cache)
        KernelAbstractions.synchronize(backend)
        @test array[1] != 0.0f0
        @test array[3] != 0.0f0
    end
end
