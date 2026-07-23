module CorePottsZarrExt

using CorePotts

using Zarr

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
        "algorithm" => payload.algorithm,
        "algorithm_contract" => payload.algorithm_contract,
        "rng_contract" => payload.rng_contract,
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
        algorithm_contract = String(group.attrs["algorithm_contract"]),
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
