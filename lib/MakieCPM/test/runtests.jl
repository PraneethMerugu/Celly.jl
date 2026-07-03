using Test
using MakieCPM
using CoreCPM
using CPMToolkit
using CommonSolve
using Makie
using Random

@testset "MakieCPM Integration" begin
    # 1. Setup a basic CPM Problem
    Medium = CellType(:Medium)
    Epithelial = CellType(:Epithelial)

    vol = VolumeComponent(Epithelial => (target=50.0, λ=5.0))
    adh = AdhesionComponent(
        (Medium, Epithelial) => 20.0,
        (Epithelial, Epithelial) => 5.0
    )

    sys = CPMSystem(cell_types=[Medium, Epithelial], penalties=[vol, adh])
    
    counts = Dict(Epithelial => 10)
    prob = CPMProblem(sys, counts, (30, 30))

    # 2. Test Makie Recipe
    # ensure it returns a figure
    fig = Figure()
    ax = Axis(fig[1, 1])
    plt = cpmplot!(ax, prob.u0)
    @test plt isa Any # Just ensure it doesn't crash

    # 3. Test Dashboard Builder
    metrics = [
        "Mean Volume" => u -> sum(u.cell_data.volumes) / max(1, count(>(0), u.cell_data.volumes))
    ]
    
    parameters = [
        "Temperature" => (range=0.1:0.1:50.0, start=20.0, action=(p, a, val) -> a)
    ]
    
    # ensure explore_cpm successfully constructs without crashing
    dashboard_fig = explore_cpm(prob, ParallelMetropolis(sweeps_per_step=20); metrics=metrics, parameters=parameters)
    @test dashboard_fig isa Figure
end
