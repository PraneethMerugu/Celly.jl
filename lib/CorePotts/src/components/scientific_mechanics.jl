@inline _mechanical_noise_scale(component, algorithm, ::AlgorithmTemperatureNoise) =
    typeof(component.eta)(algorithm.temperature)
@inline _mechanical_noise_scale(component, algorithm, noise::FixedMechanicalNoise) =
    typeof(component.eta)(noise.value)
@inline _mechanical_noise_scale(component, algorithm) =
    _mechanical_noise_scale(component, algorithm, component.noise)

"""Exact frozen-observable Ornstein-Uhlenbeck transition used by stable mechanics."""
function mechanical_ou_transition(q::Real, displacement::Real, strength::Real,
        eta::Real, noise_scale::Real, interval::Real, standard_normal::Real)
    T = float(promote_type(typeof(q), typeof(displacement), typeof(strength),
        typeof(eta), typeof(noise_scale), typeof(interval), typeof(standard_normal)))
    values = T.((q, displacement, strength, eta, noise_scale, interval,
        standard_normal))
    all(isfinite, values) || throw(ArgumentError(
        "mechanical OU transition inputs must be finite"))
    values[3] >= zero(T) || throw(ArgumentError(
        "mechanical strength must be non-negative"))
    values[4] > zero(T) || throw(ArgumentError(
        "mechanical relaxation rate must be positive"))
    values[5] >= zero(T) || throw(ArgumentError(
        "mechanical noise scale must be non-negative"))
    values[6] >= zero(T) || throw(ArgumentError(
        "mechanical interval must be non-negative"))
    return _mechanical_ou_transition(values...)
end

@inline function _mechanical_ou_transition(q, displacement, strength, eta,
        noise_scale, interval, standard_normal)
    alpha = exp(-eta * interval)
    mean = (one(alpha) - alpha) * (2 * strength * displacement)
    variance = 2 * strength * noise_scale *
               max(zero(alpha), one(alpha) - alpha * alpha)
    return alpha * q + mean + sqrt(variance) * standard_normal
end

@inline function _mechanical_observable(component::FluctuatingVolumePressure,
        state, cell)
    return @inbounds state.trackers.finite_volumes[cell]
end

@inline function _mechanical_observable(component::FluctuatingSurfaceTension,
        state, cell)
    return @inbounds state.trackers.boundary_measures[cell]
end

@inline function _mechanical_mean_inputs(component, state, cell)
    targets = _property_column(state, _mechanical_target(component))
    strengths = _property_column(state, _mechanical_strength(component))
    T = typeof(component.eta)
    displacement = T(_mechanical_observable(component, state, cell)) -
                   T(@inbounds targets[cell])
    strength = T(@inbounds strengths[cell])
    return displacement, strength
end

@inline function _mechanical_address(stream, component, state, cell, mcs,
        subround, phase)
    generation = @inbounds state.core.generations[cell]
    return _rng_address_unchecked(stream, mcs, subround, component.instance_id,
        CellEntity, Base.unsafe_trunc(UInt32, cell), generation, phase, UInt16(0))
end

@inline _initialize_mechanical_tuple!(::Tuple{}, state, algorithm, rng, seed, cell) = nothing

@inline function _initialize_mechanical_tuple!(mechanics::Tuple, state, algorithm,
        rng, seed, cell)
    _initialize_mechanical_cell!(first(mechanics), state, algorithm, rng, seed, cell)
    _initialize_mechanical_tuple!(Base.tail(mechanics), state, algorithm, rng, seed, cell)
    return nothing
end

@inline function _initialize_mechanical_cell!(component, state, algorithm, rng,
        seed, cell)
    values = _property_column(state, _mechanical_state(component))
    if @inbounds state.core.active[cell] == UInt8(0)
        @inbounds values[cell] = zero(eltype(values))
        return nothing
    end
    component.initialization === PreserveMechanicalInitialization && return nothing
    displacement, strength = _mechanical_mean_inputs(component, state, cell)
    T = typeof(component.eta)
    mean = T(2) * strength * displacement
    if component.initialization === ConstitutiveMeanInitialization
        @inbounds values[cell] = mean
        return nothing
    end
    noise_scale = _mechanical_noise_scale(component, algorithm)
    address = _mechanical_address(AuxiliaryInitializationStream, component, state,
        cell, UInt64(0), UInt8(0), UInt8(0))
    normal = normal_box_muller(T, rng, seed, address)
    @inbounds values[cell] = mean + sqrt(T(2) * strength * noise_scale) * normal
    return nothing
end

