using CairoMakie
CairoMakie.activate!()

# # Cell Sorting
#
# One of the most striking emergent behaviours in multicellular systems is
# *cell sorting*: a mixture of two cell types spontaneously segregates into
# pure-type clusters. This phenomenon was first observed by Holtfreter in
# amphibian embryo explants and later formalised by Malcolm Steinberg as the
# **Differential Adhesion Hypothesis (DAH)**. The DAH states that cells
# behave like immiscible liquids — the tissue configuration that minimises
# total interfacial energy is the one cells evolve toward. In CPM terms, this
# means the relative magnitudes of the contact energy J determine whether two
# cell types mix, partially sort, or completely engulf one another.

# ## Packages

using CPMToolkit
using MakieCPM
using Statistics: mean

# ## Cell Types
#
# We define two epithelial-like cell types, TypeA and TypeB, plus the
# background Medium. Steinberg's original experiments used pigmented retinal
# and neural retinal cells; here the two types are abstract but the physics
# is identical.

TypeA  = CellType(:TypeA)
TypeB  = CellType(:TypeB)
Medium = CellType(:Medium)

# ## Adhesion Matrix — the Key DAH Parameter
#
# The sorting outcome is governed entirely by the adhesion matrix:
#
# | Pair        | J value | Meaning                              |
# |-------------|---------|--------------------------------------|
# | A–A         | 2.0     | strong homotypic cohesion            |
# | B–B         | 2.0     | strong homotypic cohesion            |
# | A–B         | 14.0    | weak heterotypic adhesion            |
# | A–Medium    | 16.0    | cells prefer each other over medium  |
# | B–Medium    | 16.0    | cells prefer each other over medium  |
#
# Because J(A,B) >> J(A,A) = J(B,B), the system minimises energy by
# maximising homotypic contacts — the hallmark of complete cell sorting.
# If J(A,B) were intermediate, you would observe partial engulfment instead.

sys = CPMSystem(
    [TypeA, TypeB, Medium],
    [
        VolumeComponent(
            TypeA => (λ = 5.0f0, target = 150),
            TypeB => (λ = 5.0f0, target = 150),
        ),
        AdhesionComponent(
            (TypeA, TypeA)  => 2.0f0,
            (TypeB, TypeB)  => 2.0f0,
            (TypeA, TypeB)  => 14.0f0,
            (TypeA, Medium) => 16.0f0,
            (TypeB, Medium) => 16.0f0,
        ),
    ]
)

# ## Problem Setup
#
# A 150 × 150 grid gives enough room for 30 + 30 cells (each ~150 sites) to
# sort without being critically space-constrained. We run for 1000 MCS so
# sorting has time to reach a near-equilibrium cluster configuration.

prob = CPMProblem(
    sys,
    Dict(TypeA => 30, TypeB => 30),
    (150, 150);
    tspan  = (0, 1000),
    topology = VonNeumannTopology{2}(),
)

alg = CheckerboardMetropolis(T = 2.0f0, sweeps_per_step = 10)

sol = solve(prob, alg; saveat = 10)

# ## Recording with a Cell-Count Metric
#
# The metrics panel shows the number of TypeA and TypeB cells separately so
# we can confirm that no spurious cell loss or gain occurs during sorting.
# Cell identity is stored in `u.cell_data.cell_types`; type indices follow
# the order given to `CPMSystem` (TypeA = 1, TypeB = 2).

record_cpm(
    "02_cell_sorting.mp4",
    sol;
    metrics = [
        "N TypeA" => u -> begin
            types = Array(u.cell_data.cell_types)
            count(==(1), types[1:u.N_cells[]])
        end,
        "N TypeB" => u -> begin
            types = Array(u.cell_data.cell_types)
            count(==(2), types[1:u.N_cells[]])
        end,
        "Mean Volume" => u -> mean(Array(u.cell_data.volumes)[1:u.N_cells[]]),
    ],
    framerate  = 24,
    resolution = (1400, 800),
)
