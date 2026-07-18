@testset "proposal construction and acceptance semantics" begin
    owners = fill(MediumOwner(1), 3, 3)
    owners[4] = CellOwner(1)
    owners[6] = CellOwner(1)
    state = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = MediumID[MediumID(1)])
    domain = CartesianDomain((3, 3))
    relation = first_shell_relation(ProposalRole(), Val(2))
    @test validate_relation_domain(domain, relation) === relation

    # At recipient 5, canonical direction 1 is -x and selects cell 1 at site 4.
    attempt = construct_copy_attempt(state, domain, relation, 5, 1;
        mcs = 7, semantic_id = 99)
    @test is_actionable(attempt)
    @test attempt.losing == MediumOwner(1)
    @test attempt.gaining == CellOwner(1)
    @test attempt.forward_multiplicity == 2
    @test attempt.reverse_multiplicity == 2
    proposal = actionable_proposal(attempt)
    @test proposal.recipient == 5
    @test proposal.donor == 4
    @test proposal.mcs == 7
    @test proposal.semantic_id == 99
    @test proposal_probabilities(proposal, mutable_site_count(domain),
        direction_count(relation)) == (q_forward = 2 / 36, q_reverse = 2 / 36)

    same_owner = construct_copy_attempt(state, domain, relation, 4, 1)
    @test same_owner.outcome === SameOwnerAttempt
    @test !is_actionable(same_owner)
    @test_throws ArgumentError actionable_proposal(same_owner)

    closed = CartesianDomain((3, 3);
        boundaries = (
            AxisBoundary(ClosedBoundary()), AxisBoundary(ClosedBoundary())))
    boundary = construct_copy_attempt(state, closed, relation, 1, 1)
    @test boundary.outcome === BoundaryNullAttempt

    obstacle_domain = CartesianDomain((3, 3);
        obstacles = (5 => MediumOwner(2),))
    obstacle_state_owners = copy(owners)
    obstacle_state_owners[5] = MediumOwner(2)
    obstacle_state = LogicalPottsState(obstacle_state_owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)),
        medium_domains = MediumID[MediumID(1), MediumID(2)])
    immutable = construct_copy_attempt(obstacle_state, obstacle_domain, relation, 5, 1)
    @test immutable.outcome === ImmutableRecipientAttempt

    compiled_state = compile_state(state)
    compiled_domain = compile_domain(domain)
    @test construct_copy_attempt(compiled_state, compiled_domain, relation, 5, 1) ==
          construct_copy_attempt(state, domain, relation, 5, 1)

    conventional_downhill = AcceptanceInputs(-1.0)
    conventional_uphill = AcceptanceInputs(2.0)
    @test acceptance_probability(ConventionalMetropolis(), conventional_downhill, 3.0) ==
          1.0
    @test acceptance_probability(ConventionalMetropolis(), conventional_uphill, 0.0) == 0.0
    @test acceptance_probability(ConventionalMetropolis(), AcceptanceInputs(0.0), 0.0) ==
          1.0
    @test acceptance_probability(ConventionalMetropolis(), conventional_uphill, 2.0) ≈
          exp(-1)

    asymmetric = AcceptanceInputs(0.0; forward_multiplicity = 4, reverse_multiplicity = 1)
    @test acceptance_probability(MetropolisHastings(), asymmetric, 0.0) == 0.25
    @test acceptance_probability(MetropolisHastings(), asymmetric, 2.0) == 0.25
    no_reverse = AcceptanceInputs(-10.0; reverse_multiplicity = 0)
    @test acceptance_probability(MetropolisHastings(), no_reverse, 2.0) == 0.0
    forbidden = AcceptanceInputs(-10.0; constraints_allowed = false)
    @test acceptance_probability(ConventionalMetropolis(), forbidden, 2.0) == 0.0
    @test acceptance_decision(MetropolisHastings(), asymmetric, 2.0, 0.2)
    @test !acceptance_decision(MetropolisHastings(), asymmetric, 2.0, 0.3)
    @test_throws ArgumentError acceptance_probability(ConventionalMetropolis(),
        AcceptanceInputs(0.0; drive_log_bias = 1.0), 0.0)
    @test_throws ArgumentError AcceptanceInputs(0.0; forward_multiplicity = 0)
    @test_throws ArgumentError acceptance_decision(ConventionalMetropolis(),
        AcceptanceInputs(0.0), 1.0, 1.0)
end
