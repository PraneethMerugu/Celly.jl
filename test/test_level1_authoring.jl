using KernelAbstractions

@testset "Level 1 declarations and problem construction" begin
    medium = PottsToolkit.Medium(:extracellular)
    population_a = PottsToolkit.CellType(:population_a)
    population_b = PottsToolkit.CellType(:population_b)

    volume = PottsToolkit.Volume(
        population_a => (target = 4, strength = 2),
        population_b => (target = 4, strength = 2),
    )
    contact_energy = PottsToolkit.PairwiseLaw(
        :contact_energy,
        (medium, medium) => 0,
        (medium, population_a) => 8,
        (medium, population_b) => 8,
        (population_a, population_a) => 2,
        (population_b, population_b) => 2,
        (population_a, population_b) => 15;
        symmetric = true,
        missing = PottsToolkit.RejectMissingPairs(),
    )
    adhesion = PottsToolkit.Adhesion(contact_energy)
    level1 = PottsToolkit.PottsModel(
        population_b, adhesion, medium, volume, population_a)

    level2 = PottsToolkit.PottsModel(
        medium,
        population_a,
        population_b,
        PottsToolkit.VolumeConstraint(
            population_a => (target = 4, strength = 2),
            population_b => (target = 4, strength = 2),
        ),
        PottsToolkit.Adhesion(
            (medium, medium) => 0,
            (medium, population_a) => 8,
            (medium, population_b) => 8,
            (population_a, population_a) => 2,
            (population_b, population_b) => 2,
            (population_a, population_b) => 15;
            name = :contact_energy,
        ),
    )

    @test Base.isvalid(level1)
    @test PottsToolkit.semantic_fingerprint(level1) ==
          PottsToolkit.semantic_fingerprint(level2)
    @test sprint(show, volume) == "Volume(:volume)"

    defaulted = PottsToolkit.PairwiseLaw(
        :defaulted_contact, (population_a, population_a) => 2;
        missing = PottsToolkit.DefaultPairValue(0),
    )
    @test defaulted.default == 0.0f0

    @test_throws UndefKeywordError PottsToolkit.FluctuatingVolumePressure(
        population_a => (target = 4, strength = 2))
    pressure = PottsToolkit.FluctuatingVolumePressure(
        population_a => (target = 4, strength = 2);
        noise = PottsToolkit.IndependentNoise(1),
    )
    @test pressure.declaration.noise isa CorePotts.FixedMechanicalNoise
    @test PottsToolkit.AcceptanceTemperature() isa CorePotts.AlgorithmTemperatureNoise

    labels = UInt64[
        1 1 0 0
        1 1 0 0
        0 0 2 2
        0 0 2 2
    ]
    layout = PottsToolkit.Layout(PottsToolkit.LabelledCells(
        labels, (1 => population_a, 2 => population_b)))
    domain = PottsToolkit.CartesianDomain((4, 4);
        spacing = (1.0, 2.0), boundaries = (
            PottsToolkit.AxisBoundary(PottsToolkit.PeriodicBoundary()),
            PottsToolkit.AxisBoundary(PottsToolkit.ClosedBoundary()),
        ))
    prob = PottsToolkit.PottsProblem(level1, domain, layout;
        capacity = 4, tspan = (0, 1), seed = 42)

    @test prob isa CorePotts.PottsProblem
    @test prob.geometry === domain
    @test prob.seed == 42
    @test CorePotts.lattice_size(prob.u0) == (4, 4)
    @test CorePotts.compatibility_report(prob,
        CorePotts.SequentialCPM(temperature = 0.0f0),
        KernelAbstractions.CPU()).qualified
    solution = CorePotts.solve(prob,
        CorePotts.SequentialCPM(temperature = 0.0f0))
    @test solution.retcode == SciMLBase.ReturnCode.Success
    @test solution.t[end] == 1

    placed = PottsToolkit.Place(population_a, labels .== 1; identity = 1)
    @test placed isa PottsToolkit.CellLayout
    @test_throws ArgumentError PottsToolkit.Layout(:not_a_layout)
end

