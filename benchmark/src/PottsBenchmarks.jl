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

@kernel function _scientific_phase6_probe!(output, metadata, state, proposal_relation,
        components, transaction, recipient, direction)
    index = @index(Global, Linear)
    if index == 1
        attempt = construct_copy_attempt(
            state, state.domain, proposal_relation, recipient, direction)
        metadata[1] = UInt32(attempt.outcome)
        metadata[2] = attempt.forward_multiplicity
        metadata[3] = attempt.reverse_multiplicity
        if is_actionable(attempt)
            proposal = actionable_proposal(attempt)
            volume = components.energies[1]
            contact = components.energies[2]
            boundary = components.energies[3]
            field_energy = components.energies[4]
            focal = components.energies[5]
            drive = components.drives[1]
            output[1] = energy_change(volume, proposal, state)
            output[2] = energy_change(contact, proposal, state, state.domain)
            output[3] = energy_change(boundary, proposal, state)
            output[4] = energy_change(field_energy, proposal, state, state.domain)
            output[5] = drive_log_bias(drive, proposal, state, state.domain)
            output[6] = energy_change(focal, proposal, state, transaction)
        end
    end
end

@kernel function _scientific_evaluation_probe!(output, metadata, state, components,
        proposal, transaction, connectivity_workspace)
    index = @index(Global, Linear)
    if index == 1
        context = ScientificProposalContext(
            state, transaction, connectivity_workspace, UInt32(4))
        evaluation = evaluate_copy(components, proposal, context, Float32)
        output[1] = evaluation.delta_h
        output[2] = evaluation.drive_log_bias
        output[3] = evaluation.kinetic_modifier
        output[4] = evaluation.yield_barrier
        metadata[1] = evaluation.constraints_allowed ? UInt32(1) : UInt32(0)
    end
end

@kernel function _scientific_query_probe!(output, metadata, state, connectivity,
        connectivity_proposal, connectivity_workspace, query_relation,
        medium_types, neighbor_workspace)
    index = @index(Global, Linear)
    if index == 1
        metadata[1] = is_allowed(connectivity, connectivity_proposal, state,
            connectivity_workspace, UInt32(1)) ? UInt32(1) : UInt32(0)
        metadata[2] = UInt32(contact_edge_count(state, state.domain, query_relation,
            CellOwner(1), AnyFiniteCell(), medium_types))
        metadata[3] = UInt32(boundary_site_count(state, state.domain, query_relation,
            CellOwner(1), AnyFiniteCell(), medium_types))
        output[1] = contact_measure(state, state.domain, query_relation,
            CellOwner(1), AnyFiniteCell(), medium_types)
        metadata[4] = UInt32(neighbor_cell_count(neighbor_workspace, state,
            state.domain, query_relation, CellOwner(1), AnyFiniteCell(), medium_types,
            UInt32(1)))
        output[2] = neighbor_property_sum(state, CellPropertyRef(:volume_strength),
            neighbor_workspace, state.domain, query_relation, CellOwner(1),
            AnyFiniteCell(), medium_types, UInt32(2))
        metadata[5] = UInt32(global_interface_measure(state, state.domain,
            query_relation, AnyFiniteCell(), AnyFiniteCell(),
            medium_types))
    end
end

@kernel function _normalized_surface_probe!(output, state, component, proposal)
    index = @index(Global, Linear)
    if index == 1
        output[1] = energy_change(component, proposal, state)
    end
end

function _backend_adaptor(name::String)
    name == "cpu" && return Array
    module_name = name == "metal" ? :Metal :
                  name == "cuda" ? :CUDA :
                  name == "amdgpu" ? :AMDGPU :
                  throw(ArgumentError(
        "Unknown backend `$name`"))
    isdefined(Main, module_name) ||
        error("$module_name must be loaded before RNG qualification")
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
    expected = reduce(vcat, collect(rng_words(contract, seed, address))
    for address in addresses)
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
    distribution_kernel(
        floating_output, integer_output, device_distribution_addresses, table,
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
    abs(mean(normals32)) < 0.06 ||
        error("$name Float32 normal mean is outside qualification")
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
        float64_kernel(
            floating64, poisson64, device_distribution_addresses, contract, seed;
            ndrange = length(distribution_addresses))
        KernelAbstractions.synchronize(backend)
        observed64 = Array(floating64)
        poisson_observed64 = Array(poisson64)
        normal64 = observed64[2:2:end]
        abs(mean(normal64)) < 0.06 ||
            error("$name Float64 normal mean is outside qualification")
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
        "float64" => float64_report
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
    observed == expected ||
        error("$name ordered execution pipeline produced incorrect output")

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
                             @allocated(launch!(
        plan, first_kernel, stage, input; ndrange = length(input))) : missing
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
        "elements" => length(observed)
    )
