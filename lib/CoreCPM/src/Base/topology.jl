abstract type AbstractTopology{N} end

"""
    VonNeumannTopology{N}

A standard periodic N-dimensional Von Neumann neighborhood (4-connected in 2D, 6-connected in 3D).
"""
struct VonNeumannTopology{N} <: AbstractTopology{N} end

"""
    MooreTopology{N}

A standard periodic N-dimensional Moore neighborhood (8-connected in 2D, 26-connected in 3D).
"""
struct MooreTopology{N} <: AbstractTopology{N} end

"""
    NoFluxVonNeumannTopology{N}

An N-dimensional Von Neumann neighborhood with rigid, non-periodic (no-flux) boundaries.
"""
struct NoFluxVonNeumannTopology{N} <: AbstractTopology{N} end

"""
    NoFluxMooreTopology{N}

An N-dimensional Moore neighborhood with rigid, non-periodic (no-flux) boundaries.
"""
struct NoFluxMooreTopology{N} <: AbstractTopology{N} end

"""
    ExtendedVonNeumannTopology{N, R}

An extended periodic N-dimensional Von Neumann neighborhood of radius `R`.
"""
struct ExtendedVonNeumannTopology{N, R} <: AbstractTopology{N} end

"""
    ExtendedMooreTopology{N, R}

An extended periodic N-dimensional Moore neighborhood of radius `R`.
"""
struct ExtendedMooreTopology{N, R} <: AbstractTopology{N} end

"""
    NoFluxExtendedVonNeumannTopology{N, R}

An extended N-dimensional Von Neumann neighborhood of radius `R` with no-flux boundaries.
"""
struct NoFluxExtendedVonNeumannTopology{N, R} <: AbstractTopology{N} end

"""
    NoFluxExtendedMooreTopology{N, R}

An extended N-dimensional Moore neighborhood of radius `R` with no-flux boundaries.
"""
struct NoFluxExtendedMooreTopology{N, R} <: AbstractTopology{N} end

is_noflux(::AbstractTopology) = false
is_noflux(::NoFluxVonNeumannTopology) = true
is_noflux(::NoFluxMooreTopology) = true
is_noflux(::NoFluxExtendedVonNeumannTopology) = true
is_noflux(::NoFluxExtendedMooreTopology) = true

@inline shortest_vector(::AbstractTopology, dx::Float32, dim_size::Float32) = dx - dim_size * round(dx / dim_size)
@inline shortest_vector(::NoFluxVonNeumannTopology, dx::Float32, dim_size::Float32) = dx
@inline shortest_vector(::NoFluxMooreTopology, dx::Float32, dim_size::Float32) = dx
@inline shortest_vector(::NoFluxExtendedVonNeumannTopology, dx::Float32, dim_size::Float32) = dx
@inline shortest_vector(::NoFluxExtendedMooreTopology, dx::Float32, dim_size::Float32) = dx

# Number of directions
num_dirs(::VonNeumannTopology{2}) = Val(4)
num_dirs(::VonNeumannTopology{3}) = Val(6)
num_dirs(::MooreTopology{2})      = Val(8)
num_dirs(::MooreTopology{3})      = Val(26)

num_dirs(::NoFluxVonNeumannTopology{N}) where N = num_dirs(VonNeumannTopology{N}())
num_dirs(::NoFluxMooreTopology{N}) where N      = num_dirs(MooreTopology{N}())

@inline get_val(::Val{N}) where {N} = UInt32(N)

offsets(::VonNeumannTopology{2}) = ((1, 0), (0, 1), (-1, 0), (0, -1))
offsets(::MooreTopology{2})      = ((1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1))

offsets(::VonNeumannTopology{3}) = ((1,0,0), (0,1,0), (0,0,1), (-1,0,0), (0,-1,0), (0,0,-1))
offsets(::MooreTopology{3})      = (
    (1,0,0), (0,1,0), (0,0,1), (-1,0,0), (0,-1,0), (0,0,-1),
    (1,1,0), (1,-1,0), (-1,1,0), (-1,-1,0),
    (1,0,1), (1,0,-1), (-1,0,1), (-1,0,-1),
    (0,1,1), (0,1,-1), (0,-1,1), (0,-1,-1),
    (1,1,1), (1,1,-1), (1,-1,1), (1,-1,-1),
    (-1,1,1), (-1,1,-1), (-1,-1,1), (-1,-1,-1)
)
offsets(::NoFluxVonNeumannTopology{N}) where N = offsets(VonNeumannTopology{N}())
offsets(::NoFluxMooreTopology{N}) where N      = offsets(MooreTopology{N}())

