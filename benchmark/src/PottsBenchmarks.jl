module PottsBenchmarks

using Adapt
using BenchmarkTools
using CorePotts
using Dates
using KernelAbstractions
using SHA
using SciMLBase
using Statistics
using TOML

const SCHEMA_VERSION = "1.0.0"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const RESULTS_ROOT = joinpath(REPOSITORY_ROOT, "benchmark", "results")

struct WorkloadSpec{N}
    name::String
    dimensions::NTuple{N, Int}
    cells::Int
    radius::Int
    adhesion::Bool
    class::String
end

const WORKLOADS = Dict(
    "volume_2d_small" => WorkloadSpec(
        "volume_2d_small", (64, 64), 16, 4, false, "latency"),
    "adhesion_2d_medium" => WorkloadSpec(
        "adhesion_2d_medium", (128, 128), 64, 4, true, "throughput"),
    "volume_3d_small" => WorkloadSpec(
        "volume_3d_small", (32, 32, 32), 8, 3, false, "three_dimensional"),
    "adhesion_2d_publication" => WorkloadSpec(
        "adhesion_2d_publication", (256, 256), 100, 5, true, "publication")
)

function evenly_spaced_centers(spec::WorkloadSpec{N}) where {N}
    per_axis = ceil(Int, spec.cells^(1 / N))
    coordinates = ntuple(N) do dimension
        lo = spec.radius + 2
        hi = spec.dimensions[dimension] - spec.radius - 1
        unique(round.(Int, range(lo, hi; length = per_axis)))
    end
    return collect(Iterators.take(Iterators.product(coordinates...), spec.cells))
end

function build_workload(spec::WorkloadSpec{N}) where {N}
    grid = zeros(UInt32, spec.dimensions)
    volume = VolumePenalty(Float32[0, 2])
    penalties = if spec.adhesion
        contact = AdhesionPenalty(Float32[0 10; 10 2])
        (volume, contact)
    else
        (volume,)
    end
    trackers = (VolumeTracker(), SurfaceAreaTracker())
    cell_data = build_cell_data(grid, spec.cells, penalties, trackers)

    for (cell_id, center) in enumerate(evenly_spaced_centers(spec))
        spawn_hypersphere!(
            grid, size(grid), Tuple(center), spec.radius, UInt32(cell_id))
        cell_data.cell_types[cell_id] = UInt8(1)
    end

    state = PottsState(grid, cell_data, Int32[spec.cells])
    topology = MooreTopology{N}()
    parameters = PottsParameters(topology, penalties, trackers)
    cache = PottsCache(state, topology)
    CorePotts.sync_cell_data!(state, parameters, cache, spec.cells)
    return PottsProblem(state, (0, 1_000), parameters)
end

function load_backend(name::String)
    if name == "cpu"
        return (identity, "KernelAbstractions.CPU")
    elseif name == "metal"
        isdefined(Main, :Metal) || error("Metal must be loaded before PottsBenchmarks")
        metal = getfield(Main, :Metal)
        Base.invokelatest(getproperty(metal, :functional)) ||
            error("Metal loaded but is not functional on this host")
        array_type = getproperty(metal, :MtlArray)
        adapt_problem = problem -> Base.invokelatest(Adapt.adapt, array_type, problem)
        device = Base.invokelatest(getproperty(metal, :device))
        return (adapt_problem, string(device))
    elseif name == "cuda"
        isdefined(Main, :CUDA) || error("CUDA must be loaded before PottsBenchmarks")
        cuda = getfield(Main, :CUDA)
        Base.invokelatest(getproperty(cuda, :functional)) ||
            error("CUDA loaded but is not functional on this host")
        array_type = getproperty(cuda, :CuArray)
        adapt_problem = problem -> Base.invokelatest(Adapt.adapt, array_type, problem)
        device = Base.invokelatest(getproperty(cuda, :device))
        return (adapt_problem, string(device))
    elseif name == "amdgpu"
        isdefined(Main, :AMDGPU) || error("AMDGPU must be loaded before PottsBenchmarks")
        amdgpu = getfield(Main, :AMDGPU)
        Base.invokelatest(getproperty(amdgpu, :functional)) ||
            error("AMDGPU loaded but is not functional on this host")
        array_type = getproperty(amdgpu, :ROCArray)
        adapt_problem = problem -> Base.invokelatest(Adapt.adapt, array_type, problem)
        device = Base.invokelatest(getproperty(amdgpu, :device))
        return (adapt_problem, string(device))
    end
    throw(ArgumentError("Unknown backend `$name`; expected cpu, metal, cuda, or amdgpu"))
end

