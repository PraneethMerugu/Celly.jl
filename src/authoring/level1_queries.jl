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

_expression_reads(::SpatialQueryExpression) = ()
_normalize_rule_expression(expression::SpatialQueryExpression, ::Type) = expression
_rule_result_types(expression::SpatialQueryExpression{ContactEdgeCountOperation}, context) =
    (Int64,)
_rule_result_types(expression::SpatialQueryExpression{BoundarySiteCountOperation}, context) =
    (Int64,)
_rule_result_types(expression::SpatialQueryExpression{ContactMeasureOperation}, context) =
    (_context_real_type(context),)

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
    end
    return diagnostics
end

function _scope_query_filter(filter::CellTypeFilter, mapping)
    return CellTypeFilter(_mapped_identity(mapping, filter.cell_type))
end
_scope_query_filter(filter::AnyFiniteCell, mapping) = filter

function _scope_rule_expression(expression::SpatialQueryExpression, mapping)
    return SpatialQueryExpression(expression.operation, expression.owner,
        expression.relation, _scope_query_filter(expression.filter, mapping))
end

function _canonical_write(io::IO, operation::AbstractSpatialQueryOperation)
    _canonical_open(io, operation)
    _canonical_write(io, Symbol(nameof(typeof(operation))))
    return _canonical_close(io)
end

_canonical_write(io::IO, relation::Contacting) = _canonical_fields(io, relation)
_canonical_write(io::IO, filter::AbstractQueryOwnerFilter) = _canonical_fields(io, filter)

const _SPATIAL_QUERY_FUNCTIONS = Set((
    :contact_edge_count, :contact_measure, :boundary_site_count))

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
    length(expression.args) == 4 || throw(ArgumentError(
        "a Level 1 spatial query requires `(owner, relation, filter)`"))
    name, owner_expression, relation_expression, filter_expression = expression.args
    owner_node = _macro_rule_expression(owner_expression, owner)
    relation_node = _macro_query_relation(relation_expression)
    filter_node = _macro_query_filter(filter_expression)
    return :($(GlobalRef(@__MODULE__, name))(
        $owner_node, $relation_node, $filter_node))
end
