module CorePottsZarrExt

using CorePotts

using Zarr
using StructArrays
import Adapt

mutable struct ZarrContainer{GridT, CellT, NCellsT}
    zarr_grid::GridT
    cell_data_group::CellT
    zarr_N_cells::NCellsT
end

function CorePotts.initialize_backend(backend::CorePotts.ZarrBackend, prob, alg, opts)
    # Estimate upper bound for number of saves
    # It is safer to slightly over-allocate and trim later, or just leave empty chunks
    if opts.save_everystep
        num_saves = Int(prob.tspan[2] - prob.tspan[1] + 2)
    else
        num_saves = length(opts.saveat) + 2
    end

    if isdir(backend.path)
        rm(backend.path, force = true, recursive = true)
    end
    zgroup = Zarr.zgroup(backend.path)

    u0 = prob.u0
    grid = u0.grid
    grid_size = size(grid)

    # Grid chunking: chunk over spatial dimensions, chunk time=1
    chunk_size = (grid_size..., 1)

    zarr_grid = Zarr.zcreate(eltype(grid), zgroup, "grid", grid_size..., num_saves;
        chunks = chunk_size, fill_value = zero(eltype(grid)))

    cell_data_group_zarr = Zarr.zgroup(zgroup, "cell_data")

    max_capacity = length(u0.cell_data.volumes)

    cell_datasets = Dict{Symbol, Any}()
    for field in propertynames(u0.cell_data)
        array = getproperty(u0.cell_data, field)
        T_el = eltype(array)
        # Zarr string handling is slightly different, but assuming numeric types for cell_data
        zarr_array = Zarr.zcreate(T_el, cell_data_group_zarr, string(field), max_capacity,
            num_saves; chunks = (max_capacity, 1), fill_value = zero(T_el))
        cell_datasets[field] = zarr_array
    end

    zarr_N_cells = Zarr.zcreate(
        Int, zgroup, "N_cells", num_saves; chunks = (num_saves,), fill_value = 0)

    sol_u = ZarrContainer(zarr_grid, cell_datasets, zarr_N_cells)
    tType = typeof(prob.tspan[1])
    sol_t = tType[]

    return sol_u, sol_t
end

function CorePotts.save_state!(integrator, backend::CorePotts.ZarrBackend)
    zc = integrator.sol_u
    idx = length(integrator.sol_t) + 1

    cpu_grid = Adapt.adapt(Array, integrator.u.grid)

    N = ndims(cpu_grid)
    if N == 2
        zc.zarr_grid[:, :, idx] = cpu_grid
    elseif N == 3
        zc.zarr_grid[:, :, :, idx] = cpu_grid
    end

    for field in propertynames(integrator.u.cell_data)
        array = Adapt.adapt(Array, getproperty(integrator.u.cell_data, field))
        zc.cell_data_group[field][:, idx] = array
    end

    zc.zarr_N_cells[idx] = Int(Array(integrator.u.N_cells)[])

    push!(integrator.sol_t, integrator.t)
end

function Base.getindex(zc::ZarrContainer, i::Int)
    grid_dims = ndims(zc.zarr_grid)

    if grid_dims == 3 # 2D + Time
        grid_slice = zc.zarr_grid[:, :, i]
    elseif grid_dims == 4 # 3D + Time
        grid_slice = zc.zarr_grid[:, :, :, i]
    end

    keys_list = Symbol[]
    vals_list = Any[]

    for (k, dataset) in zc.cell_data_group
        push!(keys_list, k)
        push!(vals_list, dataset[:, i])
    end

    nt = NamedTuple{Tuple(keys_list)}(Tuple(vals_list))
    cell_data = StructArray(nt)

    n_cells_val = zc.zarr_N_cells[i]
    return (grid = grid_slice, cell_data = cell_data, N_cells = Ref(n_cells_val))
end

function _zarr_write_array(group, name, values)
    array = Zarr.zcreate(eltype(values), group, name, size(values)...;
        chunks = size(values), fill_value = zero(eltype(values)))
    indices = ntuple(_ -> Colon(), ndims(values))
    array[indices...] = values
    return array
end

