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

# ConstructionBase Overloads
struct AdhesionReconstructor{Trait, Iso} end
function (::AdhesionReconstructor{Trait, Iso})(J) where {Trait, Iso}
    AdhesionPenalty{Trait, typeof(J), Iso}(J)
end
function ConstructionBase.constructorof(::Type{<:AdhesionPenalty{
        Trait, MatrixT, Iso}}) where {Trait, MatrixT, Iso}
    AdhesionReconstructor{Trait, Iso}()
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

import ChainRulesCore

function _compute_adhesion_energy_and_gradients(p::AdhesionPenalty{FlexType}, u, params, isotropic::Bool) where {FlexType}
    F = eltype(p.J)
    
    # Avoid scalar indexing on GPU by pulling data to CPU (zero allocation if already on CPU)
    cpu_grid = u.grid isa Array ? u.grid : Array(u.grid)
    c_types = u.cell_data.cell_types isa Array ? u.cell_data.cell_types : Array(u.cell_data.cell_types)
    dims = size(cpu_grid)
    
    types_padded = vcat([1], Int.(c_types) .+ 1)
    
    if FlexType === Flex
        cpu_mods = u.cell_data.adhesion_modifiers isa Array ? u.cell_data.adhesion_modifiers : Array(u.cell_data.adhesion_modifiers)
        mods_padded = vcat([one(F)], cpu_mods)
    else
        mods_padded = nothing
    end
    
    offs = offsets(params.topology)
    weights = isotropic ? neighbor_weights(params.topology) : nothing
    
    E = zero(F)
    dE_dJ = zeros(F, size(p.J))
    
    for I in CartesianIndices(cpu_grid)
        src_val = cpu_grid[I]
        src_type = types_padded[src_val + 1]
        mod_src = FlexType === Flex ? mods_padded[src_val + 1] : one(F)
        
        for i in 1:length(offs)
            Δ = offs[i]
            w = isotropic ? F(weights[i]) : one(F)
            
            # Periodic wrapped index
            I_n = CartesianIndex(mod1.(Tuple(I) .+ Tuple(Δ), dims))
            n_val = cpu_grid[I_n]
            
            if src_val != n_val
                n_type = types_padded[n_val + 1]
                mod_n = FlexType === Flex ? mods_padded[n_val + 1] : one(F)
                
                term = w * mod_src * mod_n
                E += F(p.J[src_type, n_type]) * term
                dE_dJ[src_type, n_type] += term
            end
        end
    end
    
    E /= 2
    dE_dJ ./= 2
    
    return E, dE_dJ
end

function compute_global_energy(p::AdhesionPenalty{FlexType, M, Iso}, u, params) where {FlexType, M, Iso}
    E, _ = _compute_adhesion_energy_and_gradients(p, u, params, Iso)
    return E
end

function ChainRulesCore.rrule(::typeof(compute_global_energy), p::AdhesionPenalty{FlexType, M, Iso}, u, params) where {FlexType, M, Iso}
    E, dE_dJ = _compute_adhesion_energy_and_gradients(p, u, params, Iso)
    function compute_global_energy_pullback(ΔE)
        dJ = ΔE .* dE_dJ
        dp = ChainRulesCore.Tangent{typeof(p)}(J = dJ)
        return (ChainRulesCore.NoTangent(), dp, ChainRulesCore.NoTangent(), ChainRulesCore.NoTangent())
    end
    return E, compute_global_energy_pullback
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

required_variables(::AdhesionPenalty{Rigid}) = (;)
required_variables(::AdhesionPenalty{Flex}) = (adhesion_modifiers = Float32,)
