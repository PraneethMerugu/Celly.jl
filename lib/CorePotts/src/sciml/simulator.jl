function SciMLBase.__init(prob::LegacyPottsProblem, alg::AbstractPottsAlgorithm, args...;
        saveat = Int[], save_everystep = isempty(saveat),
        save_start = true, save_end = true, callback = nothing, kwargs...)
    # Merge callbacks from the problem definition (prob.kwargs) and solve call (kwargs)
    prob_cb = get(prob.kwargs, :callback, nothing)

    cb_set = if callback === nothing && prob_cb === nothing
        SciMLBase.CallbackSet()
    elseif callback === nothing
        prob_cb isa SciMLBase.CallbackSet ? prob_cb : SciMLBase.CallbackSet(prob_cb)
    elseif prob_cb === nothing
        callback isa SciMLBase.CallbackSet ? callback : SciMLBase.CallbackSet(callback)
    else
        SciMLBase.CallbackSet(callback, prob_cb)
    end

    t_end = prob.tspan[2]
    backend = get(kwargs, :backend, MemoryBackend())
    tType = typeof(prob.tspan[1])
    if saveat isa Number
        saveat_vec = collect(tType, prob.tspan[1]:saveat:prob.tspan[2])
    else
        saveat_vec = tType.(saveat)
    end
    sort!(saveat_vec)

    opts = (; callback = cb_set, t_end = t_end, backend = backend,
        saveat = saveat_vec, save_everystep = save_everystep,
        save_start = save_start, save_end = save_end, kwargs...)

    # Initialize event masks for zero-allocation mask-driven events
    event_masks = map(prob.p.events) do ev
        if has_device_trigger(ev)
            similar(prob.u0.cell_data.volumes, Bool)
        else
            nothing
        end
    end

    # Initialize algorithmic cache
    block_size = get(kwargs, :block_size, DEFAULT_BLOCK_SIZE)
    cache = PottsCache(prob.u0, prob.p.topology, event_masks; block_size = block_size)

    # Instantiate workspace buffers inside the events themselves
    initialized_events = map(ev -> initialize_workspace(ev, prob.u0, prob.p.topology), prob.p.events)
    p_initialized = PottsParameters(prob.p.topology, prob.p.penalties, prob.p.trackers, initialized_events)

    sol_u, sol_t = initialize_backend(backend, prob, alg, opts)
    return LegacyPottsIntegrator(
        deepcopy(prob.u0), p_initialized, prob.tspan[1], alg, cache, opts, sol_u,
        sol_t, saveat_vec, save_everystep, save_start, save_end, prob)
end

@inline function _update_step_auxiliary!(
        items::Tuple, u, p::PottsParameters, cache::PottsCache,
        T::FT, dt::FT, ::Val{I}) where {I, FT}
    if I <= length(items)
        update_step_auxiliary!(items[I], u, p, cache, T, dt)
        _update_step_auxiliary!(items, u, p, cache, T, dt, Val(I+1))
    end
end
@inline _update_step_auxiliary!(items::Tuple, u, p::PottsParameters, cache::PottsCache,
    T::FT, dt::FT = one(FT)) where {FT} = _update_step_auxiliary!(
    items, u, p, cache, T, dt, Val(1))

@inline function _update_sweep_auxiliary!(
        items::Tuple, u, p::PottsParameters, cache::PottsCache,
        T::FT, dt::FT, ::Val{I}) where {I, FT}
    if I <= length(items)
        update_sweep_auxiliary!(items[I], u, p, cache, T, dt)
        _update_sweep_auxiliary!(items, u, p, cache, T, dt, Val(I+1))
    end
end
@inline _update_sweep_auxiliary!(items::Tuple, u, p::PottsParameters, cache::PottsCache,
    T::FT, dt::FT = one(FT)) where {FT} = _update_sweep_auxiliary!(
    items, u, p, cache, T, dt, Val(1))

