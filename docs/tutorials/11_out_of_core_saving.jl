using CairoMakie
CairoMakie.activate!()

# # Out-of-Core Saving with Zarr & HDF5
#
# Long 2-D simulations and all 3-D simulations can easily produce hundreds of
# gigabytes of lattice data — far more than fits in RAM.  PottsToolkit solves
# this through *backend extensions*: instead of accumulating snapshots in a
# PottsSolution object, the solver streams each saved frame directly to disk.
# Two backends ship out of the box: **ZarrBackend** (chunked, compressed,
# cloud-friendly) and **HDF5Backend** (widely supported in the scientific
# Python/Julia ecosystem).

# ## Packages
#
# Loading `Zarr` and `HDF5` activates the corresponding PottsToolkit package
# extensions that define the backend types.

using PottsToolkit
using Zarr
using HDF5
using Statistics

# ## Model definition (shared)
#
# We build a simple two-population sorting model that will be solved twice —
# once with each backend — so the results can be compared.

A = CellType(:A)
B = CellType(:B)
Medium = CellType(:Medium, is_background = true)

sys = PottsSystem(
    cell_types = [Medium, A, B],
    penalties = [
        VolumeComponent(
            A => (λ = 5.0f0, target = 500),
            B => (λ = 5.0f0, target = 500)
        ),
        AdhesionComponent(
            (A, Medium) => 16.0f0,
            (B, Medium) => 16.0f0,
            (A, A) => 2.0f0,
            (B, B) => 2.0f0,
            (A, B) => 14.0f0
        )
    ]
)

prob = PottsProblem(
    sys,
    Dict(A => 20, B => 20),
    (200, 200);
    tspan = (0, 1000),
    topology = VonNeumannTopology{2}()
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

# ## Solving with ZarrBackend
#
# Pass `backend = ZarrBackend("path/to/output.zarr")` to `solve`.  The solver
# writes each saved frame as a new chunk in the Zarr store.  The returned
# value is a `PottsSolution` where the state history is backed by the Zarr store instead of RAM.
#
# The Zarr store is a directory on disk; you can open it with any Zarr-aware
# tool (Python `zarr`, Julia `Zarr.jl`, Dask, xarray …).

zarr_path = "cell_sorting_sim.zarr"
sol_zarr = solve(prob, alg; saveat = 20, backend = ZarrBackend(zarr_path))

# ## Inspecting the Zarr archive
#
# Open the store, list the arrays, and read a single snapshot frame.

store = zopen(zarr_path, "r")
lattice = store["grid"]          # dimensions: (Nx, Ny, n_frames)
println("Zarr lattice shape : ", size(lattice))
println("Number of frames   : ", size(lattice, 3))

# Read the final frame for a quick sanity check
final_frame = lattice[:, :, end]
println("Unique cell labels in final frame: ", length(unique(final_frame)))

# ## Solving with HDF5Backend
#
# The HDF5Backend writes the same data into an HDF5 file under a `/lattice`
# dataset.  HDF5 supports chunked storage and GZIP compression automatically.

hdf5_path = "cell_sorting_sim.h5"
solve(prob, alg; saveat = 20, backend = HDF5Backend(hdf5_path))

# ## Inspecting the HDF5 file

h5open(hdf5_path, "r") do f
    ds = f["grid"]
    println("HDF5 dataset shape : ", size(ds))
    println("HDF5 chunk layout  : ", HDF5.get_chunk(ds))
end

# ## Trade-offs
#
# | Feature                 | MemoryBackend | ZarrBackend | HDF5Backend |
# |-------------------------|:-------------:|:-----------:|:-----------:|
# | RAM usage               | full          | tiny        | tiny        |
# | explore_potts support     | ✓             | ✗           | ✗           |
# | record_potts from file    | ✓             | ✓           | ✓           |
# | Cloud / parallel writes | ✗             | ✓ (N5/S3)   | partial     |
# | Ecosystem compatibility | Julia only    | Python/Julia | universal  |
#
# Because the backends stream to disk, `explore_potts` (which needs a live
# integrator + MemoryBackend) is not available.  Use `record_potts` with the
# returned PottsSolution for post-hoc visualisation.

# ## Recording from the Zarr store
#
# `record_potts` works transparently with the `sol_zarr` object because it
# acts as a lazy container.

using MakiePotts

record_potts(
    "cell_sorting_zarr.mp4",
    sol_zarr;
    framerate = 15,
    resolution = (800, 800)
)

# ```@raw html
# <video autoplay loop muted playsinline controls src="../cell_sorting_zarr.mp4" width="100%"></video>
# ```
