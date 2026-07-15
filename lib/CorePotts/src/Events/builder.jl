# RuleBuilder and validation for CorePotts

export RuleBuilder, EventBuilder, build_rule, build_event, add_rule!, validate_closure!

"""
    RuleBuilder

A programmatic builder for `CompiledRule` objects.
Ensures that the provided closure matches the expected 4-argument signature:
`(cell_data, cell_id, ctx, current_val)` before wrapping it in a `CompiledRule`.
"""
struct RuleBuilder{F}
    closure::F
    spatial_deps::Tuple
end

function RuleBuilder(closure; spatial_deps = ())
    validate_closure!(closure)
    return RuleBuilder(closure, spatial_deps)
end

function build_rule(builder::RuleBuilder)
    return CompiledRule(builder.closure, builder.spatial_deps)
end

"""
    validate_closure!(closure)

Pre-flight validation to ensure the closure signature is structurally sound
before we send it to the GPU. Catches errors like 3-argument vs 4-argument mismatches.
"""
function validate_closure!(closure)
    # The expected signature is (cell_data, cell_id, ctx, current_val)
    # We use `applicable` with dummy generic types to ensure the method signature matches.
    if !applicable(closure, nothing, 1, nothing, nothing)
        error("""
        Invalid Rule Closure Signature!

        The provided closure does not accept the required 4 arguments:
        (cell_data, cell_id, ctx, current_val).

        If you generated this via a macro, there is a bug in the DSL parser.
        """)
    end
end

"""
    EventBuilder

A programmatic builder for constructing events with strongly-typed rules.
"""
struct EventBuilder
    event_type::Type{<:AbstractEvent}
    type_id::Int
    rules::Vector{RuleBuilder}
end

function EventBuilder(event_type::Type{<:AbstractEvent}, type_id::Int)
    return EventBuilder(event_type, type_id, RuleBuilder[])
end

function add_rule!(builder::EventBuilder, rule::RuleBuilder)
    push!(builder.rules, rule)
    return builder
end

function build_event(builder::EventBuilder)
    compiled_rules = Tuple(build_rule(r) for r in builder.rules)
    return builder.event_type(builder.type_id, compiled_rules)
end
