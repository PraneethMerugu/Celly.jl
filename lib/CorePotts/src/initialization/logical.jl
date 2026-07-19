abstract type AbstractInitialOverlapPolicy end
"""Reject a site claimed by distinct semantic owners."""
struct RejectInitialOverlap <: AbstractInitialOverlapPolicy end
"""Select the unique greatest explicit claim priority and reject a tied winner."""
struct StableInitialPriority <: AbstractInitialOverlapPolicy end

"""Stable layout-time identity; it is not a requested runtime cell ID."""
struct ProvisionalCellID <: AbstractScientificID
    value::UInt64
    function ProvisionalCellID(value::Integer)
        value > 0 || throw(ArgumentError("provisional cell identity must be positive"))
        new(UInt64(value))
    end
end

value(id::ProvisionalCellID) = id.value
ProvisionalCellID(id::ProvisionalCellID) = id
ProvisionalCellID(id::CellID) = ProvisionalCellID(value(id))

abstract type AbstractInitialLayout end

"""Compact requirements declared by an initialization layout."""
struct InitialLayoutRequirements
    dimensions::UInt8
    device_native::Bool
    stage::UInt8
    function InitialLayoutRequirements(dimensions::Integer; device_native::Bool = false,
            stage::Integer = 0)
        dimensions in (2, 3) || throw(ArgumentError("initial layouts must be 2D or 3D"))
        0 <= stage <= typemax(UInt8) || throw(ArgumentError(
            "initial layout claim stage must fit in UInt8"))
        new(UInt8(dimensions), device_native, UInt8(stage))
    end
end


"""Open construction-time requirements query for one layout."""
function initial_layout_requirements end
"""Open claim-emission operation into compiler-owned initialization storage."""
function emit_initial_claims! end

"""A provisional finite-cell raster with its declared compiled cell type."""
struct InitialCellLayout{N, M <: AbstractArray{Bool, N}} <: AbstractInitialLayout
    provisional_id::ProvisionalCellID
    cell_type::CellTypeID
    mask::M
    priority::Int32
end

function InitialCellLayout(id, type, mask::AbstractArray{Bool, N}; priority::Integer = 0) where {N}
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "initial claim priority must fit in Int32"))
    return InitialCellLayout{N, typeof(mask)}(ProvisionalCellID(value(ProvisionalCellID(id))),
        CellTypeID(type), mask, Int32(priority))
end

"""A raster owned by one declared conceptual medium domain."""
struct InitialMediumLayout{N, M <: AbstractArray{Bool, N}} <: AbstractInitialLayout
    domain::MediumID
    mask::M
    priority::Int32
end

function InitialMediumLayout(domain, mask::AbstractArray{Bool, N}; priority::Integer = 0) where {N}
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "initial claim priority must fit in Int32"))
    return InitialMediumLayout{N, typeof(mask)}(MediumID(domain), mask, Int32(priority))
end

"""Explicit coordinates owned by one provisional finite cell."""
struct CoordinateCellLayout{N, C <: AbstractVector{CartesianIndex{N}}} <: AbstractInitialLayout
    provisional_id::ProvisionalCellID
    cell_type::CellTypeID
    coordinates::C
    priority::Int32
end

function CoordinateCellLayout(id, type, coordinates::AbstractVector{CartesianIndex{N}};
        priority::Integer = 0) where {N}
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "initial claim priority must fit in Int32"))
    return CoordinateCellLayout{N, typeof(coordinates)}(ProvisionalCellID(id), CellTypeID(type),
        coordinates, Int32(priority))
end

initial_layout_requirements(::InitialCellLayout{N}) where {N} = InitialLayoutRequirements(N)
initial_layout_requirements(::InitialMediumLayout{N}) where {N} = InitialLayoutRequirements(N)
initial_layout_requirements(::CoordinateCellLayout{N}) where {N} = InitialLayoutRequirements(N)

struct ProvisionalCellDeclaration
    id::ProvisionalCellID
    cell_type::CellTypeID
    overrides::Vector{Pair{Symbol, Any}}
end

struct InitialClaimant
    tag::UInt8
    identity::UInt64
end

const _INITIAL_CELL_CLAIM = UInt8(1)
const _INITIAL_MEDIUM_CLAIM = UInt8(2)

