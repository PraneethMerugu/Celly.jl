"""Explicit resolution rule for overlapping initial layouts."""
@enum LayoutOverlapPolicy::UInt8 begin
    ErrorOnOverlap = 1
    ReplaceOnOverlap = 2
    PreserveOnOverlap = 3
end

abstract type AbstractInitialLayout end

"""A provisional finite-cell raster with its declared compiled cell type."""
struct InitialCellLayout{N, M <: AbstractArray{Bool, N}} <: AbstractInitialLayout
    provisional_id::CellID
    cell_type::CellTypeID
    mask::M
end

InitialCellLayout(id, type, mask::AbstractArray{Bool, N}) where {N} =
    InitialCellLayout{N, typeof(mask)}(CellID(id), CellTypeID(type), mask)

"""A raster owned by one declared conceptual medium domain."""
struct InitialMediumLayout{N, M <: AbstractArray{Bool, N}} <: AbstractInitialLayout
    domain::MediumID
    mask::M
end

InitialMediumLayout(domain, mask::AbstractArray{Bool, N}) where {N} =
    InitialMediumLayout{N, typeof(mask)}(MediumID(domain), mask)

struct InitialLayoutOverlapError <: Exception
    site::CartesianIndex
    existing::OwnerRef
    requested::OwnerRef
end

function Base.showerror(io::IO, error::InitialLayoutOverlapError)
    print(io, "initial layouts overlap at ", Tuple(error.site), ": ", error.existing,
        " conflicts with ", error.requested)
end

"""Stable result of initialization finalization, including provisional-to-runtime ID evidence."""
struct LogicalInitializationReport
    provisional_to_runtime::Vector{Pair{CellID, CellID}}
    discarded_provisional_ids::Vector{CellID}
end

struct InitializedLogicalState{S <: LogicalPottsState}
    state::S
    report::LogicalInitializationReport
end

logical_state(initialized::InitializedLogicalState) = initialized.state
initialization_report(initialized::InitializedLogicalState) = initialized.report

_layout_owner(layout::InitialCellLayout) = CellOwner(layout.provisional_id)
_layout_owner(layout::InitialMediumLayout) = MediumOwner(layout.domain)
_layout_mask(layout::AbstractInitialLayout) = layout.mask

function _validate_initial_layouts(shape, layouts, medium_domains)
    provisional_types = Dict{CellID, CellTypeID}()
    declared_media = Set(medium_domains)
    for layout in layouts
        layout isa AbstractInitialLayout || throw(ArgumentError(
            "initial layouts must be InitialCellLayout or InitialMediumLayout"))
        size(_layout_mask(layout)) == shape || throw(ArgumentError(
            "initial layout mask shape $(size(_layout_mask(layout))) does not match lattice shape $shape"))
        if layout isa InitialCellLayout
            existing = get(provisional_types, layout.provisional_id, nothing)
            existing === nothing || existing == layout.cell_type || throw(ArgumentError(
                "provisional cell $(layout.provisional_id) has incompatible declared cell types"))
            provisional_types[layout.provisional_id] = layout.cell_type
        else
            layout.domain in declared_media || throw(ArgumentError(
                "initial medium layout references undeclared domain $(layout.domain)"))
        end
    end
    return provisional_types
end

"""
    finalize_initial_state(shape, layouts...; capacity, medium_domains, property_schema,
                           overlap_policy=ErrorOnOverlap)

Finalize raster layouts into an invariant-valid `LogicalPottsState`.  The pipeline deliberately
follows the accepted state-model order: explicit overlap resolution, zero-occupancy removal,
deterministic compact runtime IDs, capacity validation, schema initialization, and derived-state
reconstruction.  It is a CPU authoring/finalization API and does not synchronize or allocate device
state.
"""
function finalize_initial_state(shape::NTuple{N, <:Integer}, layouts::AbstractInitialLayout...;
        capacity::CellCapacity, medium_domains, property_schema::PropertySchema = PropertySchema(),
        overlap_policy::LayoutOverlapPolicy = ErrorOnOverlap) where {N}
    N in (2, 3) || throw(ArgumentError("logical CPM initialization currently requires a 2D or 3D lattice"))
    dimensions = ntuple(i -> Int(shape[i]), N)
    all(>(0), dimensions) || throw(ArgumentError("logical CPM lattice dimensions must be positive"))
    domains = collect(MediumID.(medium_domains))
    isempty(domains) && throw(ArgumentError("at least one medium domain must be declared"))
    length(unique(domains)) == length(domains) || throw(ArgumentError("medium-domain IDs must be unique"))
    _validate_initial_layouts(dimensions, layouts, domains)

    owners = fill(MediumOwner(first(domains)), dimensions)
    claimed = falses(dimensions)
    for layout in layouts
        requested = _layout_owner(layout)
        mask = _layout_mask(layout)
        for site in CartesianIndices(mask)
            mask[site] || continue
            if claimed[site]
                overlap_policy === ErrorOnOverlap && throw(InitialLayoutOverlapError(
                    site, owners[site], requested))
                overlap_policy === PreserveOnOverlap && continue
            end
            owners[site] = requested
            claimed[site] = true
        end
    end

    provisional_types = _validate_initial_layouts(dimensions, layouts, domains)
    surviving = sort!(unique(CellID(owner.value) for owner in owners if is_cell_owner(owner)); by = value)
    length(surviving) <= nslots(capacity) || throw(CellCapacityError(length(surviving), capacity))
    runtime_ids = CellID[CellID(index) for index in eachindex(surviving)]
    compact_ids = Dict(zip(surviving, runtime_ids))
    for index in eachindex(owners)
        owner = owners[index]
        is_cell_owner(owner) && (owners[index] = CellOwner(compact_ids[CellID(owner.value)]))
    end
    types = Dict(compact_ids[id] => provisional_types[id] for id in surviving)
    state = LogicalPottsState(owners, capacity; cell_types = types, medium_domains = domains,
        property_schema = property_schema)
    # `LogicalPottsState` reconstructs this cache in its constructor; the explicit call documents
    # that initialization finalization is the authoritative derived-state reconstruction boundary.
    rebuild_derived_state!(state)
    assert_valid_state(state)
    discarded = sort!(collect(setdiff(keys(provisional_types), Set(surviving))); by = value)
    report = LogicalInitializationReport(Pair.(surviving, runtime_ids), discarded)
    return InitializedLogicalState(state, report)
end
