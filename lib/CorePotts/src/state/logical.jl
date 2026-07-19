"""
    OwnerRef

Compact, isbits logical owner identity for one realized lattice site.  The tag makes finite-cell
and medium-domain identity disjoint even when their numeric identifiers are equal.  It is a host
representation in this phase; a future device lowering may use a different encoding while exposing
the same accessors.
"""
struct OwnerRef
    tag::UInt8
    value::UInt32

    function OwnerRef(tag::UInt8, value::UInt32)
        tag in (0x01, 0x02) ||
            throw(ArgumentError("owner tag must identify a cell or medium domain"))
        value > 0 || throw(ArgumentError("owner identity must be positive"))
        new(tag, value)
    end

    OwnerRef(tag::UInt8, value::UInt32, ::Val{:unchecked}) = new(tag, value)
end

@inline _owner_ref_unchecked(tag::UInt8, value::UInt32) = OwnerRef(tag, value, Val(:unchecked))

const _CELL_OWNER_TAG = UInt8(1)
const _MEDIUM_OWNER_TAG = UInt8(2)

"""Logical owner reference for one finite cell."""
CellOwner(id::CellID) = OwnerRef(_CELL_OWNER_TAG, value(id))
CellOwner(id::Integer) = CellOwner(CellID(id))

"""Logical owner reference for one conceptual medium domain."""
MediumOwner(id::MediumID) = OwnerRef(_MEDIUM_OWNER_TAG, value(id))
MediumOwner(id::Integer) = MediumOwner(MediumID(id))

is_cell_owner(owner::OwnerRef) = owner.tag == _CELL_OWNER_TAG
is_medium_owner(owner::OwnerRef) = owner.tag == _MEDIUM_OWNER_TAG
function cell_id(owner::OwnerRef)
    is_cell_owner(owner) ? CellID(owner.value) :
    throw(ArgumentError("owner $owner is not a finite cell"))
end
function medium_id(owner::OwnerRef)
    is_medium_owner(owner) ? MediumID(owner.value) :
    throw(ArgumentError("owner $owner is not a medium domain"))
end

function Base.show(io::IO, owner::OwnerRef)
    if is_cell_owner(owner)
        print(io, "CellOwner(", owner.value, ")")
    else
        print(io, "MediumOwner(", owner.value, ")")
    end
end

"""Fixed-capacity columns compiled from a `PropertySchema`."""
struct PropertyStore{S <: PropertySchema, C <: NamedTuple}
    schema::S
    columns::C
end

function _property_column(descriptor::PropertyDescriptor, capacity::CellCapacity)
    T = value_type(descriptor)
    retired = retired_property_value(descriptor.retirement, descriptor)
    return fill(convert(T, retired), nslots(capacity))
end

function PropertyStore(schema::PropertySchema, capacity::CellCapacity)
    names = Tuple(property_keys(schema))
    columns = ntuple(i -> _property_column(schema.descriptors[i], capacity), length(names))
    return PropertyStore(schema, NamedTuple{names}(columns))
end

property_values(store::PropertyStore, key::Symbol) = getproperty(store.columns, key)

"""Derived occupancy data reconstructed exclusively from authoritative lattice ownership."""
struct OccupancyDerivedState
    finite_volumes::Vector{Int}
    medium_volumes::Vector{Int}
end

"""Backend-adaptable structure-of-arrays lowering of logical site ownership."""
struct CompiledOwnership{N, T <: AbstractArray{UInt8, N}, I <: AbstractArray{UInt32, N}}
    tags::T
    ids::I
end

function owner_at(ownership::CompiledOwnership, site::Integer)
    _owner_ref_unchecked(ownership.tags[site], ownership.ids[site])
end
function owner_at(ownership::CompiledOwnership, site::CartesianIndex)
    _owner_ref_unchecked(ownership.tags[site], ownership.ids[site])
end

function Adapt.adapt_structure(to, ownership::CompiledOwnership)
    return CompiledOwnership(Adapt.adapt(to, ownership.tags), Adapt.adapt(to, ownership.ids))
end

"""Thrown when a logical state violates one or more accepted state-model invariants."""
struct LogicalStateInvariantError <: Exception
    errors::Vector{String}
end

function Base.showerror(io::IO, error::LogicalStateInvariantError)
    print(io, "logical state invariant violation: ", join(error.errors, "; "))
end

"""
    LogicalPottsState

Final CPU logical state boundary.  The underscored fields are deliberately storage details; callers
use the accessors below so this state can later be lowered to backend-specific representations
without changing scientific meaning.
"""
mutable struct LogicalPottsState{N, P <: PropertyStore} <: AbstractPottsState
    _owners::Array{OwnerRef, N}
    _capacity::CellCapacity
    _active::BitVector
    _reusable::Vector{CellSlot}
    _generations::Vector{CellGeneration}
    _cell_types::Vector{UInt32}
    _medium_ids::Vector{MediumID}
    properties::P
    _derived::OccupancyDerivedState
end

