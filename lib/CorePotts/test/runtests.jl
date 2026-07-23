using Test
using CorePotts
import CorePotts: LegacyPottsProblem, LegacyPottsIntegrator, LegacyPottsSolution,
                  AbstractSampler, MetropolisSampler, PottsState, PottsParameters,
                  PottsCache, ParallelMetropolis, CheckerboardMetropolis,
                  SequentialMetropolis, IntrinsicCheckerboardMetropolis

backend_zeros(::Type{T}, dims...) where {T} = zeros(T, dims...)

const TEST_ALGORITHMS = (
    ParallelMetropolis,
    CheckerboardMetropolis,
    SequentialMetropolis
)

@testset "CorePotts" begin
    include("closures_test.jl")
    include("test_checkerboard.jl")
    include("test_chemotaxis.jl")
    include("test_connectivity.jl")
    include("test_edgecases.jl")
    include("test_event_gpu_sync.jl")
    include("test_focal_point_3d.jl")
    include("test_hst_detailed_balance.jl")
    include("test_hst_focal_point.jl")
    include("test_hst_length.jl")
    include("test_inheritance_rules.jl")
    include("test_length_3d.jl")
    include("test_logical_initialization.jl")
    include("test_logical_lifecycle.jl")
    include("test_logical_state.jl")
    include("test_mass_conservation.jl")
    include("test_mermaid_integration.jl")
    include("test_mitosis_overhaul.jl")
    include("test_ooc_backends.jl")
    include("test_property_updates.jl")
    include("test_rng_semantics.jl")
    include("test_execution_contracts.jl")
    include("test_reference_engine.jl")
    include("test_sciml_saving.jl")
    include("test_scientific_protocols.jl")
    include("test_phase13_contract_versions.jl")
    include("test_phase13_quality_gates.jl")
    include("test_state_semantics.jl")
    include("test_phase8_protocols.jl")
    include("test_phase8_lifecycle.jl")
    include("test_phase8_persistence.jl")
    include("test_phase9_sciml_interface.jl")
    include("test_topology_abstractions.jl")
    include("test_cartesian_relations.jl")
    include("test_proposal_acceptance.jl")
    include("test_scientific_hamiltonians.jl")
    include("test_scientific_transactions.jl")
    include("test_scientific_fields.jl")
    include("test_scientific_queries_connectivity.jl")
    include("test_scientific_focal_points.jl")
    include("test_scientific_elongation.jl")
    include("test_scientific_inner_loop.jl")
    include("test_phase10_extension_protocol.jl")
    include("test_scientific_mechanics.jl")
    include("test_sequential_algorithms.jl")
    include("test_checkerboard_algorithms.jl")
    include("test_tiled_checkerboard.jl")
    include("test_lottery_algorithms.jl")
    include("test_scientific_device_path.jl")
end