function SciMLBase.step!(integrator::LegacyPottsIntegrator)
    u = integrator.u
    p = integrator.p
    cache = integrator.cache
    alg = integrator.alg

    # Extract the simulation float type
    FT = typeof(alg.T)
    half_dt = FT(0.5)

    # Phase 1: Pre-step auxiliary updates
    _update_step_auxiliary!(p.penalties, u, p, cache, alg.T, half_dt)
    _update_step_auxiliary!(p.trackers, u, p, cache, alg.T, half_dt)

    current_event = nothing
    for _ in 1:alg.sweeps_per_step
        # Phase 2: Pre-sweep auxiliary field updates
        _update_sweep_auxiliary!(p.penalties, u, p, cache, alg.T, half_dt)
        _update_sweep_auxiliary!(p.trackers, u, p, cache, alg.T, half_dt)

        # Phase 3: Local grid updates (MC Sweeps)
        current_event = execute_step!(u, p, cache, alg, current_event)

        # Phase 4: Post-sweep updates
        _update_sweep_auxiliary!(p.penalties, u, p, cache, alg.T, half_dt)
        _update_sweep_auxiliary!(p.trackers, u, p, cache, alg.T, half_dt)
    end

    # Phase 5: Post-step auxiliary updates
    _update_step_auxiliary!(p.penalties, u, p, cache, alg.T, half_dt)
    _update_step_auxiliary!(p.trackers, u, p, cache, alg.T, half_dt)

    # Phase 6: Core Events (AbstractEvent)
    if !isempty(p.events)
        dev_events = device_events(p.events)
        if !isbits(dev_events)
            throw(ArgumentError("One or more events capture non-bitstype variables! Ensure @rule closures only interpolate scalar primitives (like Float32, Int32) and do not capture full structs (like evt or CellType)."))
        end
        deps = current_event === nothing ? () : (current_event,)
        masks = cache.event_masks::Tuple
        current_event = _evaluate_all_events!(
            p.events, dev_events, masks, u, p, cache, integrator.t, deps)
    end

    # Phase 7: Intrinsic Death Processing (Reclaim IDs for target_volume <= 0)
    if hasproperty(u.cell_data, :target_volumes)
        process_death_events!(u, cache)
    end

    integrator.t += 1
end

function SciMLBase.terminate!(integrator::LegacyPottsIntegrator, retcode = SciMLBase.ReturnCode.Terminated)
    integrator.opts = merge(integrator.opts, (; t_end = integrator.t))
end

"""
    SciMLBase.solve!(integrator::LegacyPottsIntegrator)

In-place execution of the Potts simulation. Steps the `integrator` forward in time until it reaches
the end of the problem's timespan. Useful for manual loop control and avoiding memory reallocation.
"""
function SciMLBase.solve!(integrator::LegacyPottsIntegrator)
    has_cbs = !isempty(integrator.opts.callback.discrete_callbacks)

    if integrator.save_start || integrator.save_everystep ||
       integrator.t in integrator.saveat
        save_state!(integrator, integrator.opts.backend)
    end

    while integrator.t < integrator.opts.t_end
        SciMLBase.step!(integrator)

        # Evaluate standard SciML discrete callbacks purely at the end of each MCS
        if has_cbs
            KernelAbstractions.synchronize(KernelAbstractions.get_backend(integrator.u.grid))
            cb_set = integrator.opts.callback
            foreach(cb_set.discrete_callbacks) do cb
                if cb.condition(integrator.u, integrator.t, integrator)
                    cb.affect!(integrator)
                end
            end
        end

        if integrator.save_everystep || integrator.t in integrator.saveat
            KernelAbstractions.synchronize(KernelAbstractions.get_backend(integrator.u.grid))
            save_state!(integrator, integrator.opts.backend)
        end
    end

    if integrator.save_end &&
       (isempty(integrator.sol_t) || integrator.sol_t[end] != integrator.t)
        KernelAbstractions.synchronize(KernelAbstractions.get_backend(integrator.u.grid))
        save_state!(integrator, integrator.opts.backend)
    end

    # Return the standardized solution type
    return LegacyPottsSolution(integrator.sol_u, integrator.sol_t, integrator.prob,
        integrator.alg, SciMLBase.ReturnCode.Success)