function algorithm_configuration(name::String, dimensions::Int)
    active_fraction, sweeps = dimensions == 3 ? (0.025f0, 40) : (0.1f0, 10)
    common = (; T = 1.0f0, active_fraction, sweeps_per_step = sweeps)
    if name == "sequential"
        return SequentialMetropolis(; common...)
    elseif name == "lottery"
        return ParallelMetropolis(; common...)
    elseif name == "checkerboard"
        return CheckerboardMetropolis(; common...)
    elseif name == "intrinsic"
        return IntrinsicCheckerboardMetropolis(; common...)
    end
    throw(ArgumentError(
        "Unknown algorithm `$name`; expected sequential, lottery, checkerboard, or intrinsic"))
end

function synchronize_state(state)
    KernelAbstractions.synchronize(KernelAbstractions.get_backend(state.grid))
    return nothing
end

function timed_step!(integrator)
    SciMLBase.step!(integrator)
    synchronize_state(integrator.u)
    return nothing
end

function bytes_of(array)
    host = Array(array)
    return reinterpret(UInt8, vec(host))
end

function state_checksum(state)
    bytes = UInt8[]
    append!(bytes, bytes_of(state.grid))
    for property in sort!(collect(propertynames(state.cell_data)); by = string)
        append!(bytes, codeunits(string(property)))
        append!(bytes, bytes_of(getproperty(state.cell_data, property)))
    end
    append!(bytes, bytes_of(state.N_cells))
    append!(bytes, bytes_of(state.free_list))
    append!(bytes, bytes_of(state.free_list_count))
    return bytes2hex(sha256(bytes))
end

function state_invariants(state)
    synchronize_state(state)
    grid = Array(state.grid)
    volumes = Array(state.cell_data.volumes)
    occupied = count(!iszero, grid)
    active_volume = sum(volumes)
    capacity = length(volumes)
    maximum_owner = isempty(grid) ? 0 : maximum(grid)
    return Dict(
        "occupied_sites" => occupied,
        "tracked_volume" => active_volume,
        "volume_matches_occupancy" => active_volume == occupied,
        "owners_within_capacity" => maximum_owner <= capacity,
        "nonnegative_volumes" => all(>=(0), volumes),
        "maximum_owner" => Int(maximum_owner),
        "capacity" => capacity
    )
end

function implementation_files()
    roots = [
        joinpath(REPOSITORY_ROOT, "Project.toml"),
        joinpath(REPOSITORY_ROOT, "src"),
        joinpath(REPOSITORY_ROOT, "lib"),
        joinpath(REPOSITORY_ROOT, "test")
    ]
    files = String[]
    for root in roots
        if isfile(root)
            push!(files, root)
        elseif isdir(root)
            for (directory, _, names) in walkdir(root)
                for name in names
                    if endswith(name, ".jl") || name == "Project.toml"
                        push!(files, joinpath(directory, name))
                    end
                end
            end
        end
    end
    return sort!(files)
end

function source_tree_checksum()
    bytes = UInt8[]
    for file in implementation_files()
        append!(bytes, codeunits(relpath(file, REPOSITORY_ROOT)))
        append!(bytes, read(file))
    end
    return bytes2hex(sha256(bytes))
end

function command_output(command; default = "unknown")
    try
        return strip(read(command, String))
    catch
        return default
    end
end

function provenance(backend::String, device::String)
    commit = command_output(`git -C $REPOSITORY_ROOT rev-parse HEAD`)
    dirty_status = command_output(`git -C $REPOSITORY_ROOT status --short`; default = "")
    source_checksum = source_tree_checksum()
    return Dict(
        "git_commit" => commit,
        "git_dirty" => !isempty(dirty_status),
        "source_tree_sha256" => source_checksum,
        "baseline_id" => string(first(commit, min(12, length(commit))), "-",
            first(source_checksum, 12)),
        "julia_version" => string(VERSION),
        "os" => string(Sys.KERNEL),
        "architecture" => string(Sys.ARCH),
        "cpu_threads" => Sys.CPU_THREADS,
        "julia_threads" => Threads.nthreads(),
        "backend" => backend,
        "device" => device,
        "kernel_intrinsics_source" => "https://github.com/PraneethMerugu/KernelIntrinsics.jl.git",
        "kernel_intrinsics_commit" => "b3a02b6e80f0839082a02f1838af7e10e992062c"
    )
end