struct InitialOwnershipClaim{N}
    site::CartesianIndex{N}
    claimant::InitialClaimant
    priority::Int32
end

mutable struct InitialClaimCollector{N, R <: AbstractRNGContract}
    shape::NTuple{N, Int}
    declarations::Vector{ProvisionalCellDeclaration}
    claims::Vector{InitialOwnershipClaim{N}}
    reserved::BitArray{N}
    rng_contract::R
    master_seed::UInt64
end

InitialClaimCollector(shape::NTuple{N, Int}, rng_contract::R, master_seed::UInt64) where {
        N, R <: AbstractRNGContract} = InitialClaimCollector{N, R}(shape,
    ProvisionalCellDeclaration[], InitialOwnershipClaim{N}[], falses(shape), rng_contract,
    master_seed)

function _initial_overrides(properties)
    return Pair{Symbol, Any}[Symbol(key) => value for (key, value) in pairs(properties)]
end

function declare_initial_cell!(collector::InitialClaimCollector, id, type;
        properties = NamedTuple())
    declaration = ProvisionalCellDeclaration(ProvisionalCellID(id), CellTypeID(type),
        _initial_overrides(properties))
    existing = findfirst(item -> item.id == declaration.id, collector.declarations)
    if existing === nothing
        push!(collector.declarations, declaration)
    else
        current = collector.declarations[existing]
        current.cell_type == declaration.cell_type || throw(ArgumentError(
            "provisional cell $(declaration.id) has incompatible cell types"))
        for override in declaration.overrides
            found = findfirst(pair -> first(pair) == first(override), current.overrides)
            found === nothing ? push!(current.overrides, override) :
                isequal(last(current.overrides[found]), last(override)) || throw(ArgumentError(
                    "provisional cell $(declaration.id) has incompatible property overrides"))
        end
    end
    return collector
end

"""Property overrides for one declared provisional cell, independent of its geometry layout."""
struct InitialCellProperties{P} <: AbstractInitialLayout
    provisional_id::ProvisionalCellID
    cell_type::CellTypeID
    properties::P
    dimensions::UInt8
end

function InitialCellProperties(id, type, properties; dimensions::Integer)
    requirements = InitialLayoutRequirements(dimensions)
    return InitialCellProperties(ProvisionalCellID(id), CellTypeID(type), properties,
        requirements.dimensions)
end

initial_layout_requirements(layout::InitialCellProperties) =
    InitialLayoutRequirements(layout.dimensions)
function emit_initial_claims!(collector::InitialClaimCollector, layout::InitialCellProperties)
    declare_initial_cell!(collector, layout.provisional_id, layout.cell_type;
        properties = layout.properties)
    return collector
end

function emit_initial_cell_claim!(collector::InitialClaimCollector{N}, site::CartesianIndex{N},
        id; priority::Integer = 0) where {N}
    checkbounds(Bool, CartesianIndices(collector.shape), site) || throw(BoundsError(
        CartesianIndices(collector.shape), site))
    push!(collector.claims, InitialOwnershipClaim(site,
        InitialClaimant(_INITIAL_CELL_CLAIM, value(ProvisionalCellID(id))), Int32(priority)))
    return collector
end

function emit_initial_medium_claim!(collector::InitialClaimCollector{N}, site::CartesianIndex{N},
        domain; priority::Integer = 0) where {N}
    checkbounds(Bool, CartesianIndices(collector.shape), site) || throw(BoundsError(
        CartesianIndices(collector.shape), site))
    push!(collector.claims, InitialOwnershipClaim(site,
        InitialClaimant(_INITIAL_MEDIUM_CLAIM, UInt64(value(MediumID(domain)))), Int32(priority)))
    return collector
end

function emit_initial_claims!(collector::InitialClaimCollector, layout::InitialCellLayout)
    size(layout.mask) == collector.shape || throw(ArgumentError(
        "initial layout shape $(size(layout.mask)) does not match lattice shape $(collector.shape)"))
    declare_initial_cell!(collector, layout.provisional_id, layout.cell_type)
    for site in CartesianIndices(layout.mask)
        layout.mask[site] && emit_initial_cell_claim!(collector, site, layout.provisional_id;
            priority = layout.priority)
    end
    return collector
