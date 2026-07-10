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
# Potts.jl uses the exact same API in 3D as in 2D: the only change
# is the topology type and grid dimensionality. This tutorial demonstrates
# that generality on a 50 × 50 × 50 lattice.

# ## Packages
#
# `Zarr` is imported alongside PottsToolkit so we can use `ZarrBackend` to
# write the 3D time-series to disk. 3D simulations produce large arrays
# (50³ × n_frames × 4 bytes ≈ tens of MB per run), making on-disk backends
# preferable to the default in-memory `MemoryBackend`.

using PottsToolkit
using MakiePotts
using Zarr

# ## Cell Type

Tumor = CellType(:Tumor)
Medium = CellType(:Medium, is_background = true)

# ## Energy Model
#
# VolumeComponent and AdhesionComponent are sufficient to produce compact
# spheroidal growth morphology. In 3D, a target volume of 65 lattice sites
# corresponds roughly to a sphere of radius 2.5 voxels. J(Tumor,Medium) is
# set high to ensure tight packing: tumour cells prefer contact with
# each other over the surrounding medium, consistent with the elevated
# E-cadherin expression observed in early-stage carcinomas.

sys = PottsSystem(
    cell_types = [Medium, Tumor],
    penalties = [
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
# problems.
#
# To accurately model a spheroid, we seed a single dense tumour mass in the centre
# of the grid using `HypersphereLayout`, rather than randomly distributing cells.

prob = PottsProblem(
    sys,
    HypersphereLayout(Tumor, (25, 25, 25), 10),
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
# MakiePotts's `record_potts` can display a 2D cross-section of a 3D grid.
# The `slice` keyword (when provided) selects a fixed index along the last
# dimension (z-axis), so the movie shows the equatorial plane of the
# spheroid — the same view used in confocal microscopy z-stack projections.
# Here we take the central slice at z = 25.

record_potts(
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

# ```@raw html
# <video autoplay loop muted playsinline controls src="../05_tumor_spheroid_3d.mp4" width="100%"></video>
# ```
