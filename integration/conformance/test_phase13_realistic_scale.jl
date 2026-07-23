using .RealisticScaleRunner
using .RealisticEvidenceArchive
using .RealisticEvidenceAnalysis
using TOML

@testset "Phase 13 realistic-scale registration and runner" begin
    manifest = load_realistic_manifest()
    @test manifest["status"] == "registered-before-realistic-scale-sampling"
    @test manifest["layout_seed_domain"] != manifest["simulation_seed_domain"]
    @test length(manifest["workloads"]) == 3

    seeds = derive_replica_seeds(0x1301000000000001)
    @test seeds == derive_replica_seeds(0x1301000000000001)
    @test seeds.layout != seeds.dynamics
    @test_throws ArgumentError derive_replica_seeds(-1)

    relaxation = deepcopy(realistic_workload("adhesion_volume_relaxation", manifest))
    relaxation["dimensions"] = [16, 16]
    relaxation["cell_count"] = 4
    relaxation["burn_in_mcs"] = 1
    relaxation["measured_mcs"] = 4
    relaxation["observation_cadence_mcs"] = 1
    problem = build_realistic_problem(relaxation, 0x1301000000000001; manifest)
    @test problem.seed == seeds.dynamics
    @test problem.capacity == CorePotts.CellCapacity(4)
    @test CorePotts.property_values(problem.u0, :volume__target)[1:4] == fill(25.0f0, 4)
    @test CorePotts.property_values(problem.u0, :volume__strength)[1:4] == fill(1.0f0, 4)

    relaxation_results = Dict{String, Any}[]
    for algorithm in ("SequentialCPM", "CheckerboardSweepCPM")
        result = run_realistic_replica(relaxation, algorithm;
            seed = 0x1301000000000001, manifest)
        algorithm == "SequentialCPM" && push!(relaxation_results, result)
        @test result["algorithm"] == algorithm
        @test result["backend"] == "CPU"
        @test result["observation_count"] == 4
        @test result["observation_synchronizations"] == 4
        @test result["measured_mcs_per_second"] > 0
        @test isfinite(result["energy_per_mutable_site_mean"])
        @test startswith(result["layout_seed_hex"], "0x")
        @test startswith(result["dynamics_seed_hex"], "0x")
    end

    second = run_realistic_replica(relaxation, "SequentialCPM";
        seed = 0x1301000000000002, manifest)
    push!(relaxation_results, second)
    evidence = build_realistic_evidence(relaxation, "SequentialCPM",
        relaxation_results; backend = "cpu", profile = :diagnostic, manifest,
        source_revision = "test-dirty", reproduction_command = "test command")
    @test evidence["result"]["status"] == "diagnostic-collected"
    @test validate_realistic_evidence(evidence).valid
    @test evidence["identity"]["workload_fingerprint"] ==
        workload_fingerprint(relaxation, manifest)
    checker_summaries = deepcopy(relaxation_results)
    foreach(summary -> summary["algorithm"] = "CheckerboardSweepCPM", checker_summaries)
    checker_evidence = build_realistic_evidence(relaxation, "CheckerboardSweepCPM",
        checker_summaries; backend = "cpu", profile = :diagnostic, manifest,
        source_revision = "test-dirty", reproduction_command = "test command")
    analysis = analyze_realistic_equivalence(evidence, checker_evidence;
        comparison = :paired_algorithm, manifest)
    @test analysis["schema"]["name"] == "potts-realistic-equivalence-analysis"
    @test analysis["multiplicity"]["method"] == "Holm two-one-sided equivalence"
    @test length(analysis["endpoints"]) == 14
    @test all(haskey(endpoint, "adjusted_interval") for endpoint in analysis["endpoints"])
    family = analyze_realistic_family([evidence, evidence],
        [checker_evidence, checker_evidence]; comparison = :paired_algorithm, manifest)
    @test family["schema"]["name"] ==
        "potts-realistic-equivalence-family-analysis"
    @test family["multiplicity"]["hypotheses"] == 28
    @test family["multiplicity"]["scope"] ==
        "all applicable primary endpoints in the claim family"
    mktempdir() do directory
        path = joinpath(directory, "realistic.toml")
        @test write_realistic_evidence(path, evidence) == path
        @test validate_realistic_evidence(TOML.parsefile(path)).valid
        @test_throws ArgumentError write_realistic_evidence(path, evidence)
    end

    sorting = deepcopy(realistic_workload("differential_adhesion_sorting", manifest))
    sorting["dimensions"] = [16, 16]
    sorting["cell_count"] = 4
    sorting["burn_in_mcs"] = 1
    sorting["measured_mcs"] = 4
    sorting["observation_cadence_mcs"] = 1
    sorting_result = run_realistic_replica(sorting, "SequentialCPM";
        seed = 0x1301000000000002, manifest)
    @test 0 <= sorting_result["heterotypic_contact_fraction_mean"] <= 1
    @test 0 <= sorting_result["segregation_index_mean"] <= 1
    @test sorting_result["sorting_effective_sample_size"] > 0

    migration = deepcopy(realistic_workload("single_cell_migration", manifest))
    migration["dimensions"] = [16, 16]
    migration["burn_in_mcs"] = 1
    migration["measured_mcs"] = 5
    migration["observation_cadence_mcs"] = 1
    migration_result = run_realistic_replica(migration, "CheckerboardSweepCPM";
        seed = 0x1301000000000003, manifest)
    @test migration_result["net_displacement"] >= 0
    @test migration_result["mean_squared_displacement"] >= 0
    @test 0 <= migration_result["persistence"] <= 1
    @test migration_result["velocity_effective_sample_size"] > 0
end