end


function emit_initial_claims!(collector::InitialClaimCollector, layout::InitialMediumLayout)
    size(layout.mask) == collector.shape || throw(ArgumentError(
        "initial layout shape $(size(layout.mask)) does not match lattice shape $(collector.shape)"))
    for site in CartesianIndices(layout.mask)
        layout.mask[site] && emit_initial_medium_claim!(collector, site, layout.domain;
            priority = layout.priority)
    end
    return collector
end


function emit_initial_claims!(collector::InitialClaimCollector{N},
        layout::CoordinateCellLayout{N}) where {N}
    declare_initial_cell!(collector, layout.provisional_id, layout.cell_type)
    for site in layout.coordinates
        emit_initial_cell_claim!(collector, site, layout.provisional_id; priority = layout.priority)
    end
    return collector
end

"""Dense nonnegative provisional-cell labels with explicit label-to-type declarations."""
struct DenseCellLabels{N, A <: AbstractArray{<:Integer, N}, D <: AbstractVector} <:
        AbstractInitialLayout
    labels::A
    declarations::D
    priority::Int32
end

function DenseCellLabels(labels::AbstractArray{<:Integer, N}, declarations::AbstractVector;
        priority::Integer = 0) where {N}
    typed = Pair{ProvisionalCellID, CellTypeID}[
        ProvisionalCellID(first(pair)) => CellTypeID(last(pair)) for pair in declarations]
    return DenseCellLabels{N, typeof(labels), typeof(typed)}(labels, typed, Int32(priority))
end

initial_layout_requirements(::DenseCellLabels{N}) where {N} = InitialLayoutRequirements(N)

function emit_initial_claims!(collector::InitialClaimCollector, layout::DenseCellLabels)
    size(layout.labels) == collector.shape || throw(ArgumentError(
        "dense label shape $(size(layout.labels)) does not match lattice shape $(collector.shape)"))
    for declaration in layout.declarations
        declare_initial_cell!(collector, first(declaration), last(declaration))
    end
    for site in CartesianIndices(layout.labels)
        label = layout.labels[site]
        label >= 0 || throw(ArgumentError("dense provisional labels must be nonnegative"))
        label == 0 && continue
        id = ProvisionalCellID(label)
        any(declaration -> first(declaration) == id, layout.declarations) || throw(ArgumentError(
            "dense provisional label $label has no cell-type declaration"))
        emit_initial_cell_claim!(collector, site, id; priority = layout.priority)
    end
    return collector
end

abstract type AbstractLatticeShape end

"""Euclidean lattice ball (disk in 2D, sphere in 3D)."""
struct LatticeBall{T <: AbstractFloat} <: AbstractLatticeShape
    radius::T
    function LatticeBall(radius::T) where {T <: AbstractFloat}
        isfinite(radius) && radius >= zero(T) || throw(ArgumentError(
            "lattice-ball radius must be finite and nonnegative"))
        new{T}(radius)
    end
end
LatticeBall(radius::Real) = LatticeBall(float(radius))

"""Axis-aligned lattice box described by an integer half-width per axis."""
struct LatticeBox{N} <: AbstractLatticeShape
    half_widths::NTuple{N, Int}
    function LatticeBox(half_widths::NTuple{N, <:Integer}) where {N}
        all(>=(0), half_widths) || throw(ArgumentError(
            "lattice-box half-widths must be nonnegative"))
        new{N}(ntuple(i -> Int(half_widths[i]), N))
    end
end

shape_extent(shape::LatticeBall, dimensions::Integer) =
    ntuple(_ -> floor(Int, shape.radius), Int(dimensions))
shape_extent(shape::LatticeBox{N}, dimensions::Integer) where {N} =
    N == dimensions ? shape.half_widths : throw(ArgumentError(
        "lattice-box dimension does not match its layout"))
shape_contains(shape::LatticeBall, displacement) =
    sum(distance -> distance * distance, displacement) <= shape.radius * shape.radius
shape_contains(shape::LatticeBox, displacement) =
    all(displacement[axis] <= shape.half_widths[axis] for axis in eachindex(displacement))