end

function SciMLBase.__solve(prob::LegacyPottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)
    integrator = SciMLBase.__init(prob, alg, args...; kwargs...)
    return SciMLBase.solve!(integrator)
end

function SciMLBase.init(prob::LegacyPottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)
    return SciMLBase.__init(prob, alg, args...; kwargs...)
end

"""
    SciMLBase.solve(prob::LegacyPottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)

Standard out-of-place execution interface. Dynamically initializes a new `LegacyPottsIntegrator`,
allocates engine structures, executes the full simulation, and returns a `LegacyPottsSolution`.
"""
function SciMLBase.solve(prob::LegacyPottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)
    return SciMLBase.__solve(prob, alg, args...; kwargs...)
end

# ------------------------------------------------------------------
# Event Evaluation (Mask-Driven & Statically Unrolled)
# ------------------------------------------------------------------

@inline _any_device_trigger(events::Tuple{}) = false
@inline _any_device_trigger(events::Tuple) = has_device_trigger(first(events)) ||
                                             _any_device_trigger(Base.tail(events))

@inline _evaluate_trigger_tuple!(::Tuple{}, ::Tuple{}, i, cd, t) = nothing

@inline function _evaluate_trigger_tuple!(events::Tuple, masks::Tuple, i, cd, t)
    evt = first(events)
    mask = first(masks)
    if mask !== nothing
        mask[i] = evaluate_trigger(evt, i, cd, t)
    end
    _evaluate_trigger_tuple!(Base.tail(events), Base.tail(masks), i, cd, t)
end

@kernel function evaluate_all_triggers_kernel!(events, masks, cell_data, t)
    i = @index(Global, Linear)
    _evaluate_trigger_tuple!(events, masks, i, cell_data, t)
end

@inline _process_events_recursive(
    events::Tuple{}, masks::Tuple{}, u, p, cache, t, deps) = deps

function process_event!(evt::AbstractEvent, mask, u, p, cache, t, deps)
    args = get_event_args(evt, mask, u, p, cache, t)
    if args === nothing
        return deps
    end

    backend = KernelAbstractions.get_backend(u.grid)
    k = get_event_kernel(evt, backend, cache.block_size)
    nd = get_event_ndrange(evt, mask, u)

    ev = dispatch_kernel!(backend, k, args...; ndrange = nd)
    return ev === nothing ? deps : (ev,)
end

@inline function _process_events_recursive(
        events::Tuple, masks::Tuple, u, p, cache, t, deps)
    evt = first(events)
    mask = first(masks)
    new_deps = process_event!(evt, mask, u, p, cache, t, deps)
    deps_next = new_deps === nothing ? deps : new_deps
    return _process_events_recursive(
        Base.tail(events), Base.tail(masks), u, p, cache, t, deps_next)
end

@inline device_event(evt) = evt
@inline device_events(events::Tuple{}) = ()
@inline device_events(events::Tuple) = (device_event(first(events)), device_events(Base.tail(events))...)

function _evaluate_all_events!(events::Tuple, dev_events::Tuple, masks::Tuple, u, p, cache, t, deps)
    if _any_device_trigger(events)
        backend = KernelAbstractions.get_backend(u.grid)
        k = evaluate_all_triggers_kernel!(backend, cache.block_size)
        ev = dispatch_kernel!(backend, k, dev_events, masks, u.cell_data, t;
            ndrange = length(u.cell_data.volumes))
        deps = ev === nothing ? deps : (ev,)
    end

    new_deps = _process_events_recursive(events, masks, u, p, cache, t, deps)
    return isempty(new_deps) ? nothing : new_deps[1]
end
