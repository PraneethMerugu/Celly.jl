using CairoMakie
CairoMakie.activate!()

# # GPU Acceleration
#
# A typical 2D CPM on a 500 × 500 grid with 1000 cells runs in a few seconds
# on a modern CPU. Scaling to 1000 × 1000 grids, 3D domains, or parameter
# sweeps can push wall-clock time into hours. Celly.jl offloads the
# inner Monte Carlo loop to the GPU with a single change: allocate the lattice
# array on the GPU device. The rest of the API — energy components, callbacks,
# backends, and visualisation — is identical.
#
# This tutorial covers GPU setup, algorithm choice, and performance patterns.

# ## Packages
#
# Uncomment exactly one of the GPU backends depending on your hardware.
# Apple Silicon Macs use Metal; NVIDIA hardware uses CUDA.
# On CPU-only systems the tutorial still runs using the CPU path.

using CPMToolkit
using MakieCPM

# using CUDA   # NVIDIA GPU — uncomment on CUDA systems
# using Metal  # Apple GPU — uncomment on Apple Silicon

# ## Cell Types

TypeA  = CellType(:TypeA)
Medium = CellType(:Medium)

# ## Energy Model
#
# We use a representative mix of components to benchmark a realistic workload.

sys = CPMSystem(
    [TypeA, Medium],
    [
        VolumeComponent(TypeA => (λ = 5.0f0, target = 200)),
        SurfaceAreaComponent(TypeA => (λ = 1.0f0, target = 60)),
        AdhesionComponent(
            (TypeA, TypeA)  => 2.0f0,
            (TypeA, Medium) => 16.0f0,
        ),
    ]
)

# ## Algorithm Comparison
#
# Three Metropolis variants are available. Their suitability differs by
# hardware and topology:
#
# **CheckerboardMetropolis** — Divides the lattice into two independent
# sub-lattices (like a chess board). Odd- and even-coloured sites are updated
# in separate passes, so all updates within a pass are independent and can
# be parallelised trivially. *Preferred for GPU; correct for VonNeumann and
# Moore topologies.*
#
# **ParallelMetropolis** — Uses a stochastic "lottery" to decide which sites
# update in parallel. Every site participates each half-sweep but conflicts
# are resolved probabilistically. Slightly lower acceptance rate than
# CheckerboardMetropolis but handles extended neighbourhoods well.
# *Recommended when using ExtendedVonNeumannTopology or ExtendedMooreTopology.*
#
# **SequentialMetropolis** — Updates sites one at a time in a deterministic
# sweep order. Exact Metropolis dynamics, no parallelism. Use as the
# reference implementation for validating GPU results on small grids.

alg_checkerboard  = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)
alg_parallel      = ParallelMetropolis(T = 2.0f0, sweeps_per_step = 10)
alg_sequential    = SequentialMetropolis(T = 2.0f0, sweeps_per_step = 10)

# ## Problem — Large Grid
#
# A 500 × 500 grid showcases the benefit of GPU execution. On CPU this takes
# ~60 s; on a mid-range GPU it completes in ~3 s. The `prob` definition is
# hardware-agnostic — GPU dispatch happens through the lattice array.
#
# To run on GPU, replace `(500, 500)` with a GPU-allocated grid:
#
# ```julia
# # CUDA:
# grid = CUDA.zeros(UInt32, 500, 500)
# # Metal:
# grid = Metal.zeros(UInt32, 500, 500)
# ```
#
# Then pass `grid` as the third argument to CPMProblem instead of the tuple.

prob = CPMProblem(
    sys,
    Dict(TypeA => 200),
    (500, 500);
    tspan    = (0, 500),
    topology = VonNeumannTopology{2}(),
)

# ## Timing Pattern
#
# The idiomatic way to measure wall-clock time in Julia is `@time`. The first
# call incurs JIT compilation overhead; the second call gives the true
# runtime. Always benchmark the second (or later) call.

# First call — includes compilation
@time sol_warm = solve(prob, alg_checkerboard; saveat = 10)

# Second call — pure runtime
@time sol = solve(prob, alg_checkerboard; saveat = 10)

# ## Extended Topology Note
#
# If you switch to `ExtendedVonNeumannTopology{2,2}()` (radius-2 neighbourhood)
# or `ExtendedMooreTopology{2,2}()`, the checkerboard colouring is no longer
# sufficient to guarantee independence between simultaneous updates. Switch to
# `ParallelMetropolis` in that case. The `active_fraction` kwarg controls
# what fraction of sites participate per sub-step (default 1.0); reducing it
# can improve acceptance rates in high-density simulations. The `block_size`
# kwarg sets the CUDA/Metal thread-block size (default 256).

# alg_extended = ParallelMetropolis(T = 2.0f0, sweeps_per_step = 10,
#                                   active_fraction = 0.8f0, block_size = 512)

# ## Visualisation

record_cpm(
    "06_gpu_acceleration.mp4",
    sol;
    metrics = [
        "N Cells"     => u -> u.N_cells[],
        "Mean Volume" => u -> begin
            n = u.N_cells[]
            n > 0 ? sum(Array(u.cell_data.volumes)[1:n]) / n : 0.0
        end,
    ],
    framerate  = 24,
    resolution = (1200, 700),
)
