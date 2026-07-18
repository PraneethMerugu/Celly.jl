# Potts.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://praneethmerugu.github.io/Potts.jl/dev/)
Welcome to **Potts.jl**, a Cellular Potts Model simulation ecosystem for Julia. The repository-root
package is **PottsToolkit**, the primary high-level modeling interface.

Potts.jl is a monorepo containing four independently testable packages:
- **CorePotts**: The core physics and simulation engine for Cellular Potts Models.
- **PottsToolkit**: The repository-root high-level API and domain-specific language (DSL).
- **MakiePotts**: Visualization and interactive dashboard tools built on top of Makie.jl.
- **NeuralPotts**: Neural network integration for Cellular Potts Models.

## Installation

The historical `Potts` re-export package has been removed. Until the package family is registered,
install `PottsToolkit` directly from the repository root. Optional satellites remain separately
installable subdirectory packages.

Open the Julia REPL, type `]` to enter the Pkg prompt, and run:

```julia
pkg> add https://github.com/PraneethMerugu/Potts.jl
pkg> add https://github.com/PraneethMerugu/Potts.jl:lib/MakiePotts
pkg> add https://github.com/PraneethMerugu/Potts.jl:lib/NeuralPotts
```

For development, you can clone the repository and develop the packages:

```julia
using Pkg
Pkg.develop(path="lib/CorePotts")
Pkg.develop(path=".")
Pkg.develop(path="lib/MakiePotts")
Pkg.develop(path="lib/NeuralPotts")
```

## Documentation

To build the documentation locally:

```bash
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.instantiate(; julia_version_strict=true)'
julia --project=docs --startup-file=no docs/make.jl
```

The documentation is built using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and is hosted on GitHub Pages.
