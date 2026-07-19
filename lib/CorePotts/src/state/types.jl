
using ArgCheck
import Functors
import Functors: @functor, fmap
const UINT32_TO_FLOAT32 = 2.3283064f-10
const MASK_24BIT = 0x00FFFFFF
const SCALE_24BIT = 0x01000000
const MITOSIS_SEED_OFFSET = UInt64(9999991)

const TWO_PI_F32 = 2.0f0 * Float32(pi)

@inline function pcg_hash(seed::UInt64)
    state = seed * 0x5851F42D4C957F2D + 0x14057B7EF767814F
    word = xor(state >> ((state >> 59) + UInt64(5)), state) * 0x5851F42D4C957F2D
    return xor(word >> 43, word)
end

@inline function randn_pcg(seed1::UInt64, seed2::UInt64)
    # Modified for Metal compatibility (no Float64 support on Apple Silicon).
    # Extract the upper 32 bits to generate a Float32 in [0, 1).
    u1 = Float32(pcg_hash(seed1) >> 32) * UINT32_TO_FLOAT32
    u2 = Float32(pcg_hash(seed2) >> 32) * UINT32_TO_FLOAT32
    return sqrt(-2.0f0 * log(max(1.0f-7, u1))) * cos(TWO_PI_F32 * u2)
end

"""
    FlexibilityTrait
    
Traits indicating whether a physical property or penalty is rigid (type-coupled) or flexible (per-cell and dynamically writable).
"""
abstract type FlexibilityTrait end
struct Rigid <: FlexibilityTrait end
struct Flex <: FlexibilityTrait end

"""
    required_variables(component)

Returns a NamedTuple mapping the required variables to their types for a given physics penalty or tracker.
"""
required_variables(comp) = (;)

"""
    PottsState{Grid, CellData}

The mutable state vector `u` for a Cellular Potts Model simulation.
Contains the grid, cell properties, and cell ID tracking structures.
"""
abstract type AbstractPottsState end

"""Backend-visible lattice storage for an explicit execution boundary."""
function lattice_storage end

struct PottsState{Grid, CellData, Scalar, FreeList} <: AbstractPottsState
    grid::Grid
    cell_data::CellData
    N_cells::Scalar
    free_list::FreeList
    free_list_count::Scalar
end
lattice_storage(state::PottsState) = state.grid
function Functors.functor(::Type{<:PottsState}, x)
    children = (grid = x.grid, cell_data = x.cell_data, N_cells = x.N_cells,
        free_list = x.free_list, free_list_count = x.free_list_count)
    reconstruct(y) = Base.typename(typeof(x)).wrapper(
        y.grid, y.cell_data, y.N_cells, y.free_list, y.free_list_count)
    return children, reconstruct
end
function Adapt.adapt_structure(to, x::PottsState)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

function PottsState(grid::AbstractArray{T, N}, cell_data::StructArray,
        N_cells::Union{Integer, AbstractArray} = [Int32(maximum(grid))],
        free_list::AbstractArray = zeros(UInt32, length(cell_data.volumes)),
        free_list_count::AbstractArray = [Int32(0)]) where {T, N}
    @argcheck length(grid) > 0 "Grid cannot be empty"
    required_fields = (:volumes, :target_volumes, :cell_types)
    for field in required_fields
        @argcheck hasproperty(cell_data, field) "cell_data is missing required field: `$field`. Use `build_cell_data`."
    end
    N_cells_arr = N_cells isa Integer ? Int32[N_cells] : N_cells

    return PottsState{
        typeof(grid), typeof(cell_data), typeof(N_cells_arr), typeof(free_list)}(
        grid, cell_data, N_cells_arr, free_list, free_list_count)
end

"""
    AbstractEvent

The base type for native engine events in the Potts simulation. Events derived from
`AbstractEvent` can be integrated directly into the `PottsParameters` and evaluated 
as part of the native sweep loop (Phase 6 of an MCS step), avoiding CPU/GPU synchronization
overheads that arise when using standard SciML `DiscreteCallback`s.

Any custom event should subtype `AbstractEvent` and provide a corresponding method for:
`CorePotts.evaluate_event!(evt, u, p, cache, t, deps)`
which launches the event asynchronously. KernelAbstractions 0.9 orders launches on the backend;
the return value is `nothing` and host observation is handled separately.
"""
abstract type AbstractEvent end

