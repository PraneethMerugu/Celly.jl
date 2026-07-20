# docs/make.jl
# Unified documentation build for the Potts Ecosystem monorepo.
# Run with: julia --project=docs/ docs/make.jl

using Documenter
using Literate

# Load all packages so their docstrings are accessible to @autodocs
using CorePotts
using PottsToolkit
using MakiePotts
using NeuralPotts

# ===========================================================================
# STEP 1: Literate pre-processing
# Converts every .jl in docs/tutorials/ → docs/src/tutorials/*.md
# The documenter=true flag wraps code blocks as @example blocks so Documenter
# can execute and validate them.
# ===========================================================================

TUTORIALS_SRC = joinpath(@__DIR__, "tutorials")
TUTORIALS_OUT = joinpath(@__DIR__, "src", "tutorials")
mkpath(TUTORIALS_OUT)

for f in sort(readdir(TUTORIALS_SRC))
    endswith(f, ".jl") || continue
    src = joinpath(TUTORIALS_SRC, f)
    # Markdown output (included in the docs site)
    Literate.markdown(src, TUTORIALS_OUT; documenter = true, execute = false)
    # Notebook output (available for download links in each tutorial page)
    Literate.notebook(src, TUTORIALS_OUT; execute = false)
end

# ===========================================================================
# STEP 2: makedocs
# ===========================================================================

makedocs(
    sitename = "Potts.jl",
    authors = "Praneeth Merugu",

    # All modules whose exported symbols should be checked for docstrings.
    # Include internal submodules so @autodocs finds Base/Tools types.
    modules = [
        CorePotts,
        PottsToolkit,
        MakiePotts,
        NeuralPotts
    ], format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://praneethmerugu.github.io/Potts.jl/",
        size_threshold = nothing,
        size_threshold_warn = nothing        # collapselevel = 2,
    ),

    # Relaxed during initial build; set warnonly = false once all docstrings land
    warnonly = true,
    checkdocs = :exports,
    remotes = nothing, pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Concepts & Math" => "concepts.md", "CorePotts" => [
            "Overview" => "corepotts/index.md",
            "Topologies" => "corepotts/topology.md",
            "Penalties" => "corepotts/penalties.md",
            "Engine & Algorithms" => "corepotts/engine.md",
            "Custom Events" => "corepotts/custom_events.md",
            "Output Backends" => "corepotts/backends.md",
            "API Reference" => "corepotts/api.md"
        ],
        "PottsToolkit" => [
            "Overview" => "pottstoolkit/index.md",
            "Reference Models" => "pottstoolkit/reference_models.md",
            "API Reference" => "pottstoolkit/api.md"
        ],
        "MakiePotts" => [
            "Overview" => "makiepotts/index.md",
            "API Reference" => "makiepotts/api.md"
        ],
        "NeuralPotts" => [
            "Overview" => "neuralpotts/index.md",
            "API Reference" => "neuralpotts/api.md"
        ],
        "Tutorials" => [
            "1: First Simulation" => "tutorials/01_first_simulation.md",
            "2: Cell Sorting" => "tutorials/02_cell_sorting.md",
            "3: Directed Migration" => "tutorials/03_directed_migration.md",
            "4: Epithelial Sheet" => "tutorials/04_epithelial_sheet.md",
            "5: 3D Tumor Spheroid" => "tutorials/05_tumor_spheroid_3d.md",
            "6: GPU Acceleration" => "tutorials/06_gpu_acceleration.md",
            "7: Growth & Mitosis" => "tutorials/07_cell_growth_mitosis.md",
            "8: Cell Death & Homeostasis" => "tutorials/08_cell_death_homeostasis.md",
            "9: Thermodynamic HST" => "tutorials/09_thermodynamic_hst.md",
            "10: Elongation & Polarity" => "tutorials/10_cell_elongation_polarity.md",
            "11: Out-of-Core Saving" => "tutorials/11_out_of_core_saving.md",
            "12: Parameter Sweeps" => "tutorials/12_parameter_sweeps.md",
            "13: Boundary Conditions" => "tutorials/13_boundary_conditions.md",
            "14: Interactive Exploration" => "tutorials/14_interactive_exploration.md",
            "15: PottsToolkit Modeling API" => "tutorials/15_pottstoolkit_dsl.md",
            "16: Visualization" => "tutorials/16_visualization.md",
            "17: Neural EBM" => "tutorials/17_neural_ebm.md"
        ]
    ]
)

# ===========================================================================
# STEP 3: Deploy (CI only)
# Requires DOCUMENTER_KEY secret in GitHub repo settings.
# Generate with: using DocumenterTools; DocumenterTools.genkeys()
# ===========================================================================

if get(ENV, "POTTS_DEPLOY_DOCS", "false") == "true"
    get(ENV, "GITHUB_ACTIONS", "false") == "true" ||
        error("Documentation deployment is only permitted inside GitHub Actions")
    get(ENV, "GITHUB_EVENT_NAME", "") == "pull_request" &&
        error("Documentation deployment is forbidden for pull requests")
    deploydocs(
        repo = "github.com/PraneethMerugu/Potts.jl.git",
        devbranch = "main",
        push_preview = false
    )
end
