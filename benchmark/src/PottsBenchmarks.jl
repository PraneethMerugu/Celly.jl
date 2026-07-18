module PottsBenchmarks

using Adapt
using BenchmarkTools
using CorePotts
using Dates
using KernelAbstractions
using SHA
using SciMLBase
using StaticArrays
using Statistics
using TOML

const SCHEMA_VERSION = "1.0.0"
const REPOSITORY_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
const RESULTS_ROOT = joinpath(REPOSITORY_ROOT, "benchmark", "results")

@kernel function _semantic_rng_probe!(output, addresses, contract, seed)
    index = @index(Global, Linear)
    if index <= length(addresses)
        words = rng_words(contract, seed, addresses[index])
        base = 4 * (index - 1)
        output[base + 1] = words[1]
        output[base + 2] = words[2]
        output[base + 3] = words[3]
        output[base + 4] = words[4]
    end
end

@kernel function _semantic_distribution_probe!(floating_output, integer_output,
        addresses, table, contract, seed)
    index = @index(Global, Linear)
    if index <= length(addresses)
        address = addresses[index]
        floating_output[2 * index - 1] = uniform_open01(Float32, contract, seed, address)
        floating_output[2 * index] = normal_box_muller(Float32, contract, seed, address)
        integer_output[5 * index - 4] = Int32(bounded_uint(
            contract, seed, address, UInt32(17)))
        integer_output[5 * index - 3] = Int32(categorical_index(
            table, contract, seed, address))
        integer_output[5 * index - 2] = bernoulli(
            contract, seed, address, 0.375f0) ? Int32(1) : Int32(0)
        integer_output[5 * index - 1] = Int32(poisson_inversion(
            contract, seed, address, 4.0f0))
        integer_output[5 * index] = Int32(poisson_normal_approx(
            contract, seed, address, 100.0f0))
    end
end

@kernel function _semantic_permutation_probe!(output, addresses, contract, seed)
    index = @index(Global, Linear)
    if index <= length(addresses)
        permutation = MVector{8, UInt16}(undef)
        small_permutation!(permutation, contract, seed, addresses[index])
        base = 8 * (index - 1)
        for element in 1:8
            @inbounds output[base + element] = permutation[element]
        end
    end
end

@kernel function _semantic_float64_probe!(floating_output, poisson_output,
        addresses, contract, seed)
    index = @index(Global, Linear)
    if index <= length(addresses)
        address = addresses[index]
        floating_output[2 * index - 1] = uniform_open01(Float64, contract, seed, address)
        floating_output[2 * index] = normal_box_muller(Float64, contract, seed, address)
        poisson_output[index] = Int32(poisson_inversion(
            contract, seed, address, 4.0))
    end
end

@kernel function _execution_stage_one!(output, input)
    index = @index(Global, Linear)
    @inbounds output[index] = input[index] + UInt32(1)
end

@kernel function _execution_stage_two!(output, input)
    index = @index(Global, Linear)
    @inbounds output[index] = input[index] * UInt32(2)
end

function _backend_adaptor(name::String)
    name == "cpu" && return Array
    module_name = name == "metal" ? :Metal : name == "cuda" ? :CUDA :
                  name == "amdgpu" ? :AMDGPU : throw(ArgumentError(
        "Unknown backend `$name`"))
    isdefined(Main, module_name) || error("$module_name must be loaded before RNG qualification")
    backend_module = getfield(Main, module_name)
    array_name = name == "metal" ? :MtlArray : name == "cuda" ? :CuArray : :ROCArray
    return getproperty(backend_module, array_name)
end

function _backend_array(name::String, values)
    name == "cpu" && return copy(values)
    return Base.invokelatest(_backend_adaptor(name), values)
end

