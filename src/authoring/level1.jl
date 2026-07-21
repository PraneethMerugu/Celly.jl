abstract type AbstractLevel1Declaration end

"""Exact quadratic finite-cell volume Hamiltonian in the Level 1 vocabulary."""
struct Volume{D <: VolumeConstraint} <: AbstractLevel1Declaration
    declaration::D
end

Volume(pairs::Pair...; kwargs...) = Volume(VolumeConstraint(pairs...; kwargs...))

"""Exact quadratic finite-cell boundary-measure Hamiltonian."""
struct Surface{D <: BoundaryConstraint} <: AbstractLevel1Declaration
    declaration::D
end

Surface(pairs::Pair...; kwargs...) = Surface(BoundaryConstraint(pairs...; kwargs...))

"""Stateful finite-cell volume-pressure mechanics with explicit noise semantics."""
struct FluctuatingVolumePressure{D <: FluctuatingVolumeConstraint} <:
        AbstractLevel1Declaration
    declaration::D
end

function FluctuatingVolumePressure(pairs::Pair...; noise, kwargs...)
    return FluctuatingVolumePressure(
        FluctuatingVolumeConstraint(pairs...; noise, kwargs...))
end

"""Stateful finite-cell surface-tension mechanics with explicit noise semantics."""
struct FluctuatingSurfaceTension{D <: FluctuatingBoundaryConstraint} <:
        AbstractLevel1Declaration
    declaration::D
end

function FluctuatingSurfaceTension(pairs::Pair...; noise, kwargs...)
    return FluctuatingSurfaceTension(
        FluctuatingBoundaryConstraint(pairs...; noise, kwargs...))
end

"""Use the acceptance-law temperature as the explicitly selected mechanical noise scale."""
AcceptanceTemperature() = CorePotts.AlgorithmTemperatureNoise()

"""Use a fixed mechanical noise scale independent of the acceptance-law temperature."""
IndependentNoise(value::Real) = CorePotts.FixedMechanicalNoise(value)

"""Binary split along a uniformly addressed random orientation."""
function RandomOrientationSplit(; label::Symbol = :division_orientation)
    operation = _semantic_rng_code(
        SemanticName(:random_orientation_split), label, UInt16(0x03ff))
    return CorePotts.RandomOrientationDivision(operation)
end

"""Binary split normal to the current major axis."""
MinorAxisSplit() = CorePotts.MinorAxisDivision()
"""Binary split normal to the current minor axis."""
MajorAxisSplit() = CorePotts.MajorAxisDivision()
"""Binary split by an explicit normal vector."""
VectorSplit(normal) = CorePotts.VectorDivision(normal)

for wrapper in (:Volume, :Surface, :FluctuatingVolumePressure,
        :FluctuatingSurfaceTension)
    @eval begin
        semantic_identity(value::$wrapper) = semantic_identity(value.declaration)
        _flatten_declaration(value::$wrapper) = (value.declaration,)
        function _scope_declaration(value::$wrapper, fragment::ModelFragment, mapping)
            return $wrapper(_scope_declaration(value.declaration, fragment, mapping))
        end
    end
end

function Base.show(io::IO, value::AbstractLevel1Declaration)
    print(io, nameof(typeof(value)), '(', semantic_identity(value), ')')
end

abstract type AbstractMissingPairPolicy end

"""Reject a model unless every required biological pair has an explicit value."""
struct RejectMissingPairs <: AbstractMissingPairPolicy end

"""Use one explicit value for required biological pairs not listed in a pairwise law."""
struct DefaultPairValue{T <: Real} <: AbstractMissingPairPolicy
    value::T
end

function PairwiseLaw(name::Symbol, pairs::Pair...;
        namespace::Namespace = Namespace(), symmetric::Bool = true,
        missing::AbstractMissingPairPolicy = RejectMissingPairs())
    default = missing isa RejectMissingPairs ? nothing : missing.value
    return PairwiseLaw(pairs...; name, namespace, symmetric, default)
end

Adhesion(law::PairwiseLaw) = Adhesion(law.name, law)

"""
Immutable collection of typed initial ownership claims. Entry order is not a conflict resolver.
"""
struct Layout{E <: Tuple}
    entries::E
end

function Layout(entries...)
    all(entry -> entry isa Union{CellLayout, CellLabelLayout, MediumLayout}, entries) ||
        throw(ArgumentError(
            "layout entries must be CellLayout, CellLabelLayout, or MediumLayout values"))
    return Layout(Tuple(entries))
end

Base.length(layout::Layout) = length(layout.entries)
Base.isempty(layout::Layout) = isempty(layout.entries)
Base.iterate(layout::Layout, state...) = iterate(layout.entries, state...)

"""Place one finite cell from an explicit mask and semantic provisional identity."""
Place(cell_type::CellType, mask::AbstractArray{Bool}; identity::Integer,
    kwargs...) = CellLayout(cell_type, identity, mask; kwargs...)

"""Place one conceptual medium domain from an explicit mask."""
Place(medium::Medium, mask::AbstractArray{Bool}; kwargs...) =
    MediumLayout(medium, mask; kwargs...)

"""Declare several provisional finite cells from one dense non-negative label raster."""
LabelledCells(labels::AbstractArray{<:Integer}, declarations; kwargs...) =
    CellLabelLayout(labels, declarations; kwargs...)

const CartesianDomain = CorePotts.CartesianDomain
const PeriodicBoundary = CorePotts.PeriodicBoundary
const ClosedBoundary = CorePotts.ClosedBoundary
const FixedExterior = CorePotts.FixedExterior
const AxisBoundary = CorePotts.AxisBoundary

"""
    PottsProblem(model, domain, layout; capacity, tspan, seed, ...)

Bind one reusable Toolkit model to a realized CorePotts/SciML experiment. The return value is the
single public `CorePotts.PottsProblem`; PottsToolkit introduces no runtime wrapper.
"""
function PottsProblem(model::PottsModel, domain::CorePotts.CartesianDomain,
        layout::Layout; capacity::Integer, tspan = (0, 1), seed::Integer = 0,
        fields = (), overlap_policy::CorePotts.AbstractInitialOverlapPolicy =
            CorePotts.RejectInitialOverlap())
    realized_model = any(declaration -> declaration isa Field,
        model.declarations) ? _realize_problem_fields(model, domain, fields) : model
    isempty(fields) || realized_model !== model || throw(ArgumentError(
        "problem field bindings were supplied but the model declares no reusable Field"))
    return problem(realized_model, domain, layout.entries...;
        capacity, tspan, seed, overlap_policy)
end
