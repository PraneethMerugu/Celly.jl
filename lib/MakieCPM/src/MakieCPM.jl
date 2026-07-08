module MakieCPM

using CoreCPM
using CommonSolve
using Makie
import Random
import SciMLBase

export cpmplot, cpmplot!
export explore_cpm, record_cpm

@recipe(CPMPlot, state) do scene
    Attributes(
        # Default colors: 1:Medium (Dark), 2:Type1 (Red), 3:Type2 (Blue), 4:Type3 (Green), etc.
        type_colors = ["#1C1C1E", "#FF3B30", "#007AFF", "#34C759",
            "#FF9500", "#AF52DE", "#5E5CE6", "#FF2D55"],
        slice = 0,
        draw_boundaries = false,
        boundary_color = "#000000"
    )
end

function Makie.plot!(plot::CPMPlot{<:Tuple{<:Any}})
    state_obs = plot[1]

    color_map_obs = lift(state_obs, plot.type_colors, plot.slice, plot.draw_boundaries,
        plot.boundary_color) do u, colors, slice_idx, draw_b, b_color
        cmap = Makie.to_colormap(colors)
        b_c = Makie.to_color(b_color)
        N_col = length(cmap)

        g_full = u.grid
        g = ndims(g_full) == 3 ?
            g_full[:, :, slice_idx <= 0 ? size(g_full, 3) ÷ 2 : slice_idx] : g_full

        ct = u.cell_data.cell_types

        img = Matrix{Makie.RGBAf}(undef, size(g))
        dims = size(g)

        if draw_b && ndims(g) == 2
            for j in 1:dims[2]
                for i in 1:dims[1]
                    id = g[i, j]

                    is_boundary = false
                    if id != 0
                        for (di, dj) in ((1, 0), (-1, 0), (0, 1), (0, -1))
                            ni, nj = i + di, j + dj
                            if ni >= 1 && ni <= dims[1] && nj >= 1 && nj <= dims[2]
                                nid = g[ni, nj]
                                if nid != id
                                    is_boundary = true
                                    break
                                end
                            end
                        end
                    end

                    if is_boundary
                        img[i, j] = b_c
                    else
                        type_id = id == 0 ? 0 : ct[id]
                        img[i, j] = Makie.to_color(cmap[mod1(type_id + 1, N_col)])
                    end
                end
            end
        else
            for i in eachindex(g)
                id = g[i]
                type_id = id == 0 ? 0 : ct[id]
                img[i] = Makie.to_color(cmap[mod1(type_id + 1, N_col)])
            end
        end

        return img
    end

    image!(plot, color_map_obs, interpolate = false)
    return plot
end

