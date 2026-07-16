using Test
using PottsToolkit
import PottsToolkit.Layouts: LayoutContext, build_layout!
import CorePotts

@testset "Layout Primitives Tests" begin
    Medium = CellType(:Medium, is_background = true)
    A = CellType(:A)
    B = CellType(:B)

    type_to_id = Dict(Medium => UInt8(0), A => UInt8(1), B => UInt8(2))

    @testset "RandomLayout" begin
        ctx = LayoutContext((20, 20), type_to_id)
        layout = RandomLayout(Dict(A => 5, B => 10))
        build_layout!(layout, ctx)

        # Grid size is 400
        # 5 cells of A and 10 cells of B should each have volume 1
        @test count(>(0), ctx.grid) == 15

        counts = Dict{UInt8, Int}(0 => 0, 1 => 0, 2 => 0)
        for val in ctx.grid
            if val > 0
                counts[ctx.cell_type_map[val]] += 1
            else
                counts[0] += 1
            end
        end
        @test counts[0] == 400 - 15
        @test counts[1] == 5
        @test counts[2] == 10
    end

    @testset "RectangleLayout" begin
        ctx = LayoutContext((20, 20), type_to_id)
        layout = RectangleLayout(A, (5, 5), (10, 10))
        build_layout!(layout, ctx)

        # 6x6 square
        @test count(>(0), ctx.grid) == 36
        @test length(ctx.cell_type_map) == 2 # Background + 1 A cell

        # Cell should be type A (id 1)
        cell_id = findfirst(==(1), ctx.grid)
        @test ctx.cell_type_map[ctx.grid[cell_id]] == 1
    end

    @testset "HypersphereLayout" begin
        ctx = LayoutContext((20, 20), type_to_id)
        layout = HypersphereLayout(B, (15, 15), 2)
        build_layout!(layout, ctx)

        # Area of circle with r=3 is approx 28 (pi * 9 = 28.27)
        c = count(>(0), ctx.grid)
        @test 8 <= c <= 16

        cell_id = findfirst(>(0), ctx.grid)
        @test ctx.cell_type_map[ctx.grid[cell_id]] == 2
    end

    @testset "ScatterSpheresLayout" begin
        ctx = LayoutContext((50, 50), type_to_id)
        layout = ScatterSpheresLayout(A, 10, 3)
        build_layout!(layout, ctx)

        # We should have spawned 10 distinct cell IDs
        # Background is 0, so max cell ID should be 10 (since next_cell_id starts at 1)
        unique_cells = unique(ctx.grid)
        @test length(unique_cells) >= 10 # Some spheres could completely overlap, but very unlikely in 50x50 with radius 3

        for id in unique_cells
            if id > 0
                @test ctx.cell_type_map[id] == 1 # Type A
            end
        end

        # Test bounded scatter
        ctx_bounded = LayoutContext((50, 50), type_to_id)
        layout_bounded = ScatterSpheresLayout(B, 5, 2, (10, 10), (20, 20))
        build_layout!(layout_bounded, ctx_bounded)

        for x in 1:50, y in 1:50
            if ctx_bounded.grid[x, y] > 0
                # A sphere of radius 2 centered between 10 and 20 can extend to 10-2 = 8 and 20+2 = 22
                @test 8 <= x <= 22
                @test 8 <= y <= 22
                @test ctx_bounded.cell_type_map[ctx_bounded.grid[x, y]] == 2 # Type B
            end
        end
    end

    @testset "CompositeLayout" begin
        ctx = LayoutContext((20, 20), type_to_id)
        layout = CompositeLayout([
            RectangleLayout(A, (2, 2), (5, 5)),
            HypersphereLayout(B, (15, 15), 2)
        ])
        build_layout!(layout, ctx)

        # Check both exist
        c_a = 0
        c_b = 0
        for val in ctx.grid
            if val > 0
                type = ctx.cell_type_map[val]
                if type == 1
                    c_a += 1
                elseif type == 2
                    c_b += 1
                end
            end
        end

        @test c_a == 16 # 4x4
        @test 9 <= c_b <= 16
    end
end
