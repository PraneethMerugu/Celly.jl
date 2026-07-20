"""Exact major-axis RMS extent derived from an unwrapped covariance tensor."""
@inline function _largest_covariance_eigenvalue(matrix::SMatrix{2, 2, T}) where {T}
    trace = matrix[1, 1] + matrix[2, 2]
    difference = matrix[1, 1] - matrix[2, 2]
    gap = sqrt(max(zero(T), difference * difference + T(4) * matrix[1, 2]^2))
    return max(zero(T), (trace + gap) / T(2))
end

@inline function _largest_covariance_eigenvalue(matrix::SMatrix{3, 3, T}) where {T}
    off_diagonal = matrix[1, 2]^2 + matrix[1, 3]^2 + matrix[2, 3]^2
    if off_diagonal <= eps(T)^2
        return max(zero(T), max(matrix[1, 1], max(matrix[2, 2], matrix[3, 3])))
    end
    mean = (matrix[1, 1] + matrix[2, 2] + matrix[3, 3]) / T(3)
    centered_11 = matrix[1, 1] - mean
    centered_22 = matrix[2, 2] - mean
    centered_33 = matrix[3, 3] - mean
    scale = sqrt((centered_11^2 + centered_22^2 + centered_33^2 +
        T(2) * off_diagonal) / T(6))
    scale <= eps(T) && return max(zero(T), mean)
    inverse_scale = inv(scale)
    b11 = centered_11 * inverse_scale
    b22 = centered_22 * inverse_scale
    b33 = centered_33 * inverse_scale
    b12 = matrix[1, 2] * inverse_scale
    b13 = matrix[1, 3] * inverse_scale
    b23 = matrix[2, 3] * inverse_scale
    determinant = b11 * (b22 * b33 - b23^2) -
                  b12 * (b12 * b33 - b23 * b13) +
                  b13 * (b12 * b23 - b22 * b13)
    ratio = clamp(determinant / T(2), -one(T), one(T))
    angle = acos(ratio) / T(3)
    return max(zero(T), mean + T(2) * scale * cos(angle))
end

@inline major_axis_rms_length(covariance) =
    sqrt(_largest_covariance_eigenvalue(covariance))

"""Conservative finite-cell energy `strength * (major_axis_rms - target)^2`."""
struct QuadraticElongationHamiltonian{TargetKey, StrengthKey,
        T <: AbstractFloat, D <: AbstractDivisionPolicy} <: AbstractEnergy
    target_division::D
end

function QuadraticElongationHamiltonian(;
        target::Symbol = :target_elongation,
        strength::Symbol = :elongation_strength,
        target_division::D = UnsupportedDivision(
            :elongation_target_policy_required),
        number_type::Type{T} = Float32) where {
        T <: AbstractFloat, D <: AbstractDivisionPolicy}
    target != strength || throw(ArgumentError(
        "elongation target and strength properties must be distinct"))
    return QuadraticElongationHamiltonian{target, strength, T, D}(target_division)
end

_elongation_target(::QuadraticElongationHamiltonian{Target}) where {Target} =
    CellPropertyRef(Target)
_elongation_strength(::QuadraticElongationHamiltonian{Target, Strength}) where {
    Target, Strength} = CellPropertyRef(Strength)

component_identity(::QuadraticElongationHamiltonian) =
    ComponentIdentity(:quadratic_elongation, v"1.0.0", :energy)
required_observables(::QuadraticElongationHamiltonian) =
    (:unwrapped_first_and_second_moments,)
required_relations(::QuadraticElongationHamiltonian) = (:connectivity,)

function required_properties(component::QuadraticElongationHamiltonian)
    requester = component_identity(component)
    T = typeof(component).parameters[3]
    return PropertySchema(
        PropertyDescriptor(property_key(_elongation_target(component)), T,
            ConstantInitializer(zero(T)); requester,
            division = component.target_division,
            transition = PreserveOnTransition(), kind = BiologicalProperty),
        PropertyDescriptor(property_key(_elongation_strength(component)), T,
            ConstantInitializer(zero(T)); requester, division = CloneOnDivision(),
            transition = PreserveOnTransition(), kind = BiologicalProperty)
    )
end

