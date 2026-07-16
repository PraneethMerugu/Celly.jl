"""
    ChemotaxisPenalty(lambdas, chemical_field)

Biases cell membrane extensions up (or down) a pre-computed spatial chemical gradient.
"""
struct ChemotaxisPenalty{FloatT <: AbstractVector, ArrayT <: AbstractArray} <:
       AbstractPenalty{Rigid}
    lambdas::FloatT
    chem_field::ArrayT
end

@inline function evaluate_penalty(p::ChemotaxisPenalty, ctx)
    return _eval_chemotaxis_penalty(p, ctx, Val(length(ctx.grid_dims)))
end

@inline function _eval_chemotaxis_penalty(p::ChemotaxisPenalty, ctx, ::Val{2})
    F = eltype(p.lambdas)
    c_i = F(p.chem_field[ctx.spatial_coords[1] + 1, ctx.spatial_coords[2] + 1])
    c_j = F(p.chem_field[ctx.source_coords[1] + 1, ctx.source_coords[2] + 1])

    dH = zero(F)
    if ctx.src != 0
        src_type = ctx.cell_data.cell_types[ctx.src]
        if src_type > 0
            dH -= F(p.lambdas[src_type + 1]) * (c_i - c_j)
        end
    end
    return dH
end

@inline function _eval_chemotaxis_penalty(p::ChemotaxisPenalty, ctx, ::Val{3})
    F = eltype(p.lambdas)
    c_i = F(p.chem_field[ctx.spatial_coords[1] + 1, ctx.spatial_coords[2] + 1, ctx.spatial_coords[3] + 1])
    c_j = F(p.chem_field[ctx.source_coords[1] + 1, ctx.source_coords[2] + 1, ctx.source_coords[3] + 1])

    dH = zero(F)
    if ctx.src != 0
        src_type = ctx.cell_data.cell_types[ctx.src]
        if src_type > 0
            dH -= F(p.lambdas[src_type + 1]) * (c_i - c_j)
        end
    end
    return dH
end

required_variables(::ChemotaxisPenalty) = (;)
