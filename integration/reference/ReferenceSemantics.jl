module ReferenceSemantics

using SHA

export AttemptAccounting, ReferenceProposal, ReferenceState, CanonicalSnapshot,
       StateInvariantViolation, CellCapacityError, DivisionRequest, reference_mcs_attempts,
       proposal_probability, ProposalProbabilities, neighbor_copy_probabilities,
       conventional_metropolis_probability, metropolis_hastings_probability,
       accepts, record_attempt, attempt_accounting_errors, assert_reference_mcs,
       SemanticStream, SemanticAddress, semantic_address_key,
       canonical_stencil, realized_neighbor, local_energy_change, volume_constraint_energy,
       contact_hamiltonian,
       canonical_snapshot, canonical_checksum, state_invariant_errors,
       assert_valid_state, recompute_volumes, volume_tracker_delta, apply_volume_tracker_delta,
       volume_tracker_errors, medium_occupancies, apply_copy_transaction,
       transactional_lifecycle, apply_division_batch, retire_zero_volume, release_retired_slots

"""Versioned named streams, represented independently of any RNG implementation."""
@enum SemanticStream::UInt16 begin
    LayoutStream = 1
    ProposalStream = 2
    AcceptanceStream = 3
    AlgorithmScheduleStream = 4
    RuleStream = 5
    EventStream = 6
    LifecycleStream = 7
    InheritanceStream = 8
    EnsembleStream = 9
end

"""Scheduling-independent semantic coordinates for one random draw."""
struct SemanticAddress
    stream::SemanticStream
    mcs::UInt64
    subround::UInt64
    operation::UInt64
    site::UInt64
    cell_id::UInt64
    cell_generation::UInt64
    draw_index::UInt64
end

function SemanticAddress(; stream::SemanticStream, mcs::Integer = 0, subround::Integer = 0,
        operation::Integer = 0, site::Integer = 0, cell_id::Integer = 0,
        cell_generation::Integer = 0, draw_index::Integer = 0)
    values = (mcs, subround, operation, site, cell_id, cell_generation, draw_index)
    all(value -> value >= 0, values) || throw(ArgumentError(
        "semantic RNG coordinates must be non-negative"))
    return SemanticAddress(stream, UInt64(mcs), UInt64(subround), UInt64(operation), UInt64(site),
        UInt64(cell_id), UInt64(cell_generation), UInt64(draw_index))
end

"""Stable diagnostic key for a semantic draw; this is not the final random-bit generator."""
function semantic_address_key(master_seed::Integer, address::SemanticAddress)
    master_seed >= 0 || throw(ArgumentError("master_seed must be non-negative"))
    identity = join((
        "potts-semantic-address-v1",
        string(UInt64(master_seed); base = 16, pad = 16),
        string(UInt16(address.stream); base = 16, pad = 4),
        string(address.mcs; base = 16, pad = 16),
        string(address.subround; base = 16, pad = 16),
        string(address.operation; base = 16, pad = 16),
        string(address.site; base = 16, pad = 16),
        string(address.cell_id; base = 16, pad = 16),
        string(address.cell_generation; base = 16, pad = 16),
        string(address.draw_index; base = 16, pad = 16),
    ), '|')
    return bytes2hex(SHA.sha256(identity))
end

"""Exact logical accounting for one normalized reference MCS."""
struct AttemptAccounting
    mutable_sites::Int
    candidate_attempts::Int
    realized_proposals::Int
    no_op_attempts::Int
    rejected_proposals::Int
    accepted_proposals::Int
end

function AttemptAccounting(mutable_sites::Integer)
    mutable_sites >= 0 || throw(ArgumentError("mutable_sites must be non-negative"))
    return AttemptAccounting(Int(mutable_sites), 0, 0, 0, 0, 0)
end

"""A non-no-op ownership-copy proposal in logical lattice coordinates."""
struct ReferenceProposal{I, O}
    recipient::I
    donor::I
    old_owner::O
    new_owner::O

    function ReferenceProposal(recipient::I, donor::I, old_owner::O, new_owner::O) where {I, O}
        old_owner != new_owner || throw(ArgumentError(
            "a ReferenceProposal must represent a non-no-op owner change"))
        return new{I, O}(recipient, donor, old_owner, new_owner)
    end
