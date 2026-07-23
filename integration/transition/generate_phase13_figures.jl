#!/usr/bin/env julia

using SHA
using TOML

function parse_number(value)
    text = string(value)
    if occursin("//", text)
        parts = split(text, "//"; limit = 2)
        return Float64(parse(BigInt, parts[1]) // parse(BigInt, parts[2]))
    end
    text == "infinity" && return Inf
    return parse(Float64, text)
end

function maximum_current(record)
    currents = record["analysis"]["probability_currents"]
    isempty(currents) && return 0.0
    return maximum(abs(parse_number(item["current"])) for item in currents)
end

function maximum_drift(record)
    observable = get(record["analysis"], "observable", Dict{String, Any}())
    values = get(observable, "drift", String[])
    isempty(values) && return 0.0
    return maximum(abs(parse_number(value)) for value in values)
end

function svg_bar_chart(path, title, labels, series; y_label)
    width, height = 920, 520
    left, right, top, bottom = 90, 30, 55, 130
    plot_width = width - left - right
    plot_height = height - top - bottom
    maximum_value = maximum((value for (_, values) in series for value in values);
        init = 0.0)
    scale_max = maximum_value > 0 ? maximum_value * 1.1 : 1.0
    groups = length(labels)
    series_count = length(series)
    group_width = plot_width / max(groups, 1)
    bar_width = 0.72group_width / max(series_count, 1)
    colors = ("#36558f", "#e07a5f", "#3d9970", "#7d5ba6")
    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\">")
        println(io, "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>")
        println(io, "<text x=\"$(width/2)\" y=\"30\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"20\">$title</text>")
        println(io, "<line x1=\"$left\" y1=\"$top\" x2=\"$left\" y2=\"$(top+plot_height)\" stroke=\"#222\"/>")
        println(io, "<line x1=\"$left\" y1=\"$(top+plot_height)\" x2=\"$(left+plot_width)\" y2=\"$(top+plot_height)\" stroke=\"#222\"/>")
        println(io, "<text transform=\"translate(22 $(top+plot_height/2)) rotate(-90)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\">$y_label</text>")
        for tick in 0:4
            value = scale_max * tick / 4
            y = top + plot_height * (1 - tick / 4)
            println(io, "<line x1=\"$left\" y1=\"$y\" x2=\"$(left+plot_width)\" y2=\"$y\" stroke=\"#ddd\"/>")
            println(io, "<text x=\"$(left-8)\" y=\"$(y+4)\" text-anchor=\"end\" font-family=\"monospace\" font-size=\"11\">$(round(value; sigdigits=3))</text>")
        end
        for (group, label) in pairs(labels)
            center = left + (group - 0.5) * group_width
            for (series_index, (_, values)) in pairs(series)
                value = values[group]
                bar_height = plot_height * value / scale_max
                x = center - 0.36group_width + (series_index - 1) * bar_width
                y = top + plot_height - bar_height
                println(io, "<rect x=\"$x\" y=\"$y\" width=\"$(0.9bar_width)\" height=\"$bar_height\" fill=\"$(colors[series_index])\"><title>$label: $value</title></rect>")
            end
            println(io, "<text transform=\"translate($center $(top+plot_height+12)) rotate(35)\" text-anchor=\"start\" font-family=\"sans-serif\" font-size=\"11\">$label</text>")
        end
        for (index, (name, _)) in pairs(series)
            x = left + (index - 1) * 180
            println(io, "<rect x=\"$x\" y=\"$(height-28)\" width=\"14\" height=\"14\" fill=\"$(colors[index])\"/>")
            println(io, "<text x=\"$(x+20)\" y=\"$(height-16)\" font-family=\"sans-serif\" font-size=\"12\">$name</text>")
        end
        println(io, "</svg>")
    end
    return path
end