function _validate_shape_domain(shape::AbstractLatticeShape, domain::NTuple{N, Int},
        periodic::NTuple{N, Bool}) where {N}
    extent = shape_extent(shape, N)
    for axis in 1:N
        periodic[axis] && 2 * extent[axis] + 1 > domain[axis] && throw(ArgumentError(
            "periodic shape support aliases itself on axis $axis"))
    end
    return extent
end

function _raster_shape(shape::AbstractLatticeShape, center::NTuple{N, Int},
        domain::NTuple{N, Int}, periodic::NTuple{N, Bool}) where {N}
    extent = _validate_shape_domain(shape, domain, periodic)
    for axis in 1:N
        if !periodic[axis] &&
                (center[axis] - extent[axis] < 1 || center[axis] + extent[axis] > domain[axis])
            return nothing
        end
    end
    sites = CartesianIndex{N}[]
    for site in CartesianIndices(domain)
        displacement = ntuple(N) do axis
            distance = abs(site[axis] - center[axis])
            periodic[axis] ? min(distance, domain[axis] - distance) : distance
        end
        shape_contains(shape, displacement) && push!(sites, site)
    end
    return sites
end

"""One explicitly centered procedural cell shape."""
struct ShapeCellLayout{N, S <: AbstractLatticeShape} <: AbstractInitialLayout
    provisional_id::ProvisionalCellID
    cell_type::CellTypeID
    center::NTuple{N, Int}
    shape::S
    periodic::NTuple{N, Bool}
    priority::Int32
end

function ShapeCellLayout(id, type, center::NTuple{N, <:Integer}, shape::AbstractLatticeShape;
        periodic = ntuple(_ -> false, N), priority::Integer = 0) where {N}
    return ShapeCellLayout{N, typeof(shape)}(ProvisionalCellID(id), CellTypeID(type),
        ntuple(i -> Int(center[i]), N), shape, ntuple(i -> Bool(periodic[i]), N), Int32(priority))
end

initial_layout_requirements(::ShapeCellLayout{N}) where {N} = InitialLayoutRequirements(N)

function emit_initial_claims!(collector::InitialClaimCollector{N}, layout::ShapeCellLayout{N}) where {N}
    all(axis -> 1 <= layout.center[axis] <= collector.shape[axis], 1:N) || throw(ArgumentError(
        "procedural shape center must lie inside the lattice"))
    sites = _raster_shape(layout.shape, layout.center, collector.shape, layout.periodic)
    sites === nothing && throw(ArgumentError(
        "nonperiodic procedural shape support extends outside the lattice"))
    declare_initial_cell!(collector, layout.provisional_id, layout.cell_type)
    for site in sites
        emit_initial_cell_claim!(collector, site, layout.provisional_id; priority = layout.priority)
    end
    return collector
end

"""Uniform injection of labeled one-site seeds into eligible, unreserved sites."""
struct UniformSiteSeeds{N, M <: AbstractArray{Bool, N}, D <: AbstractVector} <:
        AbstractInitialLayout
    declarations::D
    eligible::M
    operation::UInt16
    priority::Int32
end

function UniformSiteSeeds(declarations::AbstractVector, eligible::AbstractArray{Bool, N};
        operation::Integer, priority::Integer = 0) where {N}
    0 <= operation <= 0x0fff || throw(ArgumentError(
        "layout RNG operation must fit the v1 12-bit domain"))
    typed = Pair{ProvisionalCellID, CellTypeID}[
        ProvisionalCellID(first(pair)) => CellTypeID(last(pair)) for pair in declarations]
    return UniformSiteSeeds{N, typeof(eligible), typeof(typed)}(
        typed, eligible, UInt16(operation), Int32(priority))
end

initial_layout_requirements(::UniformSiteSeeds{N}) where {N} =
    InitialLayoutRequirements(N; stage = 1)

