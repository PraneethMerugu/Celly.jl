using Test
using CorePotts
using PottsToolkit
using SciMLBase

@testset "Typed biophysical reference workloads" begin
    sorting_model = PottsToolkit.ReferenceModels.differential_adhesion_model(
        within_a = 2, within_b = 3, between = 15, medium_contact = 8)
    sorting = PottsToolkit.ReferenceModels.differential_adhesion_problem(
        (16, 16); cells_per_population = 3, capacity = 12,
        tspan = (0, 1), seed = 0x201,
        within_a = 2, within_b = 3, between = 15, medium_contact = 8)
    @test PottsToolkit.semantic_fingerprint(sorting_model) ==
        PottsToolkit.semantic_fingerprint(PottsToolkit.normalize(sorting_model))
    @test length(CorePotts.active_cell_ids(sorting.u0)) == 6
    sorting_solution = CorePotts.solve(sorting,
        CorePotts.SequentialCPM(temperature = 3.0f0))
    @test sorting_solution.retcode == SciMLBase.ReturnCode.Success

    profile_fingerprints = PottsToolkit.SemanticFingerprint[]
    for profile in (:linear, :half_normal, :exponential)
        model = PottsToolkit.ReferenceModels.chemotaxis_model(target_volume = 12)
        push!(profile_fingerprints, PottsToolkit.semantic_fingerprint(model))
        report = PottsToolkit.explain(model)
        @test any(declaration -> declaration.kind === :field,
            report.declarations)
        chemotaxis = PottsToolkit.ReferenceModels.chemotaxis_problem(
            (16, 16); profile, target_volume = 12,
            capacity = 2, tspan = (0, 1), seed = 0x202)
        @test CorePotts.solve(chemotaxis,
            CorePotts.SequentialCPM(temperature = 2.0f0)).retcode ==
            SciMLBase.ReturnCode.Success
    end
    @test length(unique(profile_fingerprints)) == 1

    droplet_2d = PottsToolkit.ReferenceModels.droplet_problem(
        (16, 16); target_volume = 32, tspan = (0, 1), seed = 0x203)
    droplet_3d = PottsToolkit.ReferenceModels.droplet_problem(
        (8, 8, 8); target_volume = 32, tspan = (0, 1), seed = 0x204)
    @test CorePotts.lattice_size(droplet_2d.u0) == (16, 16)
    @test CorePotts.lattice_size(droplet_3d.u0) == (8, 8, 8)
end
