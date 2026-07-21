"""Immutable semantic rule phase with explicit predecessor dependencies."""
struct Phase
    name::SemanticName
    after::Tuple
end

function Phase(name::Symbol; namespace::Namespace = Namespace(), after = ())
    dependencies = after isa Phase ? (after,) : Tuple(after)
    all(value -> value isa Phase, dependencies) || throw(ArgumentError(
        "phase dependencies must be Phase values"))
    identities = Tuple(semantic_identity(value) for value in dependencies)
    length(unique(identities)) == length(identities) || throw(ArgumentError(
        "phase dependencies must be unique"))
    identity = SemanticName(name; namespace)
    identity in identities && throw(ArgumentError("a phase cannot depend on itself"))
    return Phase(identity, identities)
end

semantic_identity(phase::Phase) = phase.name

function Base.show(io::IO, phase::Phase)
    print(io, "Phase(", repr(phase.name.name))
    isempty(phase.name.namespace.parts) || print(io, "; namespace=", phase.name.namespace)
    isempty(phase.after) || print(io, "; after=", phase.after)
    print(io, ')')
end

abstract type AbstractRuleExpression end

struct RuleLiteral{T} <: AbstractRuleExpression
    value::T
    function RuleLiteral(value::T) where {T}
        isbitstype(T) || throw(ArgumentError(
            "Level 1 rule literals must be immutable isbits values"))
        return new{T}(value)
    end
end

struct OwnerReference <: AbstractRuleExpression
    name::Symbol
end

struct PropertyRead <: AbstractRuleExpression
    property::SemanticName
    owner::Symbol
end

struct CellParameterRead <: AbstractRuleExpression
    parameter::SemanticName
    owner::Symbol
end

struct ModelParameterRead <: AbstractRuleExpression
    parameter::SemanticName
end

abstract type AbstractScalarOperation end
struct AddOperation <: AbstractScalarOperation end
struct SubtractOperation <: AbstractScalarOperation end
struct MultiplyOperation <: AbstractScalarOperation end
struct DivideOperation <: AbstractScalarOperation end
struct PowerOperation <: AbstractScalarOperation end
struct LessOperation <: AbstractScalarOperation end
struct LessEqualOperation <: AbstractScalarOperation end
struct GreaterOperation <: AbstractScalarOperation end
struct GreaterEqualOperation <: AbstractScalarOperation end
struct EqualOperation <: AbstractScalarOperation end
struct NotEqualOperation <: AbstractScalarOperation end
struct AndOperation <: AbstractScalarOperation end
struct OrOperation <: AbstractScalarOperation end
struct NotOperation <: AbstractScalarOperation end
struct MinOperation <: AbstractScalarOperation end
struct MaxOperation <: AbstractScalarOperation end
struct ClampOperation <: AbstractScalarOperation end
struct AbsOperation <: AbstractScalarOperation end
struct SqrtOperation <: AbstractScalarOperation end
struct ExpOperation <: AbstractScalarOperation end
struct LogOperation <: AbstractScalarOperation end
struct SinOperation <: AbstractScalarOperation end
struct CosOperation <: AbstractScalarOperation end
struct TanOperation <: AbstractScalarOperation end
struct IfElseOperation <: AbstractScalarOperation end

struct ScalarCall{O <: AbstractScalarOperation, A <: Tuple} <: AbstractRuleExpression
    operation::O
    arguments::A
end

struct ConditionalExpression{C <: AbstractRuleExpression,
        T <: AbstractRuleExpression, F <: AbstractRuleExpression} <: AbstractRuleExpression
    condition::C
    if_true::T
    if_false::F
end

"""Explicitly report that a rule performs no write for one owner."""
struct NoChange <: AbstractRuleExpression end

_rule_expression(value::AbstractRuleExpression) = value
_rule_expression(value) = RuleLiteral(value)

function _rule_reference(property::CellProperty, owner::OwnerReference)
    return PropertyRead(semantic_identity(property), owner.name)
end

(property::CellProperty)(owner::OwnerReference) = _rule_reference(property, owner)

function _rule_reference(parameter::CellParameter, owner::OwnerReference)
    return CellParameterRead(semantic_identity(parameter), owner.name)
