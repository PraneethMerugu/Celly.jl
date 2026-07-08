using StructArrays
import Adapt
using ArgCheck
import Functors
import Functors: @functor, fmap
@inline function pcg_hash(seed::UInt64)
    state = seed * 0x5851F42D4C957F2D + 0x14057B7EF767814F
    word = xor(state >> ((state >> 59) + UInt64(5)), state) * 0x5851F42D4C957F2D
    return xor(word >> 43, word)
end

@inline function randn_pcg(seed1::UInt64, seed2::UInt64)
    # Modified for Metal compatibility (no Float64 support on Apple Silicon).
    # Extract the upper 32 bits to generate a Float32 in [0, 1).
    u1 = Float32(pcg_hash(seed1) >> 32) * 2.3283064f-10 # multiply by 2^-32
    u2 = Float32(pcg_hash(seed2) >> 32) * 2.3283064f-10
    return sqrt(-2.0f0 * log(max(1.0f-7, u1))) * cos(2.0f0 * Float32(pi) * u2)
end

"""
    FlexibilityTrait
    
Traits indicating whether a physical property or penalty is rigid (type-coupled) or flexible (per-cell and dynamically writable).
"""
abstract type FlexibilityTrait end
struct Rigid <: FlexibilityTrait end
struct Flex <: FlexibilityTrait end

"""
    CPMState{Grid, CellData}

The mutable state vector `u` for a Cellular Potts Model simulation.
Contains the grid, cell properties, and cell ID tracking structures.
"""
abstract type AbstractCPMState end

struct CPMState{Grid, CellData} <: AbstractCPMState
    grid::Grid
    cell_data::CellData
    N_cells::Base.RefValue{Int}
    free_list::Vector{UInt32}
end
function Functors.functor(::Type{<:CPMState}, x)
    children = (grid = x.grid, cell_data = x.cell_data)
    reconstruct(y) = Base.typename(typeof(x)).wrapper(y.grid, y.cell_data, x.N_cells, x.free_list)
    return children, reconstruct
end
function Adapt.adapt_structure(to, x::CPMState)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

function CPMState(grid::AbstractArray{T, N}, cell_data::StructArray,
        N_cells::Int = Int(maximum(grid))) where {T, N}
    @argcheck length(grid) > 0 "Grid cannot be empty"
    required_fields = (:volumes, :target_volumes, :cell_types, :anchor_x, :anchor_y)
    for field in required_fields
        @argcheck hasproperty(cell_data, field) "cell_data is missing required field: `$field`. Use `build_cell_data`."
    end

    return CPMState(grid, cell_data, Ref(N_cells), UInt32[])
end

"""
    CPMParameters{Topo, P, Tr}

The physics definition parameters `p` for a Cellular Potts Model simulation.
"""
struct CPMParameters{Topo <: AbstractTopology, P <: Tuple, Tr <: Tuple}
    topology::Topo
    penalties::P
    trackers::Tr
end
function Functors.functor(::Type{<:CPMParameters}, x)
    children = (topology = x.topology, penalties = x.penalties, trackers = x.trackers)
    reconstruct(y) = Base.typename(typeof(x)).wrapper(y.topology, y.penalties, y.trackers)
    return children, reconstruct
end
function Adapt.adapt_structure(to, x::CPMParameters)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

"""
    CPMCache{N}

The algorithmic workspace and cache used during Monte Carlo execution.
"""
struct CPMCache{N, ArrayT, IdxArrayT}
    grid_dims::NTuple{N, Int}
    step_counter::Base.RefValue{UInt64}
    noise_counter::Base.RefValue{UInt64}
    block_size::Int
    sin_lut_x::ArrayT
    cos_lut_x::ArrayT
    sin_lut_y::ArrayT
    cos_lut_y::ArrayT
    sin_lut_z::ArrayT
    cos_lut_z::ArrayT
    color_indices::IdxArrayT
    color_offsets::Vector{Int}
end