function property_values(state::LogicalPottsState, key::Symbol)
    property_values(state.properties, key)
end
lattice_storage(state::LogicalPottsState) = state._owners

function compile_ownership(state::LogicalPottsState)
    tags = similar(state._owners, UInt8)
    ids = similar(state._owners, UInt32)
    for index in eachindex(state._owners)
        owner = state._owners[index]
        tags[index] = owner.tag
        ids[index] = owner.value
    end
    return CompiledOwnership(tags, ids)
end

function property_value(state::LogicalPottsState, key::Symbol, id::CellID)
    is_active(state, id) || throw(ArgumentError("cell $id is not active"))
    return property_values(state, key)[Int(value(id))]
end

function set_cell_property!(state::LogicalPottsState, key::Symbol, id::CellID, new_value)
    is_active(state, id) || throw(ArgumentError("cell $id is not active"))
    descriptor = property_descriptor(state.properties.schema, key)
    descriptor.mutability === MutableProperty ||
        throw(ArgumentError("property `$key` is read-only"))
    values = property_values(state, key)
    values[Int(value(id))] = convert(eltype(values), new_value)
    return state
end

capacity(state::LogicalPottsState) = state._capacity
n_cells(state::LogicalPottsState) = count(state._active)
function active_cell_ids(state::LogicalPottsState)
    CellID[CellID(index) for index in eachindex(state._active) if state._active[index]]
end
reusable_cell_slots(state::LogicalPottsState) = copy(state._reusable)
medium_ids(state::LogicalPottsState) = copy(state._medium_ids)
generation(state::LogicalPottsState, id::CellID) = state._generations[Int(value(id))]
function is_active(state::LogicalPottsState, id::CellID)
    Int(value(id)) <= nslots(capacity(state)) && state._active[Int(value(id))]
end

function cell_type(state::LogicalPottsState, id::CellID)
    is_active(state, id) || throw(ArgumentError("cell $id is not active"))
    return CellTypeID(state._cell_types[Int(value(id))])
end

owner_at(state::LogicalPottsState, site::CartesianIndex) = state._owners[site]
owner_at(state::LogicalPottsState, site::Integer) = state._owners[site]
function owner_at(state::LogicalPottsState, coordinates::Vararg{Integer, N}) where {N}
    state._owners[coordinates...]
end
lattice_size(state::LogicalPottsState) = size(state._owners)
derived_state(state::LogicalPottsState) = state._derived

function finite_volume(state::LogicalPottsState, id::CellID)
    is_active(state, id) || throw(ArgumentError("cell $id is not active"))
    state._derived.finite_volumes[Int(value(id))]
end

function medium_occupancy(state::LogicalPottsState, id::MediumID)
    index = findfirst(==(id), state._medium_ids)
    index === nothing && throw(ArgumentError("medium domain $id is not declared"))
    return state._derived.medium_volumes[index]
end

function _validated_slot_index(id::CellID, capacity::CellCapacity)
    index = Int(value(id))
    index <= nslots(capacity) ||
        throw(ArgumentError("cell $id exceeds fixed capacity $capacity"))
    return index
end

function _default_property_value(descriptor::PropertyDescriptor)
    initializer = descriptor.initializer
    initializer isa ConstantInitializer || throw(ArgumentError(
        "property `$(descriptor.key)` has no supported compiled initializer"))
    return convert(value_type(descriptor), initializer.value)
end

function _initialize_active_properties!(properties::PropertyStore, active::BitVector)
    for descriptor in properties.schema.descriptors
        values = property_values(properties, descriptor.key)
        initial = _default_property_value(descriptor)
        for index in eachindex(active)
            active[index] && (values[index] = initial)
        end
    end
    return properties
end

function _recompute_occupancy(owners, capacity::CellCapacity, media::Vector{MediumID})
    finite_volumes = zeros(Int, nslots(capacity))
    medium_volumes = zeros(Int, length(media))
    for owner in owners
        if is_cell_owner(owner)
            owner.value <= value(capacity) && (finite_volumes[Int(owner.value)] += 1)
        else
            index = findfirst(==(MediumID(owner.value)), media)
            index === nothing || (medium_volumes[index] += 1)
        end
    end
    return OccupancyDerivedState(finite_volumes, medium_volumes)
end

