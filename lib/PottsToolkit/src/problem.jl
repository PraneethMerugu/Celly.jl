module Problem

using CorePotts
using StructArrays
using Random
using ..System

export PottsProblem

"""
    compile_penalties(sys::PottsSystem, type_to_id::Dict{CellType, UInt8}, num_types::Int)

Converts symbolic `PottsToolkit` penalties into `CorePotts` dense array penalties.
Returns a tuple of compiled penalties and a Dict of initial properties to populate `cell_data`.
"""
function compile_penalties(sys::PottsSystem, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    compiled_penalties = []
    required_trackers = []

    # properties to inject into the StructArray
    # e.g., type_id => (target_volumes=500.0,)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for id in 0:(num_types - 1)
        initial_props[UInt8(id)] = Dict{Symbol, Any}()
    end

    for pen in sys.penalties
        if pen isa VolumeComponent
            FlexType = typeof(pen).parameters[1]
            push!(required_trackers, CorePotts.VolumeTracker())
            if FlexType === CorePotts.Flex
                push!(required_trackers, CorePotts.VolumeFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_volumes] = Int32(round(vals.target))
                if FlexType === CorePotts.Flex
                    initial_props[id][:volume_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CorePotts.Flex
                push!(compiled_penalties, CorePotts.VolumePenalty{Flex}())
            else
                push!(compiled_penalties, CorePotts.VolumePenalty(λ_vec))
            end

        elseif pen isa HSTVolumeComponent
            FlexType = typeof(pen).parameters[1]
            push!(required_trackers, CorePotts.VolumeTracker())
            if FlexType === CorePotts.Flex
                push!(required_trackers, CorePotts.VolumeFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_volumes] = Int32(round(vals.target))
                if FlexType === CorePotts.Flex
                    initial_props[id][:volume_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CorePotts.Flex
                push!(compiled_penalties, CorePotts.HSTVolumePenalty{Flex}(eta = pen.eta))
            else
                push!(compiled_penalties, CorePotts.HSTVolumePenalty(λ_vec, eta = pen.eta))
            end

        elseif pen isa SurfaceAreaComponent
            FlexType = typeof(pen).parameters[1]
            push!(required_trackers, CorePotts.SurfaceAreaTracker())
            if FlexType === CorePotts.Flex
                push!(required_trackers, CorePotts.SurfaceAreaFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_surface_areas] = Int32(round(vals.target))
                if FlexType === CorePotts.Flex
                    initial_props[id][:surface_area_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CorePotts.Flex
                push!(compiled_penalties, CorePotts.HSTSurfaceAreaPenalty{Flex}(eta = pen.eta))
            else
                push!(compiled_penalties, CorePotts.HSTSurfaceAreaPenalty(λ_vec, eta = pen.eta))
            end

        elseif pen isa LengthComponent
            FlexType = typeof(pen).parameters[1]
            # Length component does not currently have a builtin tracker equivalent,
            # we rely on the inertia tensors being tracked if needed, 
            # but currently LengthPenalty evaluates purely locally or via tracked COM.
            if FlexType === CorePotts.Flex
                push!(required_trackers, CorePotts.LengthFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_lengths] = Float32(vals.target)
                if FlexType === CorePotts.Flex
                    initial_props[id][:length_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CorePotts.Flex
                push!(compiled_penalties, CorePotts.HSTLengthPenalty{Flex}(eta = pen.eta))
            else
                push!(compiled_penalties, CorePotts.HSTLengthPenalty(λ_vec, eta = pen.eta))
            end

        elseif pen isa ChemotaxisComponent
            λ_vec = zeros(Float32, num_types)
            for (ct, val) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = val
            end
            push!(compiled_penalties, CorePotts.ChemotaxisPenalty(λ_vec, pen.chemical_field))

        elseif pen isa AdhesionComponent
            FlexType = typeof(pen).parameters[1]
            Isotropic = typeof(pen).parameters[2]
            if FlexType === CorePotts.Flex
                push!(required_trackers, CorePotts.AdhesionFlexTracker())
                # For Medium, initialized properties fall back to 1.0 logic in get_modifier
                for id in 1:(num_types - 1)
                    initial_props[id][:adhesion_modifiers] = 1.0f0
                end
            end
            J_mat = zeros(Float32, num_types, num_types)
            for ((t1, t2), val) in pen.mappings
                id1 = type_to_id[t1]
                id2 = type_to_id[t2]
                J_mat[id1 + 1, id2 + 1] = val
                J_mat[id2 + 1, id1 + 1] = val
            end
            if FlexType === CorePotts.Flex
                push!(compiled_penalties, CorePotts.AdhesionPenalty{Flex}(J_mat; isotropic=Isotropic))
            else
                push!(compiled_penalties, CorePotts.AdhesionPenalty(J_mat; isotropic=Isotropic))
            end

        elseif pen isa CorePotts.AbstractPenalty
            # Raw penalty fallback
            push!(compiled_penalties, pen)
        else
            error("Unknown penalty type: $(typeof(pen))")
        end
    end

    return tuple(compiled_penalties...), required_trackers, initial_props
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
        grid_size::Tuple;
        max_cells::Union{Int, Nothing} = nothing)
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

            # Place exactly 1 pixel
            linear_idx = available_indices[idx_counter]
            idx_counter += 1

            grid[linear_idx] = cell_id

            volumes[cell_id] = 1
            cell_types[cell_id] = type_id
        end
    end

    # Use CorePotts's initialization to safely create all required tracking fields 
    # (pressures, tensions, anchors, etc.) to guarantee compatibility with all physics rules.
    allocated_cells = max_cells === nothing ? total_cells + 1 : max_cells
    cell_data = CorePotts.build_cell_data(grid, allocated_cells; FloatType = Float32, IntType = Int32)

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

    return PottsState(grid, cell_data)
end

function CorePotts.PottsProblem(sys::PottsSystem,
        u0_counts::Dict{CellType, Int},
        grid_size::Tuple;
        tspan = (0, 10),
        topology = VonNeumannTopology{2}(),
        trackers = (),
        max_cells = nothing)

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
    compiled_penalties, required_trackers, initial_props = compile_penalties(sys, type_to_id, num_types)

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
    u0 = build_initial_state(
        u0_counts, type_to_id, initial_props, grid_size; max_cells = max_cells)

    # 4. Construct Problem
    p = PottsParameters(topology, compiled_penalties, all_trackers)

    return PottsProblem(u0, tspan, p)
end

end