end

function _rule_reference(parameter::ModelParameter, owner::OwnerReference)
    return ModelParameterRead(semantic_identity(parameter))
end

(parameter::CellParameter)(owner::OwnerReference) = _rule_reference(parameter, owner)
(parameter::ModelParameter)(owner::OwnerReference) = _rule_reference(parameter, owner)

_as_rule_expression(value::AbstractRuleExpression) = value
_as_rule_expression(value) = RuleLiteral(value)

Base.:+(left::AbstractRuleExpression, right) =
    ScalarCall(AddOperation(), (left, _as_rule_expression(right)))
Base.:+(left, right::AbstractRuleExpression) =
    ScalarCall(AddOperation(), (_as_rule_expression(left), right))
Base.:-(left::AbstractRuleExpression, right) =
    ScalarCall(SubtractOperation(), (left, _as_rule_expression(right)))
Base.:-(left::AbstractRuleExpression) = ScalarCall(SubtractOperation(), (left,))
Base.:*(left::AbstractRuleExpression, right) =
    ScalarCall(MultiplyOperation(), (left, _as_rule_expression(right)))
Base.:*(left, right::AbstractRuleExpression) =
    ScalarCall(MultiplyOperation(), (_as_rule_expression(left), right))
Base.:/(left::AbstractRuleExpression, right) =
    ScalarCall(DivideOperation(), (left, _as_rule_expression(right)))
Base.:^(left::AbstractRuleExpression, right) =
    ScalarCall(PowerOperation(), (left, _as_rule_expression(right)))
Base.:>=(left::AbstractRuleExpression, right) =
    ScalarCall(GreaterEqualOperation(), (left, _as_rule_expression(right)))
Base.:<=(left::AbstractRuleExpression, right) =
    ScalarCall(LessEqualOperation(), (left, _as_rule_expression(right)))
Base.:>(left::AbstractRuleExpression, right) =
    ScalarCall(GreaterOperation(), (left, _as_rule_expression(right)))
Base.:<(left::AbstractRuleExpression, right) =
    ScalarCall(LessOperation(), (left, _as_rule_expression(right)))

function _rule_reference(value, owner::OwnerReference)
    throw(ArgumentError(
        "$(typeof(value)) is not a registered Level 1 callable model reference"))
end

"""One immutable scalar property rule."""
struct Rule{E <: AbstractRuleExpression}
    name::SemanticName
    target::SemanticName
    cell_types::Tuple
    owner::Symbol
    expression::E
    phase::Phase
    source::Union{Nothing, SourceLocation}
end

function Rule(target::CellProperty, owner::Symbol, expression;
        phase::Phase, name::Union{Nothing, Symbol} = nothing,
        namespace::Namespace = Namespace(), source::Union{Nothing, SourceLocation} = nothing)
    identity = name === nothing ? Symbol(target.name.name, "__", phase.name.name, "__rule") : name
    return Rule(SemanticName(identity; namespace), semantic_identity(target),
        target.cell_types, owner, _rule_expression(expression), phase, source)
end

semantic_identity(rule::Rule) = rule.name

function Base.show(io::IO, rule::Rule)
    print(io, "Rule(", repr(rule.name.name), "; target=", rule.target,
        ", phase=", rule.phase.name, ')')
end

"""An atomic group of property rules that read one phase snapshot."""
struct RuleGroup{R <: Tuple}
    name::SemanticName
    rules::R
    phase::Phase
    source::Union{Nothing, SourceLocation}
end

function RuleGroup(rules::Tuple; name::Symbol = :rule_group,
        namespace::Namespace = Namespace(), source::Union{Nothing, SourceLocation} = nothing)
    isempty(rules) && throw(ArgumentError("a rule group must contain at least one rule"))
    all(rule -> rule isa Rule, rules) || throw(ArgumentError(
        "a rule group may contain only Rule values"))
    phases = unique(rule.phase for rule in rules)
    length(phases) == 1 || throw(ArgumentError(
        "every rule in an atomic group must use the same phase"))
    targets = map(rule -> rule.target, rules)
    length(unique(targets)) == length(targets) || throw(ArgumentError(
        "an atomic rule group cannot write one property more than once"))
    return RuleGroup(SemanticName(name; namespace), rules, only(phases), source)
