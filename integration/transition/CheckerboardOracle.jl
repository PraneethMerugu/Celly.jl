module CheckerboardOracle

using SparseArrays
using ..TransitionKernelOracle

export CheckerboardColoring, canonical_greedy_coloring, color_orders,
       CheckerboardLiftedState, CheckerboardLiftedCatalog, lifted_state_catalog,
       lifted_state_id, OrderedPriorityPattern, ordered_priority_patterns,
       ConflictSelectionDistribution, conflict_selection_distribution,
       checkerboard_color_pass_row, checkerboard_lifted_color_pass_row,
       checkerboard_lifted_mcs_row, marginalize_configuration,
       checkerboard_mcs_row, CheckerboardLiftedKernel,
       checkerboard_color_pass_kernel, checkerboard_mcs_kernel

const _PRIORITY_CARDINALITY = big(1) << 32

"""Canonical greedy coloring of the realized mutable-site conflict graph."""
struct CheckerboardColoring
    sites::Vector{Int}
    colors::Vector{Int}
    color_sites::Vector{Vector{Int}}
end

function _relation_dimensions(relation::OracleRelation)
    return length(first(relation.offsets))
end

function _default_conflict_relations(model::OracleModel)
    relations = Any[model.proposal_relation]
    for energy in model.energies
        energy isa OracleContactEnergy && push!(relations, energy.relation)
    end
    unique!(relations)
    return Tuple(relations)
end

function canonical_greedy_coloring(domain::OracleDomain, relations)
    relation_values = Tuple(relations)
    isempty(relation_values) && throw(ArgumentError(
        "checkerboard coloring requires a conflict relation"))
    all(relation -> relation isa OracleRelation, relation_values) || throw(ArgumentError(
        "checkerboard conflict relations must be OracleRelation values"))
    all(relation -> _relation_dimensions(relation) == length(domain.dims),
        relation_values) || throw(ArgumentError(
        "checkerboard conflict relations must match the domain dimension"))

    sites = sort!(copy(domain.mutable_sites))
    site_set = Set(sites)
    site_position = Dict(site => index for (index, site) in pairs(sites))
    neighbors = Vector{Vector{Int}}(undef, length(sites))
    for (index, site) in pairs(sites)
        realized = Int[]
        for relation in relation_values
            for direction in eachindex(relation.offsets)
                neighbor = realize_neighbor(domain, relation, site, direction)
                neighbor === nothing && continue
                neighbor != site && neighbor in site_set &&
                    push!(realized, site_position[neighbor])
            end
        end
        neighbors[index] = sort!(unique!(realized))
    end

    colors = zeros(Int, length(sites))
    maximum_color = 0
    for index in eachindex(sites)
        forbidden = Set{Int}()
        for neighbor_position in neighbors[index]
            color = colors[neighbor_position]
            color > 0 && push!(forbidden, color)
        end
        color = 1
        while color in forbidden
            color += 1
        end
        colors[index] = color
        maximum_color = max(maximum_color, color)
    end
    color_sites = [Int[sites[index] for index in eachindex(sites)
        if colors[index] == color] for color in 1:maximum_color]
    return CheckerboardColoring(sites, colors, color_sites)
end

function _permutations(values::Vector{Int})
    isempty(values) && return [()]
    result = Tuple[]
    for index in eachindex(values)
        head = values[index]
        tail = Int[values[j] for j in eachindex(values) if j != index]
        for suffix in _permutations(tail)
            push!(result, (head, suffix...))
        end
    end
    return result
end

"""Every color order, each of which has probability `1 / factorial(color_count)`."""
color_orders(coloring::CheckerboardColoring) =
    _permutations(collect(eachindex(coloring.color_sites)))

"""Configuration plus the realized color order and next color ordinal."""
struct CheckerboardLiftedState{S <: OracleMicrostate, O <: Tuple}
    configuration::S
    order::O
    ordinal::Int

    function CheckerboardLiftedState(configuration::S, order::O,
            ordinal::Integer) where {S <: OracleMicrostate, O <: Tuple}
        isempty(order) && throw(ArgumentError("a lifted checkerboard order cannot be empty"))
        sort(collect(order)) == collect(1:length(order)) || throw(ArgumentError(
            "a lifted checkerboard order must be a permutation of its colors"))
        1 <= ordinal <= length(order) + 1 || throw(ArgumentError(
            "a lifted checkerboard ordinal must name a pass or the completed boundary"))
        return new{S, O}(configuration, order, Int(ordinal))
    end
end

