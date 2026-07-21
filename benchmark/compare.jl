VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

include(joinpath(@__DIR__, "src", "Phase12Comparison.jl"))
using .Phase12Comparison
using TOML

function options(arguments)
    values = Dict("baseline" => String[], "candidate" => String[])
    minimum_processes = 3
    output = nothing
    for argument in arguments
        if startswith(argument, "--baseline=")
            push!(values["baseline"], split(argument, "="; limit = 2)[2])
        elseif startswith(argument, "--candidate=")
            push!(values["candidate"], split(argument, "="; limit = 2)[2])
        elseif startswith(argument, "--minimum-processes=")
            minimum_processes = parse(Int, split(argument, "="; limit = 2)[2])
        elseif startswith(argument, "--output=")
            output = split(argument, "="; limit = 2)[2]
        else
            throw(ArgumentError("unknown comparison option `$argument`"))
        end
    end
    isempty(values["baseline"]) && throw(ArgumentError(
        "provide at least one --baseline=PATH"))
    isempty(values["candidate"]) && throw(ArgumentError(
        "provide at least one --candidate=PATH"))
    return values, minimum_processes, output
end

function main(arguments)
    paths, minimum_processes, output = options(arguments)
    baseline = load_record.(paths["baseline"])
    candidate = load_record.(paths["candidate"])
    comparison = compare_record_groups(baseline, candidate; minimum_processes)
    print_comparison(comparison)
    if output !== nothing
        open(output, "w") do io
            TOML.print(io, comparison; sorted = true)
        end
    end
    return comparison["passed"] ? 0 : 1
end

exit(main(ARGS))
