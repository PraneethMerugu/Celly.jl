module RuleMacros

using CorePotts
using MLStyle

export @rule

mutable struct ExtractionState
    count::Int
    spatial_rules::Vector{Expr}
end

"""
    @rule expression

Translates standard Julia syntax into CorePotts.CompiledRule for GPU evaluation.
Extracts spatial dependencies at compile-time to be bundled in the CompiledRule.
"""
macro rule(expr)
    state = ExtractionState(0, Expr[])
    transformed_expr = transform_rule(expr, state)
    spatial_tuple = Expr(:tuple, state.spatial_rules...)
    return quote
        CorePotts.RuleBuilder(
            ($(esc(:cell_data)), $(esc(:cell_id)), $(esc(:ctx)),
                $(esc(:current_val))) -> $(esc(transformed_expr));
            spatial_deps = $spatial_tuple
        )
    end
end

function transform_rule(expr, state::ExtractionState)
    @match expr begin
        # Interpolation: evaluate outer scope
        Expr(:$, arg) => arg

        # Property access: cell.property -> cell_data.property[cell_id]
        :(cell.$prop) => :(cell_data.$prop[cell_id])

        # Special spatial functions
        :(center_of_mass(:x)) => :(CorePotts.get_center_of_mass_x(cell_data, cell_id, ctx))
        :(center_of_mass(:y)) => :(CorePotts.get_center_of_mass_y(cell_data, cell_id, ctx))
        :(center_of_mass(:z)) => :(CorePotts.get_center_of_mass_z(cell_data, cell_id, ctx))
        :(major_axis_length()) =>
            :(CorePotts.get_major_axis_length(cell_data, cell_id, ctx))
        :(minor_axis_length()) =>
            :(CorePotts.get_minor_axis_length(cell_data, cell_id, ctx))

        # Special variables
        :(time()) => :(CorePotts.get_time(ctx))

        # Random generators
        :(rand()) =>
            :(CorePotts.gpu_rand_uniform(cell_id, ctx.step_counter, 1, 0.0f0, 1.0f0))
        :(rand(Float32)) =>
            :(CorePotts.gpu_rand_uniform(cell_id, ctx.step_counter, 1, 0.0f0, 1.0f0))
        :(randn()) =>
            :(CorePotts.gpu_rand_normal(cell_id, ctx.step_counter, 1, 0.0f0, 1.0f0))
        :(randn(Float32)) =>
            :(CorePotts.gpu_rand_normal(cell_id, ctx.step_counter, 1, 0.0f0, 1.0f0))
        :(random_uniform($min, $max)) => :(CorePotts.gpu_rand_uniform(
            cell_id, ctx.step_counter, 1, $(transform_rule(min, state)),
            $(transform_rule(max, state))))
        :(random_normal($mean, $std)) => :(CorePotts.gpu_rand_normal(
            cell_id, ctx.step_counter, 1, $(transform_rule(mean, state)),
            $(transform_rule(std, state))))

        # Identity assignment for nothing or None()
        :(nothing) => :current_val
        ::Nothing => :current_val
        :(None()) => :current_val

        # Map/reduce contacts and neighbors
        :(contact($type_id)) => begin
            state.count += 1
            push!(state.spatial_rules,
                :(CorePotts.ContactArea($(transform_rule(type_id, state)), $(state.count))))
            :(ctx.spatial_buffer[($(state.count) - 1) * length(cell_data.volumes) + cell_id])
        end
        :(medium_contact()) => begin
            state.count += 1
            push!(state.spatial_rules, :(CorePotts.ContactArea(0, $(state.count))))
            :(ctx.spatial_buffer[($(state.count) - 1) * length(cell_data.volumes) + cell_id])
        end
        :(neighbor_count($type_id)) => begin
            state.count += 1
            push!(state.spatial_rules,
                :(CorePotts.NeighborCount($(transform_rule(type_id, state)), $(state.count))))
            :(ctx.spatial_buffer[($(state.count) - 1) * length(cell_data.volumes) + cell_id])
        end
        :(neighbor_sum($prop, $type_id)) => begin
            state.count += 1
            prop_sym = prop isa QuoteNode ? prop.value : prop
            push!(state.spatial_rules,
                :(CorePotts.NeighborSum($(QuoteNode(prop_sym)),
                    $(transform_rule(type_id, state)), $(state.count))))
            :(ctx.spatial_buffer[($(state.count) - 1) * length(cell_data.volumes) + cell_id])
        end

        # Recursively transform function arguments
        Expr(:call, op, args...) =>
            Expr(:call, op, map(a -> transform_rule(a, state), args)...)

        # Recursively transform short-circuiting operators
        Expr(:&&, a, b) => Expr(:&&, transform_rule(a, state), transform_rule(b, state))
        Expr(:||, a, b) => Expr(:||, transform_rule(a, state), transform_rule(b, state))

        # Recursively transform if-statements
        Expr(:if, cond, t_branch) =>
            Expr(:if, transform_rule(cond, state), transform_rule(t_branch, state))
        Expr(:if, cond, t_branch, f_branch) => Expr(:if, transform_rule(cond, state),
            transform_rule(t_branch, state), transform_rule(f_branch, state))

        # Recursively transform blocks
        Expr(:block, args...) => Expr(:block, map(a -> transform_rule(a, state), args)...)

        # Return primitives and literals as is
        _ => expr
    end
end

end
