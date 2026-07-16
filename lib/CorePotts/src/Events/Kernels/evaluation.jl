struct UpdateContext{T, G, Top, S, R}
    t::T
    grid::G
    topology::Top
    step_counter::UInt32
    spatial_buffer::S
    spatial_rules::R
end

UpdateContext(t, grid, topology, step_counter, spatial_buffer) = UpdateContext(t, grid, topology, step_counter, spatial_buffer, ())

@inline function evaluate_update_rule(
        rule::CompiledRule, cell_data, cell_id, ctx, ::Val{P}) where {P}
    current_val = getproperty(cell_data, P)[cell_id]
    return rule.func(cell_data, cell_id, ctx, current_val)
end

# GPU Random Number Generation helper for native closures
@inline function gpu_rand_uniform(cell_id, step_counter, offset, min_val, max_val)
    seed = UInt64(cell_id) * 0x853c49e6748fea9b +
           UInt64(step_counter) * 0xda3e39cb94b95bdb + UInt64(offset)
    u = Float32(pcg_hash(seed) >> 32) * UINT32_TO_FLOAT32
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

@inline function gpu_rand_poisson(cell_id, step_counter, offset, lambda)
    if lambda >= 15.0f0
        val = gpu_rand_normal(cell_id, step_counter, offset, lambda, sqrt(lambda))
        return round(max(0.0f0, val))
    else
        L = exp(-lambda)
        k = 0.0f0
        p = 1.0f0
        current_offset = offset
        while true
            u = gpu_rand_uniform(cell_id, step_counter, current_offset, 0.0f0, 1.0f0)
            p *= u
            current_offset += 1
            if p <= L || current_offset > offset + 1000
                break
            end
            k += 1.0f0
        end
        return k
    end
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
@inline _find_buffer_idx_impl(::Tuple{}, ::Type{RuleT}, type_id, prop) where {RuleT} = 0
@inline function _find_buffer_idx_impl(rules::Tuple, ::Type{RuleT}, type_id, prop) where {RuleT}
    rule = rules[1]
    if rule isa RuleT && rule.type_id == type_id
        if prop === nothing
            return rule.buffer_index
        elseif rule isa NeighborSum && rule.prop == prop
            return rule.buffer_index
        end
    end
    return _find_buffer_idx_impl(Base.tail(rules), RuleT, type_id, prop)
end

@inline function _extract_from_buffer(cell_data, cell_id, ctx, ::Type{RuleT}, type_id, prop=nothing) where {RuleT}
    idx = _find_buffer_idx_impl(ctx.spatial_rules, RuleT, type_id, prop)
    idx == 0 && return 0.0f0 # Fallback if rule not found
    buf_idx = (idx - 1) * length(cell_data.volumes) + cell_id
    return ctx.spatial_buffer[buf_idx]
end

@inline get_contact_area(cell_data, cell_id, ctx, type_id) = _extract_from_buffer(cell_data, cell_id, ctx, ContactArea, type_id)
@inline get_neighbor_count(cell_data, cell_id, ctx, type_id) = _extract_from_buffer(cell_data, cell_id, ctx, NeighborCount, type_id)
@inline get_neighbor_sum(cell_data, cell_id, ctx, prop::Symbol, type_id) = _extract_from_buffer(cell_data, cell_id, ctx, NeighborSum, type_id, prop)

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
