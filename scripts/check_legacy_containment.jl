using SHA
using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const FREEZE_FILE = joinpath(ROOT, "design", "audits", "phase-7-legacy-freeze.toml")

const FORBIDDEN_PATTERNS = [
    r"HST[A-Za-z_]*Penalty",
    r"\bVolumePenalty\b",
    r"\bAdhesionPenalty\b",
    r"\bChemotaxisPenalty\b",
    r"\bFocalPointSpringPenalty\b",
    r"\bAbstractPenalty\b",
    r"\bAbstractSampler\b",
    r"\bMetropolisSampler\b",
    r"\bMetropolisAlgorithm\b",
    r"\bMooreTopology\b",
    r"\bVolumeTracker\b",
    r"\bSurfaceAreaTracker\b",
    r"\bevaluate_penalty\b",
    r"\bexecute_step!",
    r"\bupdate_sweep_auxiliary!",
    r"\bPottsState\b",
    r"\bPottsParameters\b",
    r"\bPottsCache\b",
    r"\bParallelMetropolis\b",
    r"\bCheckerboardMetropolis\b",
    r"\bIntrinsicCheckerboardMetropolis\b",
    r"\bSequentialMetropolis\b",
    r"\bactive_fraction\b",
    r"\bsweeps_per_step\b",
]

function require(condition, message)
    condition || error(message)
end

function relative_julia_sources(root)
    sources = String[]
    for search_root in ["src", "lib", "benchmark/src", "test", "integration", "docs", "examples"]
        absolute = joinpath(root, search_root)
        isdir(absolute) || continue
        for (directory, directories, files) in walkdir(absolute)
            filter!(name -> name != "build" && name != "results", directories)
            for file in files
                endswith(file, ".jl") || continue
                push!(sources, relpath(joinpath(directory, file), root))
            end
        end
    end
    return sort!(unique!(sources))
end

function protected_scientific_source(path)
    startswith(path, "lib/CorePotts/src/algorithms/") && return true
    startswith(path, "lib/CorePotts/src/components/scientific_") && return true
    return path in (
        "lib/CorePotts/src/execution/contracts.jl",
        "lib/CorePotts/src/initialization/logical.jl",
        "lib/CorePotts/src/protocols/scientific.jl",
        "lib/CorePotts/src/reference/engine.jl",
        "lib/CorePotts/src/rng/semantic.jl",
        "lib/CorePotts/src/spatial/cartesian.jl",
        "lib/CorePotts/src/state/logical.jl",
        "lib/CorePotts/src/state/semantics.jl",
    )
end

function production_source(path)
    startswith(path, "src/") && return true
    startswith(path, "benchmark/src/") && return true
    return startswith(path, "lib/") && occursin("/src/", path)
end

function forbidden_matches(text)
    return [string(pattern) for pattern in FORBIDDEN_PATTERNS if occursin(pattern, text)]
end

require(isfile(FREEZE_FILE), "missing Phase 7 legacy freeze manifest")
freeze = TOML.parsefile(FREEZE_FILE)
require(get(freeze, "version", nothing) == 1, "unsupported legacy freeze manifest version")
frozen_files = get(freeze, "files", Dict{String, Any}())
require(!isempty(frozen_files), "legacy freeze manifest has no files")
frozen_signatures = get(freeze, "signatures", Dict{String, Any}())
require(!isempty(frozen_signatures), "legacy freeze manifest has no mixed-file signatures")

for (path, expected_digest) in sort!(collect(frozen_files); by = first)
    absolute = joinpath(ROOT, path)
    require(isfile(absolute),
        "frozen legacy file `$path` disappeared; remove it from the manifest in the owning migration")
    actual_digest = bytes2hex(sha256(read(absolute)))
    require(actual_digest == expected_digest,
        "frozen legacy file `$path` changed; historical code is read-only during Phase 7")
end

for (path, expected_digest) in sort!(collect(frozen_signatures); by = first)
    absolute = joinpath(ROOT, path)
    require(isfile(absolute), "mixed legacy consumer `$path` disappeared without manifest cleanup")
    matching_lines = [line for line in eachline(absolute)
                      if !isempty(forbidden_matches(line))]
    actual_digest = bytes2hex(sha256(codeunits(join(matching_lines, "\n") * "\n")))
    require(actual_digest == expected_digest,
        "quarantined lines in mixed source `$path` changed; update only through an explicit audit")
end

all_sources = relative_julia_sources(ROOT)
inventory = union(Set(keys(frozen_files)), Set(keys(frozen_signatures)))
for path in all_sources
    if production_source(path)
        matches = forbidden_matches(read(joinpath(ROOT, path), String))
        require(isempty(matches) || path in inventory,
            "production legacy consumer `$path` is absent from the frozen inventory: " *
            join(matches, ", "))
    end
    protected_scientific_source(path) || continue
    matches = forbidden_matches(read(joinpath(ROOT, path), String))
    require(isempty(matches),
        "scientific source `$path` references quarantined vocabulary: $(join(matches, ", "))")
end

# The change-level check covers packages, tests, benchmarks, tutorials, examples, and integration
# fixtures. Deletions are allowed; added historical references are not. The checker itself is the
# sole control-file exception because it must spell the rejected vocabulary.
base = get(ENV, "BASE_SHA", "")
diff_command = if isempty(base)
    `git -C $ROOT diff --unified=0 HEAD -- '*.jl'`
else
    `git -C $ROOT diff --unified=0 $base...HEAD -- '*.jl'`
end
function added_legacy_violations(diff_text)
    current_path = ""
    violations = String[]
    for line in eachline(IOBuffer(diff_text))
        if startswith(line, "+++ b/")
            current_path = line[7:end]
        elseif startswith(line, "+") && !startswith(line, "+++") &&
               current_path != "scripts/check_legacy_containment.jl"
            matches = forbidden_matches(line[2:end])
            isempty(matches) || push!(violations,
                "$current_path adds $(join(matches, ", ")): $(line[2:end])")
        end
    end
    return violations
end

require(isempty(added_legacy_violations("diff --git a/src/new.jl b/src/new.jl\n" *
    "+++ b/src/new.jl\n+SequentialCPM()\n")),
    "legacy diff checker rejected replacement API vocabulary")
require(length(added_legacy_violations("diff --git a/src/new.jl b/src/new.jl\n" *
    "+++ b/src/new.jl\n+active_fraction = 0.1\n")) == 1,
    "legacy diff checker failed its rejection self-test")
violations = added_legacy_violations(read(diff_command, String))
require(isempty(violations),
    "new Julia code consumes quarantined legacy vocabulary:\n" * join(violations, "\n"))

println("Phase 7 legacy containment passes: $(length(frozen_files)) frozen files, " *
        "$(length(frozen_signatures)) mixed-file signatures, clean scientific path, and no " *
        "added legacy consumers")
