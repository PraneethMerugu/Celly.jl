module PottsToolkitMermaidExt

using PottsToolkit
using Mermaid
using CorePotts

function CorePotts.PottsComponent(sys::PottsSystem,
        layout::AbstractLayout,
        grid_size::Tuple,
        alg::AbstractPottsAlgorithm;
        name::AbstractString = "Tissue",
        timestep::Real = 1.0,
        kwargs...)

    # Compile the high-level DSL system into a raw CorePotts problem
    prob = PottsProblem(sys, layout, grid_size; kwargs...)

    # Delegate to the existing CorePottsMermaidExt component constructor
    return CorePotts.PottsComponent(prob, alg; name = name, timestep = timestep)
end

function CorePotts.PottsComponent(sys::PottsSystem,
        u0_counts::Dict{CellType, Int},
        grid_size::Tuple,
        alg::AbstractPottsAlgorithm;
        kwargs...)
    return CorePotts.PottsComponent(sys, Layouts.RandomLayout(u0_counts), grid_size, alg; kwargs...)
end

end
