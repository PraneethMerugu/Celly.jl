module Problem

using CorePotts
using StructArrays
using Random
using ..System

export PottsProblem

"""
    compile_component(pen::AbstractComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)

Returns `(compiled_penalty, required_trackers, initial_props)`.
"""
function compile_component end

function compile_component(pen::VolumeComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    FlexType = typeof(pen).parameters[1]
    required_trackers = Any[CorePotts.VolumeTracker()]
    if FlexType === CorePotts.Flex
        push!(required_trackers, CorePotts.VolumeFlexTracker())
    end
    λ_vec = zeros(Float32, num_types)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for (ct, vals) in pen.mappings
        id = type_to_id[ct]
        λ_vec[id + 1] = vals.λ
        props = Dict{Symbol, Any}(:target_volumes => Int32(round(vals.target)))
        if FlexType === CorePotts.Flex
            props[:volume_lambdas] = Float32(vals.λ)
        end
        initial_props[id] = props
    end
    comp_pen = FlexType === CorePotts.Flex ? CorePotts.VolumePenalty{Flex}() : CorePotts.VolumePenalty(λ_vec)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::HSTVolumeComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    FlexType = typeof(pen).parameters[1]
    required_trackers = Any[CorePotts.VolumeTracker()]
    if FlexType === CorePotts.Flex
        push!(required_trackers, CorePotts.VolumeFlexTracker())
    end
    λ_vec = zeros(Float32, num_types)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for (ct, vals) in pen.mappings
        id = type_to_id[ct]
        λ_vec[id + 1] = vals.λ
        props = Dict{Symbol, Any}(:target_volumes => Int32(round(vals.target)))
        if FlexType === CorePotts.Flex
            props[:volume_lambdas] = Float32(vals.λ)
        end
        initial_props[id] = props
    end
    comp_pen = FlexType === CorePotts.Flex ? CorePotts.HSTVolumePenalty{Flex}(eta = pen.eta) : CorePotts.HSTVolumePenalty(λ_vec, eta = pen.eta)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::SurfaceAreaComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    FlexType = typeof(pen).parameters[1]
    required_trackers = Any[CorePotts.SurfaceAreaTracker()]
    if FlexType === CorePotts.Flex
        push!(required_trackers, CorePotts.SurfaceAreaFlexTracker())
    end
    λ_vec = zeros(Float32, num_types)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for (ct, vals) in pen.mappings
        id = type_to_id[ct]
        λ_vec[id + 1] = vals.λ
        props = Dict{Symbol, Any}(:target_surface_areas => Int32(round(vals.target)))
        if FlexType === CorePotts.Flex
            props[:surface_area_lambdas] = Float32(vals.λ)
        end
        initial_props[id] = props
    end
    comp_pen = FlexType === CorePotts.Flex ? CorePotts.HSTSurfaceAreaPenalty{Flex}(eta = pen.eta) : CorePotts.HSTSurfaceAreaPenalty(λ_vec, eta = pen.eta)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::LengthComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    FlexType = typeof(pen).parameters[1]
    required_trackers = Any[]
    if FlexType === CorePotts.Flex
        push!(required_trackers, CorePotts.LengthFlexTracker())
    end
    λ_vec = zeros(Float32, num_types)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for (ct, vals) in pen.mappings
        id = type_to_id[ct]
        λ_vec[id + 1] = vals.λ
        props = Dict{Symbol, Any}(:target_lengths => Float32(vals.target))
        if FlexType === CorePotts.Flex
            props[:length_lambdas] = Float32(vals.λ)
        end
        initial_props[id] = props
    end
    comp_pen = FlexType === CorePotts.Flex ? CorePotts.HSTLengthPenalty{Flex}(eta = pen.eta) : CorePotts.HSTLengthPenalty(λ_vec, eta = pen.eta)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::ChemotaxisComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    λ_vec = zeros(Float32, num_types)
    for (ct, val) in pen.mappings
        id = type_to_id[ct]
        λ_vec[id + 1] = val
    end
    return CorePotts.ChemotaxisPenalty(λ_vec, pen.chemical_field), Any[], Dict{UInt8, Dict{Symbol, Any}}()
end

function compile_component(pen::AdhesionComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    FlexType = typeof(pen).parameters[1]
    Isotropic = typeof(pen).parameters[2]
    required_trackers = Any[]
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    
    if FlexType === CorePotts.Flex
        push!(required_trackers, CorePotts.AdhesionFlexTracker())
        for id in 1:(num_types - 1)
            initial_props[UInt8(id)] = Dict{Symbol, Any}(:adhesion_modifiers => 1.0f0)
        end
    end
    
    J_mat = zeros(Float32, num_types, num_types)
    for ((t1, t2), val) in pen.mappings
        id1 = type_to_id[t1]
        id2 = type_to_id[t2]
        J_mat[id1 + 1, id2 + 1] = val
        J_mat[id2 + 1, id1 + 1] = val
    end
    
    comp_pen = FlexType === CorePotts.Flex ? CorePotts.AdhesionPenalty{Flex}(J_mat; isotropic = Isotropic) : CorePotts.AdhesionPenalty(J_mat; isotropic = Isotropic)
    return comp_pen, required_trackers, initial_props
end

required_variables(comp::AbstractComponent) = (;)

function compile_penalties(sys::PottsSystem, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    compiled_penalties = []
    required_trackers = []
    
    # Declarative variables (symbol => datatype)
    all_variables = Dict{Symbol, DataType}()

    # properties to inject into the StructArray
    # e.g., type_id => (target_volumes=500.0,)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for id in 0:(num_types - 1)
        initial_props[UInt8(id)] = Dict{Symbol, Any}()
    end

    for pen in sys.penalties
        if pen isa CorePotts.AbstractPenalty
            push!(compiled_penalties, pen)
        else
            # Extract MTK-style required variables
            vars = required_variables(pen)
            for (k, v) in pairs(vars)
                all_variables[k] = v
            end

            # Call the multiple dispatch hook!
            comp_pen, comp_trackers, comp_props = compile_component(pen, type_to_id, num_types)
            
            push!(compiled_penalties, comp_pen)
            append!(required_trackers, comp_trackers)
            
            # Merge properties
            for (id, props) in comp_props
                if haskey(initial_props, id)
                    merge!(initial_props[id], props)
                else
                    initial_props[id] = props
                end
            end
        end
    end

    return tuple(compiled_penalties...), required_trackers, initial_props, NamedTuple(all_variables)
end

"""
    build_initial_state(u0_counts::Dict{CellType, Int}, 
                        type_to_id::Dict{CellType, UInt8}, 
                        initial_props::Dict{UInt8, Dict{Symbol, Any}},
                        grid_size::Tuple)

Constructs the grid and StructArray for the PottsState.
"""
function build_initial_state(u0_counts::Dict{CellType, Int},
        type_to_id::Dict{CellType, UInt8},
        initial_props::Dict{UInt8, Dict{Symbol, Any}},
        custom_vars::NamedTuple,
        grid_size::Tuple;
        max_cells::Union{Int, Nothing} = nothing,
        seed_center::Union{Tuple, Nothing} = nothing,
        seed_radius::Union{Int, Nothing} = nothing)
    grid = zeros(Int32, grid_size...)

    total_cells = sum(values(u0_counts))

    # We will randomly seed the cells in the grid, each starting with volume 1
    cell_id = 1
    available_indices = shuffle(1:length(grid))
    idx_counter = 1

    volumes = zeros(Int32, total_cells + 1)
    cell_types = zeros(UInt8, total_cells + 1)

    volumes[1] = prod(grid_size) - total_cells
    cell_types[1] = 0

    for (ct, count) in u0_counts
        if ct.name == :Medium
            continue # Already handled
        end

        type_id = type_to_id[ct]

        for _ in 1:count
            cell_id += 1

            if seed_center !== nothing && seed_radius !== nothing && total_cells == 1
                CorePotts.spawn_hypersphere!(grid, grid_size, seed_center, seed_radius, UInt32(cell_id))
                volumes[cell_id] = 0 # Will be synced automatically later by sync_cell_data!
            else
                # Place exactly 1 pixel
                linear_idx = available_indices[idx_counter]
                idx_counter += 1
                grid[linear_idx] = cell_id
                volumes[cell_id] = 1
            end
            
            cell_types[cell_id] = type_id
        end
    end

    allocated_cells = max_cells === nothing ? total_cells + 1 : max_cells
    
    # Allocate MTK-style custom kwargs
    custom_kwargs = Dict{Symbol, Any}()
    for (k, T) in pairs(custom_vars)
        custom_kwargs[k] = zeros(T, allocated_cells)
    end

    # Use CorePotts's initialization to safely create all required tracking fields 
    # (pressures, tensions, anchors, etc.) to guarantee compatibility with all physics rules.
    cell_data = CorePotts.build_cell_data(grid, allocated_cells; FloatType = Float32, IntType = Int32, custom_kwargs...)

    cell_data.volumes[1:(total_cells + 1)] .= volumes
    cell_data.cell_types[1:(total_cells + 1)] .= cell_types

    # Apply initial property map
    for i in 1:(total_cells + 1)
        ct_id = cell_data.cell_types[i]
        props = get(initial_props, ct_id, nothing)
        if props !== nothing
            for (k, v) in props
                getproperty(cell_data, k)[i] = v
            end
        end
    end
    
    # Empty free list. Mitosis will just bump u.N_cells[] up to the allocated capacity!
    free_list = UInt32[]

    return PottsState(grid, cell_data, Ref(total_cells + 1), free_list)
end

function CorePotts.PottsProblem(sys::PottsSystem,
        u0_counts::Dict{CellType, Int},
        grid_size::Tuple;
        tspan = (0, 10),
        topology = VonNeumannTopology{2}(),
        trackers = (),
        max_cells = nothing,
        seed_center = nothing,
        seed_radius = nothing)

    # 1. Map CellTypes to IDs
    # Ensure Medium is always ID 0
    type_to_id = Dict{CellType, UInt8}()
    medium_ct = CellType(:Medium)

    type_to_id[medium_ct] = 0
    current_id = 1
    for ct in sys.cell_types
        if ct != medium_ct && !haskey(type_to_id, ct)
            type_to_id[ct] = current_id
            current_id += 1
        end
    end
    num_types = length(type_to_id)

    # 2. Compile Penalties and gather initial properties, along with dynamically required trackers
    compiled_penalties, required_trackers, initial_props, custom_vars = compile_penalties(sys, type_to_id, num_types)

    # Deduplicate trackers by type
    unique_trackers = []
    tracker_types = Set{DataType}()
    for t in (required_trackers..., trackers...)
        if !(typeof(t) in tracker_types)
            push!(tracker_types, typeof(t))
            push!(unique_trackers, t)
        end
    end
    all_trackers = tuple(unique_trackers...)

    # 3. Build Initial State
    state = build_initial_state(u0_counts, type_to_id, initial_props, custom_vars, grid_size; 
                                max_cells = max_cells, seed_center = seed_center, seed_radius = seed_radius)

    # 4. Construct Problem
    p = PottsParameters(topology, compiled_penalties, all_trackers)

    return PottsProblem(state, tspan, p)
end

function CorePotts.PottsProblem(sys::PottsSystem, state::PottsState; tspan=(0, 10), trackers=())
    type_to_id = Dict{CellType, UInt8}()
    medium_ct = CellType(:Medium)

    type_to_id[medium_ct] = 0
    current_id = 1
    for ct in sys.cell_types
        if ct != medium_ct && !haskey(type_to_id, ct)
            type_to_id[ct] = current_id
            current_id += 1
        end
    end
    num_types = length(type_to_id)

    compiled_penalties, required_trackers, initial_props = compile_penalties(sys, type_to_id, num_types)

    unique_trackers = []
    tracker_types = Set{DataType}()
    for t in (required_trackers..., trackers...)
        if !(typeof(t) in tracker_types)
            push!(tracker_types, typeof(t))
            push!(unique_trackers, t)
        end
    end
    all_trackers = tuple(unique_trackers...)

    p = PottsParameters(MooreTopology{2}(), compiled_penalties, all_trackers)

    return PottsProblem(state, tspan, p)
end

end