struct CheckerboardLiftedCatalog{L <: CheckerboardLiftedState}
    states::Vector{L}
    index::Dict{L, Int}
end

function lifted_state_catalog(catalog::StateCatalog,
        coloring::CheckerboardColoring)
    orders = color_orders(coloring)
    isempty(orders) && error("a checkerboard coloring has no color order")
    sample = CheckerboardLiftedState(first(catalog.states), first(orders), 1)
    states = typeof(sample)[]
    for configuration in catalog.states, order in orders,
            ordinal in 1:(length(order) + 1)
        push!(states, CheckerboardLiftedState(configuration, order, ordinal))
    end
    return CheckerboardLiftedCatalog(states,
        Dict(state => index for (index, state) in pairs(states)))
end

function lifted_state_id(catalog::CheckerboardLiftedCatalog,
        state::CheckerboardLiftedState)
    id = get(catalog.index, state, 0)
    id == 0 && throw(KeyError(state))
    return id
end

"""
One weak ordering of independent uniform `UInt32` priorities.

`ranks` run from lowest to highest priority. A pattern with `k` occupied ranks has probability
`binomial(2^32, k) / (2^32)^m`; enumerating every surjective rank vector therefore includes ties
without iterating over individual priority words.
"""
struct OrderedPriorityPattern
    ranks::Vector{Int}
    probability::ExactProbability
end

function ordered_priority_patterns(count::Integer)
    count >= 0 || throw(ArgumentError("priority pattern count must be non-negative"))
    count == 0 && return [OrderedPriorityPattern(Int[], one(ExactProbability))]
    patterns = OrderedPriorityPattern[]
    for distinct in 1:count
        rank_values = ntuple(_ -> 1:distinct, count)
        probability = ExactProbability(
            binomial(_PRIORITY_CARDINALITY, distinct),
            _PRIORITY_CARDINALITY^count)
        for assignment in Iterators.product(rank_values...)
            length(unique(assignment)) == distinct || continue
            push!(patterns, OrderedPriorityPattern(collect(assignment), probability))
        end
    end
    sum(pattern -> pattern.probability, patterns; init = zero(ExactProbability)) ==
        one(ExactProbability) || error("ordered priority patterns do not normalize")
    return patterns
end

function _claimed_cells(proposal::OracleProposal)
    claims = OracleOwner[]
    proposal.losing.kind === OracleCellKind && push!(claims, proposal.losing)
    proposal.gaining.kind === OracleCellKind && push!(claims, proposal.gaining)
    return unique!(claims)
end

function _claims(proposals)
    result = Dict{OracleOwner, Vector{Int}}()
    for (index, proposal) in pairs(proposals)
        for owner in _claimed_cells(proposal)
            push!(get!(result, owner, Int[]), index)
        end
    end
    return result
end

function _selected_indices(proposals, ranks)
    claims = _claims(proposals)
    winners = Dict{OracleOwner, Int}()
    for (owner, indices) in claims
        maximum_rank = maximum(index -> ranks[index], indices)
        tied = Int[index for index in indices if ranks[index] == maximum_rank]
        sort!(tied; by = index -> (proposals[index].recipient, index))
        winners[owner] = first(tied)
    end
    selected = Int[]
    for (index, proposal) in pairs(proposals)
        all(owner -> winners[owner] == index, _claimed_cells(proposal)) &&
            push!(selected, index)
    end
    return Tuple(selected)
end

function _has_claim_tie(proposals, ranks)
    for indices in values(_claims(proposals))
        maximum_rank = maximum(index -> ranks[index], indices)
        count(index -> ranks[index] == maximum_rank, indices) > 1 && return true
    end
    return false
end

struct ConflictSelectionDistribution
    outcomes::Dict{Tuple{Vararg{Int}}, ExactProbability}
    claim_tie_probability::ExactProbability
end

"""Exact conflict winners after finite-cell max-priority and recipient-identity tie breaking."""
function conflict_selection_distribution(proposals)
    proposal_values = collect(proposals)
    all(proposal -> proposal isa OracleProposal, proposal_values) || throw(ArgumentError(
        "checkerboard conflict inputs must be OracleProposal values"))
    outcomes = Dict{Tuple{Vararg{Int}}, ExactProbability}()
    tie_probability = zero(ExactProbability)
    for pattern in ordered_priority_patterns(length(proposal_values))
        selected = _selected_indices(proposal_values, pattern.ranks)
        outcomes[selected] = get(outcomes, selected, zero(ExactProbability)) +
                             pattern.probability
        _has_claim_tie(proposal_values, pattern.ranks) &&
            (tie_probability += pattern.probability)
    end
    sum(values(outcomes); init = zero(ExactProbability)) == one(ExactProbability) ||
        error("checkerboard conflict distribution does not normalize")
    return ConflictSelectionDistribution(outcomes, tie_probability)
