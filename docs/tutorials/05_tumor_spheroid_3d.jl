using CairoMakie
CairoMakie.activate!()

# # 3D Tumor Spheroid
#
# Tumour spheroids grown in suspension are a classical *in vitro* model for
# avascular solid tumours. They recapitulate key features of in vivo tumour
# biology: a proliferating outer shell, a quiescent mid-zone, and a necrotic
# core — all driven by oxygen and nutrient gradients. Simulating spheroid
# growth in 3D is essential because the geometry of diffusion-limited growth
# is qualitatively different from its 2D projection.
#
# Celly.jl uses the exact same API in 3D as in 2D: the only change
# is the topology type and grid dimensionality. This tutorial demonstrates
# that generality on a 50 × 50 × 50 lattice.

# ## Packages
#
# `Zarr` is imported alongside CPMToolkit so we can use `ZarrBackend` to
# write the 3D time-series to disk. 3D simulations produce large arrays
# (50³ × n_frames × 4 bytes ≈ tens of MB per run), making on-disk backends
# preferable to the default in-memory `MemoryBackend`.

using CPMToolkit
using MakieCPM
using Zarr

# ## Cell Type

Tumor = CellType(:Tumor)
Medium = CellType(:Medium)

# ## Energy Model
#
# VolumeComponent and AdhesionComponent are sufficient to produce compact
# spheroidal growth morphology. In 3D, a target volume of 65 lattice sites
# corresponds roughly to a sphere of radius 2.5 voxels. J(Tumor,Medium) is
# set high to ensure tight packing: tumour cells prefer contact with
# each other over the surrounding medium, consistent with the elevated
# E-cadherin expression observed in early-stage carcinomas.

sys = CPMSystem(
    [Tumor, Medium],
    [
        VolumeComponent(Tumor => (λ = 5.0f0, target = 65)),
        AdhesionComponent(
            (Tumor, Tumor) => 2.0f0,
            (Tumor, Medium) => 18.0f0
        )
    ]
)

# ## Problem — 3D Lattice
#
# Passing a 3-element tuple `(50, 50, 50)` as the grid size automatically
# constructs a 3D lattice. `VonNeumannTopology{3}()` gives 6-connectivity
# (the six face-adjacent voxels), which is the 3D analogue of the 4-connected
# 2D neighbourhood and the appropriate choice for isotropic diffusion-limited
# problems. We seed 20 tumour cells in the centre and run for 400 MCS.

prob = CPMProblem(
    sys,
    Dict(Tumor => 20),
    (50, 50, 50);
    tspan = (0, 400),
    topology = VonNeumannTopology{3}()
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

# ## Solving with On-Disk Storage
#
# `ZarrBackend` writes each saved frame as a compressed chunk in a Zarr store.
# The store path is relative to the current working directory. Zarr supports
# random access, so you can load any frame without reading the full file.
# Pass the backend to `solve` alongside `saveat`.

sol = solve(prob, alg;
    saveat = 5,
    backend = ZarrBackend("05_tumor_spheroid.zarr")
)

# ## Visualising a Z-Slice
#
# MakieCPM's `record_cpm` can display a 2D cross-section of a 3D grid.
# The `slice` keyword (when provided) selects a fixed index along the last
# dimension (z-axis), so the movie shows the equatorial plane of the
# spheroid — the same view used in confocal microscopy z-stack projections.
# Here we take the central slice at z = 25.

record_cpm(
    "05_tumor_spheroid_3d.mp4",
    sol;
    slice = 25,
    metrics = [
        "N Cells" => u -> u.N_cells[],
        "Mean Volume" => u -> begin
            n = u.N_cells[]
            n > 0 ? sum(Array(u.cell_data.volumes)[1:n]) / n : 0.0
        end
    ],
    framerate = 20,
    resolution = (1200, 700)
)