"""Execute the Phase 5 raw-word probe and require exact CPU/backend identity."""
function qualify_rng_backend(name::String)
    contract = Philox4x32x10V1()
    seed = UInt64(0x706f7474732d7631)
    addresses = [RNGAddress(stream = ProposalDirectionStream, mcs = 11,
        subround = 3, operation = 7, entity_kind = SiteEntity, entity = index,
        invocation = 2, draw = 5) for index in 1:257]
    expected = reduce(vcat, collect(rng_words(contract, seed, address)) for address in addresses)
    device_addresses = _backend_array(name, addresses)
    output = similar(device_addresses, UInt32, 4 * length(addresses))
    backend = KernelAbstractions.get_backend(device_addresses)
    kernel = _semantic_rng_probe!(backend, 128)
    kernel(output, device_addresses, contract, seed; ndrange = length(addresses))
    KernelAbstractions.synchronize(backend)
    observed = Array(output)
    observed == expected || error("$name Philox words differ from the CPU contract")

    distribution_addresses = [RNGAddress(stream = HSTStream, mcs = 23,
        subround = 2, operation = 9, entity_kind = SiteEntity, entity = index,
        draw = 11) for index in 1:4096]
    device_distribution_addresses = _backend_array(name, distribution_addresses)
    table = CategoricalTable((1.0f0, 2.0f0, 3.0f0))
    floating_output = similar(device_distribution_addresses, Float32,
        2 * length(distribution_addresses))
    integer_output = similar(device_distribution_addresses, Int32,
        5 * length(distribution_addresses))
    distribution_kernel = _semantic_distribution_probe!(backend, 128)
    distribution_kernel(floating_output, integer_output, device_distribution_addresses, table,
        contract, seed; ndrange = length(distribution_addresses))
    KernelAbstractions.synchronize(backend)
    observed_floating = Array(floating_output)
    observed_integer = Array(integer_output)
    expected_floating = Vector{Float32}(undef, 2 * length(distribution_addresses))
    expected_integer = Vector{Int32}(undef, 5 * length(distribution_addresses))
    for (index, address) in pairs(distribution_addresses)
        expected_floating[2 * index - 1] = uniform_open01(Float32, contract, seed, address)
        expected_floating[2 * index] = normal_box_muller(Float32, contract, seed, address)
        expected_integer[5 * index - 4] = Int32(bounded_uint(
            contract, seed, address, UInt32(17)))
        expected_integer[5 * index - 3] = Int32(categorical_index(
            table, contract, seed, address))
        expected_integer[5 * index - 2] = bernoulli(
            contract, seed, address, 0.375f0) ? Int32(1) : Int32(0)
        expected_integer[5 * index - 1] = Int32(poisson_inversion(
            contract, seed, address, 4.0f0))
        expected_integer[5 * index] = Int32(poisson_normal_approx(
            contract, seed, address, 100.0f0))
    end
    bitwise_indices = reduce(vcat,
        (5 * index - 4):(5 * index - 2) for index in eachindex(distribution_addresses))
    observed_integer[bitwise_indices] == expected_integer[bitwise_indices] || error(
        "$name bitwise discrete distribution outputs differ from the CPU contract")
    all(isapprox.(observed_floating, expected_floating; rtol = 8eps(Float32), atol = 0)) ||
        error("$name floating distribution outputs exceed the numerical profile")

    permutation_output = similar(device_distribution_addresses, UInt16,
        8 * length(distribution_addresses))
    permutation_kernel = _semantic_permutation_probe!(backend, 128)
    permutation_kernel(permutation_output, device_distribution_addresses, contract, seed;
        ndrange = length(distribution_addresses))
    KernelAbstractions.synchronize(backend)
    observed_permutations = Array(permutation_output)
    expected_permutations = similar(observed_permutations)
    for (index, address) in pairs(distribution_addresses)
        small_permutation!(view(expected_permutations, (8 * index - 7):(8 * index)),
            contract, seed, address)
    end
    observed_permutations == expected_permutations || error(
        "$name small permutations differ from the CPU contract")

    normals32 = observed_floating[2:2:end]
    poisson_exact32 = observed_integer[4:5:end]
    poisson_approx32 = observed_integer[5:5:end]
    abs(mean(normals32)) < 0.06 || error("$name Float32 normal mean is outside qualification")
    abs(var(normals32) - 1) < 0.10 || error(
        "$name Float32 normal variance is outside qualification")
    abs(mean(poisson_exact32) - 4) < 0.12 || error(
        "$name exact Poisson mean is outside qualification")
    abs(var(poisson_exact32) - 4) < 0.25 || error(
        "$name exact Poisson variance is outside qualification")
    abs(mean(poisson_approx32) - 100) < 0.5 || error(
        "$name approximate Poisson mean is outside qualification")
    abs(var(poisson_approx32) - 100) < 5 || error(
        "$name approximate Poisson variance is outside qualification")

    capabilities = backend_capabilities(backend)
    float64_report = if capabilities.device_float64
        floating64 = similar(device_distribution_addresses, Float64,
            2 * length(distribution_addresses))
        poisson64 = similar(device_distribution_addresses, Int32,
            length(distribution_addresses))
        float64_kernel = _semantic_float64_probe!(backend, 128)
        float64_kernel(floating64, poisson64, device_distribution_addresses, contract, seed;
            ndrange = length(distribution_addresses))
        KernelAbstractions.synchronize(backend)
        observed64 = Array(floating64)
        poisson_observed64 = Array(poisson64)
        normal64 = observed64[2:2:end]
        abs(mean(normal64)) < 0.06 || error("$name Float64 normal mean is outside qualification")
        abs(var(normal64) - 1) < 0.10 || error(
            "$name Float64 normal variance is outside qualification")
        abs(mean(poisson_observed64) - 4) < 0.12 || error(
            "$name Float64 Poisson mean is outside qualification")
        Dict("status" => "qualified", "samples" => length(distribution_addresses))
    else
        Dict("status" => "unsupported", "reason" => "backend capability forbids Float64")
    end
    return Dict(
        "backend" => name,
        "contract" => string(rng_contract_version(contract)),
        "addresses" => length(addresses),
        "raw_words" => length(observed),
        "bitwise_identity" => true,
        "bitwise_distributions" => ["bounded_uint", "bernoulli", "categorical",
            "small_permutation"],
        "statistical_distributions" => ["normal_box_muller", "poisson_inversion",
            "poisson_normal_approx"],
        "floating_distribution_tolerance" => "8eps(Float32)",
        "distribution_samples" => length(distribution_addresses),
        "float64" => float64_report,
    )