end

semantic_identity(group::RuleGroup) = group.name
_flatten_declaration(group::RuleGroup) = group.rules

function Base.show(io::IO, group::RuleGroup)
    print(io, "RuleGroup(", repr(group.name.name), "; ", length(group.rules),
        " rules, phase=", group.phase.name, ')')
end

"""A named pure state-dependent lifecycle predicate."""
struct TriggerRule{E <: AbstractRuleExpression}
    name::SemanticName
    owner::Symbol
    expression::E
    source::Union{Nothing, SourceLocation}
end

function TriggerRule(name::Symbol, owner::Symbol, expression;
        namespace::Namespace = Namespace(), source::Union{Nothing, SourceLocation} = nothing)
    return TriggerRule(SemanticName(name; namespace), owner,
        _rule_expression(expression), source)
end

semantic_identity(trigger::TriggerRule) = trigger.name

function Base.show(io::IO, trigger::TriggerRule)
    print(io, "TriggerRule(", repr(trigger.name.name), "; phase_snapshot_owner=",
        repr(trigger.owner), ')')
end

function _property_at_least(expression::ScalarCall{GreaterEqualOperation})
    left, right = expression.arguments
    left isa PropertyRead && right isa RuleLiteral || return nothing
    right.value isa Real || return nothing
    return CorePotts.PropertyAtLeast(
        Symbol(_property_prefix(left.property)), right.value)
end

_property_at_least(expression) = nothing

function _lifecycle_trigger(trigger::TriggerRule)
    lowered = _property_at_least(trigger.expression)
    lowered === nothing && throw(ArgumentError(
        "the initial lifecycle trigger compiler supports `property(cell) >= literal`; " *
        "use a typed CorePotts trigger for another qualified predicate"))
    return lowered
end

EveryMCS() = CorePotts.EveryMCS()
function EveryMCS(period::Integer; start::Integer = period)
    return CorePotts.PeriodicMCS(start, period)
end
AtMCS(mcs::Integer) = CorePotts.OnceAtMCS(mcs)
AtMCS(boundaries) = CorePotts.AtMCS(boundaries)
BetweenMCS(start::Integer, stop::Integer; every::Integer = 1) =
    CorePotts.PeriodicMCS(start, every; stop)

_operation_value(::AddOperation, left, right) = left + right
_operation_value(::SubtractOperation, left, right) = left - right
_operation_value(::SubtractOperation, value) = -value
_operation_value(::MultiplyOperation, left, right) = left * right
_operation_value(::DivideOperation, left, right) = left / right
_operation_value(::PowerOperation, left, right) = left^right
_operation_value(::LessOperation, left, right) = left < right
_operation_value(::LessEqualOperation, left, right) = left <= right
_operation_value(::GreaterOperation, left, right) = left > right
_operation_value(::GreaterEqualOperation, left, right) = left >= right
_operation_value(::EqualOperation, left, right) = left == right
_operation_value(::NotEqualOperation, left, right) = left != right
_operation_value(::AndOperation, left, right) = left && right
_operation_value(::OrOperation, left, right) = left || right
_operation_value(::NotOperation, value) = !value
_operation_value(::MinOperation, values...) = min(values...)
_operation_value(::MaxOperation, values...) = max(values...)
_operation_value(::ClampOperation, value, lower, upper) = clamp(value, lower, upper)
_operation_value(::AbsOperation, value) = abs(value)
_operation_value(::SqrtOperation, value) = sqrt(value)
_operation_value(::ExpOperation, value) = exp(value)
_operation_value(::LogOperation, value) = log(value)
_operation_value(::SinOperation, value) = sin(value)
_operation_value(::CosOperation, value) = cos(value)
_operation_value(::TanOperation, value) = tan(value)
_operation_value(::IfElseOperation, condition, if_true, if_false) =
    ifelse(condition, if_true, if_false)

_reference_value(values::NamedTuple, identity::SemanticName) =
    getproperty(values, identity.name)
