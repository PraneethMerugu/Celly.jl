module Problem

using CorePotts
using Random
using ..System
using ..Layouts
using ..Events
import ..Layouts: AbstractLayout
import ..System: required_variables

export PottsProblem

"""
    compile_component(pen::AbstractComponent, type_to_id::Dict{CellType, UInt8}, num_types::Int)

Returns `(compiled_penalty, required_trackers, initial_props)`.
"""
function compile_component(pen::AbstractComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
    error("NotImplementedError: compile_component is not implemented for $(typeof(pen)). Please implement compile_component to return (compiled_penalty, required_trackers, initial_props).")
end

function compile_component(pen::VolumeComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
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
    comp_pen = FlexType === CorePotts.Flex ? CorePotts.VolumePenalty{Flex}() :
               CorePotts.VolumePenalty(λ_vec)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::HSTVolumeComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
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
    comp_pen = FlexType === CorePotts.Flex ?
               CorePotts.HSTVolumePenalty{Flex}(eta = pen.eta) :
               CorePotts.HSTVolumePenalty(λ_vec, eta = pen.eta)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::SurfaceAreaComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
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
    comp_pen = FlexType === CorePotts.Flex ?
               CorePotts.HSTSurfaceAreaPenalty{Flex}(eta = pen.eta) :
               CorePotts.HSTSurfaceAreaPenalty(λ_vec, eta = pen.eta)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::LengthComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
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
    comp_pen = FlexType === CorePotts.Flex ?
               CorePotts.HSTLengthPenalty{Flex}(eta = pen.eta) :
               CorePotts.HSTLengthPenalty(λ_vec, eta = pen.eta)
    return comp_pen, required_trackers, initial_props
end

function compile_component(pen::ChemotaxisComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
    λ_vec = zeros(Float32, num_types)
    for (ct, val) in pen.mappings
        id = type_to_id[ct]
        λ_vec[id + 1] = val
    end
    return CorePotts.ChemotaxisPenalty(λ_vec, pen.chemical_field), Any[],
    Dict{UInt8, Dict{Symbol, Any}}()
end

function compile_component(pen::AdhesionComponent, sys::PottsSystem,
        type_to_id::Dict{CellType, UInt8}, num_types::Int)
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

    comp_pen = FlexType === CorePotts.Flex ?
               CorePotts.AdhesionPenalty{Flex}(J_mat; isotropic = Isotropic) :
               CorePotts.AdhesionPenalty(J_mat; isotropic = Isotropic)
    return comp_pen, required_trackers, initial_props
end


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
            vars = required_variables(pen)
            for (k, v) in pairs(vars)
                all_variables[k] = v
            end
        else
            # Call the multiple dispatch hook!
            comp_pen, comp_trackers, comp_props = compile_component(pen, sys, type_to_id, num_types)
            
            # Extract MTK-style required variables from the compiled penalty
            vars = required_variables(comp_pen)
            for (k, v) in pairs(vars)
                all_variables[k] = v
            end
            
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

    for t in required_trackers
        vars = required_variables(t)
        for (k, v) in pairs(vars)
            all_variables[k] = v
        end
    end

    all_trackers = Tuple(unique(required_trackers))

    return Tuple(compiled_penalties), all_trackers, initial_props, NamedTuple(all_variables)
end

"""
    build_initial_state(layout::AbstractLayout, 
                        type_to_id::Dict{CellType, UInt8}, 
                        initial_props::Dict{UInt8, Dict{Symbol, Any}},
                        custom_vars::NamedTuple,
                        grid_size::Tuple;
                        max_cells::Union{Int, Nothing} = nothing)

Constructs the grid and StructArray for the PottsState using a declarative layout.
"""
function build_initial_state(layout::AbstractLayout,
        type_to_id::Dict{CellType, UInt8},
        initial_props::Dict{UInt8, Dict{Symbol, Any}},
        custom_vars::NamedTuple,
        grid_size::Tuple;
        max_cells::Union{Int, Nothing} = nothing)
    ctx = Layouts.LayoutContext(grid_size, type_to_id)
    Layouts.build_layout!(layout, ctx)

    total_cells = ctx.next_cell_id - 1
    allocated_cells = max_cells === nothing ? total_cells : max_cells

    volumes = zeros(Int32, allocated_cells)
    for px in ctx.grid
        if px > 0 && px <= allocated_cells
            volumes[px] += 1
        end
    end

    cell_types = zeros(UInt8, allocated_cells)
    for (cell_id, type_id) in ctx.cell_type_map
        if cell_id > 0 && cell_id <= allocated_cells
            cell_types[cell_id] = type_id
        end
    end

    # Allocate MTK-style custom kwargs
    custom_kwargs = Dict{Symbol, Any}()
    for (k, T) in pairs(custom_vars)
        custom_kwargs[k] = zeros(T, allocated_cells)
    end

    # Use CorePotts's initialization to safely create all required tracking fields 
    cell_data = CorePotts.build_cell_data(
        ctx.grid, allocated_cells; FloatType = Float32, IntType = Int32, custom_kwargs...)

    cell_data.volumes[1:total_cells] .= volumes[1:total_cells]
    cell_data.cell_types[1:total_cells] .= cell_types[1:total_cells]

    # Apply initial property map
    for i in 1:total_cells
        ct_id = cell_data.cell_types[i]
        props = get(initial_props, ct_id, nothing)
        if props !== nothing
            for (k, v) in props
                getproperty(cell_data, k)[i] = v
            end
        end
    end

    # Pre-allocate free_list to max capacity so it can be used on GPU
    free_list = zeros(UInt32, length(cell_data.volumes))

    return PottsState(convert(Array{UInt32}, ctx.grid), cell_data,
        Int32[total_cells], free_list, Int32[0])
end

function CorePotts.PottsProblem(sys::PottsSystem,
        layout::AbstractLayout,
        grid_size::Tuple;
        tspan = (0, 10),
        topology = VonNeumannTopology{2}(),
        trackers = (),
        max_cells = nothing)

    # 1. Map CellTypes to IDs
    # Ensure background types (is_background = true) are mapped to ID 0
    type_to_id = Dict{CellType, UInt8}()

    for ct in sys.cell_types
        if ct.is_background
            type_to_id[ct] = 0
        end
    end

    current_id = 1
    for ct in sys.cell_types
        if !ct.is_background && !haskey(type_to_id, ct)
            type_to_id[ct] = current_id
            current_id += 1
        end
    end
    num_types = current_id

    # 2. Compile Penalties and gather initial properties, along with dynamically required trackers
    compiled_penalties, required_trackers, initial_props, custom_vars = compile_penalties(
        sys, type_to_id, num_types)

    # 2.5 Compile Events
    resolved_events, event_reqs = Events.compile_events(sys.events, sys, type_to_id, sys.check_interval)

    # Merge event reqs into custom_vars
    merged_custom_vars = Dict{Symbol, DataType}()
    for (k, v) in pairs(custom_vars)
        merged_custom_vars[k] = v
    end
    for req in event_reqs
        for (k, v) in pairs(req)
            merged_custom_vars[k] = v
        end
    end
    for t in trackers
        req = required_variables(t)
        for (k, v) in pairs(req)
            merged_custom_vars[k] = v
        end
    end
    custom_vars = NamedTuple(merged_custom_vars)

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
    state = build_initial_state(layout, type_to_id, initial_props, custom_vars, grid_size;
        max_cells = max_cells)

    # 4. Construct Problem
    p = PottsParameters(topology, compiled_penalties, all_trackers, resolved_events)

    # 5. Strictly synchronize all physics trackers to match the layout
    # set_targets = false because target_volumes/areas are already initialized from initial_props!
    cache = CorePotts.PottsCache(state, topology)
    CorePotts.sync_cell_data!(state, p, cache, state.N_cells[]; set_targets = false)

    return PottsProblem(state, tspan, p)
end

function CorePotts.PottsProblem(sys::PottsSystem,
        u0_counts::Dict{CellType, Int},
        grid_size::Tuple;
        kwargs...)
    return CorePotts.PottsProblem(sys, Layouts.RandomLayout(u0_counts), grid_size; kwargs...)
end

function CorePotts.PottsProblem(sys::PottsSystem, state::PottsState; tspan = (0, 10), trackers = ())
    type_to_id = Dict{CellType, UInt8}()

    for ct in sys.cell_types
        if ct.is_background
            type_to_id[ct] = 0
        end
    end

    current_id = 1
    for ct in sys.cell_types
        if !ct.is_background && !haskey(type_to_id, ct)
            type_to_id[ct] = current_id
            current_id += 1
        end
    end
    num_types = current_id

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
