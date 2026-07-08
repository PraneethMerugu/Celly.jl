module CorePottsMermaidExt

using CorePotts
using Mermaid
using Adapt
using CommonSolve
import CommonSolve: init, step!
import Mermaid: AbstractTimeDependentComponent, AbstractComponentIntegrator,
                ConnectedVariable

"""
    PottsComponent(model::PottsProblem, alg::AbstractPottsAlgorithm;
                 name::String="Tissue", timestep::Real=1.0)

A Mermaid component that wraps a Cellular Potts Model simulation.
"""
struct _PottsComponent{P <: PottsProblem, A <: AbstractPottsAlgorithm} <:
       AbstractTimeDependentComponent
    model::P
    alg::A
    name::String
    timestep::Float64
    state_names::Dict{String, Any}
end

function CorePotts.PottsComponent(model::PottsProblem, alg::AbstractPottsAlgorithm;
        name::AbstractString = "Tissue", timestep::Real = 1.0)
    return _PottsComponent(model, alg, name, timestep, Dict{String, Any}())
end

mutable struct _PottsComponentIntegrator{I, C} <: AbstractComponentIntegrator
    integrator::I
    component::C
    getters::Dict{String, Function}
end

function init(c::_PottsComponent)
    integrator = init(c.model, c.alg)

    getters = Dict{String, Function}()

    # 1. Base states
    getters["#time"] = (intg) -> intg.t
    getters["#state"] = (intg) -> intg.u
    getters["#grid"] = (intg) -> intg.u.grid

    getters["#ids"] = (intg) -> begin
        N = intg.u.N_cells[]
        vols = Adapt.adapt(Array, intg.u.cell_data.volumes)
        return findall(i -> vols[i] > 0, 1:N)
    end

    # 2. Cell data
    for field in propertynames(integrator.u.cell_data)
        field_str = string(field)
        let f = field
            getters[field_str] = (intg) -> getproperty(intg.u.cell_data, f)
        end
    end

    # 3. Penalties & Trackers
    name_counts = Dict{String, Int}()
    for p in integrator.p.penalties
        tname = string(nameof(typeof(p)))
        name_counts[tname] = get(name_counts, tname, 0) + 1
    end

    current_counts = Dict{String, Int}()
    for (i, p) in enumerate(integrator.p.penalties)
        tname = string(nameof(typeof(p)))
        if name_counts[tname] > 1
            current_counts[tname] = get(current_counts, tname, 0) + 1
            p_name = "$(tname)[$(current_counts[tname])]"
        else
            p_name = tname
        end

        for field in propertynames(p)
            var_name = "$(p_name).$(field)"
            let i_idx = i, f = field
                getters[var_name] = (intg) -> getproperty(intg.p.penalties[i_idx], f)
            end
        end
    end

    return _PottsComponentIntegrator(integrator, c, getters)
end

function step!(compInt::_PottsComponentIntegrator)
    # The Potts Integrator intrinsically handles its own time mapping, but Mermaid requests a step.
    # We call the base SciML step! 
    step!(compInt.integrator)
end

function Mermaid.getstate(compInt::_PottsComponentIntegrator, key::ConnectedVariable)
    var = key.variable

    if !haskey(compInt.getters, var)
        throw(KeyError(var))
    end

    data = compInt.getters[var](compInt.integrator)

    if first(var) == '#'
        return data isa AbstractArray ? Adapt.adapt(Array, data) : data
    end

    cpu_data = data isa AbstractArray ? Adapt.adapt(Array, data) : data

    if isnothing(key.variableindex)
        # If it's cell data, bound it by N_cells
        if hasproperty(compInt.integrator.u.cell_data, Symbol(var))
            N = compInt.integrator.u.N_cells[]
            vols = Adapt.adapt(Array, compInt.integrator.u.cell_data.volumes)
            # Return actively bound slice. If returning an array that can be written to, 
            # returning a view is better, but getstate implies reading. We'll return an array of active.
            return [cpu_data[i] for i in 1:N if vols[i] > 0]
        else
            return cpu_data
        end
    else
        out = [cpu_data[i] for i in key.variableindex]
        return length(out) == 1 ? out[1] : out
    end