function _logical_state_errors(owners, capacity::CellCapacity, active::BitVector,
        reusable::Vector{CellSlot}, generations::Vector{CellGeneration}, cell_types::Vector{UInt32},
        media::Vector{MediumID}, properties::PropertyStore, derived::OccupancyDerivedState)
    errors = String[]
    slot_count = nslots(capacity)
    length(active) == slot_count ||
        push!(errors, "active-slot mask must cover fixed capacity")
    length(generations) == slot_count ||
        push!(errors, "generation table must cover fixed capacity")
    length(cell_types) == slot_count ||
        push!(errors, "cell-type table must cover fixed capacity")
    length(unique(media)) == length(media) ||
        push!(errors, "medium-domain IDs must be unique")
    length(unique(reusable)) == length(reusable) ||
        push!(errors, "reusable cell slots must be unique")
    issorted(reusable; by = value) ||
        push!(errors, "reusable cell slots must be in ascending order")

    reusable_indices = Int[value(slot) for slot in reusable]
    all(index -> 1 <= index <= slot_count, reusable_indices) || push!(errors,
        "reusable cell slots must lie within fixed capacity")
    for index in 1:min(length(active), length(cell_types))
        if active[index]
            cell_types[index] > 0 ||
                push!(errors, "every active finite cell must have one cell type")
            index in reusable_indices && push!(errors, "no active cell may be reusable")
        else
            cell_types[index] == 0 ||
                push!(errors, "inactive slots must not retain a cell type")
        end
    end

    declared_media = Set(media)
    finite_occupancy = zeros(Int, slot_count)
    medium_occupancy = zeros(Int, length(media))
    for owner in owners
        if is_cell_owner(owner)
            owner.value <= value(capacity) || (push!(errors,
                    "finite lattice owner exceeds fixed capacity"); continue)
            index = Int(owner.value)
            index <= length(active) && active[index] || push!(errors,
                "every finite lattice owner must be active")
            finite_occupancy[index] += 1
        elseif is_medium_owner(owner)
            domain = MediumID(owner.value)
            domain in declared_media || push!(errors,
                "every medium lattice owner must be declared")
            index = findfirst(==(domain), media)
            index === nothing || (medium_occupancy[index] += 1)
        else
            push!(errors, "every lattice site must have a valid owner")
        end
    end
    for index in 1:min(length(active), slot_count)
        active[index] && finite_occupancy[index] == 0 &&
            push!(errors,
                "every active finite cell must own at least one site")
    end

    for descriptor in properties.schema.descriptors
        values = property_values(properties, descriptor.key)
        length(values) == slot_count || push!(errors,
            "property `$(descriptor.key)` must cover every finite-cell slot")
        default = retired_property_value(descriptor.retirement, descriptor)
        for index in 1:min(length(active), length(values))
            !active[index] && values[index] != default &&
                push!(errors,
                    "retired slot $index must hold canonical value for property `$(descriptor.key)`")
        end
    end
    derived.finite_volumes == finite_occupancy || push!(errors,
        "finite-cell occupancy must equal a full lattice recomputation")
    derived.medium_volumes == medium_occupancy || push!(errors,
        "medium-domain occupancy must equal a full lattice recomputation")
    return unique(errors)
end

function state_invariant_errors(state::LogicalPottsState)
    _logical_state_errors(state._owners,
        state._capacity, state._active, state._reusable, state._generations, state._cell_types,
        state._medium_ids, state.properties, state._derived)
end

function assert_valid_state(state::LogicalPottsState)
    errors = state_invariant_errors(state)
    isempty(errors) || throw(LogicalStateInvariantError(errors))
    return state
end

"""Recompute the derived occupancy layer from authoritative lattice ownership."""
function rebuild_derived_state!(state::LogicalPottsState)
    state._derived = _recompute_occupancy(state._owners, state._capacity, state._medium_ids)
    return state
end

function LogicalPottsState(owners::AbstractArray{OwnerRef, N}, capacity::CellCapacity;
        active_ids = nothing, reusable_slots = CellSlot[], generations = nothing,
        cell_types = Dict{CellID, CellTypeID}(), medium_domains = MediumID[],
        property_schema = PropertySchema()) where {N}
    N in (2, 3) ||
        throw(ArgumentError("logical CPM state currently requires a 2D or 3D lattice"))
    copied_owners = Array(owners)
    slot_count = nslots(capacity)
    active = falses(slot_count)
    inferred = sort!(
        unique(CellID(owner.value)
        for owner in copied_owners if is_cell_owner(owner)); by = value)
    ids = active_ids === nothing ? inferred : collect(CellID.(active_ids))
    for id in ids
        active[_validated_slot_index(id, capacity)] = true
    end
    reusable = sort!(collect(CellSlot.(reusable_slots)); by = value)
    generation_values = generations === nothing ? fill(CellGeneration(0), slot_count) :
                        collect(CellGeneration.(generations))
    length(generation_values) == slot_count || throw(ArgumentError(
        "generation table must have one entry per fixed cell slot"))
    types = fill(UInt32(0), slot_count)
    for (id, type) in cell_types
        types[_validated_slot_index(CellID(id), capacity)] = value(CellTypeID(type))
    end
    declared_media = sort!(unique(MediumID.(medium_domains)); by = value)
    isempty(declared_media) &&
        throw(ArgumentError("at least one medium domain must be declared"))
    properties = PropertyStore(property_schema, capacity)
    _initialize_active_properties!(properties, active)
    derived = _recompute_occupancy(copied_owners, capacity, declared_media)
    state = LogicalPottsState(copied_owners, capacity, active, reusable, generation_values,
        types, declared_media, properties, derived)
    return assert_valid_state(state)
end