function benchmark_case(
        workload_name::String, algorithm_name::String, backend_name::String;
        samples::Int = 10, seconds::Float64 = 30.0, warmup_steps::Int = 2)
    haskey(WORKLOADS, workload_name) ||
        throw(ArgumentError("Unknown workload `$workload_name`"))
    backend_name != "cpu" && algorithm_name == "sequential" &&
        throw(ArgumentError("The current sequential baseline is CPU-only"))

    spec = WORKLOADS[workload_name]
    adapt_problem, device = load_backend(backend_name)

    build_seconds = @elapsed cpu_problem = build_workload(spec)
    initial_checksum = state_checksum(cpu_problem.u0)
    adaptation_seconds = @elapsed problem = adapt_problem(cpu_problem)
    algorithm = algorithm_configuration(algorithm_name, length(spec.dimensions))

    initialization_seconds = @elapsed integrator = SciMLBase.init(
        problem, algorithm; save_everystep = false, save_start = false, save_end = false)
    initial_invariants = state_invariants(integrator.u)
    first_mcs_seconds = @elapsed timed_step!(integrator)

    for _ in 1:warmup_steps
        timed_step!(integrator)
    end

    benchmarkable = BenchmarkTools.@benchmarkable timed_step!($integrator) evals = 1
    trial = BenchmarkTools.run(benchmarkable; samples, seconds)
    times_seconds = Float64.(trial.times) ./ 1.0e9
    final_invariants = state_invariants(integrator.u)
    expected_attempts = prod(spec.dimensions) * Float64(algorithm.active_fraction) *
                        Int(algorithm.sweeps_per_step)

    metrics = Dict(
        "samples" => length(times_seconds),
        "raw_seconds" => times_seconds,
        "minimum_seconds_per_mcs" => minimum(times_seconds),
        "median_seconds_per_mcs" => median(times_seconds),
        "mean_seconds_per_mcs" => mean(times_seconds),
        "maximum_seconds_per_mcs" => maximum(times_seconds),
        "median_mcs_per_second" => inv(median(times_seconds)),
        "expected_attempts_per_public_step" => expected_attempts,
        "median_expected_attempts_per_second" => expected_attempts / median(times_seconds),
        "benchmark_host_memory_bytes" => trial.memory,
        "benchmark_host_allocations" => trial.allocs,
        "workload_build_seconds" => build_seconds,
        "backend_adaptation_seconds" => adaptation_seconds,
        "integrator_initialization_seconds" => initialization_seconds,
        "first_mcs_seconds" => first_mcs_seconds
    )

    return Dict(
        "schema_version" => SCHEMA_VERSION,
        "recorded_at_utc" => string(now(UTC)),
        "provenance" => provenance(backend_name, device),
        "workload" => Dict(
            "name" => spec.name,
            "class" => spec.class,
            "dimensions" => collect(spec.dimensions),
            "sites" => prod(spec.dimensions),
            "initial_cells" => spec.cells,
            "radius" => spec.radius,
            "adhesion" => spec.adhesion,
            "initial_checksum" => initial_checksum
        ),
        "algorithm" => Dict(
            "name" => algorithm_name,
            "type" => string(typeof(algorithm)),
            "temperature" => Float64(algorithm.T),
            "active_fraction" => Float64(algorithm.active_fraction),
            "sweeps_per_step" => Int(algorithm.sweeps_per_step),
            "semantic_warning" => "Legacy public-step accounting; not accepted normalized-MCS semantics"
        ),
        "initial_invariants" => initial_invariants,
        "final_invariants" => final_invariants,
        "final_checksum" => state_checksum(integrator.u),
        "metrics" => metrics,
        "known_limitations" => [
            "Current engine exposes no actual proposal or acceptance counters",
            "Kernel launches, transfers, device allocations, and implicit waits are not yet instrumented",
            "State evolves across steady-state benchmark samples",
            "Current RNG has no public semantic master seed"
        ]
    )
end

function write_result(result)
    provenance_data = result["provenance"]
    workload = result["workload"]["name"]
    algorithm = result["algorithm"]["name"]
    backend = provenance_data["backend"]
    timestamp = Dates.format(now(UTC), dateformat"yyyymmddTHHMMSS")
    directory = joinpath(RESULTS_ROOT, provenance_data["baseline_id"], backend)
    mkpath(directory)
    path = joinpath(directory, "$(timestamp)-$(workload)-$(algorithm).toml")
    open(path, "w") do io
        TOML.print(io, result; sorted = true)
    end
    return path
end

function parse_arguments(arguments)
    options = Dict(
        "backend" => "cpu",
        "workload" => "volume_2d_small",
        "algorithm" => "checkerboard",
        "samples" => "10",
        "seconds" => "30",
        "warmup" => "2"
    )
    for argument in arguments
        startswith(argument, "--") ||
            throw(ArgumentError("Expected --key=value, received `$argument`"))
        parts = split(argument[3:end], "="; limit = 2)
        length(parts) == 2 || throw(ArgumentError("Expected --key=value"))
        haskey(options, parts[1]) || throw(ArgumentError("Unknown option --$(parts[1])"))
        options[parts[1]] = parts[2]
    end
    return options
end

function main(arguments)
    try
        options = parse_arguments(arguments)
        result = benchmark_case(
            options["workload"], options["algorithm"], options["backend"];
            samples = parse(Int, options["samples"]),
            seconds = parse(Float64, options["seconds"]),
            warmup_steps = parse(Int, options["warmup"])
        )
        path = write_result(result)
        println("BASELINE_RESULT=", path)
        println("BASELINE_ID=", result["provenance"]["baseline_id"])
        println("MEDIAN_MCS_PER_SECOND=", result["metrics"]["median_mcs_per_second"])
        return 0
    catch error
        showerror(stderr, error, catch_backtrace())
        println(stderr)
        return 1
    end
end

end
