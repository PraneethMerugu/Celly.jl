using Test

include(joinpath(@__DIR__, "..", "src", "Phase12Comparison.jl"))
using .Phase12Comparison

function synthetic_record(process_id; steady = 1.0, first_mcs = 2.0,
        memory = 1000, backend = "cpu", hardware_id = "cpu-arm64-reference",
        fingerprint = "model-fingerprint", device_allocations = 0)
    return Dict(
        "schema_version" => PHASE12_SCHEMA_VERSION,
        "record_kind" => "phase12-performance-run",
        "comparison_identity" => Dict(
            "contract_version" => PHASE12_CONTRACT_VERSION,
            "workload_set_version" => "paper-core-1.0.0",
            "harness_tree_sha256" => "harness-tree",
            "backend" => backend,
            "hardware_id" => hardware_id,
            "julia_version" => "1.12.6",
            "architecture" => "aarch64",
            "os" => "Darwin",
            "julia_threads" => 1,
            "precision" => "Float32",
            "profile" => "full",
            "tuning_policy" => "conservative",
        ),
        "run" => Dict("process_id" => process_id),
        "provenance" => Dict(
            "implementation_commit" => "baseline-implementation",
            "implementation_tree_sha256" => "tree",
            "harness_commit" => "harness",
            "git_dirty" => false,
        ),
        "workloads" => Dict(
            "migration_2d" => Dict(
                "family" => "single_cell_migration",
                "algorithm" => "SequentialCPM",
                "semantic_fingerprint" => fingerprint,
                "dimension_count" => 2,
                "dimensions" => [128, 128],
                "sites" => 128^2,
                "timed_mcs" => 10,
                "declared_lifecycle_observation_per_mcs" => false,
                "steady_median_seconds_per_mcs" => steady,
                "first_mcs_seconds" => first_mcs,
                "steady_median_host_allocated_bytes_per_mcs" => 0.0,
                "warm_execution_metrics" => Dict(
                    "host_allocations" => 0,
                    "device_allocations" => device_allocations,
                    "host_to_device_transfers" => 0,
                    "host_synchronizations" => 0,
                    "device_to_host_transfers" => 0,
                ),
                "residency" => Dict("backend_resident_bytes" => memory),
            ),
        ),
    )
end

@testset "Phase 12 comparison contract" begin
    baseline = [synthetic_record("baseline-$index"; steady = 1 + 0.01index)
                for index in 1:3]
    faster = [synthetic_record("faster-$index"; steady = 0.9 + 0.01index,
                  first_mcs = 1.9, memory = 1000)
              for index in 1:3]
    result = compare_record_groups(baseline, faster)
    @test result["comparable"]
    @test result["passed"]
    @test result["geometric_mean_steady_seconds_ratio"] < 1

    regression = [synthetic_record("regression-$index"; steady = 1.2,
                      first_mcs = 2.0, memory = 1000)
                  for index in 1:3]
    result = compare_record_groups(baseline, regression)
    @test result["comparable"]
    @test !result["passed"]
    @test !result["workloads"]["migration_2d"]["passed"]

    wrong_hardware = deepcopy(faster)
    for record in wrong_hardware
        record["comparison_identity"]["hardware_id"] = "different-host"
    end
    result = compare_record_groups(baseline, wrong_hardware)
    @test !result["comparable"]
    @test any(contains("hardware_id"), result["issues"])

    wrong_model = deepcopy(faster)
    for record in wrong_model
        record["workloads"]["migration_2d"]["semantic_fingerprint"] = "different"
    end
    result = compare_record_groups(baseline, wrong_model)
    @test !result["comparable"]
    @test any(contains("semantic_fingerprint"), result["issues"])

    allocating = [synthetic_record("allocating-$index"; steady = 0.8,
                      device_allocations = 1)
                  for index in 1:3]
    result = compare_record_groups(baseline, allocating)
    @test result["comparable"]
    @test !result["passed"]
    @test !isempty(result["residency_issues"])

    duplicate_process = [synthetic_record("same") for _ in 1:3]
    result = compare_record_groups(baseline, duplicate_process)
    @test !result["comparable"]
    @test any(contains("repeated process_id"), result["issues"])

    wrong_harness = deepcopy(faster)
    for record in wrong_harness
        record["comparison_identity"]["harness_tree_sha256"] = "different-harness"
    end
    result = compare_record_groups(baseline, wrong_harness)
    @test !result["comparable"]
    @test any(contains("harness_tree_sha256"), result["issues"])

    dirty = deepcopy(faster)
    dirty[1]["provenance"]["git_dirty"] = true
    result = compare_record_groups(baseline, dirty)
    @test !result["comparable"]
    @test any(contains("clean worktree"), result["issues"])

    hidden_transfer = deepcopy(faster)
    hidden_transfer[1]["workloads"]["migration_2d"]["warm_execution_metrics"][
        "device_to_host_transfers"] = 1
    result = compare_record_groups(baseline, hidden_transfer)
    @test result["comparable"]
    @test !result["passed"]
    @test any(contains("device_to_host_transfers"), result["residency_issues"])

    @test_throws ArgumentError aggregate_records(baseline[1:2])
end