@generated function offsets(::ExtendedVonNeumannTopology{N, R}) where {N, R}
    offs = []
    if N == 2
        for r in 1:R
            push!(offs, (r, 0)); push!(offs, (0, r)); push!(offs, (-r, 0)); push!(offs, (0, -r))
        end
    elseif N == 3
        for r in 1:R
            push!(offs, (r, 0, 0)); push!(offs, (0, r, 0)); push!(offs, (0, 0, r))
            push!(offs, (-r, 0, 0)); push!(offs, (0, -r, 0)); push!(offs, (0, 0, -r))
        end
    end
    return Tuple(offs)
end

@generated function offsets(::ExtendedMooreTopology{N, R}) where {N, R}
    offs = []
    if N == 2
        for dx in -R:R
            for dy in -R:R
                if dx == 0 && dy == 0; continue; end
                push!(offs, (dx, dy))
            end
        end
    elseif N == 3
        for dx in -R:R
            for dy in -R:R
                for dz in -R:R
                    if dx == 0 && dy == 0 && dz == 0; continue; end
                    push!(offs, (dx, dy, dz))
                end
            end
        end
    end
    return Tuple(offs)
end

offsets(::NoFluxExtendedVonNeumannTopology{N, R}) where {N, R} = offsets(ExtendedVonNeumannTopology{N, R}())
offsets(::NoFluxExtendedMooreTopology{N, R}) where {N, R} = offsets(ExtendedMooreTopology{N, R}())

num_dirs(topo::ExtendedVonNeumannTopology) = Val(length(offsets(topo)))
num_dirs(topo::ExtendedMooreTopology) = Val(length(offsets(topo)))
num_dirs(topo::NoFluxExtendedVonNeumannTopology) = Val(length(offsets(topo)))
num_dirs(topo::NoFluxExtendedMooreTopology) = Val(length(offsets(topo)))

# Lottery validation always uses the Moore neighborhood to guarantee independent sets
@inline lottery_offsets(::AbstractTopology{2}) = offsets(MooreTopology{2}())
@inline lottery_offsets(::AbstractTopology{3}) = offsets(MooreTopology{3}())

@inline lottery_offsets(::ExtendedVonNeumannTopology{2, R}) where R = offsets(ExtendedMooreTopology{2, R}())
@inline lottery_offsets(::ExtendedVonNeumannTopology{3, R}) where R = offsets(ExtendedMooreTopology{3, R}())
@inline lottery_offsets(::ExtendedMooreTopology{2, R}) where R = offsets(ExtendedMooreTopology{2, R}())
@inline lottery_offsets(::ExtendedMooreTopology{3, R}) where R = offsets(ExtendedMooreTopology{3, R}())

@inline lottery_offsets(::NoFluxExtendedVonNeumannTopology{2, R}) where R = offsets(ExtendedMooreTopology{2, R}())
@inline lottery_offsets(::NoFluxExtendedVonNeumannTopology{3, R}) where R = offsets(ExtendedMooreTopology{3, R}())
@inline lottery_offsets(::NoFluxExtendedMooreTopology{2, R}) where R = offsets(ExtendedMooreTopology{2, R}())
@inline lottery_offsets(::NoFluxExtendedMooreTopology{3, R}) where R = offsets(ExtendedMooreTopology{3, R}())

# Euclidean distance weights for topologies
@inline neighbor_weights(topo::AbstractTopology) = map(x -> 1.0f0 / sqrt(Float32(sum(y -> y^2, x))), offsets(topo))

# Branchless math for 1D <-> ND coordinates
@inline function idx_to_coord(idx::UInt32, dims::NTuple{2, Int})
    idx0 = idx - UInt32(1)
    W = UInt32(dims[1])
    return (idx0 % W, idx0 ÷ W)
end

@inline function idx_to_coord(idx::UInt32, dims::NTuple{3, Int})
    idx0 = idx - UInt32(1)
    W = UInt32(dims[1])
    H = UInt32(dims[2])
    stride = W * H
    z = idx0 ÷ stride
    rem = idx0 % stride
    return (rem % W, rem ÷ W, z)
end

@inline function coord_to_idx(coords::NTuple{2, UInt32}, dims::NTuple{2, Int})
    return coords[1] + coords[2] * UInt32(dims[1]) + UInt32(1)
end

@inline function coord_to_idx(coords::NTuple{3, UInt32}, dims::NTuple{3, Int})
    return coords[1] + coords[2] * UInt32(dims[1]) + coords[3] * UInt32(dims[1]) * UInt32(dims[2]) + UInt32(1)
end

@inline function get_neighbor_by_dir(topo::AbstractTopology{N}, idx::UInt32, dir::UInt32, dims::NTuple{N, Int}) where N
    coords = idx_to_coord(idx, dims)
    offs = offsets(topo)[dir]
    
    new_coords = ntuple(Val(N)) do i
        Base.@_inline_meta
        c = Int32(coords[i])
        d = Int32(dims[i])
        dx = Int32(offs[i])
        if is_noflux(topo)
            UInt32(clamp(c + dx, 0, d - 1))
        else
            c_new = c + dx
            c_new = c_new < 0 ? c_new + d : (c_new >= d ? c_new - d : c_new)
            UInt32(c_new)
        end
    end
    
    return coord_to_idx(new_coords, dims)
