using Test
using .ReferenceSemantics

function reference_fixture(; property_order = :forward)
    properties = property_order === :forward ?
        (target_volume = Int32[0, 4, 5], age = Int32[0, 1, 2]) :
        (age = Int32[0, 1, 2], target_volume = Int32[0, 4, 5])
    return ReferenceState((2, 2), Int32[1, 1, 0, 2];
        active_ids = Int32[1, 2], reusable_ids = Int32[3],
        generations = Dict(Int32(1) => 1, Int32(2) => 2, Int32(3) => 0),
        cell_types = Dict(Int32(1) => :epithelial, Int32(2) => :mesenchymal),
        properties = properties, medium_ids = Int32[0])
end

@testset "scalar reference semantics" begin
    @test reference_mcs_attempts(7) == 7
    @test proposal_probability(4, 8, Float32) == 1f0 / 32f0
    @test conventional_metropolis_probability(2.0, 1.0) == exp(-2.0)
    @test conventional_metropolis_probability(0.0, 0.0) == 1.0
    @test conventional_metropolis_probability(1.0, 0.0) == 0.0
    @test metropolis_hastings_probability(0.0, 0.0, 4.0, 1.0) == 0.25
    @test accepts(1.0, 0.999) && !accepts(0.0, 0.0)
    @test canonical_stencil(((1, 0), (0, -1), (-1, 0), (0, 1)); symmetric = true) ==
          [(-1, 0), (0, -1), (0, 1), (1, 0)]
    @test realized_neighbor((1, 1), (-1, 0), (2, 2), :closed) === nothing
    @test realized_neighbor((1, 1), (-1, 0), (2, 2), :periodic) == (2, 1)
    address = SemanticAddress(stream = ReferenceSemantics.ProposalStream,
        mcs = 4, site = 7, draw_index = 2)
    @test semantic_address_key(0x42, address) == semantic_address_key(0x42, address)
    @test semantic_address_key(0x42, address) != semantic_address_key(0x42,
        SemanticAddress(stream = ReferenceSemantics.AcceptanceStream,
            mcs = 4, site = 7, draw_index = 2))

    accounting = AttemptAccounting(7)
    for outcome in (:accepted, :rejected, :no_op, :accepted, :no_op, :rejected, :no_op)
        accounting = record_attempt(accounting, outcome)
    end
    @test isempty(attempt_accounting_errors(accounting))
    @test assert_reference_mcs(accounting) === accounting

    incomplete = record_attempt(AttemptAccounting(2), :accepted)
    @test !isempty(attempt_accounting_errors(incomplete))
end

@testset "logical state and transaction references" begin
    state = reference_fixture()
    @test isempty(state_invariant_errors(state))
    @test recompute_volumes(state) == Dict(Int32(1) => 2, Int32(2) => 1)
    @test medium_occupancies(state) == Dict(Int32(0) => 1)
    @test canonical_checksum(state) == canonical_checksum(reference_fixture(property_order = :reverse))

    proposal = ReferenceProposal(3, 2, Int32(0), Int32(1))
    rejected = apply_copy_transaction(state, proposal; accepted = false)
    @test rejected === state
    accepted = apply_copy_transaction(state, proposal; accepted = true)
    @test accepted.owners == Int32[1, 1, 1, 2]
    @test recompute_volumes(accepted) == Dict(Int32(1) => 3, Int32(2) => 1)
    energy = candidate -> count(==(Int32(1)), candidate.owners)
    @test local_energy_change(energy, state, proposal) == 1

    @test_throws StateInvariantViolation transactional_lifecycle(state) do candidate
        push!(candidate.active_ids, Int32(4))
    end
    @test state.active_ids == Int32[1, 2]

    invalid = reference_fixture()
    invalid.owners[1] = Int32(9)
    @test !isempty(state_invariant_errors(invalid))

    invalid_id = reference_fixture()
    invalid_id.active_ids[1] = Int32(0)
    @test !isempty(state_invariant_errors(invalid_id))
end