end

"""A requested daughter geometry; requests are compacted by parent ID before assignment."""
struct DivisionRequest{O}
    parent::O
    daughter_sites::Vector{Int}
end

DivisionRequest(parent, daughter_sites) = DivisionRequest(parent, collect(Int, daughter_sites))

struct CellCapacityError <: Exception
    requested::Int
    available::Int
end

function Base.showerror(io::IO, error::CellCapacityError)
    print(io, "fixed cell capacity cannot accommodate ", error.requested,
        " valid divisions; only ", error.available, " slots are available")
end

"""
    ReferenceState(shape, owners; active_ids, reusable_ids, generations, cell_types,
                   properties, medium_ids)

Minimal logical state used only by the conformance suite. It deliberately carries no device arrays,
workspaces, or legacy storage fields.
"""
mutable struct ReferenceState{O, C, P}
    shape::Tuple
    owners::Vector{O}
    active_ids::Vector{O}
    reusable_ids::Vector{O}
    generations::Dict{O, UInt64}
    cell_types::Dict{O, C}
    properties::P
    medium_ids::Vector{O}
end

function ReferenceState(shape::Tuple, owners::AbstractArray{O};
        active_ids::AbstractVector{O} = O[], reusable_ids::AbstractVector{O} = O[],
        generations::AbstractDict{O, <:Integer} = Dict{O, UInt64}(),
        cell_types::AbstractDict = Dict{O, Any}(), properties::NamedTuple = NamedTuple(),
        medium_ids::AbstractVector{O} = O[]) where {O}
    length(owners) == prod(shape) || throw(ArgumentError(
        "owner length $(length(owners)) does not match logical shape $shape"))
    copied_generations = Dict{O, UInt64}(id => UInt64(generation) for (id, generation) in generations)
    copied_cell_types = Dict{O, Any}(cell_types)
    return ReferenceState{O, Any, typeof(properties)}(
        shape, collect(owners), collect(active_ids), collect(reusable_ids), copied_generations,
        copied_cell_types, properties, collect(medium_ids))
end

"""A layout-independent, canonically ordered logical snapshot."""
struct CanonicalSnapshot{O, C, P}
    shape::Tuple
    owners::Vector{O}
    active_ids::Vector{O}
    reusable_ids::Vector{O}
    generations::Vector{Pair{O, UInt64}}
    cell_types::Vector{Pair{O, C}}
    properties::P
    medium_ids::Vector{O}
end

reference_mcs_attempts(mutable_sites::Integer) =
    mutable_sites >= 0 ? Int(mutable_sites) : throw(ArgumentError("mutable_sites must be non-negative"))

struct ProposalProbabilities{T}
    q_forward::T
    q_reverse::T
    forward_multiplicity::Int
    reverse_multiplicity::Int
end

function proposal_probability(mutable_sites::Integer, directions::Integer, ::Type{T} = Float64) where {T}
    mutable_sites > 0 || throw(ArgumentError("a proposal domain must have at least one mutable site"))
    directions > 0 || throw(ArgumentError("a proposal neighborhood must have at least one direction"))
    return inv(T(mutable_sites) * T(directions))
end

"""
    neighbor_copy_probabilities(mutable_sites, neighbor_owners, losing_owner, gaining_owner)

Reference forward and reverse mass for uniform recipient-and-direction copy proposals. The caller
passes the recipient's neighbor owners from the common proposal snapshot; a donor identity may occur
through several directions and every such direction contributes proposal mass.
"""
function neighbor_copy_probabilities(mutable_sites::Integer, neighbor_owners,
        losing_owner, gaining_owner, ::Type{T} = Float64) where {T}
    losing_owner != gaining_owner || throw(ArgumentError(
        "same-owner selections are no-op attempts and have no proposal probability"))
    directions = length(neighbor_owners)
    base_probability = proposal_probability(mutable_sites, directions, T)
    forward_multiplicity = count(==(gaining_owner), neighbor_owners)
    reverse_multiplicity = count(==(losing_owner), neighbor_owners)
    forward_multiplicity > 0 || throw(ArgumentError(
        "a generated neighbor-copy proposal must have positive forward support"))
    return ProposalProbabilities(base_probability * T(forward_multiplicity),
        base_probability * T(reverse_multiplicity), forward_multiplicity, reverse_multiplicity)