function CPMCache(u::AbstractCPMState, topology::AbstractTopology, block_size::Int = 256)
    grid = u.grid
    N = ndims(grid)
    grid_dims = ntuple(i -> size(grid, i), Val(N))
    ArrayT = typeof(similar(grid, Float32, 1))
    IdxArrayT = typeof(similar(grid, UInt32, 1))

    W = grid_dims[1]
    sin_lut_x = similar(grid, Float32, W)
    cos_lut_x = similar(grid, Float32, W)
    sin_lut_x .= sin.(2.0f0 .* Float32(pi) .* (0:(W - 1)) ./ W)
    cos_lut_x .= cos.(2.0f0 .* Float32(pi) .* (0:(W - 1)) ./ W)

    H = grid_dims[2]
    sin_lut_y = similar(grid, Float32, H)
    cos_lut_y = similar(grid, Float32, H)
    sin_lut_y .= sin.(2.0f0 .* Float32(pi) .* (0:(H - 1)) ./ H)
    cos_lut_y .= cos.(2.0f0 .* Float32(pi) .* (0:(H - 1)) ./ H)

    if N == 3
        D = grid_dims[3]
        sin_lut_z = similar(grid, Float32, D)
        cos_lut_z = similar(grid, Float32, D)
        sin_lut_z .= sin.(2.0f0 .* Float32(pi) .* (0:(D - 1)) ./ D)
        cos_lut_z .= cos.(2.0f0 .* Float32(pi) .* (0:(D - 1)) ./ D)
    else
        sin_lut_z = similar(grid, Float32, 0)
        cos_lut_z = similar(grid, Float32, 0)
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

    return CPMCache{N, ArrayT, IdxArrayT}(
        grid_dims, Ref(UInt64(0)), Ref(UInt64(0)), block_size,
        sin_lut_x, cos_lut_x, sin_lut_y, cos_lut_y, sin_lut_z,
        cos_lut_z, device_indices, color_offsets)
end

abstract type AbstractCPMProblem <: SciMLBase.AbstractSciMLProblem end
abstract type AbstractCPMAlgorithm <: SciMLBase.AbstractSciMLAlgorithm end

"""
    CPMProblem{uType, tType, pType} <: AbstractCPMProblem

A SciML-compatible problem definition for a Cellular Potts Model.

# Fields
- `u0`: The initial state (`CPMState`).
- `tspan`: A tuple `(t_start, t_end)` defining the simulation duration in Monte Carlo steps.
- `p`: The simulation parameters (`CPMParameters`).
"""
struct CPMProblem{uType, tType, pType} <: AbstractCPMProblem
    u0::uType
    tspan::Tuple{tType, tType}
    p::pType
end
function Functors.functor(::Type{<:CPMProblem}, x)
    children = (u0 = x.u0, p = x.p)
    reconstruct(y) = Base.typename(typeof(x)).wrapper(y.u0, x.tspan, y.p)
    return children, reconstruct
end
function Adapt.adapt_structure(to, x::CPMProblem)
    children, reconstruct = Functors.functor(typeof(x), x)
    return reconstruct(Adapt.adapt(to, children))
end

"""
    ParallelMetropolis{S <: AbstractSampler, FloatT, IntT} <: AbstractCPMAlgorithm

The solver algorithm for `CPMProblem`s. Specifies how Monte Carlo Sweeps are executed.

# Keyword Arguments
- `sampler`: The sampling strategy (default `MetropolisSampler()`).
- `sweeps_per_step`: How many Monte Carlo Sweeps equal one simulation time unit (default 10).
- `active_fraction`: Fraction of the grid proposed for updates per sweep (default 0.1).
- `T`: The computational temperature regulating membrane fluctuation (default 1.0).
"""
struct ParallelMetropolis{S <: AbstractSampler, FloatT, IntT} <: AbstractCPMAlgorithm
    sampler::S
    T::FloatT
    active_fraction::FloatT
    sweeps_per_step::IntT
end
function ParallelMetropolis(; sampler = MetropolisSampler(), sweeps_per_step = 10,
        active_fraction = 0.1, T = 1.0, FloatType = Float32, IntType = Int32)
    return ParallelMetropolis{typeof(sampler), FloatType, IntType}(
        sampler, FloatType(T), FloatType(active_fraction), IntType(sweeps_per_step))
end

function Base.getproperty(alg::ParallelMetropolis{S, FloatT, IntT}, sym::Symbol) where {
        S, FloatT, IntT}
    if sym === :FloatType
        return FloatT
    elseif sym === :IntType
        return IntT
    else
        return getfield(alg, sym)
    end
end

"""
    CheckerboardMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

A deterministic-stochastic checkerboard engine. It calculates the mathematically perfect graph coloring
for the topology to completely remove the random lottery and maximize GPU utilization while remaining mathematically equivalent.
"""
struct CheckerboardMetropolis{S <: AbstractSampler, FloatT, IntT} <: AbstractCPMAlgorithm
    sampler::S
    T::FloatT
    active_fraction::FloatT
    sweeps_per_step::IntT