end

function _convert_probability(::Type{T}, probability::ExactProbability) where {T <: Real}
    return convert(T, numerator(probability)) / convert(T, denominator(probability))
end

function _conventional_acceptance(model::OracleModel, state::OracleMicrostate,
        proposal::OracleProposal, domain::OracleDomain,
        ::Type{ExactProbability})
    iszero(model.temperature) || throw(ArgumentError(
        "exact checkerboard acceptance is limited to zero temperature"))
    destination = destination_state(state, proposal)
    delta = global_energy(model, destination, domain, ExactProbability) -
            global_energy(model, state, domain, ExactProbability)
    return delta <= 0 ? one(ExactProbability) : zero(ExactProbability)
end

function _conventional_acceptance(model::OracleModel, state::OracleMicrostate,
        proposal::OracleProposal, domain::OracleDomain, ::Type{BigFloat})
    temperature = BigFloat(model.temperature)
    temperature > 0 || throw(ArgumentError(
        "BigFloat checkerboard acceptance requires positive temperature"))
    destination = destination_state(state, proposal)
    delta = global_energy(model, destination, domain, BigFloat) -
            global_energy(model, state, domain, BigFloat)
    log_probability = -delta / temperature
    return log_probability >= 0 ? one(BigFloat) : exp(log_probability)
end

function _simultaneous_destination(state::OracleMicrostate, proposals, accepted)
    owners = state.owners
    for index in accepted
        proposal = proposals[index]
        state.owners[proposal.recipient] == proposal.losing || error(
            "checkerboard proposal no longer matches its common snapshot")
        owners = Base.setindex(owners, proposal.gaining, proposal.recipient)
    end
    return OracleMicrostate(owners; discrete = state.discrete)
end

function _acceptance_outcomes(state, proposals, selected, domain, model, ::Type{T}) where {T}
    isempty(selected) && return Dict(state => one(T))
    probabilities = T[_conventional_acceptance(
        model, state, proposals[index], domain, T) for index in selected]
    result = Dict{OracleMicrostate, T}()
    choices = ntuple(_ -> (false, true), length(selected))
    for decisions in Iterators.product(choices...)
        weight = one(T)
        accepted = Int[]
        for position in eachindex(selected)
            probability = probabilities[position]
            if decisions[position]
                weight *= probability
                push!(accepted, selected[position])
            else
                weight *= one(T) - probability
            end
        end
        iszero(weight) && continue
        destination = _simultaneous_destination(state, proposals, accepted)
        result[destination] = get(result, destination, zero(T)) + weight
    end
    return result
end

function _checkerboard_color_pass_row(state::OracleMicrostate, sites,
        domain::OracleDomain, model::OracleModel, ::Type{T}) where {T <: Real}
    relation = model.proposal_relation
    direction_count = length(relation.offsets)
    direction_count > 0 || error("checkerboard proposal relation has no directions")
    direction_choices = ntuple(_ -> 1:direction_count, length(sites))
    direction_weight = one(T) /
        convert(T, big(direction_count)^length(sites))
    row = Dict{OracleMicrostate, T}()
    for directions in Iterators.product(direction_choices...)
        proposals = OracleProposal[]
        for (position, recipient) in pairs(sites)
            proposal = direct_proposal(
                state, domain, relation, recipient, directions[position])
            proposal === nothing || push!(proposals, proposal)
        end
        conflicts = conflict_selection_distribution(proposals)
        for (selected, exact_conflict_weight) in conflicts.outcomes
            conflict_weight = _convert_probability(T, exact_conflict_weight)
            for (destination, acceptance_weight) in _acceptance_outcomes(
                    state, proposals, selected, domain, model, T)
                row[destination] = get(row, destination, zero(T)) +
                    direction_weight * conflict_weight * acceptance_weight
            end
        end
    end
    return row
end

function checkerboard_color_pass_row(state::OracleMicrostate, color::Integer,
        coloring::CheckerboardColoring, domain::OracleDomain, model::OracleModel;
        precision::PrecisionPolicy = PrecisionPolicy())
    1 <= color <= length(coloring.color_sites) || throw(BoundsError(
        coloring.color_sites, color))
    sites = coloring.color_sites[color]
    if iszero(model.temperature)
        return _checkerboard_color_pass_row(
            state, sites, domain, model, ExactProbability)
    end
    return setprecision(precision.bits + precision.refinement_bits) do
        _checkerboard_color_pass_row(state, sites, domain, model, BigFloat)
    end