end

function _validate_temperature(T)
    T >= zero(T) || throw(ArgumentError("temperature must be non-negative"))
    return nothing
end

"""Conventional CPM Metropolis acceptance probability; it has no Hastings correction."""
function conventional_metropolis_probability(delta_h, temperature)
    _validate_temperature(temperature)
    if temperature == zero(temperature)
        return delta_h <= zero(delta_h) ? one(temperature) : zero(temperature)
    end
    return min(one(temperature), exp(-delta_h / temperature))
end

"""Metropolis-Hastings acceptance probability with explicit forward and reverse proposal mass."""
function metropolis_hastings_probability(delta_h, temperature, q_forward, q_reverse)
    _validate_temperature(temperature)
    q_forward > zero(q_forward) || throw(ArgumentError("q_forward must be positive"))
    q_reverse >= zero(q_reverse) || throw(ArgumentError("q_reverse must be non-negative"))
    q_reverse == zero(q_reverse) && return zero(temperature)
    ratio = q_reverse / q_forward
    if temperature == zero(temperature)
        return delta_h < zero(delta_h) ? one(temperature) :
               delta_h > zero(delta_h) ? zero(temperature) : min(one(temperature), ratio)
    end
    log_ratio = -delta_h / temperature + log(q_reverse) - log(q_forward)
    return log_ratio >= zero(log_ratio) ? one(temperature) : exp(log_ratio)
end

function accepts(probability, draw)
    zero(probability) <= probability <= one(probability) || throw(ArgumentError(
        "acceptance probability must lie in [0, 1]"))
    zero(draw) <= draw < one(draw) || throw(ArgumentError("uniform draw must lie in [0, 1)"))
    return draw < probability
end

"""Validate and canonically order explicit Cartesian stencil offsets."""
function canonical_stencil(offsets; spacing = nothing, symmetric::Bool = false)
    isempty(offsets) && throw(ArgumentError("a stencil must contain at least one offset"))
    stencil = [Tuple(Int.(offset)) for offset in offsets]
    dimension = length(first(stencil))
    dimension > 0 || throw(ArgumentError("a stencil offset must have positive dimension"))
    all(length(offset) == dimension for offset in stencil) || throw(ArgumentError(
        "every stencil offset must have the same dimension"))
    any(offset -> all(iszero, offset), stencil) && throw(ArgumentError(
        "a stencil must not contain the zero offset"))
    length(unique(stencil)) == length(stencil) || throw(ArgumentError(
        "a stencil must not contain duplicate offsets"))
    local_spacing = spacing === nothing ? ntuple(_ -> 1.0, dimension) : Tuple(spacing)
    length(local_spacing) == dimension || throw(ArgumentError(
        "spacing dimension must match stencil dimension"))
    all(value -> isfinite(value) && value > 0, local_spacing) || throw(ArgumentError(
        "spacing values must be finite and positive"))
    if symmetric
        all(offset -> Tuple(-value for value in offset) in stencil, stencil) || throw(ArgumentError(
            "a symmetric stencil must contain every opposite offset"))
    end
    return sort(stencil; by = offset -> (sum((local_spacing[i] * offset[i])^2 for i in eachindex(offset)),
        offset))
end

function _boundary_tuple(boundary, dimension)
    boundary isa Symbol && return ntuple(_ -> boundary, dimension)
    boundary isa Tuple && length(boundary) == dimension || throw(ArgumentError(
        "boundary must be a Symbol or one rule per dimension"))
    return boundary
end