component_semantic_data(component::QuadraticElongationHamiltonian) = (
    measure = :major_axis_rms_extent,
    target_property = property_key(_elongation_target(component)),
    strength_property = property_key(_elongation_strength(component)),
    target_division = component.target_division,
    number_type = nameof(typeof(component).parameters[3]),
)

@inline function _elongation_energy(component::QuadraticElongationHamiltonian,
        state::Union{CompiledScientificState, ScientificExecutionState}, owner::OwnerRef,
        covariance)
    index = Int(owner.value)
    core = _focal_core(state)
    targets = _property_column(core, _elongation_target(component))
    strengths = _property_column(core, _elongation_strength(component))
    T = promote_type(eltype(targets), eltype(strengths), eltype(covariance))
    length_value = T(major_axis_rms_length(covariance))
    return T(@inbounds strengths[index]) *
           (length_value - T(@inbounds targets[index]))^2
end

function global_energy(component::QuadraticElongationHamiltonian,
        state::Union{CompiledScientificState, ScientificExecutionState})
    core = _focal_core(state)
    targets = _property_column(core, _elongation_target(component))
    T = eltype(targets)
    result = zero(T)
    for index in eachindex(core.active)
        @inbounds core.active[index] == UInt8(0) && continue
        owner = CellOwner(UInt32(index))
        result += _elongation_energy(component, state, owner,
            unwrapped_covariance(state, owner))
    end
    return result
end

@inline function _proposed_unwrapped_covariance(state, owner::OwnerRef,
        position, direction::Int)
    storage = state.trackers.moments
    storage isa UnwrappedMomentStorage || throw(ArgumentError(
        "elongation requires unwrapped first and second moments"))
    moment_is_tracked(storage, owner) || throw(ArgumentError(
        "elongation owner is absent from the unwrapped-moment tracker"))
    index = Int(owner.value)
    old_volume = @inbounds state.trackers.finite_volumes[index]
    new_volume = old_volume + direction
    new_volume > 0 || throw(ArgumentError(
        "an extinct owner has no proposed elongation covariance"))
    N = length(storage.coordinate_sums)
    T = eltype(first(storage.coordinate_sums))
    inverse_volume = inv(T(new_volume))
    return SMatrix{N, N, T}(ntuple(N * N) do linear_index
        row = (linear_index - 1) % N + 1
        column = (linear_index - 1) ÷ N + 1
        packed = _packed_symmetric_index(row, column, Val(N))
        first_row = @inbounds(storage.coordinate_sums[row][index]) +
                    T(direction) * position[row]
        first_column = @inbounds(storage.coordinate_sums[column][index]) +
                       T(direction) * position[column]
        second = @inbounds(storage.quadratic_sums[packed][index]) +
                 T(direction) * position[row] * position[column]
        second * inverse_volume -
        (first_row * inverse_volume) * (first_column * inverse_volume)
    end)
end

@inline function energy_change(component::QuadraticElongationHamiltonian,
        proposal::CopyProposal,
        state::Union{CompiledScientificState, ScientificExecutionState},
        transaction::StagedCopyTransaction)
    proposal.losing == proposal.gaining && return zero(
        eltype(_property_column(_focal_core(state), _elongation_target(component))))
    moments = transaction.trackers.moments
    moments isa UnwrappedMomentDelta || throw(ArgumentError(
        "elongation energy requires a staged unwrapped-moment delta"))
    targets = _property_column(_focal_core(state), _elongation_target(component))
    T = eltype(targets)
    result = zero(T)
    if is_cell_owner(proposal.losing)
        owner = proposal.losing
        old = _elongation_energy(component, state, owner,
            unwrapped_covariance(state, owner))
        volume = @inbounds state.trackers.finite_volumes[Int(owner.value)]
        result -= old
        if volume > 1
            proposed = _proposed_unwrapped_covariance(
                state, owner, moments.losing_position, -1)
            result += _elongation_energy(component, state, owner, proposed)
        end
    end
    if is_cell_owner(proposal.gaining)
        owner = proposal.gaining
        old = _elongation_energy(component, state, owner,
            unwrapped_covariance(state, owner))
        proposed = _proposed_unwrapped_covariance(
            state, owner, moments.gaining_position, 1)
        result += _elongation_energy(component, state, owner, proposed) - old
    end
    return result
end
