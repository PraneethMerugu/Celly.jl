function SciMLBase.__init(prob::PottsProblem, alg::AbstractPottsAlgorithm, args...;
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

    # Initialize algorithmic cache
    block_size = get(kwargs, :block_size, DEFAULT_BLOCK_SIZE)
    cache = PottsCache(prob.u0, prob.p.topology, block_size)

    sol_u, sol_t = initialize_backend(backend, prob, alg, opts)
    return PottsIntegrator(
        deepcopy(prob.u0), prob.p, prob.tspan[1], alg, cache, opts, sol_u,
        sol_t, saveat_vec, save_everystep, save_start, save_end)
end

@inline function _update_step_auxiliary!(
        items::Tuple, u, p::PottsParameters, cache::PottsCache,
        T::Float32, dt::Float32, ::Val{I}) where {I}
    if I <= length(items)
        update_step_auxiliary!(items[I], u, p, cache, T, dt)
        _update_step_auxiliary!(items, u, p, cache, T, dt, Val(I+1))
    end
end
@inline _update_step_auxiliary!(items::Tuple, u, p::PottsParameters, cache::PottsCache,
    T::Float32, dt::Float32 = 1.0f0) = _update_step_auxiliary!(
    items, u, p, cache, T, dt, Val(1))

@inline function _update_sweep_auxiliary!(
        items::Tuple, u, p::PottsParameters, cache::PottsCache,
        T::Float32, dt::Float32, ::Val{I}) where {I}
    if I <= length(items)
        update_sweep_auxiliary!(items[I], u, p, cache, T, dt)
        _update_sweep_auxiliary!(items, u, p, cache, T, dt, Val(I+1))
    end
end
@inline _update_sweep_auxiliary!(items::Tuple, u, p::PottsParameters, cache::PottsCache,
    T::Float32, dt::Float32 = 1.0f0) = _update_sweep_auxiliary!(
    items, u, p, cache, T, dt, Val(1))

function SciMLBase.step!(integrator::PottsIntegrator)
    u = integrator.u
    p = integrator.p
    cache = integrator.cache
    alg = integrator.alg

    for _ in 1:alg.sweeps_per_step
        # Phase 1: Pre-sweep global auxiliary field updates (Gibbs exact draw + COM tracking)
        _update_step_auxiliary!(p.penalties, u, p, cache, Float32(alg.T), 0.5f0)
        _update_step_auxiliary!(p.trackers, u, p, cache, Float32(alg.T), 0.5f0)
        _update_sweep_auxiliary!(p.penalties, u, p, cache, Float32(alg.T), 0.5f0)
        _update_sweep_auxiliary!(p.trackers, u, p, cache, Float32(alg.T), 0.5f0)

        # Phase 2: Local grid updates (MC Sweeps)
        execute_step!(u, p, cache, alg)

        # Phase 3: Post-sweep updates
        _update_step_auxiliary!(p.penalties, u, p, cache, Float32(alg.T), 0.5f0)
        _update_step_auxiliary!(p.trackers, u, p, cache, Float32(alg.T), 0.5f0)
        _update_sweep_auxiliary!(p.penalties, u, p, cache, Float32(alg.T), 0.5f0)
        _update_sweep_auxiliary!(p.trackers, u, p, cache, Float32(alg.T), 0.5f0)
    end

    integrator.t += 1
end

"""
    SciMLBase.solve!(integrator::PottsIntegrator)

In-place execution of the Potts simulation. Steps the `integrator` forward in time until it reaches
the end of the problem's timespan. Useful for manual loop control and avoiding memory reallocation.
"""
function SciMLBase.solve!(integrator::PottsIntegrator)
    t_end = integrator.opts.t_end

    has_cbs = haskey(integrator.opts, :callback)

    if integrator.save_start || integrator.save_everystep ||
       integrator.t in integrator.saveat
        save_state!(integrator, integrator.opts.backend)
    end

    while integrator.t < t_end
        SciMLBase.step!(integrator)

        # Evaluate standard SciML discrete callbacks purely at the end of each MCS
        if has_cbs
            cb_set = integrator.opts.callback
            foreach(cb_set.discrete_callbacks) do cb
                if cb.condition(integrator.u, integrator.t, integrator)
                    cb.affect!(integrator)
                end
            end
        end

        if integrator.save_everystep || integrator.t in integrator.saveat
            save_state!(integrator, integrator.opts.backend)
        end
    end

    if integrator.save_end &&
       (isempty(integrator.sol_t) || integrator.sol_t[end] != integrator.t)
        save_state!(integrator, integrator.opts.backend)
    end

    # Return the standardized solution type
    return PottsSolution(integrator.sol_u, integrator.sol_t, nothing,
        integrator.alg, SciMLBase.ReturnCode.Success)
end

function SciMLBase.__solve(prob::PottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)
    integrator = SciMLBase.__init(prob, alg, args...; kwargs...)
    return SciMLBase.solve!(integrator)
end

function SciMLBase.init(prob::PottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)
    return SciMLBase.__init(prob, alg, args...; kwargs...)
end

"""
    SciMLBase.solve(prob::PottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)

Standard out-of-place execution interface. Dynamically initializes a new `PottsIntegrator`,
allocates engine structures, executes the full simulation, and returns a `PottsSolution`.
"""
function SciMLBase.solve(prob::PottsProblem, alg::AbstractPottsAlgorithm, args...; kwargs...)
    return SciMLBase.__solve(prob, alg, args...; kwargs...)
end
