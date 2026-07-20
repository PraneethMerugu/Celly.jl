using SciMLBase
using KernelAbstractions

@testset "Phase 10 immutable Level 2 authoring foundation" begin
    L2 = PottsToolkit.Authoring

    medium = L2.Medium(:Medium)
    cell = L2.CellType(:Cell)
    volume = L2.VolumeConstraint(cell => (target = 12.0, strength = 2.0))
    adhesion = L2.Adhesion(
        (medium, medium) => 0.0,
        (medium, cell) => 8.0,
        (cell, cell) => 3.0,
    )

    model = L2.PottsModel(medium, cell, volume, adhesion)
    normalized = L2.normalize(model)
    report = L2.explain(normalized)

    @test Base.isvalid(model)
    @test CorePotts.real_type(normalized.numerics) === Float32
    normalized_volume = only(component for component in normalized.components
        if component isa L2.VolumeConstraint)
    @test normalized_volume.bindings[cell].target === 12.0f0
    @test report.fingerprint == L2.semantic_fingerprint(normalized)
    @test length(report.declarations) == 2
    volume_report = only(declaration for declaration in report.declarations
        if declaration.identity == L2.semantic_identity(volume))
    @test only(volume_report.semantic_data.bindings).target == 12.0f0
    @test volume_report.capabilities.dimensions == (2, 3)
    @test all(entry -> entry isa L2.ProvenanceEntry &&
        !isempty(entry.lowering_path), L2.provenance(normalized))
    @test isempty(L2.dependencies(normalized).unresolved)
    manifest = L2.semantic_manifest(normalized)
    @test manifest.fingerprint == normalized.fingerprint
    @test manifest.reconstruction === :not_claimed
    @test occursin("PottsToolkit normalized model",
        sprint(show, MIME("text/plain"), normalized))
    @test occursin("portable", sprint(show, MIME("text/plain"), report))

    reordered = L2.PottsModel(adhesion, volume, cell, medium)
    @test L2.semantic_fingerprint(L2.normalize(reordered)) ==
          L2.semantic_fingerprint(normalized)

    renamed_source_order = L2.Adhesion(
        (cell, cell) => 3.0,
        (cell, medium) => 8.0,
        (medium, medium) => 0.0,
    )
    @test L2.semantic_fingerprint(L2.normalize(
        L2.PottsModel(cell, renamed_source_order, medium, volume))) ==
          L2.semantic_fingerprint(normalized)

    float64_model = L2.PottsModel(medium, cell, volume, adhesion;
        numerics = CorePotts.NumericalPolicy(Float64))
    float64_normalized = L2.normalize(float64_model)
    float64_volume = only(component for component in float64_normalized.components
        if component isa L2.VolumeConstraint)
    @test float64_volume.bindings[cell].target === 12.0
    @test L2.semantic_fingerprint(float64_normalized) !=
          L2.semantic_fingerprint(normalized)

    added = L2.add(L2.PottsModel(medium, cell, volume), adhesion)
    @test length(added) == 4
    @test length(model) == 4
    removed = L2.remove(added, L2.semantic_identity(adhesion))
    @test length(removed) == 3
    replaced = L2.replace(removed, L2.semantic_identity(volume),
        L2.VolumeConstraint(cell => (target = 14.0, strength = 2.0)))
    @test L2.semantic_fingerprint(L2.normalize(L2.add(replaced, adhesion))) !=
          L2.semantic_fingerprint(normalized)

    fragment = L2.ModelFragment(:mechanics, volume, adhesion;
        exports = (L2.semantic_identity(volume), L2.semantic_identity(adhesion)))
    composed = L2.compose(L2.PottsModel(medium, cell), fragment)
    @test L2.semantic_fingerprint(L2.normalize(composed)) ==
          L2.semantic_fingerprint(normalized)

    private_fragment = L2.ModelFragment(:private_mechanics, volume, adhesion)
    private_normalized = L2.normalize(
        L2.compose(L2.PottsModel(medium, cell), private_fragment))
    @test all(component -> component.name.namespace.parts == (:private_mechanics,),
        private_normalized.components)
    @test all(entry -> entry.origin === :fragment,
        filter(entry -> entry.fragment !== nothing, L2.provenance(private_normalized)))

    required_fragment = L2.ModelFragment(:required, volume;
        requirements = (cell,), exports = (volume,))
    @test L2.normalize(L2.compose(
        L2.PottsModel(medium, cell), required_fragment)) isa L2.NormalizedModel
    missing_requirement = L2.ModelFragment(:missing_requirement, volume;
        requirements = (L2.CellType(:Missing),), exports = (volume,))
    requirement_report = L2.validate(L2.compose(
        L2.PottsModel(medium, cell), missing_requirement))
    @test any(item -> item.code === :unsatisfied_fragment_requirement,
        requirement_report)
    bad_export = L2.ModelFragment(:bad_export, volume;
        exports = (L2.SemanticName(:missing),))
    export_report = L2.validate(L2.compose(L2.PottsModel(medium, cell), bad_export))
    @test any(item -> item.code === :unknown_fragment_export, export_report)

    inner_fragment = L2.ModelFragment(:inner, volume)
    outer_fragment = L2.ModelFragment(:outer, inner_fragment)
    nested = L2.normalize(L2.compose(L2.PottsModel(medium, cell), outer_fragment))
    @test only(nested.components).name.namespace.parts == (:outer, :inner)
    @test only(entry for entry in L2.provenance(nested)
        if entry.fragment !== nothing).fragment ==
        L2.SemanticName(:inner; namespace = L2.Namespace(:outer))

    incomplete_adhesion = L2.Adhesion((medium, cell) => 8.0)
    incomplete_model = L2.PottsModel(medium, cell, volume, incomplete_adhesion)
    invalid_report = L2.validate(incomplete_model)
    @test !Base.isvalid(invalid_report)
    @test any(item -> item.code === :missing_pairwise_values, invalid_report)
    missing_pairs = only(item for item in invalid_report
        if item.code === :missing_pairwise_values)
    @test missing_pairs.stage === :normalization
    @test !isempty(missing_pairs.correction)
    @test_throws L2.ModelValidationError L2.normalize(incomplete_model)

    defaulted = L2.Adhesion((medium, cell) => 8.0; default = 0.0)
    @test Base.isvalid(L2.PottsModel(medium, cell, volume, defaulted))

    other = L2.CellType(:Other)
    unknown_binding = L2.VolumeConstraint(other => (target = 4.0, strength = 1.0))
    unknown_report = L2.validate(L2.PottsModel(medium, cell, unknown_binding))
    @test any(item -> item.code === :unknown_cell_type, unknown_report)

    duplicate_report = L2.validate(L2.PottsModel(medium, cell, cell, volume, adhesion))
    @test any(item -> item.code === :duplicate_identity, duplicate_report)

    writer_a = L2.PropertyUpdate(volume, cell; name = :writer_a, amount = 1.0)
    writer_b = L2.PropertyUpdate(volume, cell; name = :writer_b, amount = 2.0)
    writer_report = L2.validate(
        L2.PottsModel(medium, cell, volume, writer_a, writer_b))
    @test any(item -> item.code === :ambiguous_property_writers, writer_report)

    direct = CorePotts.PositiveYield(0.25f0)
    direct_model = L2.PottsModel(medium, cell, volume, adhesion, direct)
    @test L2.normalize(direct_model) isa L2.NormalizedModel
    @test only(component for component in L2.explain(direct_model).declarations
        if component.identity.name === :positive_yield).effects ==
        (:proposal_rate_modifier,)

    contact_relation = CorePotts.first_shell_relation(
        CorePotts.ContactRole(), Val(2); spacing = (1.0f0, 1.0f0))
    surface_relation = CorePotts.first_shell_relation(
        CorePotts.SurfaceRole(), Val(2); spacing = (1.0f0, 1.0f0))
    connectivity_relation = CorePotts.first_shell_relation(
        CorePotts.ConnectivityRole(), Val(2); spacing = (1.0f0, 1.0f0))
    medium_types = CorePotts.MediumTypeTable(
        CorePotts.MediumID(1) => CorePotts.CellTypeID(2))
    direct_components = (
        CorePotts.QuadraticVolumeHamiltonian(number_type = Float32),
        CorePotts.UnorderedContactHamiltonian(
            Float32[1 2; 2 0], medium_types, contact_relation),
        CorePotts.QuadraticBoundaryHamiltonian(
            CorePotts.BoundaryEdgeCount(), surface_relation; number_type = Float32),
        CorePotts.FluctuatingSurfaceTension(
            CorePotts.BoundaryEdgeCount(), surface_relation),
        CorePotts.PreserveConnectedCells(connectivity_relation),
        CorePotts.FocalPointSpringHamiltonian(),
        CorePotts.FixedFocalEndpointConstraint(CorePotts.FocalPointSpringHamiltonian()),
    )
    for component in direct_components
        fingerprint = L2.semantic_fingerprint(L2.normalize(
            L2.PottsModel(medium, cell, component)))
        @test !isempty(fingerprint.digest)
    end
    @test L2.semantic_fingerprint(L2.normalize(direct_model)) !=
        L2.semantic_fingerprint(L2.normalize(
            L2.PottsModel(medium, cell, volume, adhesion,
                CorePotts.PositiveYield(0.5f0))))
