using Test
using .ReferenceSemantics
using .ConformanceHarness

struct FixtureAdapter <: AbstractConformanceAdapter
    state::ReferenceState
    accounting::AttemptAccounting
end

ConformanceHarness.reference_state(adapter::FixtureAdapter) = adapter.state
ConformanceHarness.attempt_accounting(adapter::FixtureAdapter) = adapter.accounting

@testset "conformance harness" begin
    cases = conformance_case_matrix(backends = (:cpu, :metal))
    @test length(cases) == 24
    @test all(case -> case.dimension in (2, 3), cases)
    @test all(case -> case.numeric_type in (Float32, Float64), cases)

    state = ReferenceState((1, 1), Int32[0]; medium_ids = Int32[0])
    context = ReproductionContext(
        semantic_seed = 0x42,
        rng_version = "phase-3-test",
        model_fingerprint = "reference-fixture-v1",
        initial_state = state,
        algorithm = :sequential,
        numeric_type = Float32,
        dimension = 2,
        backend_report = "CPU scalar reference",
        command = "julia --project=integration integration/runtests.jl",
    )
    report = reproduction_report(context)
    @test occursin("semantic_seed=0x0000000000000042", report)
    @test occursin("initial_state_checksum=", report)
    failure = try
        require_conformance(false, "expected fixture failure", context; details = (attempts = 3,))
        nothing
    catch error
        error
    end
    @test failure isa ConformanceFailure
    @test occursin("reproduce=", sprint(showerror, failure))

    completed = AttemptAccounting(1)
    completed = record_attempt(completed, :no_op)
    validated = validate_adapter(FixtureAdapter(state, completed))
    @test validated.state_checksum == canonical_checksum(state)
    @test require_logical_match(state, state, context) === nothing

    ci = statistical_procedure(:ci)
    @test assess_bernoulli(5_000, 10_000, 0.5, ci).pass
    @test !assess_bernoulli(5_300, 10_000, 0.5, ci).pass
    @test assess_bernoulli(0, 10_000, 0.0, ci).pass
    @test !assess_bernoulli(0, 10, 0.0, ci).pass
end
