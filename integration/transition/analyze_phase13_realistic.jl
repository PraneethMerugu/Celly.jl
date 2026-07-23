#!/usr/bin/env julia

using TOML

include(joinpath(@__DIR__, "TransitionEmpirical.jl"))
include(joinpath(@__DIR__, "RealisticScaleRunner.jl"))
include(joinpath(@__DIR__, "RealisticEvidenceArchive.jl"))
include(joinpath(@__DIR__, "RealisticEvidenceAnalysis.jl"))

using .RealisticScaleRunner
using .RealisticEvidenceAnalysis

function parse_options(args)
    options = Dict{String, String}()
    force = false
    index = 1
    while index <= length(args)
        if args[index] == "--force"
            force = true
            index += 1
        else
            startswith(args[index], "--") || throw(ArgumentError(
                "unexpected positional argument: $(args[index])"))
            index < length(args) || throw(ArgumentError("missing value for $(args[index])"))
            options[args[index][3:end]] = args[index + 1]
            index += 2
        end
    end
    return (; options, force)
end

function main(args)
    parsed = parse_options(args)
    options = parsed.options
    haskey(options, "reference") || throw(ArgumentError("--reference is required"))
    haskey(options, "candidate") || throw(ArgumentError("--candidate is required"))
    references = TOML.parsefile.(split(options["reference"], ','))
    candidates = TOML.parsefile.(split(options["candidate"], ','))
    length(references) == length(candidates) || throw(ArgumentError(
        "comma-separated --reference and --candidate lists must have equal lengths"))
    comparison = Symbol(get(options, "comparison", "paired_algorithm"))
    manifest = load_realistic_manifest()
    result = length(references) == 1 ?
        analyze_realistic_equivalence(only(references), only(candidates);
            comparison, manifest) :
        analyze_realistic_family(references, candidates; comparison, manifest)
    output = abspath(get(options, "output", "phase13-realistic-analysis.toml"))
    write_realistic_analysis(output, result; force = parsed.force)
    println("wrote Phase 13 realistic $(result["result"]["status"]) to $output")
    result["result"]["qualification_eligible"] &&
        !result["result"]["qualification_passed"] && exit(1)
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main(ARGS)