"""
    get_event_kernel(evt::AbstractEvent, backend, block_size)

Returns the compiled `@kernel` function for the given event. Users defining custom events 
must implement this method and return the kernel instance initialized with the `backend` and `block_size`.
"""
function get_event_kernel(evt::AbstractEvent, backend, block_size)
    error("`get_event_kernel` not implemented for custom event $(typeof(evt)). " *
          "Please implement `CorePotts.get_event_kernel(::$(typeof(evt)), backend, block_size)`.")
end

"""
    get_event_args(evt::AbstractEvent, mask, u::AbstractPottsState, p::PottsParameters, cache::PottsCache, t)

Returns a tuple of arguments to be splatted into the event's kernel function. Users defining 
custom events must implement this method. Returning a tuple of exactly what the kernel needs 
prevents massive memory closures and GPU compiler crashes on `Metal.jl`.

Note that `mask` is passed directly. If your kernel requires the `mask` as its first argument, 
you must explicitly include it in the returned tuple, e.g. `return (mask, u.cell_data.volumes)`.

If the event should not run during the current step (e.g. `t % check_interval != 0`), 
return `nothing` to skip kernel execution.
"""
function get_event_args(evt::AbstractEvent, mask, u, p, cache, t)
    error("`get_event_args` not implemented for custom event $(typeof(evt)). " *
          "Please implement `CorePotts.get_event_args(::$(typeof(evt)), mask, u, p, cache, t)`.")
end

"""
    initialize_workspace(evt::AbstractEvent, u::AbstractPottsState, topology::AbstractTopology)

Called exactly once during simulation initialization. By default, returns `evt` unmodified. 
Custom events can override this to allocate dynamic memory workspaces.
"""
initialize_workspace(evt::AbstractEvent, u, topology) = evt

"""
    get_event_ndrange(evt::AbstractEvent, mask, u)

Returns the size of the iteration space for this event's kernel. 
By default, this sweeps over all cells (`length(mask)`).
"""
get_event_ndrange(evt::AbstractEvent, mask, u) = length(mask)

"""
    has_device_trigger(evt::AbstractEvent)

Returns `true` if this event provides a device-side `evaluate_trigger` function 
that should be evaluated in the unified event kernel to generate a boolean mask.
By default, this is `false`.
"""
has_device_trigger(::AbstractEvent) = false

"""
    evaluate_trigger(evt::AbstractEvent, i::Int, cell_data, t)

Evaluates the event trigger for cell `i` on the device. Only called if 
`has_device_trigger(evt)` returns `true`. Should return a `Bool`.
"""
@inline evaluate_trigger(evt::AbstractEvent, i, cell_data, t) = false

"""
    PottsParameters{Topo, P, Tr, Ev}

The physics definition parameters `p` for a Cellular Potts Model simulation.
"""
struct PottsParameters{Topo <: AbstractTopology, P <: Tuple, Tr <: Tuple, Ev <: Tuple}
    topology::Topo
    penalties::P
    trackers::Tr
    events::Ev
    
    function PottsParameters(topology::Topo, penalties::P, trackers::Tr, events::Ev) where {Topo <: AbstractTopology, P <: Tuple, Tr <: Tuple, Ev <: Tuple}
        if any(p -> typeof(p) <: ConnectivityConstraint, penalties) &&
           !(typeof(topology) <: Union{MooreTopology{2}, NoFluxMooreTopology{2}})
            throw(ArgumentError("ConnectivityConstraint is only supported on 2D MooreTopology and NoFluxMooreTopology."))
        end
        new{Topo, P, Tr, Ev}(topology, penalties, trackers, events)
    end
end

function PottsParameters(topology, penalties, trackers)
    return PottsParameters(topology, penalties, trackers, ())
end

function Functors.functor(::Type{<:PottsParameters}, x)
    children = (topology = x.topology, penalties = x.penalties,
        trackers = x.trackers, events = x.events)
    reconstruct(y) = Base.typename(typeof(x)).wrapper(y.topology, y.penalties, y.trackers, y.events)
    return children, reconstruct
end
function Adapt.adapt_structure(to, x::PottsParameters)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

"""
    PottsCache{N}

The algorithmic workspace and cache used during Monte Carlo execution.
"""
struct PottsCache{N, ArrayT, IdxArrayT, EMType}
    grid_dims::NTuple{N, Int}
    step_counter::Vector{UInt64}
    noise_counter::Vector{UInt64}
    block_size::Int
    sin_luts::NTuple{N, ArrayT}
    cos_luts::NTuple{N, ArrayT}
    color_indices::IdxArrayT
    color_offsets::Vector{Int}
    event_masks::EMType
end

