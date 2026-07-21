abstract type _AbstractCompiledRuleExpression <: AbstractRuleExpression end

struct _CompiledPropertyRead{Key} <: _AbstractCompiledRuleExpression end

struct _CompiledCellParameterRead{V <: Tuple} <: _AbstractCompiledRuleExpression
    values::V
end

struct _CompiledRandomDraw{D <: AbstractDrawDistribution} <:
        _AbstractCompiledRuleExpression
    distribution::D
    operation::UInt16
end

struct _CompiledUnitVector{N, T <: AbstractFloat} <: AbstractDrawDistribution end

struct _CompiledSpatialQueryExpression{O <: AbstractSpatialQueryOperation,
        R, F <: CorePotts.AbstractOwnerFilter, M <: CorePotts.MediumTypeTable} <:
        AbstractRuleExpression
    operation::O
    relation::R
    filter::F
    medium_types::M
end

struct _CompiledNeighborPropertySumOperation{Key} <: AbstractSpatialQueryOperation end
struct _CompiledNeighborPropertyMeanOperation{Key, T} <: AbstractSpatialQueryOperation
    empty::T
end

struct _ExactRuleOutput{T} end

struct _CompiledRuleAssignment{Key, E <: AbstractRuleExpression, S <: Tuple, P}
    expression::E
    cell_type_ids::S
    output_policy::P
end

struct _CompiledRulePhase{A <: Tuple}
    assignments::A
end

"""
One isbits lifecycle effect containing the complete ordered Level 1 property-rule program.

Keeping all phases in one effect makes phase order independent of lifecycle event sorting. Each
phase first computes every output for one cell, then commits those outputs before evaluating the
next phase.
"""
struct _CompiledRuleProgram{P <: Tuple} <: CorePotts.AbstractLifecycleEffect
    phases::P
    event_id::UInt16
end

function _compiled_parameter_values(parameter::CellParameter,
        context::_LoweringContext)
    return Tuple((UInt32(CorePotts.value(CorePotts.CellTypeID(
        _biological_index(context, entry.key)))), entry.value)
        for entry in parameter.bindings)
end

function _compile_distribution(distribution::Bernoulli,
        rule::Rule, context::_LoweringContext)
    return Bernoulli(_compile_rule_expression(
        distribution.probability, rule, context))
end

function _compile_distribution(distribution::Uniform,
        rule::Rule, context::_LoweringContext)
    return Uniform(
        _compile_rule_expression(distribution.lower, rule, context),
        _compile_rule_expression(distribution.upper, rule, context))
end

function _compile_distribution(distribution::Normal,
        rule::Rule, context::_LoweringContext)
    return Normal(
        _compile_rule_expression(distribution.mean, rule, context),
        _compile_rule_expression(distribution.standard_deviation, rule, context))
end

_compile_rule_expression(expression::RuleLiteral, rule, context) = expression
_compile_rule_expression(expression::OwnerReference, rule, context) = expression
_compile_rule_expression(expression::NoChange, rule, context) = expression

_compile_query_filter(::AnyFiniteCell, context) = CorePotts.AnyFiniteCell()
function _compile_query_filter(filter::CellTypeFilter, context)
    cell_type = only(value for value in context.cell_types
        if semantic_identity(value) == filter.cell_type)
    return CorePotts.CellTypeFilter(CorePotts.CellTypeID(
        _biological_index(context, cell_type)))
end

function _compile_rule_expression(expression::SpatialQueryExpression, rule,
        context::_LoweringContext)
    filter = _compile_query_filter(expression.filter, context)
    medium_types = CorePotts.MediumTypeTable(Tuple(
        CorePotts.MediumID(index) =>
            CorePotts.CellTypeID(length(context.cell_types) + index)
        for index in eachindex(context.media)))
    operation = _compile_query_operation(expression.operation, context)
    return _CompiledSpatialQueryExpression(operation,
        context.query_relation, filter, medium_types)
end


_compile_query_operation(operation::AbstractSpatialQueryOperation, context) = operation
function _compile_query_operation(operation::NeighborPropertySumOperation, context)
    key = Symbol(_property_prefix(operation.property))
    return _CompiledNeighborPropertySumOperation{key}()