_reference_value(values::AbstractDict, identity::SemanticName) = values[identity]

evaluate(expression::RuleLiteral, values) = expression.value
evaluate(::OwnerReference, values) = values
evaluate(expression::PropertyRead, values) = _reference_value(values, expression.property)
evaluate(expression::CellParameterRead, values) =
    _reference_value(values, expression.parameter)
evaluate(expression::ModelParameterRead, values) =
    _reference_value(values, expression.parameter)
function evaluate(expression::ScalarCall, values)
    arguments = map(argument -> evaluate(argument, values), expression.arguments)
    return _operation_value(expression.operation, arguments...)
end
function evaluate(expression::ConditionalExpression, values)
    return evaluate(expression.condition, values) ?
        evaluate(expression.if_true, values) : evaluate(expression.if_false, values)
end
evaluate(::NoChange, values) = NoChange()
evaluate(rule::Union{Rule, TriggerRule}, values) = evaluate(rule.expression, values)

_expression_reads(::RuleLiteral) = ()
_expression_reads(::OwnerReference) = ()
_expression_reads(expression::PropertyRead) = (expression.property,)
_expression_reads(expression::CellParameterRead) = (expression.parameter,)
_expression_reads(expression::ModelParameterRead) = (expression.parameter,)
_expression_reads(expression::ScalarCall) = Tuple(unique(identity
    for argument in expression.arguments for identity in _expression_reads(argument)))
_expression_reads(expression::ConditionalExpression) = Tuple(unique(identity
    for branch in (expression.condition, expression.if_true, expression.if_false)
    for identity in _expression_reads(branch)))
_expression_reads(::NoChange) = ()

_normalize_rule_expression(expression::RuleLiteral{<:AbstractFloat}, ::Type{T}) where {T} =
    RuleLiteral(T(expression.value))
_normalize_rule_expression(expression::RuleLiteral, ::Type) = expression
_normalize_rule_expression(expression::Union{OwnerReference, PropertyRead,
    CellParameterRead, ModelParameterRead, NoChange}, ::Type) = expression
function _normalize_rule_expression(expression::ScalarCall, type::Type)
    arguments = map(argument -> _normalize_rule_expression(argument, type),
        expression.arguments)
    return ScalarCall(expression.operation, arguments)
end
function _normalize_rule_expression(expression::ConditionalExpression, type::Type)
    return ConditionalExpression(
        _normalize_rule_expression(expression.condition, type),
        _normalize_rule_expression(expression.if_true, type),
        _normalize_rule_expression(expression.if_false, type))
end

function _normalize_component(rule::Rule, ::Type{T}) where {T <: AbstractFloat}
    expression = _normalize_rule_expression(rule.expression, T)
    return Rule(rule.name, rule.target, rule.cell_types, rule.owner,
        expression, rule.phase, rule.source)
end

_canonical_write(io::IO, phase::Phase) = _canonical_fields(io, phase)
function _canonical_write(io::IO, operation::AbstractScalarOperation)
    _canonical_open(io, operation)
    _canonical_write(io, Symbol(nameof(typeof(operation))))
    return _canonical_close(io)
end
_canonical_write(io::IO, expression::AbstractRuleExpression) = _canonical_fields(io, expression)
function _canonical_write(io::IO, rule::Rule)
    _canonical_open(io, rule)
    _canonical_write(io, rule.name)
    _canonical_write(io, rule.target)
    _canonical_write(io, rule.cell_types)
    _canonical_write(io, rule.owner)
    _canonical_write(io, rule.expression)
    _canonical_write(io, rule.phase)
    return _canonical_close(io)
end

