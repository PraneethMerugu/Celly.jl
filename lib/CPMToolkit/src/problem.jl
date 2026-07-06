module Problem

using CoreCPM
using StructArrays
using Random
using ..System

export CPMProblem

"""
    compile_penalties(sys::CPMSystem, type_to_id::Dict{CellType, UInt8}, num_types::Int)

Converts symbolic `CPMToolkit` penalties into `CoreCPM` dense array penalties.
Returns a tuple of compiled penalties and a Dict of initial properties to populate `cell_data`.
"""
function compile_penalties(sys::CPMSystem, type_to_id::Dict{CellType, UInt8}, num_types::Int)
    compiled_penalties = []
    required_trackers = []
    
    # properties to inject into the StructArray
    # e.g., type_id => (target_volumes=500.0,)
    initial_props = Dict{UInt8, Dict{Symbol, Any}}()
    for id in 0:(num_types-1)
        initial_props[UInt8(id)] = Dict{Symbol, Any}()
    end

    for pen in sys.penalties
        if pen isa VolumeComponent
            FlexType = typeof(pen).parameters[1]
            push!(required_trackers, CoreCPM.VolumeTracker())
            if FlexType === CoreCPM.Flex
                push!(required_trackers, CoreCPM.VolumeFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_volumes] = Int32(round(vals.target))
                if FlexType === CoreCPM.Flex
                    initial_props[id][:volume_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CoreCPM.Flex
                push!(compiled_penalties, CoreCPM.VolumePenalty{Flex}())
            else
                push!(compiled_penalties, CoreCPM.VolumePenalty(λ_vec))
            end
            
        elseif pen isa HSTVolumeComponent
            FlexType = typeof(pen).parameters[1]
            push!(required_trackers, CoreCPM.VolumeTracker())
            if FlexType === CoreCPM.Flex
                push!(required_trackers, CoreCPM.VolumeFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_volumes] = Int32(round(vals.target))
                if FlexType === CoreCPM.Flex
                    initial_props[id][:volume_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CoreCPM.Flex
                push!(compiled_penalties, CoreCPM.HSTVolumePenalty{Flex}(eta=pen.eta))
            else
                push!(compiled_penalties, CoreCPM.HSTVolumePenalty(λ_vec, eta=pen.eta))
            end

        elseif pen isa SurfaceAreaComponent
            FlexType = typeof(pen).parameters[1]
            push!(required_trackers, CoreCPM.SurfaceAreaTracker())
            if FlexType === CoreCPM.Flex
                push!(required_trackers, CoreCPM.SurfaceAreaFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_surface_areas] = Int32(round(vals.target))
                if FlexType === CoreCPM.Flex
                    initial_props[id][:surface_area_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CoreCPM.Flex
                push!(compiled_penalties, CoreCPM.HSTSurfaceAreaPenalty{Flex}(eta=pen.eta))
            else
                push!(compiled_penalties, CoreCPM.HSTSurfaceAreaPenalty(λ_vec, eta=pen.eta))
            end
            
        elseif pen isa LengthComponent
            FlexType = typeof(pen).parameters[1]
            # Length component does not currently have a builtin tracker equivalent,
            # we rely on the inertia tensors being tracked if needed, 
            # but currently LengthPenalty evaluates purely locally or via tracked COM.
            if FlexType === CoreCPM.Flex
                push!(required_trackers, CoreCPM.LengthFlexTracker())
            end
            λ_vec = zeros(Float32, num_types)
            for (ct, vals) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = vals.λ
                initial_props[id][:target_lengths] = Float32(vals.target)
                if FlexType === CoreCPM.Flex
                    initial_props[id][:length_lambdas] = Float32(vals.λ)
                end
            end
            if FlexType === CoreCPM.Flex
                push!(compiled_penalties, CoreCPM.HSTLengthPenalty{Flex}(eta=pen.eta))
            else
                push!(compiled_penalties, CoreCPM.HSTLengthPenalty(λ_vec, eta=pen.eta))
            end
            
        elseif pen isa ChemotaxisComponent
            λ_vec = zeros(Float32, num_types)
            for (ct, val) in pen.mappings
                id = type_to_id[ct]
                λ_vec[id + 1] = val
            end
            push!(compiled_penalties, CoreCPM.ChemotaxisPenalty(λ_vec, pen.chemical_field))

        elseif pen isa AdhesionComponent
            FlexType = typeof(pen).parameters[1]
            if FlexType === CoreCPM.Flex
                push!(required_trackers, CoreCPM.AdhesionFlexTracker())
                # For Medium, initialized properties fall back to 1.0 logic in get_modifier
                for id in 1:(num_types-1)
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
            if FlexType === CoreCPM.Flex
                push!(compiled_penalties, CoreCPM.AdhesionPenalty{Flex}(J_mat))
            else
                push!(compiled_penalties, CoreCPM.AdhesionPenalty(J_mat))
            end
            
        elseif pen isa CoreCPM.AbstractPenalty
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

Constructs the grid and StructArray for the CPMState.
"""
function build_initial_state(u0_counts::Dict{CellType, Int}, 
                             type_to_id::Dict{CellType, UInt8}, 
                             initial_props::Dict{UInt8, Dict{Symbol, Any}},
                             grid_size::Tuple;
                             max_cells::Union{Int, Nothing}=nothing)
                             
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
    
    # Use CoreCPM's initialization to safely create all required tracking fields 
    # (pressures, tensions, anchors, etc.) to guarantee compatibility with all physics rules.
    allocated_cells = max_cells === nothing ? total_cells + 1 : max_cells
    cell_data = CoreCPM.build_cell_data(grid, allocated_cells; FloatType=Float32, IntType=Int32)
    
    cell_data.volumes[1:total_cells+1] .= volumes
    cell_data.cell_types[1:total_cells+1] .= cell_types
    
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
    
    return CPMState(grid, cell_data)
end

function CoreCPM.CPMProblem(sys::CPMSystem, 
                            u0_counts::Dict{CellType, Int}, 
                            grid_size::Tuple; 
                            tspan=(0, 10), 
                            topology=VonNeumannTopology{2}(),
                            trackers=(),
                            max_cells=nothing)
    
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
    u0 = build_initial_state(u0_counts, type_to_id, initial_props, grid_size; max_cells=max_cells)
    
    # 4. Construct Problem
    p = CPMParameters(topology, compiled_penalties, all_trackers)
    
    return CPMProblem(u0, tspan, p)
end

end