"""
    realized_neighbor(coord, offset, dims, boundary)

Realize one one-based Cartesian offset. A closed-boundary departure is `nothing`, never a clamped
self-edge. `boundary` may be `:periodic`, `:closed`, or one rule per dimension.
"""
function realized_neighbor(coord::Tuple, offset::Tuple, dims::Tuple, boundary)
    dimension = length(coord)
    length(offset) == dimension == length(dims) || throw(ArgumentError(
        "coordinate, offset, and dimensions must have equal dimension"))
    rules = _boundary_tuple(boundary, dimension)
    all(rule -> rule in (:periodic, :closed), rules) || throw(ArgumentError(
        "reference boundary rules must be :periodic or :closed"))
    all(i -> 1 <= coord[i] <= dims[i] && dims[i] > 0, eachindex(coord)) || throw(ArgumentError(
        "coordinates must lie in a positive realized domain"))
    neighbor = Vector{Int}(undef, dimension)
    for i in 1:dimension
        proposed = coord[i] + offset[i]
        if 1 <= proposed <= dims[i]
            neighbor[i] = proposed
        elseif rules[i] === :periodic
            neighbor[i] = mod1(proposed, dims[i])
        else
            return nothing
        end
    end
    return Tuple(neighbor)
end

"""Exact scalar oracle for the defining Hamiltonian local-energy identity."""
function local_energy_change(energy::F, state::ReferenceState, proposal::ReferenceProposal) where {F}
    candidate = apply_copy_transaction(state, proposal; accepted = true)
    return energy(candidate) - energy(state)
end

"""Reference quadratic finite-cell volume Hamiltonian evaluated from authoritative ownership."""
function volume_constraint_energy(state::ReferenceState, targets::AbstractDict,
        strengths::AbstractDict)
    volumes = recompute_volumes(state)
    energy = 0
    for id in state.active_ids
        haskey(targets, id) || throw(ArgumentError("missing target volume for cell $id"))
        haskey(strengths, id) || throw(ArgumentError("missing volume strength for cell $id"))
        energy += strengths[id] * (volumes[id] - targets[id])^2
    end
    return energy
end

function _linear_site_index(coord::Tuple, dims::Tuple)
    return LinearIndices(dims)[CartesianIndex(coord)]
end

"""
    contact_hamiltonian(state, offsets, owner_type, interaction; boundary=:periodic, weights=nothing)

Reference unordered-edge contact Hamiltonian. `owner_type(owner)` and
`interaction(type_a, type_b)` make medium and finite-cell type semantics explicit.
"""
function contact_hamiltonian(state::ReferenceState, offsets, owner_type::F, interaction::G;
        boundary = :periodic, weights = nothing) where {F, G}
    stencil = canonical_stencil(offsets; symmetric = true)
    weights === nothing || length(weights) == length(offsets) || throw(ArgumentError(
        "contact weights must have one entry per declared offset"))
    weight_for = weights === nothing ? (_ -> 1) :
        offset -> weights[findfirst(==(offset), offsets)]
    edges = Dict{Tuple{Int, Int}, typeof(first(stencil))}()
    for index in CartesianIndices(state.shape)
        coord = Tuple(index)
        first_site = _linear_site_index(coord, state.shape)
        for offset in stencil
            neighbor = realized_neighbor(coord, offset, state.shape, boundary)
            neighbor === nothing && continue
            second_site = _linear_site_index(neighbor, state.shape)
            first_site == second_site && continue
            edges[minmax(first_site, second_site)] = offset
        end
    end
    energy = 0
    for ((first_site, second_site), offset) in edges
        first_owner = state.owners[first_site]
        second_owner = state.owners[second_site]
        first_owner == second_owner && continue
        energy += weight_for(offset) * interaction(owner_type(first_owner), owner_type(second_owner))
    end
    return energy
end

function record_attempt(accounting::AttemptAccounting, outcome::Symbol)
    outcome in (:no_op, :rejected, :accepted) || throw(ArgumentError(
        "outcome must be :no_op, :rejected, or :accepted"))
    realized = accounting.realized_proposals + (outcome === :no_op ? 0 : 1)
    no_ops = accounting.no_op_attempts + (outcome === :no_op ? 1 : 0)
    rejected = accounting.rejected_proposals + (outcome === :rejected ? 1 : 0)
    accepted = accounting.accepted_proposals + (outcome === :accepted ? 1 : 0)
    return AttemptAccounting(accounting.mutable_sites, accounting.candidate_attempts + 1,
        realized, no_ops, rejected, accepted)