function _validate_declaration(rule::Rule, context::_ValidationContext)
    diagnostics = ()
    target_index = findfirst(component -> semantic_identity(component) == rule.target,
        context.components)
    if target_index === nothing || !(context.components[target_index] isa CellProperty)
        diagnostics = (diagnostics..., Diagnostic(:error, :unknown_rule_target,
            "rule target must name a declared CellProperty";
            identity = rule.name, related = (rule.target,), source = rule.source,
            correction = "declare the property before constructing the model"))
    end
    for cell_type in rule.cell_types
        cell_type in context.cell_types || (diagnostics = (diagnostics..., Diagnostic(
            :error, :unknown_cell_type, "rule scope references an undeclared cell type";
            identity = rule.name, related = (cell_type,), source = rule.source,
            correction = "declare the cell type or correct the target property scope")))
    end
    for identity in _expression_reads(rule.expression)
        index = findfirst(component -> semantic_identity(component) == identity,
            context.components)
        index !== nothing && context.components[index] isa Union{
            CellProperty, CellParameter, ModelParameter} ||
            (diagnostics = (diagnostics..., Diagnostic(:error, :unknown_rule_read,
                "rule expression reads an undeclared or incompatible property";
                identity = rule.name, related = (identity,), source = rule.source,
                correction = "declare a compatible typed property reference")))
    end
    _qualified_rule_increment(rule, context) ||
        (diagnostics = (diagnostics..., Diagnostic(
        :error, :unqualified_rule_lowering,
        "this rule is valid Level 1 syntax but has no qualified runtime lowering yet";
        identity = rule.name, source = rule.source,
        correction = "the current executable slice supports `property(cell) = property(cell) + literal`"),))
    return diagnostics
end

function _rule_increment_expression(rule::Rule)
    expression = rule.expression
    expression isa ScalarCall{AddOperation} || return nothing
    length(expression.arguments) == 2 || return nothing
    left, right = expression.arguments
    left isa PropertyRead && left.property == rule.target && return right
    right isa PropertyRead && right.property == rule.target && return left
    return nothing
end


function _qualified_rule_increment(rule::Rule, context::_ValidationContext)
    increment = _rule_increment_expression(rule)
    increment isa RuleLiteral && return increment.value isa Real
    identity = increment isa CellParameterRead ? increment.parameter :
        increment isa ModelParameterRead ? increment.parameter : nothing
    identity === nothing && return false
    index = findfirst(component -> semantic_identity(component) == identity,
        context.components)
    index === nothing && return false
    declaration = context.components[index]
    return declaration isa CellParameter || declaration isa ModelParameter
end

function _rule_increment(rule::Rule)
    increment = _rule_increment_expression(rule)
    return increment isa RuleLiteral && increment.value isa Real ? increment.value : nothing
end

_property_write_target(rule::Rule) = (rule.target, :value)
_lifecycle_event_id(rule::Rule) =
    UInt16(1 + _semantic_rng_code(rule.name, :event, UInt16(0x0ffe)))

function _lower_component(rule::Rule, context::_LoweringContext)
    increment = _rule_increment_expression(rule)
    increment === nothing && throw(ArgumentError(
        "rule $(rule.name) has no qualified runtime lowering"))
    if increment isa RuleLiteral && increment.value isa Real
        update = PropertyUpdate(rule.target, rule.cell_types...;
            name = rule.name.name, namespace = rule.name.namespace,
            role = :value, amount = increment.value, schedule = CorePotts.EveryMCS())
        return _lower_component(update, context)
    elseif increment isa ModelParameterRead
        parameter = only(component for component in context.declarations
            if semantic_identity(component) == increment.parameter)
        update = PropertyUpdate(rule.target, rule.cell_types...;
            name = rule.name.name, namespace = rule.name.namespace,
            role = :value, amount = parameter.value, schedule = CorePotts.EveryMCS())
        return _lower_component(update, context)
    elseif increment isa CellParameterRead
        parameter = only(component for component in context.declarations
            if semantic_identity(component) == increment.parameter)
        lowered = _LoweredComponents()
        for cell_type in rule.cell_types
            amount = parameter.bindings[cell_type]
            suffix = Base.replace(
                _identity_text(semantic_identity(cell_type)), '.' => '_')
            update = PropertyUpdate(rule.target, cell_type;
                name = Symbol(rule.name.name, "__", suffix),
                namespace = rule.name.namespace, role = :value, amount,
                schedule = CorePotts.EveryMCS())
            lowered = _merge_lowered(lowered, _lower_component(update, context))
        end
        return lowered
    end
    throw(ArgumentError("rule $(rule.name) has no qualified runtime lowering"))
