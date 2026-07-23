# Getting Started

The high-level API describes biological identities, energies, geometry, and initial placement.
Execution algorithms remain explicit so their scientific guarantees cannot be selected implicitly.

```@example first_model
using PottsToolkit
import CorePotts

medium = Medium(:extracellular)
cell = CellType(:cell)

model = PottsModel(
    medium,
    cell,
    Volume(cell => (target = 4, strength = 2)),
    Adhesion(
        (medium, medium) => 0,
        (medium, cell) => 8,
        (cell, cell) => 2,
    ),
)

labels = UInt64[
    1 1 0 0
    1 1 0 0
    0 0 0 0
    0 0 0 0
]

domain = CartesianDomain((4, 4))
layout = Layout(LabelledCells(labels, (1 => cell,)))
problem = PottsProblem(
    model, domain, layout;
    capacity = 2,
    tspan = (0, 2),
    seed = 42,
)

solution = CorePotts.solve(
    problem,
    CorePotts.SequentialCPM(temperature = 0.0f0),
)

(solution.retcode, solution.t[end])
```

The model's semantic fingerprint is independent of declaration order and is suitable for evidence
and cache identity:

```@example first_model
semantic_fingerprint(model)
```

Before selecting an execution algorithm or backend, inspect its guarantee and compatibility
reports:

```@example first_model
CorePotts.algorithm_guarantees(CorePotts.SequentialCPM(temperature = 0.0f0))
```

The Phase 13 owner packet, not export status by itself, defines which documented symbols receive
the paper API compatibility guarantee.