function explore_cpm(prob, alg;
        metrics::Vector{<:Pair} = Pair{String, Any}[],
        parameters::Vector{<:Pair} = Pair{String, NamedTuple}[],
        resolution = (1400, 900),
        solve_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    fig = Figure(size = resolution)

    # Deepcopy initial state BEFORE running the simulation
    base_u0 = deepcopy(prob.u0)

    # Pre-solve so we have something to show
    sol = CommonSolve.solve(prob, alg; solve_kwargs...)

    sol_obs = Observable(sol)
    time_obs = Observable(1)

    # ----- Left Panel (Grid View) -----
    ax_grid = Axis(fig[1, 1], title = "CPM Grid", aspect = DataAspect())
    hidespines!(ax_grid)
    hidedecorations!(ax_grid)

    grid_frame_obs = lift(sol_obs, time_obs) do s, t
        idx = clamp(t, 1, length(s.t))
        return s.u[idx]
    end

    cpmplot!(ax_grid, grid_frame_obs; kwargs...)

    # ----- Right Panel (Metrics View) -----
    if !isempty(metrics)
        metrics_layout = GridLayout(fig[1, 2])
        for (i, (m_name, m_func)) in enumerate(metrics)
            ax_m = Axis(metrics_layout[i, 1], title = m_name, titlealign = :left, titlesize = 16)
            hidespines!(ax_m, :t, :r)
            if i == length(metrics)
                ax_m.xlabel = "Time Step"
            else
                hidexdecorations!(ax_m, grid = false)
            end

            y_vals_obs = lift(sol_obs) do s
                return Float32[Float32(applicable(m_func, s, i) ? m_func(s, i) :
                                       m_func(s.u[i])) for i in 1:length(s.t)]
            end

            t_vals_obs = lift(sol_obs) do s
                return Float32.(s.t)
            end

            lines!(ax_m, t_vals_obs, y_vals_obs, color = "#007AFF", linewidth = 3)

            # Cursor
            current_t_obs = lift(sol_obs, time_obs) do s, t
                idx = clamp(t, 1, length(s.t))
                return Float32(s.t[idx])
            end
            vlines!(ax_m, current_t_obs, color = :red, linewidth = 2)

            # Auto-scale when sol_obs changes
            on(sol_obs) do _
                autolimits!(ax_m)
            end
        end
    end

    # ----- Bottom Panel (Controls) -----
    control_layout = GridLayout(fig[2, 1:2])

    # Playback controls
    play_layout = GridLayout(control_layout[1, 1])
    play_btn = Button(play_layout[1, 1], label = "Play", width = 120)
    time_slider = Slider(play_layout[1, 2], range = lift(s -> 1:length(s.t), sol_obs), startvalue = 1)

    # Sync time slider and observable
    on(time_slider.value) do val
        time_obs[] = val
    end
    on(time_obs) do val
        set_close_to!(time_slider, val)
    end

    # Playback async task
    is_playing = Observable(false)
    on(play_btn.clicks) do _
        is_playing[] = !is_playing[]
        play_btn.label[] = is_playing[] ? "Pause" : "Play"
    end

    @async begin
        while true
            if is_playing[]
                if time_obs[] < length(sol_obs[].t)
                    time_obs[] += 1
                else
                    is_playing[] = false
                    play_btn.label[] = "Play"
                end
            end
            sleep(0.05)
        end
    end

    # Parameter Sliders & Recompute
    if !isempty(parameters)
        recompute_btn = Button(play_layout[1, 3], label = "Recompute", width = 120)

        sg_args = []
        for (p_name, p_spec) in parameters
            push!(sg_args, (
                label = p_name, range = p_spec.range, startvalue = p_spec.start))
        end
        sg = SliderGrid(control_layout[2, 1], sg_args...; tellwidth = false)

        on(recompute_btn.clicks) do _
            recompute_btn.label[] = "Computing..."
            yield()

            # Restore base state FIRST (in-place because CPMProblem and CPMState are immutable structs)
            prob.u0.grid .= base_u0.grid
            for k in propertynames(base_u0.cell_data)
                getproperty(prob.u0.cell_data, k) .= getproperty(base_u0.cell_data, k)
            end
            prob.u0.N_cells[] = base_u0.N_cells[]

            # Apply slider parameters to the freshly restored problem
            current_prob = prob
            current_alg = alg
            for (i, (p_name, p_spec)) in enumerate(parameters)
                val = sg.sliders[i].value[]
                res = p_spec.action(current_prob, current_alg, val)
                if res isa Tuple
                    current_prob, current_alg = res[1], res[2]
                elseif res !== nothing
                    if res isa SciMLBase.AbstractDiscreteProblem ||
                       res isa CoreCPM.AbstractCPMProblem
                        current_prob = res
                    else
                        current_alg = res
                    end
                end
            end

            new_sol = CommonSolve.solve(current_prob, current_alg; solve_kwargs...)

            sol_obs[] = new_sol
            time_obs[] = 1

            recompute_btn.label[] = "Recompute"
        end
    end

    return fig
end

function record_cpm(filename::String, sol::CPMSolution;
        metrics::Vector{<:Pair} = Pair{String, Any}[],
        resolution = (1400, 900),
        framerate = 30,
        slice = 0,
        kwargs...)
    fig = Figure(size = resolution)

    sol_obs = Observable(sol)
    time_obs = Observable(1)

    # ----- Left Panel (Grid View) -----
    ax_grid = Axis(fig[1, 1], title = "CPM Grid", aspect = DataAspect())
    hidespines!(ax_grid)
    hidedecorations!(ax_grid)

    grid_frame_obs = lift(sol_obs, time_obs) do s, t
        idx = clamp(t, 1, length(s.t))
        return s.u[idx]
    end

    cpmplot!(ax_grid, grid_frame_obs; slice = slice, kwargs...)

    # ----- Right Panel (Metrics View) -----
    if !isempty(metrics)
        metrics_layout = GridLayout(fig[1, 2])
        for (i, (m_name, m_func)) in enumerate(metrics)
            ax_m = Axis(metrics_layout[i, 1], title = m_name, titlealign = :left, titlesize = 16)
            hidespines!(ax_m, :t, :r)
            if i == length(metrics)
                ax_m.xlabel = "Time Step"
            else
                hidexdecorations!(ax_m, grid = false)
            end

            y_vals_obs = lift(sol_obs) do s
                return Float32[Float32(applicable(m_func, s, i) ? m_func(s, i) :
                                       m_func(s.u[i])) for i in 1:length(s.t)]
            end

            t_vals_obs = lift(sol_obs) do s
                return Float32.(s.t)
            end

            lines!(ax_m, t_vals_obs, y_vals_obs, color = "#007AFF", linewidth = 3)

            # Cursor
            current_t_obs = lift(sol_obs, time_obs) do s, t
                idx = clamp(t, 1, length(s.t))
                return Float32(s.t[idx])
            end
            vlines!(ax_m, current_t_obs, color = :red, linewidth = 2)
            autolimits!(ax_m)
        end
    end

    record(fig, filename, 1:length(sol.t); framerate = framerate) do t
        time_obs[] = t
    end

    return nothing
end

end
