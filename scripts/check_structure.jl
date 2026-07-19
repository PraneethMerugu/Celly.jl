using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const JULIA_TARGET = "1.12.6"
const STDLIBS = Set(["LinearAlgebra", "Random", "Serialization", "SHA", "Statistics", "Test"])
const RELEASED_PROJECTS = [
    joinpath(ROOT, "Project.toml"),
    joinpath(ROOT, "lib", "CorePotts", "Project.toml"),
    joinpath(ROOT, "lib", "MakiePotts", "Project.toml"),
    joinpath(ROOT, "lib", "NeuralPotts", "Project.toml"),
]

function require(condition, message)
    condition || error(message)
end

function project_files()
    projects = String[]
    for (root, dirs, files) in walkdir(ROOT)
        filter!(dir -> dir != ".git" && dir != "build" && dir != "results", dirs)
        "Project.toml" in files && push!(projects, joinpath(root, "Project.toml"))
    end
    return sort(projects)
end

for project_file in project_files()
    project = TOML.parsefile(project_file)
    compat = get(project, "compat", Dict{String, Any}())
    require(get(compat, "julia", nothing) == JULIA_TARGET,
        "$(relpath(project_file, ROOT)) must target Julia $JULIA_TARGET exactly")
end

for project_file in RELEASED_PROJECTS
    project = TOML.parsefile(project_file)
    deps = get(project, "deps", Dict{String, Any}())
    compat = get(project, "compat", Dict{String, Any}())
    require(!haskey(deps, "Test"), "Test must not be a runtime dependency of $(project["name"])")
    for dependency in keys(deps)
        dependency in STDLIBS && continue
        require(haskey(compat, dependency),
            "$(project["name"]) lacks a compat bound for $dependency")
    end
end

root_project = TOML.parsefile(joinpath(ROOT, "Project.toml"))
require(root_project["name"] == "PottsToolkit", "the repository-root package must be PottsToolkit")
require(root_project["uuid"] == "e4c62a4c-8889-4cc8-ad3a-75efc86c53b9",
    "the PottsToolkit UUID changed")
require(isfile(joinpath(ROOT, "src", "PottsToolkit.jl")), "src/PottsToolkit.jl is missing")
require(!ispath(joinpath(ROOT, "src", "Potts.jl")), "the Potts umbrella source still exists")
nested_toolkit = joinpath(ROOT, "lib", "PottsToolkit")
nested_files = isdir(nested_toolkit) ?
               collect(Iterators.flatten(files for (_, _, files) in walkdir(nested_toolkit))) :
               String[]
require(isempty(nested_files), "the nested PottsToolkit package still contains files")

family_deps = Dict(
    "CorePotts" => Set(keys(get(TOML.parsefile(RELEASED_PROJECTS[2]), "deps", Dict()))),
    "PottsToolkit" => Set(keys(get(root_project, "deps", Dict()))),
    "MakiePotts" => Set(keys(get(TOML.parsefile(RELEASED_PROJECTS[3]), "deps", Dict()))),
    "NeuralPotts" => Set(keys(get(TOML.parsefile(RELEASED_PROJECTS[4]), "deps", Dict()))),
)
require(isempty(intersect(family_deps["CorePotts"], Set(["PottsToolkit", "MakiePotts", "NeuralPotts"]))),
    "CorePotts depends on an upward layer")
require(isempty(intersect(family_deps["PottsToolkit"], Set(["MakiePotts", "NeuralPotts"]))),
    "PottsToolkit depends on a satellite")
require(isempty(intersect(family_deps["NeuralPotts"], Set(["PottsToolkit", "MakiePotts"]))),
    "NeuralPotts depends on an unnecessary higher layer")

for runner in [
        joinpath(ROOT, "test", "runtests.jl"),
        joinpath(ROOT, "lib", "CorePotts", "test", "runtests.jl"),
        joinpath(ROOT, "lib", "MakiePotts", "test", "runtests.jl"),
        joinpath(ROOT, "lib", "NeuralPotts", "test", "runtests.jl"),
        joinpath(ROOT, "integration", "runtests.jl")]
    require(isfile(runner), "missing test owner: $(relpath(runner, ROOT))")
end

for manifest in [
        "Manifest.toml",
        "lib/CorePotts/Manifest.toml",
        "lib/MakiePotts/Manifest.toml",
        "lib/NeuralPotts/Manifest.toml"]
    tracked = readchomp(`git -C $ROOT ls-files -- $manifest`)
    require(isempty(tracked), "$manifest must not be tracked by an independently installable library")
end

for generated in ["docs/build", "benchmark/results"]
    tracked = readchomp(`git -C $ROOT ls-files -- $generated`)
    require(isempty(tracked), "$generated contains tracked generated output")
end

println("Repository structure satisfies the Phase 2 package, dependency, test, manifest, and Julia-target contract")