end
function _compile_query_operation(operation::NeighborPropertyMeanOperation, context)
    key = Symbol(_property_prefix(operation.property))
    return _CompiledNeighborPropertyMeanOperation{key, typeof(operation.empty)}(
        operation.empty)
end

function _compile_rule_expression(expression::PropertyRead, rule, context)
    key = Symbol(_property_prefix(expression.property))
    return _CompiledPropertyRead{key}()
end

function _compile_rule_expression(expression::CellParameterRead, rule,
        context::_LoweringContext)
    parameter = only(component for component in context.declarations
        if component isa CellParameter &&
           semantic_identity(component) == expression.parameter)
    return _CompiledCellParameterRead(
        _compiled_parameter_values(parameter, context))
end

function _compile_rule_expression(expression::ModelParameterRead, rule,
        context::_LoweringContext)
    parameter = only(component for component in context.declarations
        if component isa ModelParameter &&
           semantic_identity(component) == expression.parameter)
    return RuleLiteral(parameter.value)
end

function _compile_rule_expression(expression::ScalarCall, rule,
        context::_LoweringContext)
    arguments = map(argument -> _compile_rule_expression(argument, rule, context),
        expression.arguments)
    return ScalarCall(expression.operation, arguments)
end

function _compile_rule_expression(expression::ConditionalExpression, rule,
        context::_LoweringContext)
    return ConditionalExpression(
        _compile_rule_expression(expression.condition, rule, context),
        _compile_rule_expression(expression.if_true, rule, context),
        _compile_rule_expression(expression.if_false, rule, context))
end

function _compile_rule_expression(expression::RandomDraw, rule,
        context::_LoweringContext)
    label = something(expression.label, :draw)
    operation = _semantic_rng_code(rule.name, label, UInt16(0x03ff))
    distribution = expression.distribution isa UnitVector ?
        _CompiledUnitVector{Int(expression.distribution.dimensions),
            _context_real_type(context)}() :
        _compile_distribution(expression.distribution, rule, context)
    return _CompiledRandomDraw(distribution, UInt16(operation))
end

_context_real_type(::_LoweringContext{T}) where {T} = T

function _compile_rule_assignment(rule::Rule, context::_LoweringContext)
    key = Symbol(_property_prefix(rule.target))
    expression = _compile_rule_expression(rule.expression, rule, context)
    cell_type_ids = Tuple(UInt32(CorePotts.value(CorePotts.CellTypeID(
        _biological_index(context, cell_type)))) for cell_type in rule.cell_types)
    target = only(component for component in context.declarations
        if component isa CellProperty && semantic_identity(component) == rule.target)
    output_policy = _ExactRuleOutput{typeof(target.initial)}()
    return _CompiledRuleAssignment{key, typeof(expression), typeof(cell_type_ids),
        typeof(output_policy)}(expression, cell_type_ids, output_policy)
end

function _rule_phase_order(rules::Tuple)
    dependencies = Dict{SemanticName, Tuple}()
    for rule in rules
        dependencies[rule.phase.name] = rule.phase.after
    end
    remaining = Set(keys(dependencies))
    complete = Set{SemanticName}(dependency for predecessors in Base.values(dependencies)
        for dependency in predecessors if !haskey(dependencies, dependency))
    result = SemanticName[]
    while !isempty(remaining)
        ready = sort!(collect(identity for identity in remaining
            if all(dependency -> dependency in complete, dependencies[identity])))
        isempty(ready) && throw(ArgumentError(
            "rule phases contain a cycle or an unresolved predecessor"))
        for identity in ready
            push!(result, identity)
            push!(complete, identity)
            delete!(remaining, identity)
        end
    end
    return Tuple(result)
end

function _lower_rule_program(components::Tuple, context::_LoweringContext)
    rules = Tuple(component for component in components if component isa Rule)
    isempty(rules) && return ()
    phases = map(_rule_phase_order(rules)) do identity
        phase_rules = sort!(collect(rule for rule in rules
            if rule.phase.name == identity); by = rule -> _identity_text(rule.name))
        assignments = Tuple(_compile_rule_assignment(rule, context)
            for rule in phase_rules)
        _CompiledRulePhase(assignments)
    end
    event_id = _rule_program_event_id()
    effect = _CompiledRuleProgram(phases, event_id)
    isbits(effect) || throw(ArgumentError(
        "a portable Level 1 rule program must lower to an isbits effect"))
    event = CorePotts.LifecycleEvent(
        CorePotts.ActiveCellsTarget(), CorePotts.EveryMCS(),
        CorePotts.AlwaysLifecycleTrigger(), effect; semantic_id = event_id)
    return (event,)