end

function _declaration_report(rule::Rule)
    reads = _expression_reads(rule.expression)
    return DeclarationReport(rule.name, :property_rule,
        (rule.target, rule.cell_types..., reads...), (), (:simultaneous_property_write,), (),
        (:Level1Rule, :LifecycleEvent),
        (target = rule.target, owner = rule.owner, phase = rule.phase.name,
            after = rule.phase.after, reads, source = rule.source),
        CorePotts.ScientificCapabilities())
end

function _scope_declaration(rule::Rule, fragment::ModelFragment, mapping)
    target = _mapped_identity(mapping, rule.target)
    expression = _scope_rule_expression(rule.expression, mapping)
    phase = Phase(_mapped_identity(mapping, rule.phase.name),
        Tuple(_mapped_identity(mapping, value) for value in rule.phase.after))
    return Rule(_mapped_identity(mapping, rule.name), target,
        Tuple(_scope_biological(value, mapping) for value in rule.cell_types),
        rule.owner, expression, phase, rule.source)
end

_scope_rule_expression(expression::PropertyRead, mapping) =
    PropertyRead(_mapped_identity(mapping, expression.property), expression.owner)
_scope_rule_expression(expression::CellParameterRead, mapping) =
    CellParameterRead(_mapped_identity(mapping, expression.parameter), expression.owner)
_scope_rule_expression(expression::ModelParameterRead, mapping) =
    ModelParameterRead(_mapped_identity(mapping, expression.parameter))
function _scope_rule_expression(expression::ScalarCall, mapping)
    return ScalarCall(expression.operation,
        map(argument -> _scope_rule_expression(argument, mapping), expression.arguments))
end

function _validate_declaration(parameter::CellParameter, context::_ValidationContext)
    diagnostics = ()
    for binding in parameter.bindings
        binding.key in context.cell_types || (diagnostics = (diagnostics..., Diagnostic(
            :error, :unknown_cell_type,
            "cell parameter binding references an undeclared cell type";
            identity = parameter.name, related = (binding.key,),
            correction = "declare the cell type or remove the binding")))
    end
    return diagnostics
end

_validate_declaration(::ModelParameter, context::_ValidationContext) = ()

function _normalize_component(parameter::CellParameter, ::Type{T}) where {T <: AbstractFloat}
    V = eltype(Tuple(values(parameter.bindings)))
    V <: AbstractFloat || return parameter
    entries = Tuple(Binding{CellType, T}(entry.key, T(entry.value))
        for entry in parameter.bindings)
    return CellParameter(parameter.name, BindingTable{CellType, T}(entries))
end

function _normalize_component(parameter::ModelParameter{V}, ::Type{T}) where {
        V <: AbstractFloat, T <: AbstractFloat}
    return ModelParameter(parameter.name, T(parameter.value))
end

_canonical_write(io::IO, parameter::Union{CellParameter, ModelParameter}) =
    _canonical_fields(io, parameter)

_lower_component(::Union{CellParameter, ModelParameter}, context::_LoweringContext) =
    _LoweredComponents()

function _declaration_report(parameter::CellParameter)
    return DeclarationReport(parameter.name, :cell_parameter,
        Tuple(keys(parameter.bindings)), (), (:immutable_parameter_read,), (), (),
        (bindings = Tuple((cell_type = semantic_identity(entry.key), value = entry.value)
            for entry in parameter.bindings),), CorePotts.ScientificCapabilities())
end

function _declaration_report(parameter::ModelParameter)
    return DeclarationReport(parameter.name, :model_parameter, (), (),
        (:immutable_parameter_read,), (), (), (value = parameter.value,),
        CorePotts.ScientificCapabilities())
end

function _scope_declaration(parameter::CellParameter{T}, fragment::ModelFragment,
        mapping) where {T}
    entries = Tuple(Binding{CellType, T}(_scope_biological(entry.key, mapping),
        entry.value) for entry in parameter.bindings)
    return CellParameter(_mapped_identity(mapping, parameter.name),
        BindingTable{CellType, T}(entries))
end

