VERSION == v"1.12.6" ||
    error("The refactor benchmark target is Julia 1.12.6; found $VERSION")

function option(name, default)
    prefix = "--$name="
    argument = findfirst(value -> startswith(value, prefix), ARGS)
    return isnothing(argument) ? default : ARGS[argument][(length(prefix) + 1):end]
end

backend = option("backend", "cpu")
profile = option("profile", "smoke")
repetitions = parse(Int, option("repetitions", "1"))
backend in ("cpu", "metal", "amdgpu") || error(
    "Phase 12 requires --backend=cpu, metal, or amdgpu")
profile in ("smoke", "full") || error("Expected --profile=smoke or full")
repetitions in (1, 3, 5) || error("Phase 12 repetitions must be 1, 3, or 5")

matrix = joinpath(@__DIR__, "matrix.jl")
project = Base.active_project()
run_id = get(ENV, "GITHUB_RUN_ID", "local")
run_attempt = get(ENV, "GITHUB_RUN_ATTEMPT", "1")

for repetition in 1:repetitions
    process_id = "$run_id-$run_attempt-$backend-$profile-$repetition"
    command = `$(Base.julia_cmd()) --project=$project --startup-file=no $matrix --backend=$backend --profile=$profile`
    run(addenv(command, "POTTS_BENCHMARK_PROCESS_ID" => process_id))
end
