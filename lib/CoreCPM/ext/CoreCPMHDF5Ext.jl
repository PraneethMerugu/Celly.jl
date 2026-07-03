module CoreCPMHDF5Ext

using CoreCPM
using CoreCPM.CoreCPMBase
using HDF5
using StructArrays
import Adapt

mutable struct HDF5Container{GridT, CellT, FileT, NCellsT}
    hdf5_file::FileT
    hdf5_grid::GridT
    cell_data_group::CellT
    hdf5_N_cells::NCellsT
end

function CoreCPMBase.initialize_backend(backend::CoreCPMBase.HDF5Backend, prob, alg, opts)
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
    
    hdf5_grid = create_dataset(h5file, "grid", datatype(eltype(grid)), dataspace(grid_initial_dims, max_dims=max_dims), chunk=chunk_size, deflate=3)
    
    cell_data_group_hdf5 = create_group(h5file, "cell_data")
    
    max_capacity = length(u0.cell_data.volumes)
    
    cell_datasets = Dict{Symbol, Any}()
    for field in propertynames(u0.cell_data)
        array = getproperty(u0.cell_data, field)
        T_el = eltype(array)
        dset = create_dataset(cell_data_group_hdf5, string(field), datatype(T_el), dataspace((max_capacity, 0), max_dims=(max_capacity, -1)), chunk=(max_capacity, 1), deflate=3)
        cell_datasets[field] = dset
    end
    
    hdf5_N_cells = create_dataset(h5file, "N_cells", datatype(Int), dataspace((0,), max_dims=(-1,)), chunk=(1,), deflate=3)
    
    sol_u = HDF5Container(h5file, hdf5_grid, cell_datasets, hdf5_N_cells)
    sol_t = Int[]
    
    return sol_u, sol_t
end

function CoreCPMBase.save_state!(integrator, backend::CoreCPMBase.HDF5Backend)
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
    hc.hdf5_N_cells[idx] = integrator.u.N_cells[]
    
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
    return (grid=grid_slice, cell_data=cell_data, N_cells=Ref(n_cells_val))
end

end