function pending_speed_fidelity(path)
    open(path, "w") do io
        print(io, """<svg xmlns="http://www.w3.org/2000/svg" width="920" height="300" viewBox="0 0 920 300">
<rect width="100%" height="100%" fill="white"/>
<text x="460" y="55" text-anchor="middle" font-family="sans-serif" font-size="20">Phase 13 speed–fidelity evidence</text>
<rect x="110" y="95" width="700" height="105" rx="8" fill="#f4f1de" stroke="#d6c98d"/>
<text x="460" y="135" text-anchor="middle" font-family="sans-serif" font-size="16">Pending registered realistic-scale real-hardware runs</text>
<text x="460" y="168" text-anchor="middle" font-family="sans-serif" font-size="13">No speed or fidelity equivalence claim is inferred from tiny-state matrices.</text>
<text x="460" y="235" text-anchor="middle" font-family="sans-serif" font-size="12">This explicit pending panel prevents absent performance evidence from appearing as a pass.</text>
</svg>
""")
    end
    return path
end

function generate(exact_directory, output_directory)
    mkpath(output_directory)
    paths = sort(filter(path -> endswith(path, "checkerboard-normalized-mcs.toml"),
        readdir(exact_directory; join = true)))
    records = TOML.parsefile.(paths)
    labels = [replace(basename(path), "-checkerboard-normalized-mcs.toml" => "")
        for path in paths]
    sequential_records = [TOML.parsefile(replace(path,
        "checkerboard-normalized-mcs.toml" => "normalized-mcs.toml")) for path in paths]
    tv = [parse_number(record["comparison"]["maximum_total_variation"])
        for record in records]
    currents = maximum_current.(records)
    checkerboard_gaps = [parse_number(record["analysis"]["spectral_gap"])
        for record in records]
    sequential_gaps = [parse_number(record["analysis"]["spectral_gap"])
        for record in sequential_records]
    checkerboard_drift = maximum_drift.(records)
    sequential_drift = maximum_drift.(sequential_records)

    figures = String[]
    push!(figures, svg_bar_chart(joinpath(output_directory, "transition-difference.svg"),
        "Sequential–checkerboard transition difference", labels,
        [("maximum row TV", tv)]; y_label = "total variation"))
    push!(figures, svg_bar_chart(joinpath(output_directory, "probability-current.svg"),
        "Checkerboard stationary probability currents", labels,
        [("maximum |current|", currents)]; y_label = "probability current"))
    push!(figures, svg_bar_chart(joinpath(output_directory, "relaxation-gap.svg"),
        "Normalized-MCS spectral gaps", labels,
        [("sequential", sequential_gaps), ("checkerboard", checkerboard_gaps)];
        y_label = "spectral gap"))
    push!(figures, svg_bar_chart(joinpath(output_directory, "observable-drift.svg"),
        "Maximum one-MCS cell-count drift", labels,
        [("sequential", sequential_drift), ("checkerboard", checkerboard_drift)];
        y_label = "maximum absolute drift"))
    push!(figures, pending_speed_fidelity(joinpath(output_directory, "speed-fidelity.svg")))

    data = Dict{String, Any}(
        "schema_version" => "1.0.0",
        "source_evidence" => relpath(exact_directory, output_directory),
        "fixtures" => [Dict(
            "id" => labels[index],
            "maximum_total_variation" => tv[index],
            "maximum_probability_current" => currents[index],
            "sequential_spectral_gap" => sequential_gaps[index],
            "checkerboard_spectral_gap" => checkerboard_gaps[index],
            "sequential_maximum_observable_drift" => sequential_drift[index],
            "checkerboard_maximum_observable_drift" => checkerboard_drift[index])
            for index in eachindex(labels)],
        "speed_fidelity_status" => "pending-registered-real-hardware-evidence",
        "figures" => [Dict(
            "path" => basename(path),
            "sha256" => bytes2hex(open(SHA.sha256, path))) for path in figures])
    index_path = joinpath(output_directory, "index.toml")
    open(index_path, "w") do io
        TOML.print(io, data; sorted = true)
    end
    return figures, index_path
end

function main(args)
    root = normpath(joinpath(@__DIR__, "..", ".."))
    exact = length(args) >= 1 ? abspath(args[1]) :
        joinpath(root, "design", "evidence", "phase-13", "exact")
    output = length(args) >= 2 ? abspath(args[2]) :
        joinpath(root, "design", "evidence", "phase-13", "figures")
    figures, index = generate(exact, output)
    println("wrote $(length(figures)) Phase 13 figures and $index")
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main(ARGS)