end

function _lifted_color_pass_row(state::CheckerboardLiftedState,
        coloring, domain, model, ::Type{T}) where {T <: Real}
    if state.ordinal == length(state.order) + 1
        return Dict(state => one(T))
    end
    color = state.order[state.ordinal]
    configuration_row = _checkerboard_color_pass_row(
        state.configuration, coloring.color_sites[color], domain, model, T)
    row = Dict{CheckerboardLiftedState, T}()
    for (configuration, probability) in configuration_row
        destination = CheckerboardLiftedState(
            configuration, state.order, state.ordinal + 1)
        row[destination] = get(row, destination, zero(T)) + probability
    end
    return row
end

function checkerboard_lifted_color_pass_row(state::CheckerboardLiftedState,
        coloring::CheckerboardColoring, domain::OracleDomain, model::OracleModel;
        precision::PrecisionPolicy = PrecisionPolicy())
    if iszero(model.temperature)
        return _lifted_color_pass_row(
            state, coloring, domain, model, ExactProbability)
    end
    return setprecision(precision.bits + precision.refinement_bits) do
        _lifted_color_pass_row(state, coloring, domain, model, BigFloat)
    end
end

function _lifted_mcs_row(source::OracleMicrostate, coloring, domain, model,
        ::Type{T}) where {T <: Real}
    orders = color_orders(coloring)
    order_weight = one(T) / convert(T, length(orders))
    row = Dict{CheckerboardLiftedState, T}()
    for order in orders
        partial = Dict(CheckerboardLiftedState(source, order, 1) => order_weight)
        for _ in eachindex(order)
            next = Dict{CheckerboardLiftedState, T}()
            for (lifted, prefix_weight) in partial
                for (destination, pass_weight) in _lifted_color_pass_row(
                        lifted, coloring, domain, model, T)
                    next[destination] = get(next, destination, zero(T)) +
                                        prefix_weight * pass_weight
                end
            end
            partial = next
        end
        for (destination, probability) in partial
            row[destination] = get(row, destination, zero(T)) + probability
        end
    end
    return row
end

function checkerboard_lifted_mcs_row(source::OracleMicrostate,
        coloring::CheckerboardColoring, domain::OracleDomain, model::OracleModel;
        precision::PrecisionPolicy = PrecisionPolicy())
    if iszero(model.temperature)
        return _lifted_mcs_row(source, coloring, domain, model, ExactProbability)
    end
    return setprecision(precision.bits + precision.refinement_bits) do
        _lifted_mcs_row(source, coloring, domain, model, BigFloat)
    end
end

function marginalize_configuration(row::AbstractDict{<:CheckerboardLiftedState, T}) where {T}
    result = Dict{OracleMicrostate, T}()
    for (state, probability) in row
        result[state.configuration] = get(
            result, state.configuration, zero(T)) + probability
    end
    return result
end

function checkerboard_mcs_row(source::OracleMicrostate,
        coloring::CheckerboardColoring, domain::OracleDomain, model::OracleModel;
        precision::PrecisionPolicy = PrecisionPolicy())
    return marginalize_configuration(checkerboard_lifted_mcs_row(
        source, coloring, domain, model; precision))
end

struct CheckerboardLiftedKernel{T, C <: CheckerboardLiftedCatalog, G}
    catalog::C
    matrix::SparseMatrixCSC{T, Int}
    coloring::CheckerboardColoring
    resolution::Symbol
    convergence::G
end

function _sparse_matrix(rows, count::Int, ::Type{T}) where {T}
    I = Int[]
    J = Int[]
    V = T[]
    for source in eachindex(rows)
        for destination in sort!(collect(keys(rows[source])))
            probability = rows[source][destination]
            iszero(probability) && continue
            push!(I, source)
            push!(J, destination)
            push!(V, probability)
        end
    end
    return sparse(I, J, V, count, count)
end

function _lifted_pass_matrix(catalog::CheckerboardLiftedCatalog, coloring,
        domain, model, ::Type{T}) where {T <: Real}
    rows = Vector{Dict{Int, T}}(undef, length(catalog.states))
    for (source, state) in pairs(catalog.states)
        row = Dict{Int, T}()
        for (destination, probability) in _lifted_color_pass_row(
                state, coloring, domain, model, T)
            destination_id = get(catalog.index, destination, 0)
            destination_id != 0 || throw(ArgumentError(
                "lifted checkerboard catalog is not closed under a color pass"))
            row[destination_id] = get(row, destination_id, zero(T)) + probability
        end
        rows[source] = row
    end
    return _sparse_matrix(rows, length(catalog.states), T)
