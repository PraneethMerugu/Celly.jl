"""Nearest-neighbor spatial-query relation selected independently of contact mechanics."""
struct Contacting end

abstract type AbstractQueryOwnerFilter end

"""Match every finite neighboring cell and exclude medium or exterior domains."""
struct AnyFiniteCell <: AbstractQueryOwnerFilter end

"""Match finite neighboring cells with one symbolic biological cell type."""
struct CellTypeFilter <: AbstractQueryOwnerFilter
    cell_type::SemanticName
end

CellTypeFilter(cell_type::CellType) = CellTypeFilter(semantic_identity(cell_type))

abstract type AbstractSpatialQueryOperation end
struct ContactEdgeCountOperation <: AbstractSpatialQueryOperation end
struct ContactMeasureOperation <: AbstractSpatialQueryOperation end
struct BoundarySiteCountOperation <: AbstractSpatialQueryOperation end
struct NeighborCellCountOperation <: AbstractSpatialQueryOperation end
struct NeighborPropertySumOperation <: AbstractSpatialQueryOperation
    property::SemanticName
end
struct NeighborPropertyMeanOperation{T} <: AbstractSpatialQueryOperation
    property::SemanticName
    empty::T
end

"""One immutable scalar spatial query in the closed portable rule IR."""
struct SpatialQueryExpression{O <: AbstractSpatialQueryOperation,
        R, F <: AbstractQueryOwnerFilter} <: AbstractRuleExpression
    operation::O
    owner::Symbol
    relation::R
    filter::F
end

function _spatial_query(operation::AbstractSpatialQueryOperation,
        owner::OwnerReference, relation::Contacting,
        filter::AbstractQueryOwnerFilter)
    return SpatialQueryExpression(operation, owner.name, relation, filter)
end

contact_edge_count(owner::OwnerReference, relation::Contacting,
    filter::AbstractQueryOwnerFilter) =
    _spatial_query(ContactEdgeCountOperation(), owner, relation, filter)
contact_measure(owner::OwnerReference, relation::Contacting,
    filter::AbstractQueryOwnerFilter) =
    _spatial_query(ContactMeasureOperation(), owner, relation, filter)
boundary_site_count(owner::OwnerReference, relation::Contacting,
    filter::AbstractQueryOwnerFilter) =
    _spatial_query(BoundarySiteCountOperation(), owner, relation, filter)
neighbor_cell_count(owner::OwnerReference, relation::Contacting,
    filter::AbstractQueryOwnerFilter) =
    _spatial_query(NeighborCellCountOperation(), owner, relation, filter)
neighbor_property_sum(property::CellProperty, owner::OwnerReference,
    relation::Contacting, filter::AbstractQueryOwnerFilter) =
    _spatial_query(NeighborPropertySumOperation(semantic_identity(property)),
        owner, relation, filter)
function neighbor_property_mean(property::CellProperty, owner::OwnerReference,
        relation::Contacting, filter::AbstractQueryOwnerFilter; empty)
    isbits(empty) || throw(ArgumentError(
        "a neighbor-property mean empty value must be immutable and isbits"))
    return _spatial_query(NeighborPropertyMeanOperation(
        semantic_identity(property), empty), owner, relation, filter)
end

_query_property(::AbstractSpatialQueryOperation) = nothing
_query_property(operation::Union{
    NeighborPropertySumOperation, NeighborPropertyMeanOperation}) = operation.property
function _expression_reads(expression::SpatialQueryExpression)
    property = _query_property(expression.operation)
    return property === nothing ? () : (property,)
end
_normalize_rule_expression(expression::SpatialQueryExpression, ::Type) = expression
_rule_result_types(expression::SpatialQueryExpression{ContactEdgeCountOperation}, context) =
    (Int64,)
_rule_result_types(expression::SpatialQueryExpression{BoundarySiteCountOperation}, context) =
    (Int64,)
_rule_result_types(expression::SpatialQueryExpression{ContactMeasureOperation}, context) =
    (_context_real_type(context),)
_rule_result_types(expression::SpatialQueryExpression{NeighborCellCountOperation}, context) =
    (Int64,)
function _neighbor_property_result_type(expression::SpatialQueryExpression, context)
    property = _query_property(expression.operation)
    return _referenced_value_type(property, context)