function _scope_declaration(parameter::ModelParameter, fragment::ModelFragment, mapping)
    return ModelParameter(_mapped_identity(mapping, parameter.name), parameter.value)
end
function _scope_rule_expression(expression::ConditionalExpression, mapping)
    return ConditionalExpression(
        _scope_rule_expression(expression.condition, mapping),
        _scope_rule_expression(expression.if_true, mapping),
        _scope_rule_expression(expression.if_false, mapping))
end
_scope_rule_expression(expression, mapping) = expression

function _phase_diagnostics(components::Tuple)
    rules = Tuple(component for component in components if component isa Rule)
    isempty(rules) && return ()
    diagnostics = ()
    phases = Dict{SemanticName, Tuple}()
    sources = Dict{SemanticName, Union{Nothing, SourceLocation}}()
    for rule in rules
        identity = rule.phase.name
        if haskey(phases, identity) && phases[identity] != rule.phase.after
            diagnostics = (diagnostics..., Diagnostic(:error,
                :inconsistent_phase_definition,
                "one phase identity has conflicting predecessor definitions";
                identity, related = (phases[identity], rule.phase.after),
                source = rule.source,
                correction = "reuse one Phase value for every rule in that phase"))
        else
            phases[identity] = rule.phase.after
            sources[identity] = rule.source
        end
    end
    function visit(identity, active::Set{SemanticName}, complete::Set{SemanticName})
        identity in complete && return false
        identity in active && return true
        push!(active, identity)
        for dependency in get(phases, identity, ())
            visit(dependency, active, complete) && return true
        end
        delete!(active, identity)
        push!(complete, identity)
        return false
    end
    complete = Set{SemanticName}()
    for identity in keys(phases)
        visit(identity, Set{SemanticName}(), complete) || continue
        diagnostics = (diagnostics..., Diagnostic(:error, :phase_dependency_cycle,
            "rule phase dependencies must form a directed acyclic graph";
            identity, source = sources[identity],
            correction = "remove one dependency from the reported phase cycle"))
    end
    return diagnostics
end

const _RULE_OPERATIONS = Dict{Symbol, DataType}(
    :+ => AddOperation, :- => SubtractOperation, :* => MultiplyOperation,
    :/ => DivideOperation, :^ => PowerOperation, :< => LessOperation,
    :<= => LessEqualOperation, :> => GreaterOperation, :>= => GreaterEqualOperation,
    :(==) => EqualOperation, :(!=) => NotEqualOperation, :! => NotOperation,
    :min => MinOperation, :max => MaxOperation, :clamp => ClampOperation,
    :abs => AbsOperation, :sqrt => SqrtOperation, :exp => ExpOperation,
    :log => LogOperation, :sin => SinOperation, :cos => CosOperation,
    :tan => TanOperation, :ifelse => IfElseOperation,
)