end

@inline function _compiled_cell_parameter_value(values::Tuple, cell_type::UInt32)
    entry = first(values)
    entry[1] == cell_type && return entry[2]
    return _compiled_cell_parameter_value(Base.tail(values), cell_type, entry[2])
end

@inline function _compiled_cell_parameter_value(values::Tuple, cell_type::UInt32,
        fallback)
    entry = first(values)
    entry[1] == cell_type && return entry[2]
    return _compiled_cell_parameter_value(Base.tail(values), cell_type, fallback)
end

@inline _compiled_cell_parameter_value(::Tuple{}, cell_type::UInt32, fallback) = fallback

@inline _compiled_rule_evaluate(expression::RuleLiteral, state, cell, mcs,
    rng, seed, event_id) = expression.value
@inline _compiled_rule_evaluate(::OwnerReference, state, cell, mcs,
    rng, seed, event_id) = cell
@inline _compiled_rule_evaluate(::NoChange, state, cell, mcs,
    rng, seed, event_id) = NoChange()

@inline function _compiled_rule_evaluate(::_CompiledPropertyRead{Key}, state,
        cell, mcs, rng, seed, event_id) where {Key}
    values = getproperty(state.core.properties, Key)
    return @inbounds values[cell]
end

@inline function _compiled_rule_evaluate(expression::_CompiledCellParameterRead,
        state, cell, mcs, rng, seed, event_id)
    cell_type = @inbounds state.core.cell_types[cell]
    return _compiled_cell_parameter_value(expression.values, cell_type)
end

@inline function _compiled_rule_evaluate(expression::ScalarCall, state, cell,
        mcs, rng, seed, event_id)
    arguments = map(argument -> _compiled_rule_evaluate(
        argument, state, cell, mcs, rng, seed, event_id), expression.arguments)
    return _operation_value(expression.operation, arguments...)
end

@inline function _compiled_rule_evaluate(expression::ConditionalExpression,
        state, cell, mcs, rng, seed, event_id)
    condition = _compiled_rule_evaluate(
        expression.condition, state, cell, mcs, rng, seed, event_id)
    return condition ? _compiled_rule_evaluate(
        expression.if_true, state, cell, mcs, rng, seed, event_id) :
        _compiled_rule_evaluate(
            expression.if_false, state, cell, mcs, rng, seed, event_id)
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledSpatialQueryExpression{ContactEdgeCountOperation},
        state, cell, mcs, rng, seed, event_id)
    return CorePotts.contact_edge_count(state, state.domain, expression.relation,
        CorePotts.compiled_cell_owner(cell), expression.filter, expression.medium_types)
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledSpatialQueryExpression{ContactMeasureOperation},
        state, cell, mcs, rng, seed, event_id)
    return CorePotts.contact_measure(state, state.domain, expression.relation,
        CorePotts.compiled_cell_owner(cell), expression.filter, expression.medium_types)
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledSpatialQueryExpression{BoundarySiteCountOperation},
        state, cell, mcs, rng, seed, event_id)
    return CorePotts.boundary_site_count(state, state.domain, expression.relation,
        CorePotts.compiled_cell_owner(cell), expression.filter, expression.medium_types)
end

@inline _compiled_query_filter_matches(::CorePotts.AnyFiniteCell,
    state, cell) = true
@inline function _compiled_query_filter_matches(filter::CorePotts.CellTypeFilter,
        state, cell)
    return @inbounds state.core.cell_types[cell] == CorePotts.value(filter.id)
end

@inline function _compiled_neighbor_matches(expression::_CompiledSpatialQueryExpression,
        state, cell, other)
    other == cell && return false
    @inbounds state.core.active[other] != 0 || return false
    _compiled_query_filter_matches(expression.filter, state, other) || return false
    return CorePotts.owners_are_neighbors(state, state.domain, expression.relation,
        CorePotts.compiled_cell_owner(cell), CorePotts.compiled_cell_owner(other))
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledSpatialQueryExpression{NeighborCellCountOperation},
        state, cell, mcs, rng, seed, event_id)
    result = Int64(0)
    for other in 1:length(state.core.active)
        _compiled_neighbor_matches(expression, state, cell, other) && (result += 1)
    end
    return result
