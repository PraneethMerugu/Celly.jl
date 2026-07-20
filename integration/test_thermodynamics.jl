using Test
using CorePotts
using PottsToolkit

@testset "Typed thermodynamic reference path" begin
    problem = PottsToolkit.ReferenceModels.single_cell_fluctuation_problem(
        (20, 20); target_volume = 32, volume_strength = 2,
        eta = 0.5, tspan = (0, 2), seed = 0x101)
    components = CorePotts.realize_components(
        problem.model, CorePotts.default_parameters(problem.model))
    @test only(components.mechanics) isa CorePotts.FluctuatingVolumePressure
    @test isempty(components.energies)

    integrator = CorePotts.init(problem,
        CorePotts.SequentialCPM(temperature = 4.0f0);
        save_start = false, save_end = false)
    CorePotts.step!(integrator)
    @test integrator.t == 1
    @test CorePotts.finite_volume(
        CorePotts.logical_state(integrator), CorePotts.CellID(1)) > 0
    pressure = CorePotts.property_value(CorePotts.logical_state(integrator),
        :fluctuating_volume__pressure, CorePotts.CellID(1))
    @test isfinite(pressure)

    report = PottsToolkit.explain(PottsToolkit.ReferenceModels.monolayer_growth_model())
    @test any(declaration -> declaration.kind === :lifecycle_rule,
        report.declarations)
    @test all(declaration -> declaration.capabilities.portable,
        report.declarations)
end
