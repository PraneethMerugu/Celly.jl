module CorePottsHDF5Ext

using CorePotts

using HDF5
using StructArrays
import Adapt

mutable struct HDF5Container{GridT, CellT, FileT, NCellsT}
    hdf5_file::FileT
    hdf5_grid::GridT
    cell_data_group::CellT
    hdf5_N_cells::NCellsT
end

function CorePotts.initialize_backend(backend::CorePotts.HDF5Backend, prob, alg, opts)
    # Estimate upper bound for number of saves
    if opts.save_everystep
        num_saves = Int(prob.tspan[2] - prob.tspan[1] + 2)
    else
        num_saves = length(opts.saveat) + 2
    end

    # mode "w" overwrites existing file
    h5file = h5open(backend.path, "w")

    u0 = prob.u0
    grid = u0.grid
    grid_size = size(grid)

    # Grid chunking: chunk over spatial dimensions, chunk time=1
    chunk_size = (grid_size..., 1)
    max_dims = (grid_size..., -1) # UNLIMITED

    # Initialize with 0 in the time dimension, we will resize on every save!
    grid_initial_dims = (grid_size..., 0)

    hdf5_grid = create_dataset(h5file, "grid", datatype(eltype(grid)),
        dataspace(grid_initial_dims, max_dims = max_dims), chunk = chunk_size, deflate = 3)

    cell_data_group_hdf5 = create_group(h5file, "cell_data")

    max_capacity = length(u0.cell_data.volumes)

    cell_datasets = Dict{Symbol, Any}()
    for field in propertynames(u0.cell_data)
        array = getproperty(u0.cell_data, field)
        T_el = eltype(array)
        dset = create_dataset(cell_data_group_hdf5, string(field), datatype(T_el),
            dataspace((max_capacity, 0), max_dims = (max_capacity, -1)),
            chunk = (max_capacity, 1), deflate = 3)
        cell_datasets[field] = dset
    end

    hdf5_N_cells = create_dataset(h5file, "N_cells", datatype(Int),
        dataspace((0,), max_dims = (-1,)), chunk = (1,), deflate = 3)

    sol_u = HDF5Container(h5file, hdf5_grid, cell_datasets, hdf5_N_cells)
    tType = typeof(prob.tspan[1])
    sol_t = tType[]

    return sol_u, sol_t
end

function CorePotts.save_state!(integrator, backend::CorePotts.HDF5Backend)
    hc = integrator.sol_u
    idx = length(integrator.sol_t) + 1

    cpu_grid = Adapt.adapt(Array, integrator.u.grid)
    N = ndims(cpu_grid)

    # Resize the HDF5 grid dataset
    grid_size = size(cpu_grid)
    HDF5.set_extent_dims(hc.hdf5_grid, (grid_size..., idx))

    if N == 2
        hc.hdf5_grid[:, :, idx] = cpu_grid
    elseif N == 3
        hc.hdf5_grid[:, :, :, idx] = cpu_grid
    end

    for field in propertynames(integrator.u.cell_data)
        array = Adapt.adapt(Array, getproperty(integrator.u.cell_data, field))
        dset = hc.cell_data_group[field]
        HDF5.set_extent_dims(dset, (length(array), idx))
        dset[:, idx] = array
    end

    HDF5.set_extent_dims(hc.hdf5_N_cells, (idx,))
    hc.hdf5_N_cells[idx] = Int(Array(integrator.u.N_cells)[])

    push!(integrator.sol_t, integrator.t)
end

function Base.getindex(hc::HDF5Container, i::Int)
    grid_dims = ndims(hc.hdf5_grid)

    if grid_dims == 3 # 2D + Time
        grid_slice = hc.hdf5_grid[:, :, i]
    elseif grid_dims == 4 # 3D + Time
        grid_slice = hc.hdf5_grid[:, :, :, i]
    end

    keys_list = Symbol[]
    vals_list = Any[]

    # Rebuild cell data
    for key_str in keys(hc.cell_data_group)
        dset = hc.cell_data_group[Symbol(key_str)]
        push!(keys_list, Symbol(key_str))
        push!(vals_list, dset[:, i])
    end

    nt = NamedTuple{Tuple(keys_list)}(Tuple(vals_list))
    cell_data = StructArray(nt)

    n_cells_val = hc.hdf5_N_cells[i]
    return (grid = grid_slice, cell_data = cell_data, N_cells = Ref(n_cells_val))
end

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