function PottsCache(u::AbstractPottsState, topology::AbstractTopology; block_size::Int = 256)
    return PottsCache(u, topology, nothing; block_size=block_size)
end

function PottsCache(u::AbstractPottsState, topology::AbstractTopology, event_masks; block_size::Int = 256)
    grid = lattice_storage(u)
    N = ndims(grid)
    grid_dims = ntuple(i -> size(grid, i), Val(N))
    ArrayT = typeof(similar(grid, Float32, 1))
    IdxArrayT = typeof(similar(grid, UInt32, 1))

    sin_luts = ntuple(Val(N)) do i
        D = grid_dims[i]
        arr = similar(grid, Float32, D)
        arr .= sin.(2.0f0 .* Float32(pi) .* (0:(D - 1)) ./ D)
        return arr
    end
    cos_luts = ntuple(Val(N)) do i
        D = grid_dims[i]
        arr = similar(grid, Float32, D)
        arr .= cos.(2.0f0 .* Float32(pi) .* (0:(D - 1)) ./ D)
        return arr
    end

    # Precompute dense thread packing indices for CheckerboardMetropolis
    num_colors = checkerboard_colors(topology)
    color_lists = [UInt32[] for _ in 1:num_colors]
    for idx in 1:length(grid)
        coords = idx_to_coord(UInt32(idx), grid_dims)
        c = checkerboard_color(topology, coords)
        push!(color_lists[c + 1], UInt32(idx))
    end

    flat_indices = UInt32[]
    color_offsets = zeros(Int, num_colors + 1)
    offset = 1
    for i in 1:num_colors
        color_offsets[i] = offset
        append!(flat_indices, color_lists[i])
        offset += length(color_lists[i])
    end
    color_offsets[end] = offset

    device_indices = Adapt.adapt(Base.typename(typeof(grid)).wrapper, flat_indices)

    return PottsCache{N, ArrayT, IdxArrayT, typeof(event_masks)}(
        grid_dims, [UInt64(0)], [UInt64(0)], block_size,
        sin_luts, cos_luts, device_indices, color_offsets, event_masks)
end

abstract type AbstractPottsProblem <: SciMLBase.AbstractSciMLProblem end
abstract type AbstractPottsAlgorithm <: SciMLBase.AbstractSciMLAlgorithm end

"""
    LegacyPottsProblem{uType, tType, pType} <: AbstractPottsProblem

A SciML-compatible problem definition for a Cellular Potts Model.

# Fields
- `u0`: The initial state (`PottsState`).
- `tspan`: A tuple `(t_start, t_end)` defining the simulation duration in Monte Carlo steps.
- `p`: The simulation parameters (`PottsParameters`).
"""
struct LegacyPottsProblem{uType, tType, pType, KType} <: AbstractPottsProblem
    u0::uType
    tspan::Tuple{tType, tType}
    p::pType
    kwargs::KType
end
function LegacyPottsProblem(u0, tspan, p; kwargs...)
    return LegacyPottsProblem(u0, tspan, p, kwargs)
end
function Functors.functor(::Type{<:LegacyPottsProblem}, x)
    children = (u0 = x.u0, p = x.p)
    reconstruct(y) = Base.typename(typeof(x)).wrapper(y.u0, x.tspan, y.p, x.kwargs)
    return children, reconstruct
end
function Adapt.adapt_structure(to, x::LegacyPottsProblem)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

abstract type AbstractMetropolisStrategy end
struct ParallelStrategy <: AbstractMetropolisStrategy end
struct CheckerboardStrategy <: AbstractMetropolisStrategy end
struct IntrinsicCheckerboardStrategy <: AbstractMetropolisStrategy end
struct SequentialStrategy <: AbstractMetropolisStrategy end

struct MetropolisAlgorithm{Strategy <: AbstractMetropolisStrategy, S <: AbstractSampler, FloatT, IntT} <: AbstractPottsAlgorithm
    sampler::S
    T::FloatT
    active_fraction::FloatT
    sweeps_per_step::IntT
end

function MetropolisAlgorithm{Strategy}(; sampler = MetropolisSampler(), sweeps_per_step = 10,
        active_fraction = 0.1, T = 1.0, FloatType = Float32, IntType = Int32) where Strategy
    return MetropolisAlgorithm{Strategy, typeof(sampler), FloatType, IntType}(
        sampler, FloatType(T), FloatType(active_fraction), IntType(sweeps_per_step))
end

function Base.getproperty(alg::MetropolisAlgorithm{Strategy, S, FloatT, IntT}, sym::Symbol) where {
        Strategy, S, FloatT, IntT}
    if sym === :FloatType
        return FloatT
    elseif sym === :IntType
        return IntT
    else
        return getfield(alg, sym)
    end