function emit_initial_claims!(collector::InitialClaimCollector, layout::UniformSiteSeeds)
    size(layout.eligible) == collector.shape || throw(ArgumentError(
        "uniform seed eligibility shape must match the lattice"))
    declarations = sort!(unique!(copy(layout.declarations)); by = pair -> value(first(pair)))
    length(declarations) == length(layout.declarations) || throw(ArgumentError(
        "uniform site seeds require unique provisional identities"))
    for declaration in declarations
        declare_initial_cell!(collector, first(declaration), last(declaration))
    end
    eligible = CartesianIndex[site for site in CartesianIndices(layout.eligible)
        if layout.eligible[site] && !collector.reserved[site]]
    length(declarations) <= length(eligible) || throw(ArgumentError(
        "uniform site seeding has insufficient eligible unreserved sites"))
    length(eligible) <= typemax(UInt32) || throw(ArgumentError(
        "uniform site seeding exceeds the v1 site-address domain"))
    order = collect(eachindex(eligible))
    for index in length(order):-1:2
        address = RNGAddress(stream = LayoutPlacementStream, operation = layout.operation,
            entity_kind = SiteEntity, entity = index)
        selected = Int(bounded_uint(collector.rng_contract, collector.master_seed,
            address, UInt32(index))) + 1
        order[index], order[selected] = order[selected], order[index]
    end
    for (declaration, selected) in zip(declarations, order)
        emit_initial_cell_claim!(collector, eligible[selected], first(declaration);
            priority = layout.priority)
    end
    return collector
end

struct InitialPlacementError <: Exception
    provisional_id::ProvisionalCellID
    attempt_limit::Int
    accepted_entities::Int
end

function Base.showerror(io::IO, error::InitialPlacementError)
    print(io, "sequential rejection placement exhausted ", error.attempt_limit,
        " attempts for ", error.provisional_id, " after placing ",
        error.accepted_entities, " entities")
end

"""Bounded, canonical sequential rejection placement of one shared shape family."""
struct SequentialRejectionPlacement{N, S <: AbstractLatticeShape,
        M <: AbstractArray{Bool, N}, D <: AbstractVector} <: AbstractInitialLayout
    declarations::D
    shape::S
    eligible_centers::M
    periodic::NTuple{N, Bool}
    attempt_limit::UInt16
    operation::UInt16
    priority::Int32
end

function SequentialRejectionPlacement(declarations::AbstractVector, shape::AbstractLatticeShape,
        eligible_centers::AbstractArray{Bool, N}; periodic = ntuple(_ -> false, N),
        attempt_limit::Integer, operation::Integer, priority::Integer = 0) where {N}
    1 <= attempt_limit <= 256 || throw(ArgumentError(
        "v1 sequential rejection attempt limit must lie in 1:256"))
    0 <= operation <= 0x0fff || throw(ArgumentError(
        "layout RNG operation must fit the v1 12-bit domain"))
    typed = Pair{ProvisionalCellID, CellTypeID}[
        ProvisionalCellID(first(pair)) => CellTypeID(last(pair)) for pair in declarations]
    return SequentialRejectionPlacement{N, typeof(shape), typeof(eligible_centers), typeof(typed)}(
        typed, shape, eligible_centers, ntuple(i -> Bool(periodic[i]), N), UInt16(attempt_limit),
        UInt16(operation), Int32(priority))
end

initial_layout_requirements(::SequentialRejectionPlacement{N}) where {N} =
    InitialLayoutRequirements(N; stage = 1)

function emit_initial_claims!(collector::InitialClaimCollector{N},
        layout::SequentialRejectionPlacement{N}) where {N}
    size(layout.eligible_centers) == collector.shape || throw(ArgumentError(
        "sequential-rejection eligibility shape must match the lattice"))
    _validate_shape_domain(layout.shape, collector.shape, layout.periodic)
    declarations = sort!(unique!(copy(layout.declarations)); by = pair -> value(first(pair)))
    length(declarations) == length(layout.declarations) || throw(ArgumentError(
        "sequential rejection requires unique provisional identities"))
    occupied = copy(collector.reserved)
    pending = Tuple{CartesianIndex{N}, ProvisionalCellID}[]
    for (entity_index, declaration) in enumerate(declarations)
        id, type = declaration
        value(id) <= typemax(UInt32) || throw(ArgumentError(
            "stochastic provisional identity exceeds the v1 entity-address domain"))
        declare_initial_cell!(collector, id, type)
        accepted = false
        for attempt in 1:Int(layout.attempt_limit)
            center = ntuple(N) do axis
                address = RNGAddress(stream = LayoutPlacementStream,
                    operation = layout.operation, entity_kind = CellEntity,
                    entity = value(id), invocation = attempt - 1, draw = axis - 1)
                Int(bounded_uint(collector.rng_contract, collector.master_seed, address,
                    UInt32(collector.shape[axis]))) + 1
            end
            layout.eligible_centers[CartesianIndex(center)] || continue
            sites = _raster_shape(layout.shape, center, collector.shape, layout.periodic)
            sites === nothing && continue
            any(site -> occupied[site] || !layout.eligible_centers[site], sites) && continue
            for site in sites
                occupied[site] = true
                push!(pending, (site, id))
            end
            accepted = true
            break
        end
        accepted || throw(InitialPlacementError(id, Int(layout.attempt_limit), entity_index - 1))
    end
    for (site, id) in pending
        emit_initial_cell_claim!(collector, site, id; priority = layout.priority)
    end
    return collector
