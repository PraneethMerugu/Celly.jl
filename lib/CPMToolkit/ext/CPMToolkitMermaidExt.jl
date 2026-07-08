module CPMToolkitMermaidExt

using CPMToolkit
using Mermaid
using CoreCPM

function CoreCPM.CPMComponent(sys::CPMSystem,
        u0_counts::Dict{CellType, Int},
        grid_size::Tuple,
        alg::AbstractCPMAlgorithm;
        name::AbstractString = "Tissue",
        timestep::Real = 1.0,
        kwargs...)

    # Compile the high-level DSL system into a raw CoreCPM problem
    prob = CPMProblem(sys, u0_counts, grid_size; kwargs...)

    # Delegate to the existing CoreCPMMermaidExt component constructor
    return CoreCPM.CPMComponent(prob, alg; name = name, timestep = timestep)
end

end