end
function _rule_result_types(
        expression::SpatialQueryExpression{NeighborPropertySumOperation}, context)
    type = _neighbor_property_result_type(expression, context)
    type === nothing && return ()
    sum_type = Base.promote_op(+, type, type)
    return sum_type === type && hasmethod(zero, Tuple{Type{type}}) ? (type,) : ()
end
function _rule_result_types(
        expression::SpatialQueryExpression{<:NeighborPropertyMeanOperation}, context)
    type = _neighbor_property_result_type(expression, context)
    type === nothing && return ()
    mean_type = Base.promote_op(/, type, Int64)
    types = _concrete_result_types(mean_type)
    isempty(types) && return ()
    return Tuple(unique((types..., typeof(expression.operation.empty))))
end

_spatial_queries(::Any) = ()
_spatial_queries(expression::SpatialQueryExpression) = (expression,)
_spatial_queries(expression::ScalarCall) = Tuple(query
    for argument in expression.arguments for query in _spatial_queries(argument))
_spatial_queries(expression::ConditionalExpression) = Tuple(query
    for branch in (expression.condition, expression.if_true, expression.if_false)
    for query in _spatial_queries(branch))
_spatial_queries(expression::RandomDraw) = Tuple(query
    for parameter in _distribution_expressions(expression.distribution)
    for query in _spatial_queries(parameter))

function _query_diagnostics(rule::Rule, context::_ValidationContext)
    diagnostics = ()
    for query in _spatial_queries(rule.expression)
        query.owner === rule.owner || (diagnostics = (diagnostics..., Diagnostic(
            :error, :invalid_query_owner,
            "a Level 1 spatial query must use the rule's declared owner";
            identity = rule.name, related = (query.owner,), source = rule.source,
            correction = "query the owner named on the left side of the rule"),))
        if query.filter isa CellTypeFilter
            cell_type = query.filter.cell_type
            any(value -> semantic_identity(value) == cell_type,
                context.cell_types) || (diagnostics = (diagnostics...,
                Diagnostic(:error, :unknown_query_filter,
                    "a spatial-query filter references an undeclared cell type";
                    identity = rule.name, related = (cell_type,), source = rule.source,
                    correction = "declare the cell type or correct the query filter"),))
        end
        property_identity = _query_property(query.operation)
        property_identity === nothing && continue
        property_index = findfirst(component ->
            semantic_identity(component) == property_identity, context.components)
        property = property_index === nothing ? nothing :
            context.components[property_index]
        property isa CellProperty || continue
        required_types = query.filter isa CellTypeFilter ?
            Tuple(value for value in context.cell_types
                if semantic_identity(value) == query.filter.cell_type) :
            context.cell_types
        missing = Tuple(value for value in required_types
            if !(value in property.cell_types))
        isempty(missing) || (diagnostics = (diagnostics..., Diagnostic(
            :error, :query_property_scope_mismatch,
            "a distinct-neighbor property reduction may reach cell types without that property";
            identity = rule.name, related = (property_identity, missing...),
            source = rule.source,
            correction = "narrow the query filter or declare the property for every reachable cell type"),))
    end
    return diagnostics
end

function _scope_query_filter(filter::CellTypeFilter, mapping)
    return CellTypeFilter(_mapped_identity(mapping, filter.cell_type))
end
_scope_query_filter(filter::AnyFiniteCell, mapping) = filter

function _scope_rule_expression(expression::SpatialQueryExpression, mapping)
    operation = _scope_query_operation(expression.operation, mapping)
    return SpatialQueryExpression(operation, expression.owner,
        expression.relation, _scope_query_filter(expression.filter, mapping))
end

_scope_query_operation(operation::AbstractSpatialQueryOperation, mapping) = operation
_scope_query_operation(operation::NeighborPropertySumOperation, mapping) =
    NeighborPropertySumOperation(_mapped_identity(mapping, operation.property))
_scope_query_operation(operation::NeighborPropertyMeanOperation, mapping) =
    NeighborPropertyMeanOperation(
        _mapped_identity(mapping, operation.property), operation.empty)