end

"""Qualify ordered launches, one explicit observation, and reusable storage on one backend."""
function qualify_execution_backend(name::String)
    input_host = UInt32.(1:257)
    input = _backend_array(name, input_host)
    stage = similar(input)
    output = similar(input)
    backend = KernelAbstractions.get_backend(input)
    metrics = ExecutionMetrics()
    plan = ExecutionPlan(backend; block_size = 128, metrics)
    first_kernel = _execution_stage_one!(backend, 128)
    second_kernel = _execution_stage_two!(backend, 128)

    launch!(plan, first_kernel, stage, input; ndrange = length(input))
    launch!(plan, second_kernel, output, stage; ndrange = length(input))
    metrics.host_synchronizations == 0 || error(
        "$name execution pipeline synchronized before its observation boundary")
    synchronize_observation!(plan)
    observed = Array(output)
    expected = 2 .* (input_host .+ UInt32(1))
    observed == expected || error("$name ordered execution pipeline produced incorrect output")

    state_metrics = ExecutionMetrics()
    state_plan = ExecutionPlan(backend; block_size = 128, metrics = state_metrics)
    logical = LogicalPottsState(fill(MediumOwner(1), 2, 2), CellCapacity(0);
        medium_domains = MediumID[MediumID(1)])
    compiled = compile_state(logical)
    adapted = adapt_execution(state_plan, _backend_adaptor(name), compiled)
    device_storage_valid(adapted.storage) || error(
        "$name adapted compiled state contains invalid or mixed-backend values")
    requirements = WorkspaceRequirements(4, 0;
        scratch_uint32 = 4, scratch_float32 = 0, flags = 0)
    allocate_workspace(state_plan, adapted, requirements)
    snapshot = logical_snapshot(state_plan, adapted)
    lattice_storage(snapshot) == lattice_storage(logical) || error(
        "$name compiled state does not round-trip to its logical snapshot")

    warm_launch_host_bytes = name == "cpu" ?
        @allocated(launch!(plan, first_kernel, stage, input; ndrange = length(input))) : missing
    name == "cpu" && synchronize_observation!(plan)
    capabilities = plan.capabilities
    return Dict(
        "backend" => name,
        "family" => string(capabilities.family),
        "contract_status" => string(capabilities.contract_status),
        "functional" => capabilities.functional,
        "ordered_launches" => capabilities.ordered_launches,
        "declared_semantic_rng_v1" => v"1.0.0" in capabilities.qualified_rng_contracts,
        "launches_before_observation" => 2,
        "internal_host_synchronizations" => 0,
        "observation_synchronizations" => 1,
        "corepotts_steady_state_scratch_allocations" => 0,
        "backend_runtime_warm_launch_host_bytes" => warm_launch_host_bytes,
        "compiled_state_roundtrip" => true,
        "workspace_bytes" => workspace_bytes(requirements),
        "initialization_host_allocations" => state_metrics.host_allocations,
        "initialization_device_allocations" => state_metrics.device_allocations,
        "initialization_host_to_device_transfers" => state_metrics.host_to_device_transfers,
        "snapshot_device_to_host_transfers" => state_metrics.device_to_host_transfers,
        "snapshot_synchronizations" => state_metrics.host_synchronizations,
        "elements" => length(observed),
    )
end

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
        joinpath(REPOSITORY_ROOT, "ext"),
        joinpath(REPOSITORY_ROOT, "lib"),
        joinpath(REPOSITORY_ROOT, "test"),
        joinpath(REPOSITORY_ROOT, "integration")
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
