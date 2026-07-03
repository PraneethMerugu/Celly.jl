"""
    AdhesionPenalty(J_matrix)

Calculates the differential adhesion (surface tension) between cells of different types,
and between cells and the medium. Drives cell sorting and morphological clustering.
"""
struct AdhesionPenalty{MatrixT <: AbstractMatrix, Isotropic} <: AbstractPenalty
    J::MatrixT # Indexed by (cell_type1, cell_type2)
end

Adapt.adapt_structure(to, x::AdhesionPenalty{M, I}) where {M, I} = AdhesionPenalty{typeof(Adapt.adapt_structure(to, x.J)), I}(Adapt.adapt_structure(to, x.J))

AdhesionPenalty(J; isotropic::Bool=false) = AdhesionPenalty{typeof(J), isotropic}(J)

@inline function evaluate_penalty(p::AdhesionPenalty{M, false}, ctx) where M
    F = eltype(p.J)
    dH = zero(F)
    
    src_type = ctx.src == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.src]) + 1
    tgt_type = ctx.tgt == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.tgt]) + 1
    
    for n_val in ctx.neighbors
        n_type = n_val == 0 ? 1 : Int(ctx.cell_data.cell_types[n_val]) + 1
        
        # Subtracted old energy, add new energy
        if n_val != ctx.src
            dH -= F(p.J[src_type, n_type])
        end
        if n_val != ctx.tgt
            dH += F(p.J[tgt_type, n_type])
        end
    end
    
    return dH
end

function compute_global_energy(p::AdhesionPenalty{M, false}, u, params) where M
    E = 0.0f0
    # Global energy for adhesion involves summing over all pairs of neighbors in the grid.
    # To avoid double counting, we would divide by 2 or iterate pairs uniquely.
    # In a full SciML EBM training loop, we can just compute the sum over the grid.
    # This will be implemented fully in the OptimizationExt or handled natively.
    return E
end

@inline function evaluate_penalty(p::AdhesionPenalty{M, true}, ctx) where M
    F = eltype(p.J)
    dH = zero(F)
    
    src_type = ctx.src == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.src]) + 1
    tgt_type = ctx.tgt == 0 ? 1 : Int(ctx.cell_data.cell_types[ctx.tgt]) + 1
    
    weights = neighbor_weights(ctx.topology)
    
    for i in 1:length(ctx.neighbors)
        n_val = ctx.neighbors[i]
        n_type = n_val == 0 ? 1 : Int(ctx.cell_data.cell_types[n_val]) + 1
        w = F(weights[i])
        
        # Subtracted old energy, add new energy
        if n_val != ctx.src
            dH -= w * F(p.J[src_type, n_type])
        end
        if n_val != ctx.tgt
            dH += w * F(p.J[tgt_type, n_type])
        end
    end
    
    return dH
end
