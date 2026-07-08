"""
    AdhesionPenalty(J_matrix)

Calculates the differential adhesion (surface tension) between cells of different types,
and between cells and the medium. Drives cell sorting and morphological clustering.
"""
struct AdhesionPenalty{
    FlexType <: FlexibilityTrait, MatrixT <: AbstractMatrix, Isotropic} <:
       AbstractPenalty{FlexType}
    J::MatrixT # Indexed by (cell_type1, cell_type2)
end

function AdhesionPenalty{Rigid}(J; isotropic::Bool = false)
    AdhesionPenalty{Rigid, typeof(J), isotropic}(J)
end
function AdhesionPenalty(J; isotropic::Bool = false)
    AdhesionPenalty{Rigid}(J; isotropic = isotropic)
end
function AdhesionPenalty{Flex}(J; isotropic::Bool = false)
    AdhesionPenalty{Flex, typeof(J), isotropic}(J)
end

@inline function get_adhesion_modifier(p::AdhesionPenalty{Rigid}, ctx, cell_id)
    return one(eltype(p.J))
end

@inline function get_adhesion_modifier(p::AdhesionPenalty{Flex}, ctx, cell_id)
    if cell_id == 0
        return one(eltype(p.J))
    else
        return eltype(p.J)(ctx.cell_data.adhesion_modifiers[cell_id])
    end
end

@inline function evaluate_penalty(
        p::AdhesionPenalty{
            FlexType, M, false}, ctx) where {FlexType, M}
    F = eltype(p.J)
    dH = zero(F)

    src_type = ctx.src == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.src]) + 1
    tgt_type = ctx.tgt == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.tgt]) + 1

    mod_src = get_adhesion_modifier(p, ctx, ctx.src)
    mod_tgt = get_adhesion_modifier(p, ctx, ctx.tgt)

    for n_val in ctx.neighbors
        n_type = n_val == 0 ? 1 : Int(ctx.cell_data.cell_types[n_val]) + 1
        mod_n = get_adhesion_modifier(p, ctx, n_val)

        # Subtracted old energy, add new energy
        if n_val != ctx.src
            dH -= F(p.J[src_type, n_type]) * mod_src * mod_n
        end
        if n_val != ctx.tgt
            dH += F(p.J[tgt_type, n_type]) * mod_tgt * mod_n
        end
    end

    return dH
end

function compute_global_energy(p::AdhesionPenalty{FlexType, M, false}, u, params) where {
        FlexType, M}
    E = 0.0f0
    # Global energy for adhesion involves summing over all pairs of neighbors in the grid.
    # To avoid double counting, we would divide by 2 or iterate pairs uniquely.
    # In a full SciML EBM training loop, we can just compute the sum over the grid.
    # This will be implemented fully in the OptimizationExt or handled natively.
    return E
end

@inline function evaluate_penalty(p::AdhesionPenalty{FlexType, M, true}, ctx) where {
        FlexType, M}
    F = eltype(p.J)
    dH = zero(F)

    src_type = ctx.src == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.src]) + 1
    tgt_type = ctx.tgt == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.tgt]) + 1

    mod_src = get_adhesion_modifier(p, ctx, ctx.src)
    mod_tgt = get_adhesion_modifier(p, ctx, ctx.tgt)

    weights = neighbor_weights(ctx.topology)

    for i in 1:length(ctx.neighbors)
        n_val = ctx.neighbors[i]
        n_type = n_val == 0 ? 1 : Int(ctx.cell_data.cell_types[n_val]) + 1
        mod_n = get_adhesion_modifier(p, ctx, n_val)
        w = F(weights[i])

        # Subtracted old energy, add new energy
        if n_val != ctx.src
            dH -= w * F(p.J[src_type, n_type]) * mod_src * mod_n
        end
        if n_val != ctx.tgt
            dH += w * F(p.J[tgt_type, n_type]) * mod_tgt * mod_n
        end
    end

    return dH
end