@kernel function _initialize_mechanics_kernel!(mechanics, state, algorithm, rng, seed)
    cell = @index(Global, Linear)
    if cell <= length(state.core.active)
        _initialize_mechanical_tuple!(mechanics, state, algorithm, rng, seed, cell)
    end
end

function _initialize_mechanics!(integrator)
    mechanics = integrator.components.mechanics
    isempty(mechanics) && return integrator
    kernel = _initialize_mechanics_kernel!(
        integrator.plan.backend, integrator.plan.block_size)
    launch!(integrator.plan, kernel, mechanics, scientific_execution(integrator.state),
        integrator.algorithm, integrator.rng, integrator.seed;
        ndrange = length(integrator.state.potts.storage.active))
    return integrator
end

@inline _advance_mechanical_tuple!(::Tuple{}, state, algorithm, rng, seed,
    mcs, subround, phase, interval, cell) = nothing

@inline function _advance_mechanical_tuple!(mechanics::Tuple, state, algorithm,
        rng, seed, mcs, subround, phase, interval, cell)
    _advance_mechanical_cell!(first(mechanics), state, algorithm, rng, seed,
        mcs, subround, phase, interval, cell)
    _advance_mechanical_tuple!(Base.tail(mechanics), state, algorithm, rng, seed,
        mcs, subround, phase, interval, cell)
    return nothing
end

@inline function _advance_mechanical_cell!(component, state, algorithm, rng, seed,
        mcs, subround, phase, interval, cell)
    values = _property_column(state, _mechanical_state(component))
    if @inbounds state.core.active[cell] == UInt8(0)
        @inbounds values[cell] = zero(eltype(values))
        return nothing
    end
    displacement, strength = _mechanical_mean_inputs(component, state, cell)
    T = typeof(component.eta)
    address = _mechanical_address(AuxiliaryEvolutionStream, component, state,
        cell, mcs, subround, phase)
    normal = normal_box_muller(T, rng, seed, address)
    q = T(@inbounds values[cell])
    updated = _mechanical_ou_transition(q, displacement, strength, component.eta,
        _mechanical_noise_scale(component, algorithm), T(interval), normal)
    @inbounds values[cell] = updated
    return nothing
end

@kernel function _advance_mechanics_kernel!(mechanics, state, algorithm, rng, seed,
        mcs, subround, phase, half_interval)
    cell = @index(Global, Linear)
    if cell <= length(state.core.active)
        _advance_mechanical_tuple!(mechanics, state, algorithm, rng, seed,
            mcs, subround, phase, half_interval, cell)
    end
end

function _advance_mechanics!(integrator, mcs::UInt64, subround::UInt8,
        phase::UInt8, half_interval)
    mechanics = integrator.components.mechanics
    isempty(mechanics) && return integrator
    kernel = _advance_mechanics_kernel!(integrator.plan.backend,
        integrator.plan.block_size)
    launch!(integrator.plan, kernel, mechanics, scientific_execution(integrator.state),
        integrator.algorithm, integrator.rng, integrator.seed, mcs, subround, phase,
        half_interval; ndrange = length(integrator.state.potts.storage.active))
    return integrator
end

@kernel function _advance_checkerboard_mechanics_kernel!(mechanics, state,
        algorithm, rng, seed, mcs, color_order, color_offsets, ordinal, phase,
        mutable_site_count)
    cell = @index(Global, Linear)
    if cell <= length(state.core.active)
        color = @inbounds color_order[Int(ordinal)]
        first_index = @inbounds color_offsets[Int(color)]
        stop_index = @inbounds color_offsets[Int(color) + 1]
        color_size = stop_index - first_index
        T = typeof(algorithm.temperature)
        half_interval = T(color_size) / (T(2) * T(mutable_site_count))
        subround = Base.unsafe_trunc(UInt8, ordinal - UInt32(1))
        _advance_mechanical_tuple!(mechanics, state, algorithm, rng, seed,
            mcs, subround, phase, half_interval, cell)
    end
end

function _advance_checkerboard_mechanics!(integrator, mcs::UInt64,
        ordinal::UInt32, phase::UInt8)
    mechanics = integrator.components.mechanics
    isempty(mechanics) && return integrator
    workspace = integrator.algorithm_workspace
    kernel = _advance_checkerboard_mechanics_kernel!(integrator.plan.backend,
        integrator.plan.block_size)
    launch!(integrator.plan, kernel, mechanics, scientific_execution(integrator.state),
        integrator.algorithm, integrator.rng, integrator.seed, mcs,
        workspace.color_order, workspace.color_offsets, ordinal, phase,
        length(workspace.sites);
        ndrange = length(integrator.state.potts.storage.active))
    return integrator
end
