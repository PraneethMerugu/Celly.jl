using CorePotts
using PottsToolkit

Medium = CellType(:Medium, is_background = true)
Epithelial = CellType(:Epithelial)
Mesenchymal = CellType(:Mesenchymal)

vol = VolumeComponent(
    Epithelial => (target = 50.0, λ = 5.0),
    Mesenchymal => (target = 50.0, λ = 5.0)
)
adh = AdhesionComponent(
    (Medium, Epithelial) => 5.0,
    (Medium, Mesenchymal) => 5.0,
    (Epithelial, Epithelial) => 2.0,
    (Mesenchymal, Mesenchymal) => 2.0,
    (Epithelial, Mesenchymal) => 15.0
)

sys = PottsSystem(cell_types = [Medium, Epithelial, Mesenchymal], penalties = [vol, adh])
counts = Dict(Epithelial => 40, Mesenchymal => 40)
layout = HypersphereLayout(counts, (100, 100))
prob = PottsProblem(sys, layout, (100, 100); tspan = (1, 500))

println("Vol lambdas: ", prob.p.penalties[1].lambdas)
println("Cell 2 target vol: ", prob.u0.cell_data.target_volumes[2])
println("Cell 2 current vol: ", prob.u0.cell_data.volumes[2])

using CommonSolve
alg = ParallelMetropolis(sweeps_per_step = 100)
sol = CommonSolve.solve(prob, alg)

println("Cell 2 final vol: ", sol.u[end].cell_data.volumes[2])
println("Mean vol (cells only): ", sum(sol.u[end].cell_data.volumes[2:end]) / 80)