end

@inline _compiled_neighbor_property_values(
    ::_CompiledNeighborPropertySumOperation{Key}, state) where {Key} =
    getproperty(state.core.properties, Key)
@inline _compiled_neighbor_property_values(
    ::_CompiledNeighborPropertyMeanOperation{Key}, state) where {Key} =
    getproperty(state.core.properties, Key)

@inline function _compiled_neighbor_property_sum_count(
        expression::_CompiledSpatialQueryExpression{O}, state, cell) where {
        O <: Union{_CompiledNeighborPropertySumOperation,
            _CompiledNeighborPropertyMeanOperation}}
    values = _compiled_neighbor_property_values(expression.operation, state)
    result = zero(@inbounds(values[cell]))
    count = Int64(0)
    for other in 1:length(state.core.active)
        _compiled_neighbor_matches(expression, state, cell, other) || continue
        result += @inbounds values[other]
        count += 1
    end
    return result, count
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledSpatialQueryExpression{<:_CompiledNeighborPropertySumOperation},
        state, cell, mcs, rng, seed, event_id)
    result, _ = _compiled_neighbor_property_sum_count(expression, state, cell)
    return result
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledSpatialQueryExpression{<:_CompiledNeighborPropertyMeanOperation},
        state, cell, mcs, rng, seed, event_id)
    result, count = _compiled_neighbor_property_sum_count(expression, state, cell)
    return count == 0 ? expression.operation.empty : result / count
end

@inline function _compiled_draw_address(state, cell, mcs, event_id, operation)
    generation = @inbounds state.core.generations[cell]
    return CorePotts.compiled_lifecycle_rng_address(
        mcs, event_id, cell, generation, operation)
end

@inline function _compiled_rule_evaluate(expression::_CompiledRandomDraw{<:Bernoulli},
        state, cell, mcs, rng, seed, event_id)
    probability = _compiled_rule_evaluate(expression.distribution.probability,
        state, cell, mcs, rng, seed, event_id)
    address = _compiled_draw_address(
        state, cell, mcs, event_id, expression.operation)
    return CorePotts.bernoulli(rng, seed, address, probability)
end

@inline function _compiled_rule_evaluate(expression::_CompiledRandomDraw{<:Uniform},
        state, cell, mcs, rng, seed, event_id)
    lower = _compiled_rule_evaluate(expression.distribution.lower,
        state, cell, mcs, rng, seed, event_id)
    upper = _compiled_rule_evaluate(expression.distribution.upper,
        state, cell, mcs, rng, seed, event_id)
    T = float(promote_type(typeof(lower), typeof(upper)))
    address = _compiled_draw_address(
        state, cell, mcs, event_id, expression.operation)
    unit = CorePotts.uniform_open01(T, rng, seed, address)
    return lower + (upper - lower) * unit
end

@inline function _compiled_rule_evaluate(expression::_CompiledRandomDraw{<:Normal},
        state, cell, mcs, rng, seed, event_id)
    mean = _compiled_rule_evaluate(expression.distribution.mean,
        state, cell, mcs, rng, seed, event_id)
    standard_deviation = _compiled_rule_evaluate(
        expression.distribution.standard_deviation,
        state, cell, mcs, rng, seed, event_id)
    T = float(promote_type(typeof(mean), typeof(standard_deviation)))
    address = _compiled_draw_address(
        state, cell, mcs, event_id, expression.operation)
    return mean + standard_deviation *
        CorePotts.normal_box_muller(T, rng, seed, address)
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledRandomDraw{<:_CompiledUnitVector{2, T}},
        state, cell, mcs, rng, seed, event_id) where {T}
    address = _compiled_draw_address(
        state, cell, mcs, event_id, expression.operation)
    angle = T(2pi) * CorePotts.uniform_open01(T, rng, seed, address)
    return StaticArrays.SVector{2, T}(cos(angle), sin(angle))
end

