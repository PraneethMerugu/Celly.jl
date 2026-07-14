using Test
using MakiePotts
using CorePotts
using PottsToolkit
using CommonSolve
using Makie
using Random

@testset "MakiePotts Integration" begin
    # 1. Setup a basic Potts Problem
    Medium = CellType(:Medium)
    Epithelial = CellType(:Epithelial)

    vol = VolumeComponent(Epithelial => (target = 50.0, λ = 5.0))
    adh = AdhesionComponent(
        (Medium, Epithelial) => 20.0,
        (Epithelial, Epithelial) => 5.0
    )

    sys = PottsSystem(cell_types = [Medium, Epithelial], penalties = [vol, adh])

    counts = Dict(Epithelial => 10)
    prob = PottsProblem(sys, counts, (30, 30))

    # 2. Test Makie Recipe
    # ensure it returns a figure
    fig = Figure()
    ax = Axis(fig[1, 1])
    plt = pottsplot!(ax, prob.u0)
    @test plt isa Any # Just ensure it doesn't crash

    # 3. Test Dashboard Builder
    metrics = [
        "Mean Volume" =>
        u -> sum(u.cell_data.volumes) / max(1, count(>(0), u.cell_data.volumes))
    ]

    parameters = [
        "Temperature" => (range = 0.1:0.1:50.0, start = 20.0, action = (p, a, val) -> a)
    ]

    # ensure explore_potts successfully constructs without crashing
    dashboard_fig = explore_potts(prob, ParallelMetropolis(sweeps_per_step = 20);
        metrics = metrics, parameters = parameters)
    @test dashboard_fig isa Figure
end
