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

struct _CompiledRuleAssignment{Key, E <: AbstractRuleExpression, S <: Tuple}
    expression::E
    cell_type_ids::S
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

struct _CompiledRuleOutput{A, T}
    assignment::A
    value::T
    applies::Bool
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
    return _CompiledRuleAssignment{key, typeof(expression), typeof(cell_type_ids)}(
        expression, cell_type_ids)
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

@inline _coerce_compiled_rule_output(::NoChange, current) = current
@inline _coerce_compiled_rule_output(value, current) = convert(typeof(current), value)

@inline function _compiled_rule_output(assignment::_CompiledRuleAssignment{Key},
        state, cell, mcs, rng, seed, event_id) where {Key}
    cell_type = @inbounds state.core.cell_types[cell]
    applies = cell_type in assignment.cell_type_ids
    values = getproperty(state.core.properties, Key)
    current = @inbounds values[cell]
    if applies
        value = _compiled_rule_evaluate(
            assignment.expression, state, cell, mcs, rng, seed, event_id)
        return _CompiledRuleOutput(
            assignment, _coerce_compiled_rule_output(value, current), true)
    end
    return _CompiledRuleOutput(assignment, current, false)
end

@inline _compiled_rule_outputs(::Tuple{}, state, cell, mcs, rng, seed, event_id) = ()
@inline function _compiled_rule_outputs(assignments::Tuple, state, cell,
        mcs, rng, seed, event_id)
    output = _compiled_rule_output(
        first(assignments), state, cell, mcs, rng, seed, event_id)
    return (output, _compiled_rule_outputs(Base.tail(assignments), state,
        cell, mcs, rng, seed, event_id)...)
end

@inline _commit_compiled_rule_outputs!(::Tuple{}, state, cell) = nothing
@inline function _commit_compiled_rule_outputs!(outputs::Tuple, state, cell)
    output = first(outputs)
    _commit_compiled_rule_output!(output, state, cell)
    _commit_compiled_rule_outputs!(Base.tail(outputs), state, cell)
    return nothing
end

@inline function _commit_compiled_rule_output!(output::_CompiledRuleOutput{A},
        state, cell) where {Key, A <: _CompiledRuleAssignment{Key}}
    if output.applies
        values = getproperty(state.core.properties, Key)
        @inbounds values[cell] = output.value
    end
    return nothing
end

@inline _run_compiled_rule_phases!(::Tuple{}, state, cell, mcs,
    rng, seed, event_id) = nothing
@inline function _run_compiled_rule_phases!(phases::Tuple, state, cell,
        mcs, rng, seed, event_id)
    outputs = _compiled_rule_outputs(first(phases).assignments,
        state, cell, mcs, rng, seed, event_id)
    _commit_compiled_rule_outputs!(outputs, state, cell)
    _run_compiled_rule_phases!(Base.tail(phases),
        state, cell, mcs, rng, seed, event_id)
    return nothing
end

CorePotts.compiled_effect_category(::_CompiledRuleProgram) =
    CorePotts.CompiledPropertyEffect()

@inline function CorePotts.compiled_apply_effect!(effect::_CompiledRuleProgram,
        state, cell, properties, mcs, rng, seed)
    _run_compiled_rule_phases!(effect.phases, state, cell, mcs, rng, seed,
        effect.event_id)
    return nothing
end
