# Trigger API
required_fields(trigger) = ()

"""
    VolumeThresholdTrigger(multiplier=2.0)

A callable trigger that evaluates to `true` when a cell's current volume is greater than 
or equal to `multiplier * target_volume`. Used to trigger mitosis.
"""
struct VolumeThresholdTrigger
    multiplier::Float32
end
VolumeThresholdTrigger() = VolumeThresholdTrigger(2.0f0)
required_fields(::VolumeThresholdTrigger) = (:volumes, :target_volumes)

function (trigger::VolumeThresholdTrigger)(cell_id, cell_data)
    return cell_data.volumes[cell_id] >=
           (cell_data.target_volumes[cell_id] * trigger.multiplier) &&
           cell_data.target_volumes[cell_id] > 0
end

"""
    LinearGrowthCallback(rate)

A SciML-compatible discrete callback that stochastically grows each cell's `target_volume`.
Each MCS, every live cell's target volume increases by 1 with probability `rate` ∈ [0, 1].
For a deterministic fixed increment use `rate = 1.0`.
"""
struct LinearGrowthCallback
    rate::Float32
end

function (growth::LinearGrowthCallback)(integrator)
    targets = Array(integrator.u.cell_data.target_volumes)
    N = Int(Array(integrator.u.N_cells)[])
    for i in 1:N
        if targets[i] > 0
            if rand() < growth.rate
                targets[i] += 1
            end
        end
    end
    copyto!(integrator.u.cell_data.target_volumes, targets)
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

struct PropertyUpdateEvent{CT, R} <: AbstractEvent
    cell_type::CT
    rules::R
    function PropertyUpdateEvent(cell_type, rules)
        new{typeof(cell_type), typeof(rules)}(cell_type, rules)
    end
end

# Extract spatial rules from NamedTuple of CompiledRules
extract_spatial_rules(rules::NamedTuple) = _extract_spatial(values(rules)...)
@inline _extract_spatial(r1::CompiledRule, rest...) = (
    r1.spatial_rules..., _extract_spatial(rest...)...)
@inline _extract_spatial() = ()

function process_event!(evt::PropertyUpdateEvent, mask, u, p, cache, t, deps)
    backend = KernelAbstractions.get_backend(u.grid)
    all_spatial = extract_spatial_rules(evt.rules)

    spatial_buffer = nothing
    if length(all_spatial) > 0
        spatial_buffer, ev_spatial = populate_spatial_buffer!(
            u, p.topology, cache, all_spatial, deps)
        deps = (ev_spatial,)
    end

    # 2. Update properties
    ctx = (t = t, step_counter = cache.step_counter[], spatial_buffer = spatial_buffer)
    k_prop = _kernel_property_update!(backend, cache.block_size)
    nd_prop = Int(Array(u.N_cells)[1])

    # evt.cell_type represents the target cell type id, default 0 means all
    target_type = UInt8(evt.cell_type isa Integer ? evt.cell_type : 0)

    ev_prop = dispatch_kernel!(k_prop, u.cell_data, evt.rules, u.N_cells, target_type, ctx;
        ndrange = nd_prop, dependencies = deps)
    return (ev_prop,)
end
abstract type AbstractMultiEvent <: AbstractEvent end
function get_sub_events end
