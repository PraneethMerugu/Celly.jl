module CorePottsHDF5Ext

using CorePotts

using HDF5

function _hdf5_write_payload(path, key, payload; fail_after = nothing)
    h5open(path, "w") do file
        attributes(file)["checkpoint_key"] = String(key)
        attributes(file)["schema_version"] = payload.schema_version
        attributes(file)["algorithm"] = payload.algorithm
        attributes(file)["algorithm_contract"] = payload.algorithm_contract
        attributes(file)["rng_contract"] = payload.rng_contract
        attributes(file)["julia_version"] = payload.julia_version
        attributes(file)["corepotts_version"] = payload.corepotts_version
        attributes(file)["numerical_mode"] = payload.numerical_mode
        attributes(file)["scalar_types"] = join(payload.scalar_types, '\n')
        attributes(file)["index_types"] = join(payload.index_types, '\n')
        attributes(file)["dependency_identities"] =
            join(payload.dependency_identities, '\n')
        attributes(file)["backend_runtime_identity"] =
            payload.backend_runtime_identity
        attributes(file)["warnings"] = join(payload.warnings, '\n')
        write(file, "mcs", [payload.mcs])
        write(file, "phase", [payload.phase])
        write(file, "dims", payload.dims)
        write(file, "capacity", [payload.capacity])
        write(file, "ownership_tags", payload.ownership_tags)
        write(file, "ownership_ids", payload.ownership_ids)
        write(file, "active", payload.active)
        write(file, "generations", payload.generations)
        write(file, "cell_types", payload.cell_types)
        write(file, "reusable_slots", payload.reusable_slots)
        write(file, "reusable_count", [payload.reusable_count])
        write(file, "medium_ids", payload.medium_ids)
        write(file, "seed", [payload.seed])
        write(file, "backend", [payload.backend])
        for name in ("model_fingerprint", "schema_fingerprint", "topology_fingerprint",
                "initial_state_fingerprint", "ancestry_fingerprint", "state_fingerprint",
                "checksum")
            write(file, name, getproperty(payload, Symbol(name)))
        end
        properties = create_group(file, "properties")
        for (index, (key_name, values)) in enumerate(zip(
                payload.property_keys, payload.property_values))
            group = create_group(properties, lpad(string(index), 8, '0'))
            attributes(group)["key"] = key_name
            write(group, "values", values)
        end
        fail_after === :payload && throw(ErrorException(
            "injected HDF5 checkpoint failure after staged payload"))
        write(file, "complete", UInt8[1])
    end
    return path
end

function _hdf5_read_payload(path, key)
    h5open(path, "r") do file
        haskey(file, "complete") || throw(CorePotts.IncompleteCheckpointError(String(key)))
        read(file["complete"])[1] == UInt8(1) ||
            throw(CorePotts.IncompleteCheckpointError(String(key)))
        stored_key = String(read(attributes(file)["checkpoint_key"]))
        stored_key == String(key) || throw(KeyError(String(key)))
        properties = file["properties"]
        property_keys = String[]
        property_values = Any[]
        for name in sort!(collect(keys(properties)))
            group = properties[name]
            push!(property_keys, String(read(attributes(group)["key"])))
            push!(property_values, read(group["values"]))
        end
        warnings_text = String(read(attributes(file)["warnings"]))
        scalar_types_text = String(read(attributes(file)["scalar_types"]))
        index_types_text = String(read(attributes(file)["index_types"]))
        dependency_identities_text =
            String(read(attributes(file)["dependency_identities"]))
        return (
            complete = UInt8(1),
            schema_version = String(read(attributes(file)["schema_version"])),
            mcs = read(file["mcs"])[1], phase = read(file["phase"])[1],
            dims = read(file["dims"]), capacity = read(file["capacity"])[1],
            ownership_tags = read(file["ownership_tags"]),
            ownership_ids = read(file["ownership_ids"]), active = read(file["active"]),
            generations = read(file["generations"]), cell_types = read(file["cell_types"]),
            reusable_slots = read(file["reusable_slots"]),
            reusable_count = read(file["reusable_count"])[1],
            medium_ids = read(file["medium_ids"]), property_keys, property_values,
            seed = read(file["seed"])[1], backend = read(file["backend"])[1],
            algorithm = String(read(attributes(file)["algorithm"])),
            algorithm_contract =
                String(read(attributes(file)["algorithm_contract"])),
            rng_contract = String(read(attributes(file)["rng_contract"])),
            julia_version = String(read(attributes(file)["julia_version"])),
            corepotts_version = String(read(attributes(file)["corepotts_version"])),
            numerical_mode = String(read(attributes(file)["numerical_mode"])),
            scalar_types = isempty(scalar_types_text) ? String[] :
                split(scalar_types_text, '\n'),
            index_types = isempty(index_types_text) ? String[] :
                split(index_types_text, '\n'),
            dependency_identities = isempty(dependency_identities_text) ? String[] :
                split(dependency_identities_text, '\n'),
            backend_runtime_identity =
                String(read(attributes(file)["backend_runtime_identity"])),
            model_fingerprint = read(file["model_fingerprint"]),
            schema_fingerprint = read(file["schema_fingerprint"]),
            topology_fingerprint = read(file["topology_fingerprint"]),
            initial_state_fingerprint = read(file["initial_state_fingerprint"]),
            ancestry_fingerprint = read(file["ancestry_fingerprint"]),
            state_fingerprint = read(file["state_fingerprint"]),
            warnings = isempty(warnings_text) ? String[] : split(warnings_text, '\n'),
            checksum = read(file["checksum"]),
        )
    end
end

function CorePotts.write_checkpoint!(store::CorePotts.HDF5CheckpointStore, key,
        checkpoint::CorePotts.CanonicalCheckpoint; fail_after = nothing)
    parent = dirname(abspath(store.path))
    mkpath(parent)
    staging, io = mktemp(parent)
    close(io)
    try
        _hdf5_write_payload(staging, key,
            CorePotts.checkpoint_storage_payload(checkpoint); fail_after)
        observed = CorePotts.checkpoint_from_storage_payload(
            _hdf5_read_payload(staging, key))
        observed.checksum == checkpoint.checksum || error(
            "staged HDF5 checkpoint differs from its canonical record")
        mv(staging, store.path; force = true)
    catch
        ispath(staging) && rm(staging; force = true)
        rethrow()
    end
    return store
end

function CorePotts.read_checkpoint(store::CorePotts.HDF5CheckpointStore, key)
    isfile(store.path) || throw(KeyError(String(key)))
    return CorePotts.checkpoint_from_storage_payload(
        _hdf5_read_payload(store.path, key))
end

end