end

function attempt_accounting_errors(accounting::AttemptAccounting; complete::Bool = true)
    errors = String[]
    fields = (accounting.candidate_attempts, accounting.realized_proposals,
        accounting.no_op_attempts, accounting.rejected_proposals, accounting.accepted_proposals)
    any(<(0), fields) && push!(errors, "attempt counters must be non-negative")
    accounting.realized_proposals == accounting.rejected_proposals + accounting.accepted_proposals ||
        push!(errors, "realized proposals must equal accepted plus rejected proposals")
    accounting.candidate_attempts == accounting.realized_proposals + accounting.no_op_attempts ||
        push!(errors, "candidate attempts must equal realized proposals plus no-op attempts")
    complete && accounting.candidate_attempts != accounting.mutable_sites && push!(errors,
        "one reference MCS requires $(accounting.mutable_sites) candidate attempts, got $(accounting.candidate_attempts)")
    return errors
end

function assert_reference_mcs(accounting::AttemptAccounting)
    errors = attempt_accounting_errors(accounting)
    isempty(errors) || throw(ArgumentError(join(errors, "; ")))
    return accounting
end

function _canonical_properties(properties::NamedTuple)
    names = Tuple(sort(collect(propertynames(properties)); by = String))
    values = ntuple(i -> collect(getproperty(properties, names[i])), length(names))
    return NamedTuple{names}(values)
end

function canonical_snapshot(state::ReferenceState{O, C}) where {O, C}
    properties = _canonical_properties(state.properties)
    return CanonicalSnapshot{O, C, typeof(properties)}(
        state.shape,
        copy(state.owners),
        sort(unique(state.active_ids)),
        sort(unique(state.reusable_ids)),
        sort!(collect(state.generations); by = first),
        sort!(collect(state.cell_types); by = first),
        properties,
        sort(unique(state.medium_ids)),
    )
end

canonical_checksum(snapshot::CanonicalSnapshot) = bytes2hex(SHA.sha256(repr(snapshot)))
canonical_checksum(state::ReferenceState) = canonical_checksum(canonical_snapshot(state))

struct StateInvariantViolation <: Exception
    errors::Vector{String}
end

function Base.showerror(io::IO, error::StateInvariantViolation)
    print(io, "logical state invariant violation: ", join(error.errors, "; "))
end

function state_invariant_errors(state::ReferenceState)
    errors = String[]
    length(state.owners) == prod(state.shape) || push!(errors,
        "owner length does not match logical shape")
    active = Set(state.active_ids)
    reusable = Set(state.reusable_ids)
    media = Set(state.medium_ids)

    length(active) == length(state.active_ids) || push!(errors, "active IDs must be unique")
    length(reusable) == length(state.reusable_ids) || push!(errors, "reusable IDs must be unique")
    all(id -> id isa Integer && id > 0, state.active_ids) || push!(errors,
        "active finite-cell IDs must be positive integers")
    all(id -> id isa Integer && id > 0, state.reusable_ids) || push!(errors,
        "reusable finite-cell IDs must be positive integers")
    length(media) == length(state.medium_ids) || push!(errors, "medium-domain IDs must be unique")
    isempty(intersect(active, reusable)) || push!(errors,
        "no finite cell ID may be both active and reusable")
    issorted(state.reusable_ids) || push!(errors, "reusable IDs must be in deterministic ascending order")

    for owner in state.owners
        owner in active || owner in media || push!(errors,
            "every site owner must be an active finite cell or declared medium domain")
    end
    for id in active
        count(==(id), state.owners) > 0 || push!(errors,
            "every active finite cell must own at least one site")
        haskey(state.cell_types, id) || push!(errors,
            "every active finite cell must have exactly one cell type")
        haskey(state.generations, id) || push!(errors,
            "every active finite cell must have a generation")
    end
    for id in reusable
        haskey(state.generations, id) || push!(errors,
            "every reusable finite-cell slot must have a generation")
    end
    for id in keys(state.cell_types)
        id in active || push!(errors,
            "only active finite cells may retain per-cell type state")
    end

    finite_ids = vcat(state.active_ids, state.reusable_ids)
    if !isempty(finite_ids) && all(id -> id isa Integer && id > 0, finite_ids)
        required_slots = maximum(Int.(finite_ids))
        for name in propertynames(state.properties)
            length(getproperty(state.properties, name)) >= required_slots || push!(errors,
                "property `$name` does not cover every finite-cell slot")
        end
    end
    return unique(errors)
