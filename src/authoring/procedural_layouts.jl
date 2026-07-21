abstract type AbstractProceduralLayout end

"""Addressed uniform injection of one-site provisional cells."""
struct UniformSiteSeedLayout{M} <: AbstractProceduralLayout
    name::SemanticName
    cell_type::CellType
    count::UInt32
    first_identity::UInt64
    eligible::M
    operation::UInt16
    priority::Int32
end

function UniformSiteSeeds(cell_type::CellType, count::Integer;
        name::Symbol = :uniform_site_seeds, namespace::Namespace = Namespace(),
        first_identity::Integer = 1, eligible = nothing,
        label::Symbol = :site_permutation, priority::Integer = 0)
    0 < count <= typemax(UInt32) || throw(ArgumentError(
        "uniform site-seed count must be positive and fit UInt32"))
    0 < first_identity <= typemax(UInt64) || throw(ArgumentError(
        "the first provisional identity must be positive and fit UInt64"))
    last_identity = big(first_identity) + big(count) - 1
    last_identity <= typemax(UInt64) || throw(ArgumentError(
        "uniform site-seed provisional identities exceed UInt64"))
    eligible === nothing || eligible isa AbstractArray{Bool} || throw(ArgumentError(
        "uniform site-seed eligibility must be a Boolean mask"))
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "layout priority must fit Int32"))
    identity = SemanticName(name; namespace)
    operation = UInt16(_semantic_rng_code(identity, label, UInt16(0x0fff)))
    return UniformSiteSeedLayout(identity, cell_type, UInt32(count),
        UInt64(first_identity), eligible, operation, Int32(priority))
end

"""Addressed bounded sequential rejection placement of one declared shape family."""
struct SequentialRejectionLayout{S, M, P <: Tuple} <: AbstractProceduralLayout
    name::SemanticName
    cell_type::CellType
    count::UInt32
    first_identity::UInt64
    shape::S
    eligible_centers::M
    periodic::P
    attempt_limit::UInt16
    operation::UInt16
    priority::Int32
end

function SequentialRejectionPlacement(cell_type::CellType, count::Integer, shape;
        name::Symbol = :sequential_rejection_placement,
        namespace::Namespace = Namespace(), first_identity::Integer = 1,
        eligible_centers = nothing, periodic = (), attempt_limit::Integer,
        label::Symbol = :candidate_centers, priority::Integer = 0)
    shape isa CorePotts.AbstractLatticeShape || throw(ArgumentError(
        "sequential rejection requires a CorePotts AbstractLatticeShape"))
    0 < count <= typemax(UInt32) || throw(ArgumentError(
        "sequential-rejection count must be positive and fit UInt32"))
    0 < first_identity <= typemax(UInt32) || throw(ArgumentError(
        "the first sequential-rejection identity must be positive and fit UInt32"))
    last_identity = big(first_identity) + big(count) - 1
    last_identity <= typemax(UInt32) || throw(ArgumentError(
        "sequential-rejection provisional identities exceed the v1 UInt32 RNG domain"))
    eligible_centers === nothing || eligible_centers isa AbstractArray{Bool} ||
        throw(ArgumentError("eligible centers must be a Boolean mask"))
    1 <= attempt_limit <= 256 || throw(ArgumentError(
        "sequential-rejection attempt_limit must lie in 1:256"))
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "layout priority must fit Int32"))
    periodic_values = Tuple(Bool(value) for value in periodic)
    identity = SemanticName(name; namespace)
    operation = UInt16(_semantic_rng_code(identity, label, UInt16(0x0fff)))
    return SequentialRejectionLayout(identity, cell_type, UInt32(count),
        UInt64(first_identity), shape, eligible_centers, periodic_values,
        UInt16(attempt_limit), operation, Int32(priority))
end