end

function _phase6_fixture(::Val{N}) where {N}
    dims = ntuple(_ -> 4, Val(N))
    volume = QuadraticVolumeHamiltonian(number_type = Float32)
    spacing = ntuple(_ -> 1.0f0, Val(N))
    surface_relation = first_shell_relation(SurfaceRole(), Val(N); spacing)
    boundary = QuadraticBoundaryHamiltonian(BoundaryEdgeCount(), surface_relation;
        number_type = Float32)
    schema = merge_property_schemas(required_properties(volume), required_properties(boundary))
    owners = fill(MediumOwner(1), dims)
    first_base = ntuple(_ -> 1, Val(N))
    first_axis = Base.setindex(first_base, 2, 1)
    first_second_axis = Base.setindex(first_base, 2, 2)
    second_base = Base.setindex(first_base, 3, 1)
    second_axis = Base.setindex(first_base, 4, 1)
    second_second_axis = Base.setindex(second_base, 2, 2)
    owners[first_base...] = owners[first_axis...] = owners[first_second_axis...] = CellOwner(1)
    owners[second_base...] = owners[second_axis...] = owners[second_second_axis...] = CellOwner(2)
    logical = LogicalPottsState(owners, CellCapacity(2);
        cell_types = Dict(CellID(1) => CellTypeID(2), CellID(2) => CellTypeID(2)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(logical, :target_volume) .= 4.0f0
    property_values(logical, :volume_strength) .= 1.25f0
    property_values(logical, :target_boundary) .= 8
    property_values(logical, :boundary_strength) .= 0.75f0
    domain = CartesianDomain(dims; spacing)
    proposal_relation = first_shell_relation(ProposalRole(), Val(N);
        spacing = domain.spacing)
    contact_relation = first_shell_relation(ContactRole(), Val(N);
        spacing = domain.spacing)
    query_relation = first_shell_relation(SpatialQueryRole(), Val(N);
        spacing = domain.spacing, symmetric = true)
    connectivity_relation = first_shell_relation(ConnectivityRole(), Val(N);
        spacing = domain.spacing)
    contact = UnorderedContactHamiltonian(Float32[0 3; 3 1],
        MediumTypeTable(MediumID(1) => CellTypeID(1)), contact_relation)
    boundary_tracker = BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation)
    moment_tracker = UnwrappedMomentTracker(
        connectivity_relation, (CellID(1), CellID(2)); number_type = Float32)
    compiled = compile_scientific_state(logical, domain, boundary_tracker; moment_tracker)
    coupling = OwnerScalarCoupling(:volume_strength, MediumID(1) => 0.0f0;
        number_type = Float32)
    field = CellCenteredField(reshape(Float32.(1:prod(dims)), dims);
        interpolation = NearestFieldInterpolation())
    field_energy = ExternalFieldOccupancyHamiltonian(field, coupling; energy_scale = 1.0f0)
    drive = ChemotaxisDrive(field, coupling, LinearResponse(), ExtensionChemotaxis())
    selected = nothing
    for recipient in eachindex(lattice_storage(logical))
        for direction in 1:direction_count(proposal_relation)
            candidate = construct_copy_attempt(
                logical, domain, proposal_relation, recipient, direction)
            if is_actionable(candidate)
                proposal = actionable_proposal(candidate)
                if is_medium_owner(proposal.losing) && is_cell_owner(proposal.gaining)
                    selected = (candidate, recipient, direction)
                    break
                end
            end
        end
        selected === nothing || break
    end
    selected === nothing &&
        error("internal Phase 6 qualification has no extension proposal")
    attempt, recipient, direction = selected
    proposal = actionable_proposal(attempt)
    transaction = stage_copy_transaction(
        compiled, boundary_tracker, proposal; moment_tracker)
    focal = FocalPointSpringHamiltonian(FocalPointLink(logical, CellID(1), CellID(2);
        strength = 1.25f0, target_length = 2.0f0))
    connectivity = PreserveConnectedCells(connectivity_relation)
    linear = LinearIndices(dims)
    bridge_recipient = linear[first_base...]
    bridge_donor = linear[second_axis...]
    connectivity_proposal = CopyProposal(bridge_recipient, bridge_donor,
        CellOwner(1), CellOwner(2))
    medium_types = MediumTypeTable(MediumID(1) => CellTypeID(1))
    return (; logical, domain, proposal_relation, volume, contact, boundary,
        boundary_tracker, moment_tracker, compiled, field_energy, drive, focal,
        proposal, transaction, recipient, direction, connectivity,
        connectivity_proposal, query_relation, medium_types,
        connectivity_workspace = ConnectivityWorkspace(prod(dims)),
        neighbor_workspace = DistinctNeighborWorkspace(nslots(capacity(logical))))
end

function _phase6_normalized_surface_fixture(::Val{N}) where {N}
    dims = ntuple(_ -> 6, Val(N))
    spacing = ntuple(_ -> 1.0f0, Val(N))
    domain = CartesianDomain(dims; spacing)
    relation = normalized_kernel_relation(Val(N); spacing = domain.spacing)
    metric = NormalizedKernelMeasure(domain, relation)
    component = QuadraticBoundaryHamiltonian(metric, relation;
        target = :target_normalized_boundary,
        strength = :normalized_boundary_strength, number_type = Float32)
    owners = fill(MediumOwner(1), dims)
    first = ntuple(_ -> 2, Val(N))
    second = Base.setindex(first, 3, 1)
    third = Base.setindex(first, 3, 2)
    owners[first...] = owners[second...] = owners[third...] = CellOwner(1)
    logical = LogicalPottsState(owners, CellCapacity(1);
        cell_types = Dict(CellID(1) => CellTypeID(1)), medium_domains = [MediumID(1)],
        property_schema = required_properties(component))
    property_values(logical, :target_normalized_boundary)[1] = 5.0f0
    property_values(logical, :normalized_boundary_strength)[1] = 0.75f0
    proposal_relation = first_shell_relation(ProposalRole(), Val(N);
        spacing = domain.spacing)
    proposal = nothing
    for recipient in eachindex(lattice_storage(logical))
        for direction in 1:direction_count(proposal_relation)
            attempt = construct_copy_attempt(
                logical, domain, proposal_relation, recipient, direction)
            if is_actionable(attempt)
                proposal = actionable_proposal(attempt)
                break
            end
        end
        proposal === nothing || break
    end
    proposal === nothing && error(
        "internal Phase 6 normalized-surface qualification has no proposal")
    tracker = BoundaryMeasureTracker(metric, relation)
    compiled = compile_scientific_state(logical, domain, tracker)
    transaction = stage_copy_transaction(compiled, tracker, proposal)
    return (; logical, domain, component, tracker, compiled, proposal, transaction)
end

"""Qualify the Phase 6 proposal, component, field, and staged-commit device path."""
function qualify_scientific_backend(name::String)
    adaptor = _backend_adaptor(name)
    compiled_bytes = Dict{String, Int}()
    workspace_byte_counts = Dict{String, Int}()
    for N in (2, 3)
        fixture = _phase6_fixture(Val(N))
        normalized = _phase6_normalized_surface_fixture(Val(N))
        runtime = scientific_execution(fixture.compiled)
        oracle_neighbor_workspace = DistinctNeighborWorkspace(
            nslots(capacity(fixture.logical)))
        oracle_connectivity_workspace = ConnectivityWorkspace(prod(fixture.domain.dims))
        host_components = ScientificComponentSet(
            energies = (fixture.volume, fixture.contact, fixture.boundary,
                fixture.field_energy, fixture.focal),
            drives = (fixture.drive,),
            constraints = (fixture.connectivity,
                FixedFocalEndpointConstraint(fixture.focal)),
            kinetic_modifiers = (PositiveYield(0.75f0),)
        )
        oracle_context = ScientificProposalContext(runtime, fixture.transaction;
            connectivity_workspace = oracle_connectivity_workspace, workspace_epoch = 4)
        oracle_evaluation = evaluate_copy(
            host_components, fixture.proposal, oracle_context, Float32)
        expected_components = Float32[
            energy_change(fixture.volume, fixture.proposal, fixture.logical),
            energy_change(fixture.contact, fixture.proposal, fixture.logical, fixture.domain),
            energy_change(fixture.boundary, fixture.proposal, fixture.logical, fixture.domain),
            energy_change(fixture.field_energy, fixture.proposal, fixture.logical, fixture.domain),
            drive_log_bias(fixture.drive, fixture.proposal, fixture.logical, fixture.domain),
            energy_change(fixture.focal, fixture.proposal, fixture.compiled,
                fixture.transaction)
        ]
        expected_evaluation = Float32[
            oracle_evaluation.delta_h,
            oracle_evaluation.drive_log_bias,
            oracle_evaluation.kinetic_modifier,
            oracle_evaluation.yield_barrier
        ]
        expected_queries = Float32[
            contact_measure(runtime, runtime.domain, fixture.query_relation,
                CellOwner(1), AnyFiniteCell(), fixture.medium_types),
            neighbor_property_sum(runtime, CellPropertyRef(:volume_strength),
                oracle_neighbor_workspace, runtime.domain, fixture.query_relation,
                CellOwner(1), AnyFiniteCell(), fixture.medium_types, UInt32(2))
        ]
        expected_proposal_metadata = UInt32[
            1,
            fixture.proposal.forward_multiplicity,
            fixture.proposal.reverse_multiplicity
        ]
        expected_evaluation_metadata = UInt32[
            oracle_evaluation.constraints_allowed ? 1 : 0,
        ]
        expected_query_metadata = UInt32[
            is_allowed(fixture.connectivity, fixture.connectivity_proposal, runtime,
                oracle_connectivity_workspace, UInt32(1)) ? 1 : 0,
            contact_edge_count(runtime, runtime.domain, fixture.query_relation,
                CellOwner(1), AnyFiniteCell(), fixture.medium_types),
            boundary_site_count(runtime, runtime.domain, fixture.query_relation,
                CellOwner(1), AnyFiniteCell(), fixture.medium_types),
            neighbor_cell_count(oracle_neighbor_workspace, runtime, runtime.domain,
                fixture.query_relation, CellOwner(1), AnyFiniteCell(), fixture.medium_types,
                UInt32(3)),
            global_interface_measure(runtime, runtime.domain, fixture.query_relation,
                AnyFiniteCell(), AnyFiniteCell(), fixture.medium_types)
        ]
        adapted = Adapt.adapt(adaptor, fixture.compiled)
        scientific_storage_valid(adapted) || error(
            "$name adapted scientific state contains invalid or mixed-backend values")
        components = Adapt.adapt(adaptor, host_components)
        connectivity_workspace = Adapt.adapt(adaptor, fixture.connectivity_workspace)
        neighbor_workspace = Adapt.adapt(adaptor, fixture.neighbor_workspace)
        validate_workspace(connectivity_workspace, scientific_execution(adapted))
        validate_workspace(neighbor_workspace, scientific_execution(adapted))
        component_output = _backend_array(
            name, zeros(Float32, length(expected_components)))
        proposal_metadata = _backend_array(
            name, zeros(UInt32, length(expected_proposal_metadata)))
        evaluation_output = _backend_array(
            name, zeros(Float32, length(expected_evaluation)))
        evaluation_metadata = _backend_array(
            name, zeros(UInt32, length(expected_evaluation_metadata)))
        query_output = _backend_array(name, zeros(Float32, length(expected_queries)))
        query_metadata = _backend_array(
            name, zeros(UInt32, length(expected_query_metadata)))
        backend = KernelAbstractions.get_backend(component_output)
        probe = _scientific_phase6_probe!(backend, 1)
        probe(component_output, proposal_metadata, scientific_execution(adapted),
            fixture.proposal_relation, components, fixture.transaction,
            fixture.recipient, fixture.direction;
            ndrange = 1)
        evaluation_probe = _scientific_evaluation_probe!(backend, 1)
        evaluation_probe(evaluation_output, evaluation_metadata,
            scientific_execution(adapted), components, fixture.proposal,
            fixture.transaction, connectivity_workspace; ndrange = 1)
        query_probe = _scientific_query_probe!(backend, 1)
        query_probe(query_output, query_metadata, scientific_execution(adapted),
            fixture.connectivity, fixture.connectivity_proposal,
            connectivity_workspace, fixture.query_relation, fixture.medium_types,
            neighbor_workspace; ndrange = 1)
        KernelAbstractions.synchronize(backend)
        observed_components = Array(component_output)
        observed_evaluation = Array(evaluation_output)
        observed_queries = Array(query_output)
        all(isapprox.(observed_components, expected_components;
            rtol = 16eps(Float32), atol = 16eps(Float32))) || error(
            "$name Phase 6 $N-D component outputs differ from the CPU oracle")
        all(isapprox.(observed_evaluation, expected_evaluation;
            rtol = 16eps(Float32), atol = 16eps(Float32))) || error(
            "$name Phase 6 $N-D generic evaluation differs from the CPU oracle")
        all(isapprox.(observed_queries, expected_queries;
            rtol = 16eps(Float32), atol = 16eps(Float32))) || error(
            "$name Phase 6 $N-D query outputs differ from the CPU oracle")
        Array(proposal_metadata) == expected_proposal_metadata || error(
            "$name Phase 6 $N-D proposal metadata differs from the CPU oracle")
        Array(evaluation_metadata) == expected_evaluation_metadata || error(
            "$name Phase 6 $N-D evaluation metadata differs from the CPU oracle")
        Array(query_metadata) == expected_query_metadata || error(
            "$name Phase 6 $N-D query metadata differs from the CPU oracle")

        normalized_expected = energy_change(normalized.component, normalized.proposal,
            normalized.logical, normalized.domain)
        adapted_normalized = Adapt.adapt(adaptor, normalized.compiled)
        scientific_storage_valid(adapted_normalized) || error(
            "$name adapted normalized-surface state contains invalid values")
        normalized_output = _backend_array(name, zeros(Float32, 1))
        normalized_backend = KernelAbstractions.get_backend(normalized_output)
        normalized_probe = _normalized_surface_probe!(normalized_backend, 1)
        normalized_probe(normalized_output, scientific_execution(adapted_normalized),
            normalized.component, normalized.proposal; ndrange = 1)
        normalized_metrics = ExecutionMetrics()
        normalized_plan = ExecutionPlan(
            normalized_backend; block_size = 1, metrics = normalized_metrics)
        launch_staged_commit!(normalized_plan, adapted_normalized,
            normalized.transaction; accepted = true)
        normalized_metrics.host_synchronizations == 0 || error(
            "$name Phase 6 normalized-surface path introduced a host synchronization")
        KernelAbstractions.synchronize(normalized_backend)
        isapprox(Array(normalized_output)[1], normalized_expected;
            rtol = 16eps(Float32), atol = 16eps(Float32)) || error(
            "$name Phase 6 $N-D normalized-surface delta differs from the CPU oracle")
        normalized_oracle = compile_scientific_state(
            normalized.logical, normalized.domain, normalized.tracker)
        commit_staged!(normalized_oracle, normalized.transaction; accepted = true)
        all(isapprox.(Array(adapted_normalized.trackers.boundary_measures),
            normalized_oracle.trackers.boundary_measures;
            rtol = 16eps(Float32), atol = 16eps(Float32))) || error(
            "$name Phase 6 $N-D normalized-surface commit differs from recomputation")

        metrics = ExecutionMetrics()
        plan = ExecutionPlan(backend; block_size = 1, metrics)
        launch_staged_commit!(plan, adapted, fixture.transaction; accepted = true)
        metrics.host_synchronizations == 0 || error(
            "$name Phase 6 staged commit introduced an internal host synchronization")
        KernelAbstractions.synchronize(backend)
        expected_compiled = compile_scientific_state(fixture.logical, fixture.domain,
            fixture.boundary_tracker; moment_tracker = fixture.moment_tracker)
        commit_staged!(expected_compiled, fixture.transaction; accepted = true)
        Array(adapted.potts.storage.ownership.ids) ==
        expected_compiled.potts.storage.ownership.ids || error(
            "$name staged ownership commit differs from the CPU oracle")
        Array(adapted.trackers.finite_volumes) ==
        expected_compiled.trackers.finite_volumes || error(
            "$name staged volume commit differs from the CPU oracle")
        Array(adapted.trackers.boundary_measures) ==
        expected_compiled.trackers.boundary_measures || error(
            "$name staged boundary commit differs from the CPU oracle")
        all(map(==, map(Array, adapted.trackers.moments.coordinate_sums),
            expected_compiled.trackers.moments.coordinate_sums)) || error(
            "$name staged moment commit differs from the CPU oracle")
        compiled_bytes[string(N, "D")] = scientific_state_bytes(adapted)
        workspace_byte_counts[string(N, "D")] = workspace_bytes(connectivity_workspace) +
                                                workspace_bytes(neighbor_workspace)
    end

    return Dict(
        "backend" => name,
        "dimensions" => [2, 3],
        "number_type" => "Float32",
        "proposal_conformance" => true,
        "volume_delta_conformance" => true,
        "contact_delta_conformance" => true,
        "boundary_delta_conformance" => true,
        "normalized_surface_conformance" => true,
        "field_energy_conformance" => true,
        "chemotaxis_conformance" => true,
        "focal_point_conformance" => true,
        "connectivity_conformance" => true,
        "spatial_query_conformance" => true,
        "transaction_conformance" => true,
        "internal_host_synchronizations" => 0,
        "compiled_bytes" => compiled_bytes,
        "workspace_bytes" => workspace_byte_counts
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