end

function assert_valid_state(state::ReferenceState)
    errors = state_invariant_errors(state)
    isempty(errors) || throw(StateInvariantViolation(errors))
    return state
end

function _copy_state(state::ReferenceState{O, C, P}) where {O, C, P}
    properties = NamedTuple{propertynames(state.properties)}(
        map(value -> copy(value), values(state.properties)))
    return ReferenceState(state.shape, copy(state.owners);
        active_ids = copy(state.active_ids), reusable_ids = copy(state.reusable_ids),
        generations = copy(state.generations), cell_types = copy(state.cell_types),
        properties = properties, medium_ids = copy(state.medium_ids))
end

function _property_capacity(state::ReferenceState)
    isempty(propertynames(state.properties)) && return maximum(vcat(0, Int.(state.active_ids),
        Int.(state.reusable_ids)))
    capacities = map(name -> length(getproperty(state.properties, name)), propertynames(state.properties))
    all(==(first(capacities)), capacities) || throw(ArgumentError(
        "all schema property columns must have one shared fixed capacity"))
    return first(capacities)
end

function _available_slots(state::ReferenceState)
    capacity = _property_capacity(state)
    active = Set(state.active_ids)
    reusable = Set(state.reusable_ids)
    O = eltype(state.active_ids)
    fresh = O[id for id in 1:capacity if !(O(id) in active || O(id) in reusable)]
    return sort(unique(vcat(state.reusable_ids, fresh)))
end

function recompute_volumes(state::ReferenceState)
    volumes = Dict(id => 0 for id in state.active_ids)
    for owner in state.owners
        haskey(volumes, owner) && (volumes[owner] += 1)
    end
    return volumes
end

"""Exact finite-cell volume deltas for one accepted ownership-copy transaction."""
function volume_tracker_delta(state::ReferenceState, proposal::ReferenceProposal; accepted::Bool)
    accepted || return Dict{eltype(state.active_ids), Int}()
    state.owners[proposal.recipient] == proposal.old_owner || throw(ArgumentError(
        "proposal old_owner does not match the recipient's snapshot owner"))
    delta = Dict{eltype(state.active_ids), Int}()
    proposal.old_owner in state.active_ids && (delta[proposal.old_owner] = -1)
    proposal.new_owner in state.active_ids && (delta[proposal.new_owner] =
        get(delta, proposal.new_owner, 0) + 1)
    return delta
end

function apply_volume_tracker_delta(tracked::AbstractDict, delta::AbstractDict)
    updated = copy(tracked)
    for (id, amount) in delta
        haskey(updated, id) || throw(ArgumentError("tracker does not contain finite cell $id"))
        updated[id] += amount
        updated[id] >= 0 || throw(ArgumentError("a volume tracker must never become negative"))
    end
    return updated
end

function volume_tracker_errors(state::ReferenceState, tracked::AbstractDict)
    reconstructed = recompute_volumes(state)
    errors = String[]
    Set(keys(tracked)) == Set(keys(reconstructed)) || push!(errors,
        "tracked finite-cell IDs differ from authoritative ownership")
    for id in keys(reconstructed)
        get(tracked, id, nothing) == reconstructed[id] || push!(errors,
            "tracked volume for cell $id differs from authoritative ownership")
    end
    return errors
end

function medium_occupancies(state::ReferenceState)
    occupancy = Dict(id => 0 for id in state.medium_ids)
    for owner in state.owners
        haskey(occupancy, owner) && (occupancy[owner] += 1)
    end
    return occupancy