function _zarr_write_payload(path, key, payload; fail_after = nothing)
    attrs = Dict{String, Any}(
        "checkpoint_key" => String(key), "schema_version" => payload.schema_version,
        "algorithm" => payload.algorithm, "rng_contract" => payload.rng_contract,
        "julia_version" => payload.julia_version,
        "corepotts_version" => payload.corepotts_version,
        "numerical_mode" => payload.numerical_mode,
        "scalar_types" => payload.scalar_types,
        "index_types" => payload.index_types,
        "dependency_identities" => payload.dependency_identities,
        "backend_runtime_identity" => payload.backend_runtime_identity,
        "warnings" => payload.warnings,
    )
    group = Zarr.zgroup(path; attrs)
    for (name, values) in (
            "mcs" => [payload.mcs], "phase" => [payload.phase], "dims" => payload.dims,
            "capacity" => [payload.capacity], "ownership_tags" => payload.ownership_tags,
            "ownership_ids" => payload.ownership_ids, "active" => payload.active,
            "generations" => payload.generations, "cell_types" => payload.cell_types,
            "reusable_slots" => payload.reusable_slots,
            "reusable_count" => [payload.reusable_count], "medium_ids" => payload.medium_ids,
            "seed" => [payload.seed], "backend" => [payload.backend],
            "model_fingerprint" => payload.model_fingerprint,
            "schema_fingerprint" => payload.schema_fingerprint,
            "topology_fingerprint" => payload.topology_fingerprint,
            "initial_state_fingerprint" => payload.initial_state_fingerprint,
            "ancestry_fingerprint" => payload.ancestry_fingerprint,
            "state_fingerprint" => payload.state_fingerprint,
            "checksum" => payload.checksum)
        _zarr_write_array(group, name, values)
    end
    properties = Zarr.zgroup(group, "properties")
    for (index, (key_name, values)) in enumerate(zip(
            payload.property_keys, payload.property_values))
        property_group = Zarr.zgroup(properties, lpad(string(index), 8, '0');
            attrs = Dict("key" => key_name))
        _zarr_write_array(property_group, "values", values)
    end
    fail_after === :payload && throw(ErrorException(
        "injected Zarr checkpoint failure after staged payload"))
    _zarr_write_array(group, "complete", UInt8[1])
    return path
end

_zarr_array(group, name) = Array(group[name])

function _zarr_read_payload(path, key)
    group = Zarr.zopen(path, "r")
    haskey(group, "complete") || throw(CorePotts.IncompleteCheckpointError(String(key)))
    _zarr_array(group, "complete")[1] == UInt8(1) ||
        throw(CorePotts.IncompleteCheckpointError(String(key)))
    String(group.attrs["checkpoint_key"]) == String(key) || throw(KeyError(String(key)))
    properties = group["properties"]
    property_keys = String[]
    property_values = Any[]
    for name in sort!(collect(keys(properties.groups)))
        property_group = properties[name]
        push!(property_keys, String(property_group.attrs["key"]))
        push!(property_values, _zarr_array(property_group, "values"))
    end
    return (
        complete = UInt8(1), schema_version = String(group.attrs["schema_version"]),
        mcs = _zarr_array(group, "mcs")[1], phase = _zarr_array(group, "phase")[1],
        dims = _zarr_array(group, "dims"), capacity = _zarr_array(group, "capacity")[1],
        ownership_tags = _zarr_array(group, "ownership_tags"),
        ownership_ids = _zarr_array(group, "ownership_ids"),
        active = _zarr_array(group, "active"),
        generations = _zarr_array(group, "generations"),
        cell_types = _zarr_array(group, "cell_types"),
        reusable_slots = _zarr_array(group, "reusable_slots"),
        reusable_count = _zarr_array(group, "reusable_count")[1],
        medium_ids = _zarr_array(group, "medium_ids"), property_keys, property_values,
        seed = _zarr_array(group, "seed")[1], backend = _zarr_array(group, "backend")[1],
        algorithm = String(group.attrs["algorithm"]),
        rng_contract = String(group.attrs["rng_contract"]),
        julia_version = String(group.attrs["julia_version"]),
        corepotts_version = String(group.attrs["corepotts_version"]),
        numerical_mode = String(group.attrs["numerical_mode"]),
        scalar_types = String.(group.attrs["scalar_types"]),
        index_types = String.(group.attrs["index_types"]),
        dependency_identities = String.(group.attrs["dependency_identities"]),
        backend_runtime_identity = String(group.attrs["backend_runtime_identity"]),
        model_fingerprint = _zarr_array(group, "model_fingerprint"),
        schema_fingerprint = _zarr_array(group, "schema_fingerprint"),
        topology_fingerprint = _zarr_array(group, "topology_fingerprint"),
        initial_state_fingerprint = _zarr_array(group, "initial_state_fingerprint"),
        ancestry_fingerprint = _zarr_array(group, "ancestry_fingerprint"),
        state_fingerprint = _zarr_array(group, "state_fingerprint"),
        warnings = String.(group.attrs["warnings"]), checksum = _zarr_array(group, "checksum"),
    )
end

function CorePotts.write_checkpoint!(store::CorePotts.ZarrCheckpointStore, key,
        checkpoint::CorePotts.CanonicalCheckpoint; fail_after = nothing)
    parent = dirname(abspath(store.path))
    mkpath(parent)
    staging = mktempdir(parent)
    try
        _zarr_write_payload(staging, key,
            CorePotts.checkpoint_storage_payload(checkpoint); fail_after)
        observed = CorePotts.checkpoint_from_storage_payload(
            _zarr_read_payload(staging, key))
        observed.checksum == checkpoint.checksum || error(
            "staged Zarr checkpoint differs from its canonical record")
        mv(staging, store.path; force = true)
    catch
        ispath(staging) && rm(staging; force = true, recursive = true)
        rethrow()
    end
    return store
end

function CorePotts.read_checkpoint(store::CorePotts.ZarrCheckpointStore, key)
    isdir(store.path) || throw(KeyError(String(key)))
    return CorePotts.checkpoint_from_storage_payload(
        _zarr_read_payload(store.path, key))
end

end
