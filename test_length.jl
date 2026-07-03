using CoreCPM
using CPMToolkit
using MakieCPM
using StructArrays

struct PeriodicXNoFluxYTopology{N} <: CoreCPM.AbstractTopology{N} end
CoreCPM.offsets(::PeriodicXNoFluxYTopology{2}) = ((1, 0), (0, 1), (-1, 0), (0, -1))
CoreCPM.lottery_offsets(::PeriodicXNoFluxYTopology{2}) = CoreCPM.offsets(PeriodicXNoFluxYTopology{2}())
CoreCPM.num_dirs(::PeriodicXNoFluxYTopology{2}) = Val(4)
CoreCPM.checkerboard_colors(::PeriodicXNoFluxYTopology{2}) = 2
CoreCPM.checkerboard_color(::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32}) = UInt32((coords[1] + coords[2]) % 2)

@inline function CoreCPM.get_lottery_neighbor_idx(topo::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32}, dir::Int, dims::NTuple{2, Int})
    offs = CoreCPM.lottery_offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CoreCPM.coord_to_idx((new_x, new_y), dims)
end

@inline function CoreCPM.get_neighbor_by_coord(topo::PeriodicXNoFluxYTopology{2}, coords::NTuple{2, UInt32}, dir::UInt32, dims::NTuple{2, Int})
    offs = CoreCPM.offsets(topo)[dir]
    new_x = UInt32((Int32(coords[1]) + Int32(dims[1]) + Int32(offs[1])) % Int32(dims[1]))
    new_y = UInt32(clamp(Int32(coords[2]) + Int32(offs[2]), 0, Int32(dims[2]) - 1))
    return CoreCPM.coord_to_idx((new_x, new_y), dims)
end

Medium = CellType(:Medium)
Leader = CellType(:Leader)
Follower = CellType(:Follower)

sys = CPMSystem(
    [Medium, Leader, Follower],
    (
        HSTVolumeComponent(Medium => (target=0, λ=0), Leader => (target=10, λ=5.0), Follower => (target=10, λ=5.0), eta=0.1),
        AdhesionComponent((Medium, Medium) => 0.0, (Medium, Leader) => 10.0, (Medium, Follower) => 15.0, (Leader, Leader) => 5.0, (Leader, Follower) => 5.0, (Follower, Follower) => 5.0)
    )
)

prob = CPMProblem(
    sys, Dict(Leader => 1, Follower => 1), (10, 10);
    tspan = (0, 1000),
    topology = PeriodicXNoFluxYTopology{2}(),
    max_cells = 5000
)

println("Original CellData Length: ", length(prob.u0.cell_data))
