struct ConnectivityConstraint <: AbstractPenalty{Rigid} end

@inline function evaluate_penalty(penalty::ConnectivityConstraint, ctx)
    _eval_connectivity(ctx.topology, penalty, ctx)
end

@inline function _eval_connectivity(::Union{MooreTopology{2}, NoFluxMooreTopology{2}}, penalty, ctx)
    if ctx.src == 0
        return 0.0f0
    end

    n = ctx.neighbors
    s = ctx.src

    # Assuming Moore topology offsets CCW: E, NE, N, NW, W, SW, S, SE
    v0 = n[1] == s ? 1 : 0
    v1 = n[2] == s ? 1 : 0
    v2 = n[3] == s ? 1 : 0
    v3 = n[4] == s ? 1 : 0
    v4 = n[5] == s ? 1 : 0
    v5 = n[6] == s ? 1 : 0
    v6 = n[7] == s ? 1 : 0
    v7 = n[8] == s ? 1 : 0

    # Rutovitz crossing number X_8
    X8 = (v0 != v1) + (v1 != v2) + (v2 != v3) + (v3 != v4) +
         (v4 != v5) + (v5 != v6) + (v6 != v7) + (v7 != v0)

    if X8 == 2
        return 0.0f0
    elseif X8 == 0 && (v0 + v1 + v2 + v3 + v4 + v5 + v6 + v7) == 0
        return 0.0f0
    end

    return typemax(Float32)
end

@inline function _eval_connectivity(::Any, penalty, ctx)
    # Connectivity check is only supported for 2D Moore topologies.
    # We fallback to allowing all moves (0.0 energy penalty).
    return 0.0f0
end

required_variables(::ConnectivityConstraint) = (;)