function _canonical_write(io::IO, operation::AbstractSpatialQueryOperation)
    _canonical_open(io, operation)
    _canonical_write(io, Symbol(nameof(typeof(operation))))
    return _canonical_close(io)
end

_canonical_write(io::IO, relation::Contacting) = _canonical_fields(io, relation)
_canonical_write(io::IO, filter::AbstractQueryOwnerFilter) = _canonical_fields(io, filter)

const _SPATIAL_QUERY_FUNCTIONS = Set((
    :contact_edge_count, :contact_measure, :boundary_site_count,
    :neighbor_cell_count, :neighbor_property_sum, :neighbor_property_mean))

function _macro_query_relation(expression)
    expression isa Expr && expression.head === :call &&
        expression.args == Any[:Contacting] || throw(ArgumentError(
        "the initial Level 1 query compiler requires the explicit `Contacting()` relation"))
    return :($(GlobalRef(@__MODULE__, :Contacting))())
end

function _macro_query_filter(expression)
    expression isa Expr && expression.head === :call || throw(ArgumentError(
        "a Level 1 spatial query requires a typed owner filter"))
    if expression.args == Any[:AnyFiniteCell]
        return :($(GlobalRef(@__MODULE__, :AnyFiniteCell))())
    end
    first(expression.args) === :CellTypeFilter && length(expression.args) == 2 ||
        throw(ArgumentError(
            "use `AnyFiniteCell()` or `CellTypeFilter(cell_type)` as the query filter"))
    cell_type = expression.args[2]
    cell_type isa Symbol || throw(ArgumentError(
        "a cell-type query filter requires a simple typed CellType binding"))
    return :($(GlobalRef(@__MODULE__, :CellTypeFilter))($(esc(cell_type))))
end

function _macro_spatial_query(expression::Expr, owner::Symbol)
    arguments = collect(expression.args)
    name = popfirst!(arguments)
    parameters = !isempty(arguments) && first(arguments) isa Expr &&
        first(arguments).head === :parameters ? popfirst!(arguments) : nothing
    property_expression = nothing
    if name in (:neighbor_property_sum, :neighbor_property_mean)
        length(arguments) == 4 || throw(ArgumentError(
            "a neighbor-property query requires `(property, owner, relation, filter)`"))
        property_expression = popfirst!(arguments)
        property_expression isa Symbol || throw(ArgumentError(
            "a neighbor-property query requires a simple typed CellProperty binding"))
    else
        length(arguments) == 3 || throw(ArgumentError(
            "a Level 1 spatial query requires `(owner, relation, filter)`"))
    end
    owner_expression, relation_expression, filter_expression = arguments
    owner_node = _macro_rule_expression(owner_expression, owner)
    relation_node = _macro_query_relation(relation_expression)
    filter_node = _macro_query_filter(filter_expression)
    if name === :neighbor_property_mean
        parameters === nothing && throw(ArgumentError(
            "`neighbor_property_mean` requires an explicit `empty` keyword"))
        length(parameters.args) == 1 || throw(ArgumentError(
            "`neighbor_property_mean` accepts only the `empty` keyword"))
        keyword = only(parameters.args)
        keyword isa Expr && keyword.head === :kw && keyword.args[1] === :empty ||
            throw(ArgumentError(
                "`neighbor_property_mean` accepts only the `empty` keyword"))
        empty_node = _macro_rule_expression(keyword.args[2], owner)
        empty_node isa Expr && empty_node.head === :call &&
            empty_node.args[1] == GlobalRef(@__MODULE__, :RuleLiteral) ||
            throw(ArgumentError(
                "`neighbor_property_mean` currently requires a literal empty value"))
        empty_value = empty_node.args[2]
        return :($(GlobalRef(@__MODULE__, name))($(esc(property_expression)),
            $owner_node, $relation_node, $filter_node; empty = $empty_value))
    end
    parameters === nothing || throw(ArgumentError(
        "this Level 1 spatial query does not accept keyword arguments"))
    if property_expression !== nothing
        return :($(GlobalRef(@__MODULE__, name))($(esc(property_expression)),
            $owner_node, $relation_node, $filter_node))
    end
    return :($(GlobalRef(@__MODULE__, name))(
        $owner_node, $relation_node, $filter_node))
end