end

function checkerboard_color_pass_kernel(catalog::StateCatalog,
        domain::OracleDomain, model::OracleModel;
        conflict_relations = _default_conflict_relations(model),
        precision::PrecisionPolicy = PrecisionPolicy())
    coloring = canonical_greedy_coloring(domain, conflict_relations)
    lifted = lifted_state_catalog(catalog, coloring)
    if iszero(model.temperature)
        matrix = _lifted_pass_matrix(
            lifted, coloring, domain, model, ExactProbability)
        return CheckerboardLiftedKernel(
            lifted, matrix, coloring, :checkerboard_color_pass, nothing)
    end
    base = setprecision(precision.bits) do
        _lifted_pass_matrix(lifted, coloring, domain, model, BigFloat)
    end
    refined_bits = precision.bits + precision.refinement_bits
    refined = setprecision(refined_bits) do
        _lifted_pass_matrix(lifted, coloring, domain, model, BigFloat)
    end
    difference = setprecision(refined_bits) do
        _maximum_matrix_difference(base, refined)
    end
    tolerance = setprecision(refined_bits) do
        parse(BigFloat, precision.tolerance)
    end
    convergence = ConvergenceRecord(precision.bits, refined_bits,
        difference, tolerance, difference <= tolerance)
    convergence.converged || throw(ErrorException(
        "checkerboard color-pass kernel did not converge: maximum difference $(difference) exceeds $(tolerance)"))
    return CheckerboardLiftedKernel(
        lifted, refined, coloring, :checkerboard_color_pass, convergence)
end

function _mcs_matrix(catalog::StateCatalog, coloring, domain, model,
        ::Type{T}) where {T <: Real}
    rows = Vector{Dict{Int, T}}(undef, length(catalog.states))
    for (source, state) in pairs(catalog.states)
        row = Dict{Int, T}()
        lifted = _lifted_mcs_row(state, coloring, domain, model, T)
        for (destination, probability) in marginalize_configuration(lifted)
            destination_id = get(catalog.index, destination, 0)
            destination_id != 0 || throw(ArgumentError(
                "checkerboard catalog is not closed under a normalized MCS"))
            row[destination_id] = get(row, destination_id, zero(T)) + probability
        end
        rows[source] = row
    end
    return _sparse_matrix(rows, length(catalog.states), T)
end

function _maximum_matrix_difference(left, right)
    result = zero(BigFloat)
    for row in axes(left, 1), column in axes(left, 2)
        result = max(result,
            abs(BigFloat(left[row, column]) - BigFloat(right[row, column])))
    end
    return result
end

function checkerboard_mcs_kernel(catalog::StateCatalog, domain::OracleDomain,
        model::OracleModel; conflict_relations = _default_conflict_relations(model),
        precision::PrecisionPolicy = PrecisionPolicy())
    model.acceptance isa OracleConventionalMetropolis || throw(ArgumentError(
        "the checkerboard oracle currently qualifies conventional Metropolis acceptance"))
    coloring = canonical_greedy_coloring(domain, conflict_relations)
    if iszero(model.temperature)
        matrix = _mcs_matrix(catalog, coloring, domain, model, ExactProbability)
        return SparseTransitionKernel(
            catalog, matrix, :checkerboard_normalized_mcs, nothing)
    end
    base = setprecision(precision.bits) do
        _mcs_matrix(catalog, coloring, domain, model, BigFloat)
    end
    refined_bits = precision.bits + precision.refinement_bits
    refined = setprecision(refined_bits) do
        _mcs_matrix(catalog, coloring, domain, model, BigFloat)
    end
    difference = setprecision(refined_bits) do
        _maximum_matrix_difference(base, refined)
    end
    tolerance = setprecision(refined_bits) do
        parse(BigFloat, precision.tolerance)
    end
    convergence = ConvergenceRecord(precision.bits, refined_bits,
        difference, tolerance, difference <= tolerance)
    convergence.converged || throw(ErrorException(
        "checkerboard high-precision kernel did not converge: maximum difference $(difference) exceeds $(tolerance)"))
    return SparseTransitionKernel(catalog, refined,
        :checkerboard_normalized_mcs, convergence)
end

end
