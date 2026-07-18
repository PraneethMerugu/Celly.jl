@testset "PottsToolkit reference vertical slice" begin
    medium = CellType(:Medium, is_background = true)
    cell = CellType(:Cell)
    system = PottsSystem(
        medium,
        cell,
        VolumeComponent(cell => (target = 12.0, λ = 2.0)),
        AdhesionComponent(
            (medium, medium) => 0.0,
            (medium, cell) => 8.0,
            (cell, cell) => 3.0,
        ),
    )
    layout = HypersphereLayout(cell, (8, 8), 2)

    first_run = reference_integrator(system, layout, (16, 16);
        temperature = 4.0, seed = 2026, max_cells = 8)
    second_run = reference_integrator(system, layout, (16, 16);
        temperature = 4.0, seed = 2026, max_cells = 8)
    inference_run = reference_integrator(system, layout, (16, 16);
        temperature = 4.0, seed = 2026, max_cells = 8)
    @test first_run isa ReferenceIntegrator
    @test n_cells(logical_state(first_run)) == 1
    @test property_value(logical_state(first_run), :target_volume, CellID(1)) == 12.0
    @test property_value(logical_state(first_run), :volume_strength, CellID(1)) == 2.0

    first_report = step_reference!(first_run)
    second_report = step_reference!(second_run)
    @test first_report == second_report
    @test (@inferred step_reference!(inference_run)) isa ReferenceMCSReport
    @test lattice_storage(logical_state(first_run)) == lattice_storage(logical_state(second_run))
    @test first_report.candidate_attempts == 16 * 16
end
