using Test
using PottsToolkit
using CorePotts
using Images

@testset "Connectivity Integration Test" begin
    # 1. Setup a system with zero adhesion and zero perimeter penalty
    # We want a very hot temperature so the cell would normally fragment.
    sys = PottsSystem(
        CellType(:Medium),
        CellType(:A),
        VolumeComponent(CellType(:Medium) => (target=0.0f0, λ=0.0f0), CellType(:A) => (target=100.0f0, λ=100.0f0); flex=true),
        # NO AdhesionComponent
        # NO SurfaceAreaComponent
        # Add our connectivity constraint
        ConnectivityConstraint()
    )

    # 2. Build problem
    prob = PottsProblem(
        sys,
        Dict(CellType(:A) => 1),
        (50, 50);
        topology = MooreTopology{2}()
    )

    # 3. Create a single connected block of cell A
    center_idx = CartesianIndex(25, 25)
    # Clear grid first
    fill!(prob.u0.grid, 0)
    for I in CartesianIndices(prob.u0.grid)
        # Create a 10x10 block
        if abs(I[1] - 25) <= 5 && abs(I[2] - 25) <= 5
            prob.u0.grid[I] = 1 # Type A
        end
    end
    prob.u0.cell_data.volumes[1] = count(x -> x == 1, prob.u0.grid)

    # Ensure it's 1 connected component initially
    labels = label_components(prob.u0.grid .== 1, centered(trues(3, 3))) # 8-connectivity
    initial_components = maximum(labels)
    @test initial_components == 1

    # 4. Run for 200 sweeps
    sol = solve(prob, CheckerboardMetropolis(T = 10.0f0, sweeps_per_step = 1), dt = 1.0, tspan = (0.0, 200.0))

    # 5. Verify it's still 1 connected component
    # Because T=10, without connectivity constraint it would definitely boil and fragment.
    # The constraint should strictly hold it together as exactly 1 piece.
    final_labels = label_components(sol.u[end].grid .== 1, centered(trues(3, 3)))
    final_components = maximum(final_labels)

    @test final_components == 1

    # Also verify volume is maintained relatively well (it shouldn't disappear)
    @test sum(sol.u[end].grid .== 1) > 50
end
