# Potts.jl

Welcome to **Potts.jl**, a Cellular Potts Model (Potts) simulation ecosystem for Julia.

Potts.jl is a monorepo containing several interconnected packages:
- **CorePotts**: The core physics and simulation engine for Cellular Potts Models.
- **PottsToolkit**: High-level utilities and domain-specific language (DSL) for defining simulations.
- **MakiePotts**: Visualization and interactive dashboard tools built on top of Makie.jl.
- **NeuralPotts**: Neural network integration for Cellular Potts Models.

## Installation

`Potts.jl` acts as a meta-package that unifies several sub-packages. Because these sub-packages are not yet in the official Julia registry, you must first install them directly from their sub-directories using their GitHub URLs before installing the main `Potts` package.

Open the Julia REPL, type `]` to enter the Pkg prompt, and run:

```julia
pkg> add https://github.com/PraneethMerugu/Potts.jl:lib/CorePotts
pkg> add https://github.com/PraneethMerugu/Potts.jl:lib/MakiePotts
pkg> add https://github.com/PraneethMerugu/Potts.jl:lib/NeuralPotts
pkg> add https://github.com/PraneethMerugu/Potts.jl:lib/PottsToolkit
pkg> add https://github.com/PraneethMerugu/Potts.jl
```

For development, you can clone the repository and develop the packages:

```julia
using Pkg
Pkg.develop(path="lib/CorePotts")
Pkg.develop(path="lib/PottsToolkit")
Pkg.develop(path="lib/MakiePotts")
Pkg.develop(path="lib/NeuralPotts")
```

## Documentation

To build the documentation locally:

```bash
julia --project=docs/ -e 'using Pkg; Pkg.develop([PackageSpec(path="lib/" * pkg) for pkg in ["CorePotts", "PottsToolkit", "MakiePotts", "NeuralPotts"]]); Pkg.instantiate(); include("docs/make.jl")'
```

The documentation is built using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and is hosted on GitHub Pages.
