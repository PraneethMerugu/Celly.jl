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

    zc.zarr_N_cells[idx] = integrator.u.N_cells[]

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

end