end


struct InitialLayoutOverlapError <: Exception
    site::CartesianIndex
    claimants::Vector{InitialClaimant}
end

function Base.showerror(io::IO, error::InitialLayoutOverlapError)
    print(io, "initial layouts have an unresolved overlap at ", Tuple(error.site),
        " among semantic claimants ", error.claimants)
end

"""Stable result of initialization finalization, including provisional-to-runtime evidence."""
struct LogicalInitializationReport
    provisional_to_runtime::Vector{Pair{ProvisionalCellID, CellID}}
    discarded_provisional_ids::Vector{ProvisionalCellID}
end

struct InitializedLogicalState{S <: LogicalPottsState}
    state::S
    report::LogicalInitializationReport
end

logical_state(initialized::InitializedLogicalState) = initialized.state
initialization_report(initialized::InitializedLogicalState) = initialized.report

function _claim_groups(claims)
    ordered = sort!(copy(claims); by = claim ->
        (Tuple(claim.site), claim.claimant.tag, claim.claimant.identity, -Int64(claim.priority)))
    groups = Vector{UnitRange{Int}}()
    first_index = 1
    while first_index <= length(ordered)
        last_index = first_index
        while last_index < length(ordered) && ordered[last_index + 1].site == ordered[first_index].site
            last_index += 1
        end
        push!(groups, first_index:last_index)
        first_index = last_index + 1
    end
    return ordered, groups
end

function _distinct_claims(ordered, group)
    distinct = eltype(ordered)[]
    for index in group
        claim = ordered[index]
        findfirst(item -> item.claimant == claim.claimant, distinct) === nothing && push!(distinct, claim)
    end
    return distinct
end

function _resolve_initial_claims(::RejectInitialOverlap, claims)
    ordered, groups = _claim_groups(claims)
    winners = eltype(ordered)[]
    for group in groups
        distinct = _distinct_claims(ordered, group)
        length(distinct) == 1 || throw(InitialLayoutOverlapError(ordered[first(group)].site,
            InitialClaimant[claim.claimant for claim in distinct]))
        push!(winners, first(distinct))
    end
    return winners
end


function _resolve_initial_claims(::StableInitialPriority, claims)
    ordered, groups = _claim_groups(claims)
    winners = eltype(ordered)[]
    for group in groups
        distinct = _distinct_claims(ordered, group)
        greatest = maximum(claim.priority for claim in distinct)
        tied = filter(claim -> claim.priority == greatest, distinct)
        length(tied) == 1 || throw(InitialLayoutOverlapError(ordered[first(group)].site,
            InitialClaimant[claim.claimant for claim in tied]))
        push!(winners, only(tied))
    end
    return winners
end

function _update_reserved!(collector::InitialClaimCollector, overlap_policy)
    fill!(collector.reserved, false)
    for claim in _resolve_initial_claims(overlap_policy, collector.claims)
        collector.reserved[claim.site] = true
    end
    return collector
end


function _claim_owner(claim::InitialOwnershipClaim, surviving, runtime_ids)
    if claim.claimant.tag == _INITIAL_MEDIUM_CLAIM
        return MediumOwner(MediumID(claim.claimant.identity))
    end
    provisional = ProvisionalCellID(claim.claimant.identity)
    index = findfirst(==(provisional), surviving)
    index === nothing && throw(ArgumentError("resolved claim refers to an empty provisional cell"))
    return CellOwner(runtime_ids[index])
