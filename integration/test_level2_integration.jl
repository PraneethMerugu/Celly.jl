using Test
using CorePotts
using KernelAbstractions
using PottsToolkit

@testset "PottsToolkit Level 2 ecosystem integration" begin
    @test PottsToolkit.PottsModel === PottsToolkit.Authoring.PottsModel
    @test !isdefined(PottsToolkit, Symbol("Potts", "System"))
    @test !isdefined(PottsToolkit, Symbol("Parallel", "Metropolis"))

    monolayer = PottsToolkit.ReferenceModels.monolayer_growth_problem(
        (20, 20); target_volume = 8, division_target = 12,
        capacity = 16, tspan = (0, 2), seed = 0x301)
    @test PottsToolkit.backend_report(monolayer,
        CorePotts.SequentialCPM(temperature = 2.0f0), BACKEND).qualified
    integrator = CorePotts.init(monolayer,
        CorePotts.SequentialCPM(temperature = 2.0f0);
        backend = BACKEND, save_start = false, save_end = false)
    CorePotts.step!(integrator)
    @test integrator.t == 1

    medium = PottsToolkit.Medium(:Medium)
    cell = PottsToolkit.CellType(:ConnectedCell)
    connected_model = PottsToolkit.PottsModel(
        medium, cell, PottsToolkit.PreserveConnectivity())
    mask = falses(8, 8)
    mask[3:6, 3:6] .= true
    connected = PottsToolkit.problem(connected_model, (8, 8),
        PottsToolkit.CellLayout(cell, 1, mask); capacity = 2, tspan = (0, 1))
    @test PottsToolkit.backend_report(connected,
        CorePotts.SequentialCPM(temperature = 2.0f0), BACKEND).qualified

    angiogenesis = PottsToolkit.ReferenceModels.elongation_driven_angiogenesis_problem(
        (12, 12); cells = 4, capacity = 8, tspan = (0, 1), seed = 0x302,
        target_volume = 4, target_elongation = 1.5)
    angiogenesis_report = PottsToolkit.backend_report(angiogenesis,
        CorePotts.SequentialCPM(temperature = 2.0f0), BACKEND)
    @test angiogenesis_report.qualified
    angiogenesis_integrator = CorePotts.init(angiogenesis,
        CorePotts.SequentialCPM(temperature = 2.0f0);
        backend = BACKEND, save_start = false, save_end = false)
    CorePotts.step!(angiogenesis_integrator)
    @test angiogenesis_integrator.t == 1
end