end

@testset "Phase 10 Level 2 public lowering vertical slice" begin
    L2 = PottsToolkit.Authoring

    medium = L2.Medium(:Medium)
    cell = L2.CellType(:Cell)
    volume = L2.VolumeConstraint(cell => (target = 4.0, strength = 2.0))
    fluctuating = L2.FluctuatingVolumeConstraint(
        cell => (target = 4.0, strength = 1.0);
        eta = 0.5, noise = CorePotts.FixedMechanicalNoise(0.25f0))
    adhesion = L2.Adhesion(
        (medium, medium) => 0.0,
        (medium, cell) => 4.0,
        (cell, cell) => 1.0)
    age = L2.CellProperty(:age, cell; initial = 0.0,
        invariant = L2.ClosedPropertyInterval(0.0, 100.0),
        division = CorePotts.CloneOnDivision(),
        transition = CorePotts.PreserveOnTransition())
    growth = L2.StochasticPropertyUpdate(volume, cell; name = :growth,
        amount = 0.5, probability = 1.0)
    aging = L2.StochasticPropertyUpdate(age, cell; name = :aging,
        role = :value, amount = 1.0, probability = 1.0)
    model = L2.PottsModel(
        medium, cell, volume, fluctuating, adhesion, age, growth, aging)

    lowered_2d = L2.lower(model; dimensions = 2)
    @test lowered_2d.core_model isa CorePotts.PottsModel
    @test length(CorePotts.property_keys(lowered_2d.property_schema)) == 6
    components = CorePotts.realize_components(
        lowered_2d.core_model, CorePotts.default_parameters(lowered_2d.core_model))
    @test length(components.energies) == 2
    @test length(components.mechanics) == 1
    @test length(CorePotts.lifecycle_events(lowered_2d.core_model)) == 2
    @test all(component -> CorePotts.validate_proposal_component(component) === component,
        (components.energies..., components.mechanics...))
    execution_id = L2.execution_fingerprint(model,
        CorePotts.SequentialCPM(temperature = 2.0f0), KernelAbstractions.CPU();
        dimensions = 2)
    @test execution_id == L2.execution_fingerprint(model,
        CorePotts.SequentialCPM(temperature = 2.0f0), KernelAbstractions.CPU();
        dimensions = 2)
    @test execution_id != L2.execution_fingerprint(model,
        CorePotts.SequentialCPM(temperature = 2.0f0), KernelAbstractions.CPU();
        dimensions = 3)

    invalid_problem = L2.validate_problem(model, (4, 4),
        L2.CellLayout(cell, 1, falses(3, 3)),
        L2.CellLayout(cell, 1, falses(4, 4));
        capacity = 0, tspan = (2, 1), seed = -1, spacing = (1.0,))
    @test !Base.isvalid(invalid_problem)
    @test all(code -> any(item -> item.code === code && item.stage === :problem,
        invalid_problem), (:layout_shape_mismatch, :invalid_cell_capacity,
        :invalid_mcs_tspan, :invalid_seed, :invalid_spacing,
        :duplicate_provisional_cell_id, :initial_capacity_exceeded))
    @test_throws L2.ProblemValidationError L2.problem(model, (4, 4),
        L2.CellLayout(cell, 1, falses(4, 4)); capacity = 0)

    mask_2d = falses(4, 4)
    mask_2d[2:3, 2:3] .= true
    problem_2d = L2.problem(model, (4, 4), L2.CellLayout(cell, 1, mask_2d);
        capacity = 4, tspan = (0, 2), seed = 0x10)
    @test problem_2d isa CorePotts.PottsProblem
    @test L2.backend_report(problem_2d,
        CorePotts.LotteryCPM(temperature = 2.0f0),
        KernelAbstractions.CPU()).qualified
    @test problem_2d.seed == 0x10
    @test CorePotts.finite_volume(problem_2d.u0, CorePotts.CellID(1)) == 4
    @test CorePotts.property_value(problem_2d.u0, :volume__target,
        CorePotts.CellID(1)) == 4.0f0
    integrator_2d = CorePotts.init(problem_2d,
        CorePotts.SequentialCPM(temperature = 2.0f0);
        save_start = false, save_end = false)
    CorePotts.step!(integrator_2d)
    @test CorePotts.property_value(CorePotts.logical_state(integrator_2d),
        :volume__target, CorePotts.CellID(1)) == 4.5f0
    @test CorePotts.property_value(CorePotts.logical_state(integrator_2d),
        :age, CorePotts.CellID(1)) == 1.0f0
    solution_2d = CorePotts.solve(problem_2d,
        CorePotts.SequentialCPM(temperature = 2.0f0))
    @test solution_2d.retcode == SciMLBase.ReturnCode.Success
    @test solution_2d.t[end] == 2

    mask_3d = falses(3, 3, 3)
    mask_3d[2, 2, 2] = true
    problem_3d = L2.problem(model, (3, 3, 3), L2.CellLayout(cell, 7, mask_3d);
        capacity = 2, tspan = (0, 1), seed = 0x20)
    solution_3d = CorePotts.solve(problem_3d,
        CorePotts.SequentialCPM(temperature = 2.0f0))
    @test solution_3d.retcode == SciMLBase.ReturnCode.Success
    @test CorePotts.lattice_size(problem_3d.u0) == (3, 3, 3)

    remade = SciMLBase.remake(model; numerics = CorePotts.NumericalPolicy(Float64))
    @test CorePotts.real_type(remade.numerics) === Float64
    @test CorePotts.real_type(model.numerics) === Float32
end
