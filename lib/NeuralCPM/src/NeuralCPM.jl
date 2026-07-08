module NeuralCPM

using CoreCPM
using CoreCPM: CPMState, CPMParameters, LocalNeuralPenalty, AbstractPenalty

using Lux
using StaticArrays
using ChainRulesCore
using Optimization
using ComponentArrays

const N_neighbors = 8
const N_features = 1 + N_neighbors
const PatchSize = 9

function CoreCPM.evaluate_penalty(p::LocalNeuralPenalty, ctx)
    # Extract cell types as Float32 features
    type_old = ctx.src == 0 ? 0.0f0 : Float32(ctx.cell_data.cell_types[ctx.src])
    type_new = ctx.tgt == 0 ? 0.0f0 : Float32(ctx.cell_data.cell_types[ctx.tgt])

    neighbors_types = ntuple(N_neighbors) do i
        Base.@_inline_meta
        n_id = ctx.neighbors[i]
        n_id == 0 ? 0.0f0 : Float32(ctx.cell_data.cell_types[n_id])
    end

    # Use SVector for allocation-free local evaluation during MCMC
    x_old = SVector{PatchSize, Float32}(type_old, neighbors_types...)
    x_new = SVector{PatchSize, Float32}(type_new, neighbors_types...)

    # Lux models return (output, state)
    H_old = first(Lux.apply(p.model, x_old, p.weights, p.state))[1]
    H_new = first(Lux.apply(p.model, x_new, p.weights, p.state))[1]

    return H_new - H_old
end

const GLOBAL_FEATURE_CACHE = [Matrix{Float32}(undef, 0, 0) for _ in 1:Threads.nthreads()]

function CoreCPM.compute_global_energy(p::LocalNeuralPenalty, u::CPMState, params::CPMParameters)
    N_cells = length(u.grid)

    # Build feature matrix (ignored by Zygote as it's data construction)
    X = ChainRulesCore.ignore_derivatives() do
        tid = Threads.threadid()
        mat = GLOBAL_FEATURE_CACHE[tid]
        if size(mat) != (PatchSize, N_cells)
            GLOBAL_FEATURE_CACHE[tid] = Matrix{Float32}(undef, PatchSize, N_cells)
            mat = GLOBAL_FEATURE_CACHE[tid]
        end

        for i in 1:N_cells
            type_center = u.grid[i] == 0 ? 0.0f0 :
                          Float32(u.cell_data.cell_types[u.grid[i]])
            mat[1, i] = type_center

            grid_dims = size(u.grid)
            coords = CoreCPM.idx_to_coord(UInt32(i), grid_dims)
            for j in 1:N_neighbors
                n_idx = CoreCPM.get_neighbor_by_coord(params.topology, coords, UInt32(j), grid_dims)
                n_id = n_idx == 0 ? UInt32(0) : u.grid[n_idx]
                mat[1 + j, i] = n_id == 0 ? 0.0f0 : Float32(u.cell_data.cell_types[n_id])
            end
        end
        mat
    end

    # Zygote fully supports Lux.apply out-of-the-box.
    # It will correctly differentiate through the batched BLAS operations!
    H_vals = first(Lux.apply(p.model, X, p.weights, p.state))
    return sum(H_vals)
end

# ------------------------------------------------------------------------------
# Default Parameter Reconstruction (Optional Helper)
# ------------------------------------------------------------------------------
# The user can define how their ComponentArray `theta` maps to the `CPMParameters`.
# For a LocalNeuralPenalty, they might map `theta` directly to `weights`.

function CoreCPM.cpm_loss(theta, cache::CoreCPM.CPMTrainingCache, data_batch)
    error("cpm_loss must be differentiated with an AD backend. Make sure Zygote or Enzyme is loaded, and ignore_derivatives is used for the MCMC step.")
end

end