@testset "Level 1 phases, closed rules, and triggers" begin
    cell_type = PottsToolkit.CellType(:rule_cell)
    medium = PottsToolkit.Medium(:rule_medium)
    age = PottsToolkit.CellProperty(:age, cell_type; initial = 0.0f0,
        division = CorePotts.CloneOnDivision(),
        transition = CorePotts.PreserveOnTransition())
    target = PottsToolkit.CellProperty(:target, cell_type; initial = 2.0f0,
        division = CorePotts.CloneOnDivision(),
        transition = CorePotts.PreserveOnTransition())

    mechanics = PottsToolkit.Phase(:mechanics)
    growth_phase = PottsToolkit.Phase(:growth; after = mechanics)
    @test PottsToolkit.semantic_identity(growth_phase) ==
          PottsToolkit.SemanticName(:growth)
    @test growth_phase.after == (PottsToolkit.SemanticName(:mechanics),)
    @test_throws ArgumentError PottsToolkit.Phase(:bad;
        after = (mechanics, mechanics))

    growth = PottsToolkit.@rule phase = growth_phase age(cell) = age(cell) + 1.0
    @test growth isa PottsToolkit.Rule
    @test growth.phase === growth_phase
    @test growth.source isa PottsToolkit.SourceLocation
    @test PottsToolkit.evaluate(growth, (age = 2.0f0,)) == 3.0f0
    owner = PottsToolkit.OwnerReference(:cell)
    programmatic_growth = PottsToolkit.Rule(age, :cell, age(owner) + 1.0;
        phase = growth_phase)
    macro_model = PottsToolkit.PottsModel(medium, cell_type, age, growth)
    programmatic_model = PottsToolkit.PottsModel(
        medium, cell_type, age, programmatic_growth)
    @test PottsToolkit.semantic_fingerprint(macro_model) ==
          PottsToolkit.semantic_fingerprint(programmatic_model)

    mask = trues(3, 3)
    growth_problem = PottsToolkit.PottsProblem(
        macro_model, PottsToolkit.CartesianDomain((3, 3)),
        PottsToolkit.Layout(PottsToolkit.Place(cell_type, mask; identity = 1));
        capacity = 1, tspan = (0, 1), seed = 7)
    growth_solution = CorePotts.solve(growth_problem,
        CorePotts.SequentialCPM(temperature = 0.0f0);
        snapshot_policy = CorePotts.HostSnapshotPolicy())
    @test CorePotts.property_value(growth_solution.u[end].state,
        :age, CorePotts.CellID(1)) == 1.0f0

    growth_rate = PottsToolkit.CellParameter(:growth_rate, cell_type => 0.5)
    global_rate = PottsToolkit.ModelParameter(:global_rate, 0.25)
    typed_growth = PottsToolkit.@rule phase = growth_phase age(cell) =
        age(cell) + growth_rate(cell)
    global_growth = PottsToolkit.@rule phase = growth_phase target(cell) =
        target(cell) + global_rate(cell)
    parameter_model = PottsToolkit.PottsModel(medium, cell_type, age, target,
        growth_rate, global_rate, typed_growth, global_growth)
    @test Base.isvalid(parameter_model)
    @test length(CorePotts.lifecycle_events(
        PottsToolkit.lower(parameter_model; dimensions = 2).core_model)) == 2
    @test PottsToolkit.evaluate(typed_growth,
        (age = 2.0, growth_rate = 0.5)) == 2.5

    bounded = PottsToolkit.@rule phase = growth_phase target(cell) =
        if age(cell) >= 5
            max(target(cell) - 1, 0)
        else
            target(cell)
        end
    @test PottsToolkit.evaluate(bounded, (age = 6, target = 2)) == 1
    @test PottsToolkit.evaluate(bounded, (age = 1, target = 2)) == 2

    simultaneous = PottsToolkit.@rules phase = growth_phase begin
        age(cell) = age(cell) + 1
        target(cell) = target(cell) + 2
    end
    @test simultaneous isa PottsToolkit.RuleGroup
    @test length(simultaneous.rules) == 2
    @test PottsToolkit.evaluate(simultaneous.rules[1], (age = 3, target = 4)) == 4
    @test_throws ArgumentError PottsToolkit.RuleGroup(
        (simultaneous.rules[1], simultaneous.rules[1]))

    unchanged = PottsToolkit.@rule phase = growth_phase age(cell) = NoChange()
    @test PottsToolkit.evaluate(unchanged, (age = 2,)) isa PottsToolkit.NoChange

    ready = PottsToolkit.@trigger ready_to_retire(cell) = age(cell) >= 10
    @test ready isa PottsToolkit.TriggerRule
    @test PottsToolkit.evaluate(ready, (age = 10,))
    death = PottsToolkit.ImmediateDeath(cell_type; medium, trigger = ready,
        schedule = PottsToolkit.AtMCS(10))
    @test death.trigger isa CorePotts.PropertyAtLeast
    @test CorePotts.is_due(death.schedule, 10)
    @test CorePotts.is_due(PottsToolkit.EveryMCS(5; start = 5), 10)
    @test !CorePotts.is_due(PottsToolkit.BetweenMCS(3, 9; every = 3), 10)
    @test_throws ArgumentError PottsToolkit.AtMCS(0)

    syntax_error = try
        macroexpand(@__MODULE__, :(
            PottsToolkit.@rule phase = growth_phase age(cell) = begin
                x = age(cell)
                x + 1
            end))
        nothing
    catch error
        error
    end
    @test syntax_error isa ArgumentError

    first_cycle = PottsToolkit.Phase(:first_cycle;
        after = PottsToolkit.Phase(:second_cycle))
    second_cycle = PottsToolkit.Phase(:second_cycle;
        after = PottsToolkit.Phase(:first_cycle))
    cycle_age = PottsToolkit.@rule phase = first_cycle age(cell) = age(cell) + 1
    cycle_target = PottsToolkit.@rule phase = second_cycle target(cell) = target(cell) + 1
    cycle_report = PottsToolkit.validate(PottsToolkit.PottsModel(
        medium, cell_type, age, target, cycle_age, cycle_target))
    @test any(diagnostic -> diagnostic.code === :phase_dependency_cycle,
        cycle_report)
end
