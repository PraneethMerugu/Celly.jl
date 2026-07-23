module TransitionKernelAnalysis

using LinearAlgebra
using SparseArrays
using ..TransitionKernelOracle: SparseTransitionKernel

export KernelComparison, compare_kernels, row_total_variation,
       communicating_classes, class_periods, is_irreducible, is_aperiodic,
       StationaryAnalysis, stationary_analysis, probability_currents,
       SpectralAnalysis, spectral_analysis, ObservableTransitionMoments,
       observable_transition_moments

struct KernelComparison{T}
    row_total_variation::Vector{T}
    maximum_total_variation::T
    maximum_row::Int
    maximum_absolute_residual::T
    missing_support::Vector{Tuple{Int, Int}}
    added_support::Vector{Tuple{Int, Int}}
end

function _compatible_matrices(left, right)
    size(left) == size(right) || throw(DimensionMismatch(
        "transition kernels must have equal dimensions"))
    size(left, 1) == size(left, 2) || throw(DimensionMismatch(
        "transition kernels must be square"))
    return nothing
end

function row_total_variation(left, right, row::Integer)
    _compatible_matrices(left, right)
    row in axes(left, 1) || throw(BoundsError(axes(left, 1), row))
    T = promote_type(eltype(left), eltype(right))
    total = zero(T)
    for destination in axes(left, 2)
        total += abs(convert(T, left[row, destination]) -
                     convert(T, right[row, destination]))
    end
    return total / convert(T, 2)
end

row_total_variation(left::SparseTransitionKernel,
    right::SparseTransitionKernel, row::Integer) =
    row_total_variation(left.matrix, right.matrix, row)

function compare_kernels(left, right; support_tolerance = 0)
    left_matrix = left isa SparseTransitionKernel ? left.matrix : left
    right_matrix = right isa SparseTransitionKernel ? right.matrix : right
    _compatible_matrices(left_matrix, right_matrix)
    T = promote_type(eltype(left_matrix), eltype(right_matrix),
        typeof(support_tolerance))
    threshold = convert(T, support_tolerance)
    threshold >= zero(T) || throw(ArgumentError(
        "support tolerance must be non-negative"))
    row_tv = T[row_total_variation(left_matrix, right_matrix, row)
               for row in axes(left_matrix, 1)]
    maximum_tv, maximum_row = findmax(row_tv)
    maximum_residual = zero(T)
    missing = Tuple{Int, Int}[]
    added = Tuple{Int, Int}[]
    for source in axes(left_matrix, 1), destination in axes(left_matrix, 2)
        left_probability = convert(T, left_matrix[source, destination])
        right_probability = convert(T, right_matrix[source, destination])
        maximum_residual = max(maximum_residual,
            abs(left_probability - right_probability))
        left_present = abs(left_probability) > threshold
        right_present = abs(right_probability) > threshold
        left_present && !right_present && push!(missing, (source, destination))
        !left_present && right_present && push!(added, (source, destination))
    end
    return KernelComparison(row_tv, maximum_tv, maximum_row,
        maximum_residual, missing, added)
end

function _support_graph(matrix; tolerance = 0)
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch(
        "a transition matrix must be square"))
    T = promote_type(eltype(matrix), typeof(tolerance))
    threshold = convert(T, tolerance)
    threshold >= zero(T) || throw(ArgumentError(
        "support tolerance must be non-negative"))
    count = size(matrix, 1)
    graph = falses(count, count)
    for source in 1:count, destination in 1:count
        graph[source, destination] =
            convert(T, matrix[source, destination]) > threshold
    end
    return graph
end

function communicating_classes(matrix; tolerance = 0)
    graph = _support_graph(matrix; tolerance)
    reachability = copy(graph)
    for state in axes(reachability, 1)
        reachability[state, state] = true
    end
    for intermediate in axes(reachability, 1), source in axes(reachability, 1)
        reachability[source, intermediate] || continue
        for destination in axes(reachability, 2)
            reachability[source, destination] |=
                reachability[intermediate, destination]
        end
    end
    unassigned = Set(axes(reachability, 1))
    classes = Vector{Vector{Int}}()
    while !isempty(unassigned)
        representative = minimum(unassigned)
        class = sort!([state for state in unassigned
                       if reachability[representative, state] &&
                          reachability[state, representative]])
        push!(classes, class)
        foreach(state -> delete!(unassigned, state), class)
    end
    sort!(classes; by = first)
    return classes
end

communicating_classes(kernel::SparseTransitionKernel; kwargs...) =
    communicating_classes(kernel.matrix; kwargs...)

is_irreducible(matrix; tolerance = 0) =
    length(communicating_classes(matrix; tolerance)) == 1
is_irreducible(kernel::SparseTransitionKernel; kwargs...) =
    is_irreducible(kernel.matrix; kwargs...)

function _class_period(graph::BitMatrix, class::Vector{Int})
    length(class) == 1 && return graph[class[1], class[1]] ? 1 : 0
    class_set = Set(class)
    root = first(class)
    distance = Dict(root => 0)
    queue = [root]
    cursor = 1
    while cursor <= length(queue)
        source = queue[cursor]
        cursor += 1
        for destination in class
            graph[source, destination] || continue
            if !haskey(distance, destination)
                distance[destination] = distance[source] + 1
                push!(queue, destination)
            end
        end
    end
    length(distance) == length(class_set) || return 0
    period = 0
    for source in class, destination in class
        graph[source, destination] || continue
        period = gcd(period, abs(distance[source] + 1 - distance[destination]))
    end
    return period