function _macro_rule_expression(expression, owner::Symbol)
    expression isa LineNumberNode && return nothing
    expression isa QuoteNode && return _macro_rule_expression(expression.value, owner)
    expression isa Union{Number, Bool, Char} &&
        return :($(GlobalRef(@__MODULE__, :RuleLiteral))($(QuoteNode(expression))))
    expression isa Symbol && expression === owner &&
        return :($(GlobalRef(@__MODULE__, :OwnerReference))($(QuoteNode(owner))))
    expression isa Symbol && throw(ArgumentError(
        "bare name `$expression` is not a Level 1 value; call a typed reference or interpolate it"))
    expression isa Expr || throw(ArgumentError(
        "unsupported Level 1 rule literal $(repr(expression))"))

    if expression.head === :$
        return :($(GlobalRef(@__MODULE__, :_rule_expression))($(esc(only(expression.args)))))
    elseif expression.head === :&& || expression.head === :||
        operation = expression.head === :&& ? AndOperation : OrOperation
        arguments = map(value -> _macro_rule_expression(value, owner), expression.args)
        return :($(GlobalRef(@__MODULE__, :ScalarCall))($operation(), ($(arguments...),)))
    elseif expression.head === :if
        length(expression.args) == 3 || throw(ArgumentError(
            "Level 1 if expressions require an explicit else branch"))
        condition, if_true, if_false = map(
            value -> _macro_rule_expression(value, owner), expression.args)
        return :($(GlobalRef(@__MODULE__, :ConditionalExpression))(
            $condition, $if_true, $if_false))
    elseif expression.head === :block
        values = filter(value -> !(value isa LineNumberNode), expression.args)
        length(values) == 1 || throw(ArgumentError(
            "multi-expression rule blocks require the local-binding compiler"))
        return _macro_rule_expression(only(values), owner)
    elseif expression.head !== :call
        throw(ArgumentError("unsupported Level 1 syntax `$(expression.head)`"))
    end

    function_name = first(expression.args)
    arguments = @view expression.args[2:end]
    function_name === :NoChange && isempty(arguments) &&
        return :($(GlobalRef(@__MODULE__, :NoChange))())
    if function_name isa Symbol && haskey(_RULE_OPERATIONS, function_name)
        operation = _RULE_OPERATIONS[function_name]
        lowered = map(value -> _macro_rule_expression(value, owner), arguments)
        return :($(GlobalRef(@__MODULE__, :ScalarCall))($operation(), ($(lowered...),)))
    end
    function_name isa Symbol || throw(ArgumentError(
        "Level 1 callable references must use a simple typed Julia binding"))
    length(arguments) == 1 || throw(ArgumentError(
        "a Level 1 property reference requires exactly one owner argument"))
    argument = _macro_rule_expression(only(arguments), owner)
    return :($(GlobalRef(@__MODULE__, :_rule_reference))(
        $(esc(function_name)), $argument))
end

function _macro_assignment(expression)
    expression isa Expr && expression.head === :(=) || throw(ArgumentError(
        "a Level 1 rule must use `property(owner) = expression`"))
    target, value = expression.args
    target isa Expr && target.head === :call && length(target.args) == 2 ||
        throw(ArgumentError("a Level 1 rule target must be `property(owner)`"))
    property, owner = target.args
    property isa Symbol && owner isa Symbol || throw(ArgumentError(
        "a Level 1 rule target must use simple property and owner bindings"))
    return property, owner, value
end

function _macro_phase(expression)
    expression isa Expr && expression.head === :(=) && expression.args[1] === :phase ||
        throw(ArgumentError("a Level 1 rule requires `phase = phase_value`"))
    return expression.args[2]
end

function _source_expression(source::LineNumberNode)
    return :($(GlobalRef(@__MODULE__, :SourceLocation))(
        $(string(source.file)), $(source.line)))
end

macro rule(phase_expression, assignment)
    phase = _macro_phase(phase_expression)
    property, owner, value = _macro_assignment(assignment)
    lowered = _macro_rule_expression(value, owner)
    source = _source_expression(__source__)
    return :($(GlobalRef(@__MODULE__, :Rule))(
        $(esc(property)), $(QuoteNode(owner)), $lowered;
        phase = $(esc(phase)), source = $source))
end

macro rules(phase_expression, block)
    phase = _macro_phase(phase_expression)
    block isa Expr && block.head === :block || throw(ArgumentError(
        "`@rules` requires a begin/end block"))
    assignments = filter(value -> !(value isa LineNumberNode), block.args)
    isempty(assignments) && throw(ArgumentError("`@rules` requires at least one assignment"))
    rules = map(assignments) do assignment
        property, owner, value = _macro_assignment(assignment)
        lowered = _macro_rule_expression(value, owner)
        :($(GlobalRef(@__MODULE__, :Rule))(
            $(esc(property)), $(QuoteNode(owner)), $lowered;
            phase = $(esc(phase)), source = $(_source_expression(__source__))))
    end
    return :($(GlobalRef(@__MODULE__, :RuleGroup))(($(rules...),);
        source = $(_source_expression(__source__))))
end

macro trigger(assignment)
    name, owner, value = _macro_assignment(assignment)
    lowered = _macro_rule_expression(value, owner)
    return :($(GlobalRef(@__MODULE__, :TriggerRule))(
        $(QuoteNode(name)), $(QuoteNode(owner)), $lowered;
        source = $(_source_expression(__source__))))
end
