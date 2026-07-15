function CorePotts.process_event!(
        evt::ResolvedPropertyUpdateEvent, mask, u, p, cache, t, deps)
    if t % evt.check_interval != 0
        return deps
    end
    backend = KernelAbstractions.get_backend(u.grid)
    all_spatial = CorePotts.extract_spatial_rules(evt.rules)

    spatial_buffer = nothing
    if length(all_spatial) > 0
        spatial_buffer, ev_spatial = CorePotts.populate_spatial_buffer!(
            u, p.topology, cache, all_spatial, deps)
        deps = (ev_spatial,)
    else
        spatial_buffer = haskey(cache.scratch, :spatial_buffer) ?
                         cache.scratch[:spatial_buffer] : nothing
    end

    ctx = (t = t, step_counter = cache.step_counter[], spatial_buffer = spatial_buffer)
    k_prop = CorePotts._kernel_property_update!(backend, cache.block_size)
    nd_prop = Int(Array(u.N_cells)[1])

    if isempty(deps)
        ev_prop = k_prop(
            u.cell_data, evt.rules, u.N_cells, evt.type_id, ctx, ndrange = nd_prop)
    else
        ev_prop = k_prop(u.cell_data, evt.rules, u.N_cells, evt.type_id,
            ctx, ndrange = nd_prop, dependencies = deps)
    end
    return (ev_prop,)
end