end

function class_periods(matrix; tolerance = 0)
    graph = _support_graph(matrix; tolerance)
    classes = communicating_classes(matrix; tolerance)
    return [(_class_period(graph, class), class) for class in classes]
end

class_periods(kernel::SparseTransitionKernel; kwargs...) =
    class_periods(kernel.matrix; kwargs...)

is_aperiodic(matrix; tolerance = 0) =
    all(first(period_and_class) == 1
        for period_and_class in class_periods(matrix; tolerance))
is_aperiodic(kernel::SparseTransitionKernel; kwargs...) =
    is_aperiodic(kernel.matrix; kwargs...)

struct StationaryAnalysis{T}
    distribution::Vector{T}
    stationarity_residual::T
    detailed_balance_residual::T
    nonnegative::Bool
    normalized::Bool
end

function stationary_analysis(matrix; tolerance = 1e-12)
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch(
        "a transition matrix must be square"))
    count = size(matrix, 1)
    count > 0 || throw(ArgumentError("a transition matrix must not be empty"))
    dense = Matrix{Float64}(matrix)
    system = vcat(transpose(dense) - Matrix{Float64}(I, count, count),
        ones(Float64, 1, count))
    target = vcat(zeros(Float64, count), 1.0)
    distribution = system \ target
    distribution[abs.(distribution) .<= tolerance] .= 0.0
    total = sum(distribution)
    iszero(total) && throw(ArgumentError(
        "stationary solve returned a zero-mass vector"))
    distribution ./= total
    stationarity = maximum(abs.(vec(transpose(distribution) * dense) .-
                                  distribution))
    balance = 0.0
    for source in 1:count, destination in 1:count
        balance = max(balance, abs(distribution[source] * dense[source, destination] -
                                   distribution[destination] * dense[destination, source]))
    end
    nonnegative = minimum(distribution) >= -tolerance
    normalized = abs(sum(distribution) - 1) <= tolerance
    return StationaryAnalysis(distribution, stationarity, balance,
        nonnegative, normalized)
end

stationary_analysis(kernel::SparseTransitionKernel; kwargs...) =
    stationary_analysis(kernel.matrix; kwargs...)

function probability_currents(matrix, distribution)
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch(
        "a transition matrix must be square"))
    length(distribution) == size(matrix, 1) || throw(DimensionMismatch(
        "stationary distribution and transition matrix sizes differ"))
    T = promote_type(eltype(matrix), eltype(distribution))
    currents = zeros(T, size(matrix))
    for source in axes(matrix, 1), destination in axes(matrix, 2)
        currents[source, destination] =
            convert(T, distribution[source]) * convert(T, matrix[source, destination]) -
            convert(T, distribution[destination]) * convert(T, matrix[destination, source])
    end
    return currents
end

probability_currents(kernel::SparseTransitionKernel, distribution) =
    probability_currents(kernel.matrix, distribution)

struct SpectralAnalysis
    eigenvalues::Vector{ComplexF64}
    unit_eigenvalue_multiplicity::Int
    spectral_gap::Float64
    relaxation_time::Float64
end

function spectral_analysis(matrix; tolerance = 1e-10)
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch(
        "a transition matrix must be square"))
    values = ComplexF64.(eigvals(Matrix{Float64}(matrix)))
    sort!(values; by = value -> (-abs(value), -real(value), -imag(value)))
    unit_count = count(value -> abs(value - 1) <= tolerance, values)
    subdominant = [abs(value) for value in values if abs(value - 1) > tolerance]
    radius = isempty(subdominant) ? 0.0 : maximum(subdominant)
    gap = max(0.0, 1.0 - radius)
    relaxation = gap > tolerance ? inv(gap) : Inf
    return SpectralAnalysis(values, unit_count, gap, relaxation)
end

spectral_analysis(kernel::SparseTransitionKernel; kwargs...) =
    spectral_analysis(kernel.matrix; kwargs...)

struct ObservableTransitionMoments{T}
    drift::Vector{T}
    diffusion::Vector{T}
    second_moment::Vector{T}
end

function observable_transition_moments(matrix, observable::AbstractVector)
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch(
        "a transition matrix must be square"))
    length(observable) == size(matrix, 1) || throw(DimensionMismatch(
        "observable and transition matrix sizes differ"))
    T = promote_type(eltype(matrix), eltype(observable))
    drift = zeros(T, length(observable))
    second = zeros(T, length(observable))
    for source in axes(matrix, 1), destination in axes(matrix, 2)
        displacement = convert(T, observable[destination]) -
                       convert(T, observable[source])
        probability = convert(T, matrix[source, destination])
        drift[source] += probability * displacement
        second[source] += probability * displacement^2
    end
    diffusion = max.(zero(T), second .- drift .^ 2)
    return ObservableTransitionMoments(drift, diffusion, second)
end

observable_transition_moments(kernel::SparseTransitionKernel,
    observable::AbstractVector) =
    observable_transition_moments(kernel.matrix, observable)

end