end

function apply_copy_transaction(state::ReferenceState, proposal::ReferenceProposal; accepted::Bool)
    accepted || return state
    state.owners[proposal.recipient] == proposal.old_owner || throw(ArgumentError(
        "proposal old_owner does not match the recipient's snapshot owner"))
    candidate = _copy_state(state)
    candidate.owners[proposal.recipient] = proposal.new_owner
    assert_valid_state(candidate)
    return candidate
end

"""Atomically validate, allocate, and commit a deterministic batch of ordinary divisions."""
function apply_division_batch(state::ReferenceState, requests::AbstractVector{<:DivisionRequest})
    isempty(requests) && return state
    assert_valid_state(state)
    ordered = sort(collect(requests); by = request -> request.parent)
    length(unique(request.parent for request in ordered)) == length(ordered) || throw(ArgumentError(
        "at most one division request may target a parent in one lifecycle boundary"))
    for request in ordered
        request.parent in state.active_ids || throw(ArgumentError("division parent is not active"))
        isempty(request.daughter_sites) && throw(ArgumentError(
            "a daughter must receive at least one parent-owned site"))
        length(unique(request.daughter_sites)) == length(request.daughter_sites) || throw(ArgumentError(
            "daughter geometry must not repeat a site"))
        all(site -> 1 <= site <= length(state.owners) && state.owners[site] == request.parent,
            request.daughter_sites) || throw(ArgumentError(
            "daughter geometry must contain only sites owned by its parent snapshot"))
        count(==(request.parent), state.owners) > length(request.daughter_sites) || throw(ArgumentError(
            "division must leave the parent with at least one site"))
    end

    available = _available_slots(state)
    length(available) >= length(ordered) || throw(CellCapacityError(length(ordered), length(available)))
    candidate = _copy_state(state)
    for (request, child) in zip(ordered, available)
        for site in request.daughter_sites
            candidate.owners[site] = child
        end
        filter!(!=(child), candidate.reusable_ids)
        push!(candidate.active_ids, child)
        sort!(candidate.active_ids)
        candidate.cell_types[child] = candidate.cell_types[request.parent]
        candidate.generations[child] = get(candidate.generations, child, UInt64(0)) + UInt64(1)
        for name in propertynames(candidate.properties)
            values = getproperty(candidate.properties, name)
            values[child] = values[request.parent]
        end
    end
    assert_valid_state(candidate)
    return candidate
end

"""Retire zero-volume cells with explicit schema reset values; reuse is deferred to the next MCS."""
function retire_zero_volume(state::ReferenceState, reset_values::NamedTuple)
    propertynames(reset_values) == propertynames(state.properties) || throw(ArgumentError(
        "retirement requires one reset value for every schema property"))
    candidate = _copy_state(state)
    retired = sort([id for id in candidate.active_ids if count(==(id), candidate.owners) == 0])
    for id in retired
        filter!(!=(id), candidate.active_ids)
        delete!(candidate.cell_types, id)
        for name in propertynames(candidate.properties)
            getproperty(candidate.properties, name)[id] = getproperty(reset_values, name)
        end
    end
    assert_valid_state(candidate)
    return (state = candidate, retired = retired)
end

"""Make prior-boundary retirements reusable in deterministic ascending order."""
function release_retired_slots(state::ReferenceState, retired::AbstractVector)
    candidate = _copy_state(state)
    all(id -> !(id in candidate.active_ids), retired) || throw(ArgumentError(
        "an active cell cannot be released as a reusable slot"))
    append!(candidate.reusable_ids, retired)
    sort!(unique!(candidate.reusable_ids))
    assert_valid_state(candidate)
    return candidate
end

"""Apply a lifecycle change to a private candidate and commit only if all invariants hold."""
function transactional_lifecycle(state::ReferenceState, transaction!::F) where {F}
    candidate = _copy_state(state)
    transaction!(candidate)
    assert_valid_state(candidate)
    return candidate
end

transactional_lifecycle(transaction!::F, state::ReferenceState) where {F} =
    transactional_lifecycle(state, transaction!)

end