end
function CheckerboardMetropolis(; sampler = MetropolisSampler(), sweeps_per_step = 10,
        active_fraction = 0.1, T = 1.0, FloatType = Float32, IntType = Int32)
    return CheckerboardMetropolis{typeof(sampler), FloatType, IntType}(
        sampler, FloatType(T), FloatType(active_fraction), IntType(sweeps_per_step))
end

function Base.getproperty(
        alg::CheckerboardMetropolis{
            S, FloatT, IntT}, sym::Symbol) where {S, FloatT, IntT}
    if sym === :FloatType
        return FloatT
    elseif sym === :IntType
        return IntT
    else
        return getfield(alg, sym)
    end
end

"""
    SparseLotteryMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

A sparse block-based stochastic engine. Used as a fallback for extended topologies where graph coloring fails.
"""
struct SparseLotteryMetropolis{S <: AbstractSampler, FloatT, IntT} <: AbstractCPMAlgorithm
    sampler::S
    T::FloatT
    active_fraction::FloatT
    sweeps_per_step::IntT
end
function SparseLotteryMetropolis(; sampler = MetropolisSampler(), sweeps_per_step = 10,
        active_fraction = 0.1, T = 1.0, FloatType = Float32, IntType = Int32)
    return SparseLotteryMetropolis{typeof(sampler), FloatType, IntType}(
        sampler, FloatType(T), FloatType(active_fraction), IntType(sweeps_per_step))
end

function Base.getproperty(
        alg::SparseLotteryMetropolis{
            S, FloatT, IntT}, sym::Symbol) where {S, FloatT, IntT}
    if sym === :FloatType
        return FloatT
    elseif sym === :IntType
        return IntT
    else
        return getfield(alg, sym)
    end
end

"""
    SequentialMetropolis(; sampler=MetropolisSampler(), sweeps_per_step=10, active_fraction=0.1f0, T=1.0f0)

A strictly sequential CPU algorithm that processes sites randomly one-by-one. No parallel contention.
"""
struct SequentialMetropolis{S <: AbstractSampler, FloatT, IntT} <: AbstractCPMAlgorithm
    sampler::S
    T::FloatT
    active_fraction::FloatT
    sweeps_per_step::IntT
end
function SequentialMetropolis(; sampler = MetropolisSampler(), sweeps_per_step = 10,
        active_fraction = 0.1, T = 1.0, FloatType = Float32, IntType = Int32)
    return SequentialMetropolis{typeof(sampler), FloatType, IntType}(
        sampler, FloatType(T), FloatType(active_fraction), IntType(sweeps_per_step))
end

function Base.getproperty(
        alg::SequentialMetropolis{
            S, FloatT, IntT}, sym::Symbol) where {S, FloatT, IntT}
    if sym === :FloatType
        return FloatT
    elseif sym === :IntType
        return IntT
    else
        return getfield(alg, sym)
    end
end

"""
    CPMIntegrator{uType, pType, tType, algType, cacheType, OptsType}

The active simulation state, holding `u`, `p`, `t`, `alg`, and the `cache`.
Provides SciML-compatible continuous integration for the CPM.
"""
mutable struct CPMIntegrator{uType, pType, tType, algType, cacheType, OptsType, SolUType}
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
end

include("backends.jl")

"""
    CPMSolution{T, P, A} <: SciMLBase.AbstractTimeseriesSolution

The result of a completed simulation. Contains the saved grid states and cell property states over time.
Accessible like an array: `sol[i]` returns the state at time `sol.t[i]`.
"""
struct CPMSolution{T, P, A} <: SciMLBase.AbstractTimeseriesSolution{Any, Any, Any}
    u::T
    t::Vector{Int}
    prob::P
    alg::A
    retcode::SciMLBase.ReturnCode.T
end

# Make it behave like an array over time steps
Base.length(sol::CPMSolution) = length(sol.t)
Base.getindex(sol::CPMSolution, i::Int) = sol.u[i]
Base.firstindex(sol::CPMSolution) = 1
Base.lastindex(sol::CPMSolution) = length(sol.t)

function Base.getproperty(sol::CPMSolution, sym::Symbol)
    if sym === :interp || sym === :destats || sym === :stats
        return nothing
    elseif sym === :dense
        return false
    else
        return getfield(sol, sym)
    end
end
