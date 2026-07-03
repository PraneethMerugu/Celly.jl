"""
    CPMTrainingCache{State, Params, Alg}

Holds the persistent MCMC chains used for negative sampling during Contrastive Divergence training.
"""
struct CPMTrainingCache{State, Params, Alg, Cache}
    persistent_states::Vector{State}
    p::Params
    alg::Alg
    caches::Vector{Cache}
end

function CPMTrainingCache(base_prob::CPMProblem, num_chains::Int, alg::AbstractCPMAlgorithm)
    persistent_states = [deepcopy(base_prob.u0) for _ in 1:num_chains]
    caches = [CPMCache(s, base_prob.p.topology) for s in persistent_states]
    return CPMTrainingCache(persistent_states, base_prob.p, alg, caches)
end

"""
    cpm_loss(theta, cache::CPMTrainingCache, data_batch, update_fn)

The pure mathematical loss function for Persistent Contrastive Divergence EBM training.
`update_fn(p::CPMParameters, theta)` maps the flat/ComponentArray `theta` back into a full `CPMParameters` struct.
This function evaluates the global energy difference `E_data - E_model`.
NOTE: The MCMC sampling step (`execute_step!`) must be run *outside* this function
(e.g., in an Optimization.jl callback) so that AD engines do not attempt to trace it.
"""
function cpm_loss(theta, cache::CPMTrainingCache, data_batch, update_fn)
    p_tracked = update_fn(cache.p, theta)
    
    E_data = sum(u -> compute_global_energy(p_tracked.penalties, u, p_tracked), data_batch) / length(data_batch)
    E_model = sum(u -> compute_global_energy(p_tracked.penalties, u, p_tracked), cache.persistent_states) / length(cache.persistent_states)
    
    return E_data - E_model
end
