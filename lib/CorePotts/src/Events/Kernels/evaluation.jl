struct UpdateContext{T, G, Top, S}
    t::T
    grid::G
    topology::Top
    step_counter::UInt32
    spatial_buffer::S
end

@inline function evaluate_update_rule(
        rule::CompiledRule, cell_data, cell_id, ctx, ::Val{P}) where {P}
    current_val = getproperty(cell_data, P)[cell_id]
    return rule.func(cell_data, cell_id, ctx, current_val)
end

# GPU Random Number Generation helper for native closures
@inline function gpu_rand_uniform(cell_id, step_counter, offset, min_val, max_val)
    seed = UInt64(cell_id) * 0x853c49e6748fea9b +
           UInt64(step_counter) * 0xda3e39cb94b95bdb + UInt64(offset)
    u = Float32(pcg_hash(seed) >> 32) * 2.3283064f-10
    return min_val + u * (max_val - min_val)
end

@inline function gpu_rand_normal(cell_id, step_counter, offset, mean_val, std_val)
    seed1 = UInt64(cell_id) * 0x853c49e6748fea9b +
            UInt64(step_counter) * 0xda3e39cb94b95bdb + UInt64(offset)
    seed2 = UInt64(cell_id) * 0x853c49e6748fea9b +
            UInt64(step_counter) * 0xda3e39cb94b95bdb + UInt64(offset + 1)
    z0 = randn_pcg(seed1, seed2)
    return mean_val + z0 * std_val
end

# Spatial Helpers for native closures
@inline get_center_of_mass_x(cell_data, cell_id, ctx) = cell_data.anchor_x[cell_id]
@inline get_center_of_mass_y(cell_data, cell_id, ctx) = cell_data.anchor_y[cell_id]
@inline get_center_of_mass_z(cell_data, cell_id, ctx) = hasproperty(cell_data, :anchor_z) ?
                                                        cell_data.anchor_z[cell_id] : 0.0f0

@inline get_major_axis_length(cell_data, cell_id, ctx) = cell_data.current_lengths[cell_id]
@inline function get_minor_axis_length(cell_data, cell_id, ctx)
    V = Float32(cell_data.volumes[cell_id])
    L = cell_data.current_lengths[cell_id]
    return L > 0 ? (V / L) : 0.0f0
end

@inline get_time(ctx) = ctx.t
@inline get_contact_area(cell_data, cell_id, ctx, type_id) = 0 # Placeholder for spatial API
@inline get_neighbor_count(cell_data, cell_id, ctx, type_id) = 0 # Placeholder for spatial API
@inline get_neighbor_sum(cell_data, cell_id, ctx, prop, type_id) = 0 # Placeholder for spatial API

struct TargetRule{P, R}
    rule::R
end

@inline wrap_rules(rules::NamedTuple{names}) where {names} = _wrap_rules(rules, names...)
@inline _wrap_rules(rules) = ()
@inline _wrap_rules(rules, p1, rest...) = (
    TargetRule{p1, typeof(getproperty(rules, p1))}(getproperty(rules, p1)),
    _wrap_rules(rules, rest...)...)

@inline function evaluate_and_assign_rules!(cell_data, cell_id, ctx, rules::NamedTuple)
    evaluate_and_assign_rules!(cell_data, cell_id, ctx, wrap_rules(rules))
end

@inline function evaluate_and_assign_rules!(cell_data, cell_id, ctx, rules::Tuple)
    _eval_rules(cell_data, cell_id, ctx, rules...)
end

@inline _eval_rules(cell_data, cell_id, ctx) = nothing

@inline function _eval_rules(cell_data, cell_id, ctx, r1::TargetRule{P}, rest...) where {P}
    val = evaluate_update_rule(r1.rule, cell_data, cell_id, ctx, Val{P}())
    if val !== nothing
        getproperty(cell_data, P)[cell_id] = safe_convert(eltype(getproperty(cell_data, P)), val)
    end
    _eval_rules(cell_data, cell_id, ctx, rest...)
end