@inline function _compiled_rule_evaluate(
        expression::_CompiledRandomDraw{<:_CompiledUnitVector{3, T}},
        state, cell, mcs, rng, seed, event_id) where {T}
    address = _compiled_draw_address(
        state, cell, mcs, event_id, expression.operation)
    z = T(2) * CorePotts.uniform_open01(T, rng, seed, address; lane = 1) - one(T)
    angle = T(2pi) * CorePotts.uniform_open01(T, rng, seed, address; lane = 3)
    radius = sqrt(max(zero(T), one(T) - z * z))
    return StaticArrays.SVector{3, T}(
        radius * cos(angle), radius * sin(angle), z)
end

@inline _coerce_compiled_rule_output(::NoChange, current, policy) = current
@inline _coerce_compiled_rule_output(value::T, current,
    ::_ExactRuleOutput{T}) where {T} = value
@inline _coerce_compiled_rule_output(value, current,
    ::_ExactRuleOutput{T}) where {T} = T(value)

@inline function _compiled_rule_value(assignment::_CompiledRuleAssignment{Key},
        state, cell, mcs, rng, seed, event_id) where {Key}
    cell_type = @inbounds state.core.cell_types[cell]
    applies = cell_type in assignment.cell_type_ids
    values = getproperty(state.core.properties, Key)
    current = @inbounds values[cell]
    if applies
        value = _compiled_rule_evaluate(
            assignment.expression, state, cell, mcs, rng, seed, event_id)
        return _coerce_compiled_rule_output(value, current, assignment.output_policy)
    end
    return current
end

CorePotts.compiled_effect_category(::_CompiledRuleProgram) =
    CorePotts.CompiledStagedPropertyEffect()
CorePotts.compiled_effect_stages(effect::_CompiledRuleProgram) = effect.phases

function _compiled_rule_assignment_workspace(
        ::_CompiledRuleAssignment{Key}, state) where {Key}
    values = getproperty(state.potts.storage.properties, Key)
    return similar(values)
end

function CorePotts.compiled_effect_workspace(effect::_CompiledRuleProgram,
        state, plan)
    stages = map(effect.phases) do phase
        map(assignment -> _compiled_rule_assignment_workspace(assignment, state),
            phase.assignments)
    end
    return CorePotts.CompiledStagedEffectWorkspace(stages)
end

@inline _evaluate_compiled_rule_stage!(::Tuple{}, ::Tuple{}, state, cell, mcs,
    rng, seed, event_id) = nothing
@inline function _evaluate_compiled_rule_stage!(assignments::Tuple,
        workspace::Tuple, state, cell, mcs, rng, seed, event_id)
    value = _compiled_rule_value(
        first(assignments), state, cell, mcs, rng, seed, event_id)
    @inbounds first(workspace)[cell] = value
    _evaluate_compiled_rule_stage!(Base.tail(assignments), Base.tail(workspace),
        state, cell, mcs, rng, seed, event_id)
    return nothing
end

@inline _commit_compiled_rule_stage!(::Tuple{}, ::Tuple{}, state, cell) = nothing
@inline function _commit_compiled_rule_stage!(assignments::Tuple,
        workspace::Tuple, state, cell)
    assignment = first(assignments)
    _commit_compiled_rule_stage_assignment!(
        assignment, first(workspace), state, cell)
    _commit_compiled_rule_stage!(Base.tail(assignments), Base.tail(workspace),
        state, cell)
    return nothing
end

@inline function _commit_compiled_rule_stage_assignment!(
        assignment::_CompiledRuleAssignment{Key}, workspace,
        state, cell) where {Key}
    cell_type = @inbounds state.core.cell_types[cell]
    if cell_type in assignment.cell_type_ids
        values = getproperty(state.core.properties, Key)
        @inbounds values[cell] = workspace[cell]
    end
    return nothing
end

@inline function CorePotts.compiled_evaluate_effect_stage!(
        effect::_CompiledRuleProgram, stage::_CompiledRulePhase, workspace::Tuple,
        state, cell, properties, mcs, rng, seed)
    _evaluate_compiled_rule_stage!(stage.assignments, workspace,
        state, cell, mcs, rng, seed, effect.event_id)
    return nothing
end

@inline function CorePotts.compiled_commit_effect_stage!(
        effect::_CompiledRuleProgram, stage::_CompiledRulePhase, workspace::Tuple,
        state, cell, properties, mcs, rng, seed)
    _commit_compiled_rule_stage!(stage.assignments, workspace, state, cell)
    return nothing
end
