# MakiePotts Interactive Dashboard Showcase
# Note: You need `GLMakie` installed in your environment to view the interactive window!
using GLMakie
using MakiePotts
using CorePotts
using PottsToolkit
using CommonSolve

function run_showcase()
    println("Setting up the Cellular Potts Model...")

    # 1. Define Cell Types
    Medium = CellType(:Medium)
    Epithelial = CellType(:Epithelial)
    Mesenchymal = CellType(:Mesenchymal)

    # 2. Define Physics Components
    vol = VolumeComponent(
        Epithelial => (target = 50.0, λ = 5.0),
        Mesenchymal => (target = 50.0, λ = 5.0)
    )

    # Adhesion tuned for Engulfment Cell Sorting (Red Core, Blue Shell)
    adh = AdhesionComponent(
        (Medium, Epithelial) => 12.0,
        (Medium, Mesenchymal) => 4.0,
        (Epithelial, Epithelial) => 2.0,
        (Mesenchymal, Mesenchymal) => 6.0,
        (Epithelial, Mesenchymal) => 8.0
    )

    sys = PottsSystem(cell_types = [Medium, Epithelial, Mesenchymal], penalties = [
        vol, adh])

    # Randomly initialize a mixture of cells
    counts = Dict(Epithelial => 80, Mesenchymal => 80)
    prob = PottsProblem(sys, counts, (100, 100); tspan = (1, 500))
    alg = SequentialMetropolis(sweeps_per_step = 100, T = 20.0) # 100 MCS per evaluation is enough

    # 3. Define the UI Dials (Parameter Sliders)
    my_parameters = [
        "Temperature (T)" => (
            range = 0.1:0.5:50.0, start = 20.0,
            action = (prob, alg, val) -> begin
                if alg isa ParallelMetropolis
                    return ParallelMetropolis(
                        sweeps_per_step = alg.sweeps_per_step, T = typeof(alg.T)(val),
                        active_fraction = alg.active_fraction, sampler = alg.sampler)
                else
                    return SequentialMetropolis(
                        sweeps_per_step = alg.sweeps_per_step, T = typeof(alg.T)(val),
                        active_fraction = alg.active_fraction, sampler = alg.sampler)
                end
            end
        ),
        "Epithelial Target Volume" => (
            range = 10.0:1.0:100.0, start = 50.0,
            action = (prob, alg, val) -> begin
                # Type ID 1 is Epithelial
                prob.u0.cell_data.target_volumes[prob.u0.cell_data.cell_types .== 1] .= Int32(val)
                return alg
            end
        ),
        "Mesenchymal Target Volume" => (
            range = 10.0:1.0:100.0, start = 50.0,
            action = (prob, alg, val) -> begin
                # Type ID 2 is Mesenchymal
                prob.u0.cell_data.target_volumes[prob.u0.cell_data.cell_types .== 2] .= Int32(val)
                return alg
            end
        ),
        "Epithelial Compressibility (λ)" => (
            range = 0.1:0.5:20.0, start = 5.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[1].lambdas[2] = val
                return alg
            end
        ),
        "Mesenchymal Compressibility (λ)" => (
            range = 0.1:0.5:20.0, start = 5.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[1].lambdas[3] = val
                return alg
            end
        ),
        "Ep-Ep Adhesion" => (
            range = 0.1:0.5:40.0, start = 2.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[2].J[2, 2] = val
                return alg
            end
        ),
        "Mes-Mes Adhesion" => (
            range = 0.1:0.5:40.0, start = 6.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[2].J[3, 3] = val
                return alg
            end
        ),
        "Ep-Mes Cross Adhesion" => (
            range = 0.1:0.5:40.0, start = 8.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[2].J[2, 3] = val
                prob.p.penalties[2].J[3, 2] = val
                return alg
            end
        ),
        "Medium-Epithelial Adhesion" => (
            range = 0.1:0.5:40.0, start = 12.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[2].J[1, 2] = val
                prob.p.penalties[2].J[2, 1] = val
                return alg
            end
        ),
        "Medium-Mesenchymal Adhesion" => (
            range = 0.1:0.5:40.0, start = 4.0,
            action = (prob, alg, val) -> begin
                prob.p.penalties[2].J[1, 3] = val
                prob.p.penalties[2].J[3, 1] = val
                return alg
            end
        )
    ]

    # 4. Define the UI Data (Metrics)
    my_metrics = [
        "Mean Volume" =>
            u -> sum(@view u.cell_data.volumes[2:end]) /
                 max(1, count(>(0), @view u.cell_data.volumes[2:end])),
        "Active Cell Count" => u -> count(>(0), @view u.cell_data.volumes[2:end])
    ]

    if !haskey(ENV, "TESTING")
        println("Launching Interactive Dashboard...")
        fig = explore_cpm(prob, alg; metrics = my_metrics, parameters = my_parameters)
        display(fig)
        return fig
    else
        println("TESTING=true, running headless pre-solve...")
        CommonSolve.solve(prob, alg)
        println("Successfully finished headless solve!")
        return nothing
    end
end

fig = run_showcase()
if !haskey(ENV, "TESTING")
    println("Press Enter to close the dashboard and exit...")
    readline()
end
