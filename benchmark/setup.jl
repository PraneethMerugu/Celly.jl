using Pkg

VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, ".."))
const MERMAID_URL = "https://github.com/eebio/Mermaid.jl.git"
const MERMAID_REV = "d4c89d0ea09af8d96bcdc42ef6bd5dd967fc7a0d"
const KERNEL_INTRINSICS_URL = "https://github.com/PraneethMerugu/KernelIntrinsics.jl.git"
const KERNEL_INTRINSICS_REV = "b3a02b6e80f0839082a02f1838af7e10e992062c"

Pkg.activate(@__DIR__)
packages = PackageSpec[
    PackageSpec(path = joinpath(REPOSITORY_ROOT, "lib", "CorePotts")),
    PackageSpec(path = joinpath(REPOSITORY_ROOT, "lib", "PottsToolkit"))
]
Pkg.add(PackageSpec(url = MERMAID_URL, rev = MERMAID_REV))
Pkg.add(PackageSpec(url = KERNEL_INTRINSICS_URL, rev = KERNEL_INTRINSICS_REV))
Pkg.develop(packages)
Pkg.instantiate()
