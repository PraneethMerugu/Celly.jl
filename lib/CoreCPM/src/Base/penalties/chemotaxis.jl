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
    N = length(ctx.grid_dims)
    F = eltype(p.lambdas)

    c_i = zero(F)
    c_j = zero(F)

    if N == 2
        c_i = F(p.chem_field[ctx.spatial_coords[1] + 1, ctx.spatial_coords[2] + 1])
        c_j = F(p.chem_field[ctx.source_coords[1] + 1, ctx.source_coords[2] + 1])
    elseif N == 3
        c_i = F(p.chem_field[ctx.spatial_coords[1] + 1, ctx.spatial_coords[2] + 1, ctx.spatial_coords[3] + 1])
        c_j = F(p.chem_field[ctx.source_coords[1] + 1, ctx.source_coords[2] + 1, ctx.source_coords[3] + 1])
    end

    dH = zero(F)
    if ctx.tgt != 0
        tgt_type = ctx.cell_data.cell_types[ctx.tgt]
        if tgt_type > 0
            dH -= F(p.lambdas[tgt_type + 1]) * (c_i - c_j)
        end
    end
    # As in classic CC3D, chemotaxis only biases the expanding cell's leading edge.
    # We do NOT apply an opposite penalty for the shrinking cell (ctx.src)
    return dH
end
