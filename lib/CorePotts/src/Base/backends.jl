abstract type AbstractOutputBackend end

"""
    MemoryBackend()

The default out-of-core data saving backend. Pushes grid and cell_data into an array in RAM.
"""
struct MemoryBackend <: AbstractOutputBackend end

function initialize_backend(::MemoryBackend, prob, alg, opts)
    tType = typeof(prob.tspan[1])
    return Any[], tType[]
end

function save_state!(integrator, ::MemoryBackend)
    # Adapt grid and cell_data to regular CPU Arrays to avoid holding multiple copies in GPU VRAM
    cpu_grid = deepcopy(Adapt.adapt(Array, integrator.u.grid))
    cpu_cell_data = deepcopy(Adapt.adapt(Array, integrator.u.cell_data))
    push!(integrator.sol_u,
        (
            grid = cpu_grid, cell_data = cpu_cell_data, N_cells = Ref(Int(Array(integrator.u.N_cells)[]))))
    push!(integrator.sol_t, integrator.t)
end

"""
    ZarrBackend(path::String)

Streams the simulation out-of-core to a Zarr dataset on disk. Requires `using Zarr`.
"""
struct ZarrBackend <: AbstractOutputBackend
    path::String
end

"""
    HDF5Backend(path::String)

Streams the simulation out-of-core to an HDF5 dataset on disk. Requires `using HDF5`.
"""
struct HDF5Backend <: AbstractOutputBackend
    path::String
end

function initialize_backend(backend::AbstractOutputBackend, prob, alg, opts)
    error("The backend $(typeof(backend)) requires an extension to be loaded. Did you forget to run `using Zarr` or `using HDF5`?")
end

function save_state!(integrator, backend::AbstractOutputBackend)
    error("The backend $(typeof(backend)) requires an extension to be loaded. Did you forget to run `using Zarr` or `using HDF5`?")
end