end

function Mermaid.getstate(compInt::_PottsComponentIntegrator)
    return compInt.integrator.u
end

function Mermaid.setstate!(compInt::_PottsComponentIntegrator, key::ConnectedVariable, value)
    var = key.variable

    if first(var) == '#'
        if var == "#time"
            compInt.integrator.t = value
            return nothing
        elseif var == "#state"
            Mermaid.setstate!(compInt, value)
            return nothing
        elseif var == "#ids"
            @warn "Cannot explicitly set #ids for CorePotts. Cells are spawned via mitosis/death."
            return nothing
        end
    end

    if !haskey(compInt.getters, var)
        throw(KeyError(var))
    end

    data_col = compInt.getters[var](compInt.integrator)

    if isnothing(key.variableindex)
        if data_col isa AbstractArray
            if hasproperty(compInt.integrator.u.cell_data, Symbol(var))
                cpu_data = Adapt.adapt(Array, data_col)
                N = compInt.integrator.u.N_cells[]
                vols = Adapt.adapt(Array, compInt.integrator.u.cell_data.volumes)
                active_ids = findall(i -> vols[i] > 0, 1:N)

                limit = min(length(value), length(active_ids))
                for idx in 1:limit
                    cpu_data[active_ids[idx]] = value[idx]
                end
                copyto!(data_col, cpu_data)
            else
                if value isa AbstractArray
                    copyto!(data_col, value)
                else
                    data_col .= value
                end
            end
        else
            @warn "Cannot mutate immutable scalar parameter $var"
        end
    else
        cpu_data = Adapt.adapt(Array, data_col)
        k = 1
        for i in key.variableindex
            cpu_data[i] = value[k]
            k += 1
        end
        copyto!(data_col, cpu_data)
    end

    # For simplicity, if any target_volume or lambda changes, re-init track metrics before next sweep
    CorePotts.initialize_all_metrics!(
        compInt.integrator.p.trackers, compInt.integrator.u.cell_data,
        compInt.integrator.u.grid, compInt.integrator.p.topology,
        compInt.integrator.cache.grid_dims)
    return nothing
end

function Mermaid.setstate!(compInt::_PottsComponentIntegrator, state::CorePotts.AbstractPottsState)
    compInt.integrator.u = state
    CorePotts.initialize_all_metrics!(
        compInt.integrator.p.trackers, compInt.integrator.u.cell_data,
        compInt.integrator.u.grid, compInt.integrator.p.topology,
        compInt.integrator.cache.grid_dims)
end

function Mermaid.variables(comp::_PottsComponent)
    # We can't access the actual instance getters until init() is called.
    # However, Mermaid calls `variables()` on the component *before* init() sometimes.
    # We must replicate the logic here using `comp.model.u0` and `comp.model.p.penalties`.

    vars = String["#ids", "#time", "#state", "#grid"]

    for p in propertynames(comp.model.u0.cell_data)
        push!(vars, string(p))
    end

    name_counts = Dict{String, Int}()
    for penalty in comp.model.p.penalties
        tname = string(nameof(typeof(penalty)))
        name_counts[tname] = get(name_counts, tname, 0) + 1
    end

    current_counts = Dict{String, Int}()
    for penalty in comp.model.p.penalties
        tname = string(nameof(typeof(penalty)))
        if name_counts[tname] > 1
            current_counts[tname] = get(current_counts, tname, 0) + 1
            p_name = "$(tname)[$(current_counts[tname])]"
        else
            p_name = tname
        end

        for prop in propertynames(penalty)
            push!(vars, p_name * "." * string(prop))
        end
    end

    return vars
end

end # module
