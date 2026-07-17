using Pkg

VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

Pkg.activate(@__DIR__)
Pkg.resolve()
Pkg.instantiate(; julia_version_strict = true)
