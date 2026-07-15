using CorePotts
using StructArrays

cell_data = StructArray(
    cell_types = UInt32[1, 2, 1],
    volumes = Int32[10, 20, 30],
    target_volumes = Int32[20, 20, 20],
    inhibition_states = UInt8[0, 0, 0],
    anchor_x = Float32[0, 0, 0],
    anchor_y = Float32[0, 0, 0]
)

W, H = 5, 5
grid = zeros(UInt32, W, H)
grid[1:2, 1:2] .= 1
grid[4:5, 4:5] .= 2
grid[3, 3:4] .= 3
grid[3:4, 3] .= 3

u = PottsState(grid, cell_data, 3)
topology = MooreTopology{2}()
cache = PottsCache(u, topology)

sr_1 = CorePotts.NeighborCount(2, 1)
sr_2 = CorePotts.NeighborSum{:volumes}(1, 2)
spatial_rules = (sr_1, sr_2)

CorePotts.populate_spatial_buffer!(u, topology, cache, spatial_rules, nothing)
println("Success in kernel!")
