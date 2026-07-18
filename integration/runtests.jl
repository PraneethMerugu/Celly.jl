using Test
using CorePotts
using PottsToolkit
include("TestBackend.jl")
using .TestBackend: BACKEND, BACKEND_GROUP, backend_array, backend_zeros, @skip_if_no_gpu

@info "Running cross-package integration suite" backend=BACKEND_GROUP

const TEST_SHARD = get(ENV, "POTTS_TEST_SHARD", "all")
const TEST_SHARDS = ("all", "thermodynamics", "biophysics", "integration", "conformance")
TEST_SHARD in TEST_SHARDS || error(
    "POTTS_TEST_SHARD must be one of $(join(TEST_SHARDS, ", ")); got $(repr(TEST_SHARD))")
run_shard(name) = TEST_SHARD == "all" || TEST_SHARD == name
@info "Selected test shard" shard=TEST_SHARD

if get(ENV, "POTTS_TEST_INTRINSIC", "false") == "true" &&
        BACKEND_GROUP in ("CUDA", "Metal")
    const INTRINSIC_ALGORITHMS = (IntrinsicCheckerboardMetropolis,)
else
    const INTRINSIC_ALGORITHMS = ()
    @info "Skipping unqualified IntrinsicCheckerboardMetropolis baseline" backend = BACKEND_GROUP
end

const TEST_ALGORITHMS = (ParallelMetropolis, CheckerboardMetropolis, SequentialMetropolis, INTRINSIC_ALGORITHMS...)

include("reference/ReferenceSemantics.jl")
include("conformance/ConformanceHarness.jl")

@testset "Potts package-family integration [$(BACKEND_GROUP)]" begin
    run_shard("thermodynamics") && include("test_thermodynamics.jl")
    run_shard("biophysics") && include("test_biophysics.jl")
    if run_shard("integration")
        include("test_events.jl")
        include("integration_connectivity.jl")
        include("test_ecosystem_fixes.jl")
        include("test_focal_point_3d_fix.jl")
        include("test_isbits_blocker.jl")
    end
    if run_shard("conformance")
        include("conformance/test_reference_semantics.jl")
        include("conformance/test_harness.jl")
    end
end
