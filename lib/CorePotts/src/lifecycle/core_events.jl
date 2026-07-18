# Trigger API


"""
    VolumeThresholdTrigger(multiplier=2.0)

A callable trigger that evaluates to `true` when a cell's current volume is greater than 
or equal to `multiplier * target_volume`. Used to trigger mitosis.
"""
struct VolumeThresholdTrigger
    multiplier::Float32
end
VolumeThresholdTrigger() = VolumeThresholdTrigger(2.0f0)
required_variables(::VolumeThresholdTrigger) = (volumes = Int32, target_volumes = Int32)

function (trigger::VolumeThresholdTrigger)(cell_id, cell_data, step)
    return cell_data.volumes[cell_id] >=
           (cell_data.target_volumes[cell_id] * trigger.multiplier) &&
           cell_data.target_volumes[cell_id] > 0
end


abstract type DivisionOrientation end
"""
    RandomOrientation <: DivisionOrientation

Cell division occurs along a completely random axis.
"""
struct RandomOrientation <: DivisionOrientation end

"""
    MajorAxisOrientation <: DivisionOrientation

Cell division occurs perpendicular to the cell's major (longest) axis.
"""
struct MajorAxisOrientation <: DivisionOrientation end

"""
    MinorAxisOrientation <: DivisionOrientation

Cell division occurs perpendicular to the cell's minor (shortest) axis.
"""
struct MinorAxisOrientation <: DivisionOrientation end

"""
    VectorOrientation(nx, ny, nz) <: DivisionOrientation

Cell division occurs perpendicular to the specified normal vector.
"""
struct VectorOrientation <: DivisionOrientation
    v::Vector{Float32}
end

struct PropertyUpdateEvent{CT, R, W} <: AbstractEvent
    cell_type::CT
    rules::R
    workspace::W
    function PropertyUpdateEvent(cell_type, rules, workspace=nothing)
        new{typeof(cell_type), typeof(rules), typeof(workspace)}(cell_type, rules, workspace)
    end
end

# Extract spatial rules from NamedTuple of CompiledRules
extract_spatial_rules(rules::NamedTuple) = _extract_spatial(values(rules)...)
@inline _extract_spatial(r1::CompiledRule, rest...) = (
    r1.spatial_rules..., _extract_spatial(rest...)...)
@inline _extract_spatial() = ()

function initialize_workspace(evt::PropertyUpdateEvent, u, topology)
    all_spatial = extract_spatial_rules(evt.rules)
    buf_size = length(all_spatial) * length(u.cell_data.volumes)
    max_edges = length(u.grid) * length(CorePotts.offsets(topology))
    
    ws = if buf_size > 0
        (;
            spatial_buffer = similar(u.grid, UInt32, buf_size),
            edge_list = similar(u.grid, UInt64, max_edges),
            edge_count = similar(u.grid, UInt32, 1)
        )
    else
        nothing
    end
    
    return PropertyUpdateEvent(evt.cell_type, evt.rules, ws)
end

function process_event!(evt::PropertyUpdateEvent, mask, u, p, cache, t, deps)
    backend = KernelAbstractions.get_backend(u.grid)
    all_spatial = extract_spatial_rules(evt.rules)

    spatial_buffer = nothing
    if length(all_spatial) > 0
        spatial_buffer, ev_spatial = populate_spatial_buffer!(
            u, p.topology, cache, evt.workspace, all_spatial, deps)
        deps = (ev_spatial,)
    end

    # 2. Update properties
    ctx = (t = t, step_counter = cache.step_counter[], spatial_buffer = spatial_buffer, spatial_rules = all_spatial)
    k_prop = _kernel_property_update!(backend, cache.block_size)
    nd_prop = length(u.cell_data.volumes)

    # evt.cell_type represents the target cell type id, default 0 means all
    target_type = UInt8(evt.cell_type isa Integer ? evt.cell_type : 0)

    ev_prop = dispatch_kernel!(backend, k_prop, u.cell_data, evt.rules, target_type, ctx;
        ndrange = nd_prop, dependencies = deps)
    return (ev_prop,)
end
