# Celly.jl

Welcome to **Celly.jl**, a Cellular Potts Model (CPM) simulation ecosystem for Julia.

Celly.jl is a monorepo containing several interconnected packages:
- **CoreCPM**: The core physics and simulation engine for Cellular Potts Models.
- **CPMToolkit**: High-level utilities and domain-specific language (DSL) for defining simulations.
- **MakieCPM**: Visualization and interactive dashboard tools built on top of Makie.jl.
- **NeuralCPM**: Neural network integration for Cellular Potts Models.

## Installation

To install the packages in this ecosystem, you can add them via the Julia package manager. 

```julia
using Pkg
Pkg.add("Celly") # If registered
```

For development, you can clone the repository and develop the packages:

```julia
using Pkg
Pkg.develop(path="lib/CoreCPM")
Pkg.develop(path="lib/CPMToolkit")
Pkg.develop(path="lib/MakieCPM")
Pkg.develop(path="lib/NeuralCPM")
```

## Documentation

To build the documentation locally:

```bash
julia --project=docs/ -e 'using Pkg; Pkg.develop([PackageSpec(path="lib/" * pkg) for pkg in ["CoreCPM", "CPMToolkit", "MakieCPM", "NeuralCPM"]]); Pkg.instantiate(); include("docs/make.jl")'
```

The documentation is built using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and is hosted on GitHub Pages.