end

"""
    ParallelMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

The solver algorithm for `LegacyPottsProblem`s. Specifies how Monte Carlo Sweeps are executed.

# Keyword Arguments
- `sampler`: The sampling strategy (default `MetropolisSampler()`).
- `sweeps_per_step`: How many Monte Carlo Sweeps equal one simulation time unit (default 10).
- `active_fraction`: Fraction of the grid proposed for updates per sweep (default 0.1).
- `T`: The computational temperature regulating membrane fluctuation (default 1.0).
"""
const ParallelMetropolis = MetropolisAlgorithm{ParallelStrategy}

"""
    CheckerboardMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

A deterministic-stochastic checkerboard engine. It calculates the mathematically perfect graph coloring
for the topology to completely remove the random lottery and maximize GPU utilization while remaining mathematically equivalent.
"""
const CheckerboardMetropolis = MetropolisAlgorithm{CheckerboardStrategy}

"""
    IntrinsicCheckerboardMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

The flagship, hardware-accelerated Monte Carlo engine of the Potts.jl ecosystem.

Standard GPU Cellular Potts Models suffer from the Global Volume Paradox: maintaining exact thermodynamics (Detailed Balance) requires perfectly tracking the volume of every cell. Global atomics cause massive memory contention, while removing them breaks the physics.

`IntrinsicCheckerboardMetropolis` solves this paradox by utilizing branchless SIMT Subgroup Reductions via `KernelIntrinsics.jl`. It uses low-level hardware intrinsics (like NVIDIA's PTX `@shfl` and `@match`, or Apple Silicon's `air.simd_ballot`) to instantaneously aggregate volume changes inside the hardware registers of the 32-thread warp. A single elected "Leader" thread then performs an O(1) atomic write to global memory.

### Properties
- **Mathematically Exact:** Perfectly preserves rigorous Detailed Balance.
- **Maximally Parallel:** Completely eliminates global memory locking and atomic contention serialization.
- **Hardware Native:** Compiles directly down to native Metal shading language (Apple) or PTX (NVIDIA) subgroup instructions.

!!! warning "Hardware Requirement"
    Requires a GPU backend that supports subgroup intrinsics (e.g., `MetalBackend` or `CUDABackend`). It will throw a `MethodError` if run on standard CPU threads.
"""
const IntrinsicCheckerboardMetropolis = MetropolisAlgorithm{IntrinsicCheckerboardStrategy}

"""
    SequentialMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

A strictly sequential CPU algorithm that processes sites randomly one-by-one. No parallel contention.
"""
const SequentialMetropolis = MetropolisAlgorithm{SequentialStrategy}

"""
    LegacyPottsIntegrator{uType, pType, tType, algType, cacheType, OptsType}

The active simulation state, holding `u`, `p`, `t`, `alg`, and the `cache`.
Provides SciML-compatible continuous integration for the Potts.
"""
mutable struct LegacyPottsIntegrator{uType, pType, tType, algType, cacheType, OptsType, SolUType, ProbType}
    u::uType
    p::pType
    t::tType
    alg::algType
    cache::cacheType
    opts::OptsType
    sol_u::SolUType
    sol_t::Vector{tType}
    saveat::Vector{tType}
    save_everystep::Bool
    save_start::Bool
    save_end::Bool
    prob::ProbType
end

include("backends.jl")

"""
    LegacyPottsSolution{T, P, A} <: SciMLBase.AbstractTimeseriesSolution

The result of a completed simulation. Contains the saved grid states and cell property states over time.
Accessible like an array: `sol[i]` returns the state at time `sol.t[i]`.
"""
struct LegacyPottsSolution{T, P, A} <: SciMLBase.AbstractTimeseriesSolution{Any, 1, Any}
    u::T
    t::Vector{Int}
    prob::P
    alg::A
    retcode::SciMLBase.ReturnCode.T
end

# Make it behave like an array over time steps
Base.length(sol::LegacyPottsSolution) = length(sol.t)
Base.getindex(sol::LegacyPottsSolution, i::Int) = sol.u[i]
Base.firstindex(sol::LegacyPottsSolution) = 1
Base.lastindex(sol::LegacyPottsSolution) = length(sol.t)

function Base.getproperty(sol::LegacyPottsSolution, sym::Symbol)
    if sym === :interp || sym === :destats || sym === :stats
        return nothing
    elseif sym === :dense
        return false
    else
        return getfield(sol, sym)
    end
end