end

@inline function get_neighbor_by_coord(topo::AbstractTopology{N}, coords::NTuple{N, UInt32}, dir::UInt32, dims::NTuple{N, Int}) where N
    offs = offsets(topo)[dir]
    new_coords = ntuple(Val(N)) do i
        Base.@_inline_meta
        c = Int32(coords[i])
        d = Int32(dims[i])
        dx = Int32(offs[i])
        if is_noflux(topo)
            UInt32(clamp(c + dx, 0, d - 1))
        else
            c_new = c + dx
            c_new = c_new < 0 ? c_new + d : (c_new >= d ? c_new - d : c_new)
            UInt32(c_new)
        end
    end
    return coord_to_idx(new_coords, dims)
end

# Graph coloring for Checkerboard algorithms
checkerboard_colors(::VonNeumannTopology) = UInt32(2)
checkerboard_colors(::MooreTopology{2}) = UInt32(4)
checkerboard_colors(::MooreTopology{3}) = UInt32(8)
checkerboard_colors(::ExtendedVonNeumannTopology{1, R}) where R = UInt32(R + 1)
checkerboard_colors(::ExtendedVonNeumannTopology{2, R}) where R = UInt32(((R + 1)^2 + 1) ÷ 2)
checkerboard_colors(::ExtendedVonNeumannTopology{N, R}) where {N, R} = checkerboard_colors(ExtendedMooreTopology{N, R}())
checkerboard_colors(::ExtendedMooreTopology{N, R}) where {N, R} = UInt32((R + 1)^N)

checkerboard_colors(::NoFluxVonNeumannTopology{N}) where N = checkerboard_colors(VonNeumannTopology{N}())
checkerboard_colors(::NoFluxMooreTopology{N}) where N = checkerboard_colors(MooreTopology{N}())
checkerboard_colors(::NoFluxExtendedVonNeumannTopology{N, R}) where {N, R} = checkerboard_colors(ExtendedVonNeumannTopology{N, R}())
checkerboard_colors(::NoFluxExtendedMooreTopology{N, R}) where {N, R} = checkerboard_colors(ExtendedMooreTopology{N, R}())

@inline checkerboard_color(::VonNeumannTopology, coords::NTuple) = UInt32(sum(coords) % 2)
@inline checkerboard_color(::MooreTopology{2}, coords::NTuple{2, UInt32}) = (coords[1] % UInt32(2)) + UInt32(2) * (coords[2] % UInt32(2))
@inline checkerboard_color(::MooreTopology{3}, coords::NTuple{3, UInt32}) = (coords[1] % UInt32(2)) + UInt32(2) * (coords[2] % UInt32(2)) + UInt32(4) * (coords[3] % UInt32(2))

@inline checkerboard_color(::ExtendedVonNeumannTopology{1, R}, coords::NTuple{1, UInt32}) where R = UInt32(coords[1] % (R + 1))
@inline function checkerboard_color(::ExtendedVonNeumannTopology{2, R}, coords::NTuple{2, UInt32}) where R
    C = UInt32(((R + 1)^2 + 1) ÷ 2)
    stride = UInt32(2 * (R ÷ 2) + 1)
    return UInt32((coords[1] + stride * coords[2]) % C)
end
@inline checkerboard_color(::ExtendedVonNeumannTopology{N, R}, coords::NTuple{N, UInt32}) where {N, R} = checkerboard_color(ExtendedMooreTopology{N, R}(), coords)

@inline function checkerboard_color(::ExtendedMooreTopology{N, R}, coords::NTuple{N, UInt32}) where {N, R}
    c = UInt32(0)
    stride = UInt32(1)
    base = UInt32(R + 1)
    for d in 1:N
        Base.@_inline_meta
        c += (coords[d] % base) * stride
        stride *= base
    end
    return c
end

@inline checkerboard_color(::NoFluxVonNeumannTopology{N}, coords) where N = checkerboard_color(VonNeumannTopology{N}(), coords)
@inline checkerboard_color(::NoFluxMooreTopology{N}, coords) where N = checkerboard_color(MooreTopology{N}(), coords)
@inline checkerboard_color(::NoFluxExtendedVonNeumannTopology{N, R}, coords) where {N, R} = checkerboard_color(ExtendedVonNeumannTopology{N, R}(), coords)
@inline checkerboard_color(::NoFluxExtendedMooreTopology{N, R}, coords) where {N, R} = checkerboard_color(ExtendedMooreTopology{N, R}(), coords)