end

"""
    finalize_initial_state(shape, layouts...; capacity, medium_domains, property_schema,
                           overlap_policy=RejectInitialOverlap())

Finalize open layout claims in an order-independent host pipeline: resolve overlaps, remove empty
entities, assign compact runtime IDs by semantic identity, validate capacity, initialize schema
properties, reconstruct derived state, and publish only an invariant-valid logical state.
"""
function finalize_initial_state(shape::NTuple{N, <:Integer}, layouts::AbstractInitialLayout...;
        capacity::CellCapacity, medium_domains, property_schema::PropertySchema = PropertySchema(),
        overlap_policy::AbstractInitialOverlapPolicy = RejectInitialOverlap(),
        seed::Integer = 0, rng_contract::AbstractRNGContract = Philox4x32x10V1()) where {N}
    N in (2, 3) || throw(ArgumentError("logical CPM initialization currently requires a 2D or 3D lattice"))
    dimensions = ntuple(i -> Int(shape[i]), N)
    all(>(0), dimensions) || throw(ArgumentError("logical CPM lattice dimensions must be positive"))
    domains = sort!(unique!(collect(MediumID.(medium_domains))); by = value)
    isempty(domains) && throw(ArgumentError("at least one medium domain must be declared"))

    0 <= seed <= typemax(UInt64) || throw(ArgumentError("initialization seed must fit in UInt64"))
    requirements = map(initial_layout_requirements, layouts)
    for item in requirements
        Int(item.dimensions) == N || throw(ArgumentError(
            "initial layout dimension $(item.dimensions) does not match lattice dimension $N"))
    end
    collector = InitialClaimCollector(dimensions, rng_contract, UInt64(seed))
    stages = sort!(unique!(UInt8[item.stage for item in requirements]))
    for stage in stages
        for (layout, item) in zip(layouts, requirements)
            item.stage == stage || continue
            emit_initial_claims!(collector, layout)
        end
        _update_reserved!(collector, overlap_policy)
    end
    sort!(collector.declarations; by = declaration -> value(declaration.id))
    resolved = _resolve_initial_claims(overlap_policy, collector.claims)
    for claim in resolved
        if claim.claimant.tag == _INITIAL_MEDIUM_CLAIM
            MediumID(claim.claimant.identity) in domains || throw(ArgumentError(
                "initial medium claim references an undeclared domain"))
        end
    end

    occupied = sort!(unique!(collect(ProvisionalCellID(claim.claimant.identity) for claim in resolved
        if claim.claimant.tag == _INITIAL_CELL_CLAIM)); by = value)
    declared = ProvisionalCellID[declaration.id for declaration in collector.declarations]
    all(id -> id in declared, occupied) || throw(ArgumentError(
        "every finite ownership claim must have one cell declaration"))
    length(occupied) <= nslots(capacity) || throw(CellCapacityError(length(occupied), capacity))
    runtime_ids = CellID[CellID(index) for index in eachindex(occupied)]
    owners = fill(MediumOwner(first(domains)), dimensions)
    for claim in resolved
        owners[claim.site] = _claim_owner(claim, occupied, runtime_ids)
    end
    types = Dict{CellID, CellTypeID}()
    for (provisional, runtime) in zip(occupied, runtime_ids)
        declaration = collector.declarations[findfirst(item -> item.id == provisional,
            collector.declarations)]
        types[runtime] = declaration.cell_type
    end
    state = LogicalPottsState(owners, capacity; cell_types = types, medium_domains = domains,
        property_schema = property_schema)
    for (provisional, runtime) in zip(occupied, runtime_ids)
        declaration = collector.declarations[findfirst(item -> item.id == provisional,
            collector.declarations)]
        for (key, override) in declaration.overrides
            descriptor = property_descriptor(property_schema, key)
            values = property_values(state, key)
            values[Int(value(runtime))] = convert(value_type(descriptor), override)
        end
    end
    rebuild_derived_state!(state)
    assert_valid_state(state)
    discarded = sort!(collect(setdiff(Set(declared), Set(occupied))); by = value)
    report = LogicalInitializationReport(Pair.(occupied, runtime_ids), discarded)
    return InitializedLogicalState(state, report)
end
