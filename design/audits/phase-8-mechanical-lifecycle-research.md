# Phase 8 Mechanical Lifecycle Research

Date: 2026-07-19

Status: Research complete; recommendations accepted in Decision 0023

## Question

What lifecycle semantics should the stable `FluctuatingVolumePressure` and
`FluctuatingSurfaceTension` families use for division, type transition, death, extinction, and slot
reuse while remaining correct relative to CPM practice and honest about their non-equilibrium OU
mechanics?

## Finding

There is no literature-standard inheritance law for Potts.jl's stochastic pressure or tension
state. Conventional CPM packages and papers define division geometry and then adjust or copy cell
attributes as model choices. They do not establish that a non-equilibrium generalized force must be
conserved, halved, cloned, or redrawn.

The safe contract is therefore to:

1. preserve conventional CPM target/property behavior as explicit property policies;
2. treat pressure and tension as intensive dynamic state, never as conserved extensive quantities;
3. select a named lifecycle policy rather than claim one rule follows from CPM literature; and
4. make the default deterministic, device-cheap, and consistent with the existing constitutive-mean
   initializer.

## Evidence from CPM Practice

The official CompuCell3D mitosis example divides a cell geometrically, halves the parent's target
volume, clones attributes to the child, and exposes an `updateAttributes` hook for model-specific
changes. The manual explicitly treats cloning as a convenience rather than a universal scientific
law. It also supplies the same random, vector, major-axis, and minor-axis division families selected
for Potts.jl.

- [CompuCell3D mitosis example](https://compucell3dreferencemanual.readthedocs.io/en/latest/example_mitosis.html)
- [CompuCell3D mitosis API](https://compucell3dreferencemanual.readthedocs.io/en/latest/appendix_a.html)

Published CPM tumor-growth work commonly grows target volume and divides approximately equal-volume
cells, again making cell-cycle and division attributes part of the model rather than a universal
CPM transition law.

- [The effects of cell compressibility, motility and contact inhibition on tumor growth](https://pmc.ncbi.nlm.nih.gov/articles/PMC3946864/)

CellularPotts.jl demonstrates that an intracellular quantity may be randomly distributed to
daughters. This is further evidence that auxiliary inheritance is family specific, not evidence for
pressure or tension inheritance in particular.

- [CellularPotts.jl: simulating multiscale cellular models in Julia](https://academic.oup.com/bioinformatics/article/40/1/btad773/7491591)

Modern non-equilibrium CPM work emphasizes separating relaxation, thermal fluctuation, athermal
noise, and nonconservative forces. That supports Potts.jl's refusal to infer equilibrium or
conservation semantics for the OU mechanical state.

- [Poissonian cellular Potts models reveal nonequilibrium kinetics of cell sorting](https://arxiv.org/abs/2306.04443)

## Mathematical Classification

For the accepted frozen-observable law,

```text
dq = eta * (2 * lambda * (O - O_target) - q) dt
     + sqrt(4 * eta * lambda * Theta) dW,
```

`q` is a generalized force: pressure for volume or tension for surface. Its fixed-observable
stationary law is

```text
q | O ~ Normal(2 * lambda * (O - O_target), 2 * lambda * Theta).
```

It is not an extensive amount. Halving `q` at binary division has no basis in this law. Conserving
`q_parent + q_child` likewise changes its physical meaning. Cloning `q` to both descendants is a
possible intensive-state memory model, while redrawing or resetting represents mechanical
reorganization. These are distinct kinetics and must be named.

## Recommended Division Policies

### Default: constitutive reset after commit

After lattice partition, target/strength inheritance, derived-observable reconstruction, and type
assignment are final, set each descendant to

```text
q_r = 2 * lambda_r * (O_r - O_target_r).
```

This is deterministic, introduces no unrequested division noise, matches the existing default
initializer, and avoids claiming that pre-mitotic pressure or tension survives mitosis. It is a
Potts.jl model default, not a theorem of CPM literature.

### Explicit intensive preservation

An explicitly selected memory policy may assign the pre-division `q` to both descendants. It must be
described as cloning an intensive state, not conserving a quantity. Each descendant then relaxes
toward its own post-division constitutive mean under the ordinary OU clock.

### Explicit stationary redraw

An explicitly selected reset policy may draw each descendant independently from its post-division
fixed-observable stationary law. Draw addresses use the division event identity, MCS, component,
parent generation, descendant role, and child generation. They do not consume initialization or
evolution addresses.

General correlated daughter noise is deferred until a model supplies a covariance law.

## Recommended Transition and Death Policies

When a type transition retains the same mechanical component identity and compatible state units,
preserve `q` continuously. New target, strength, or noise parameters take effect in the subsequent
OU transition, allowing physical relaxation rather than an unannounced jump. Reset or redraw remains
an explicit alternative. Removing the component clears its state; adding it uses its declared
initializer.

Growth, target changes, and progressive shrink death likewise preserve `q` and let the accepted OU
law follow the changing constitutive mean. Immediate death and stochastic extinction clear state in
the retirement transaction. Reusing a slot creates a new generation and applies ordinary mechanical
initialization; stale state is never preserved.

## Target and Strength Properties

Mechanical-state policy does not decide biological target or stiffness inheritance.

- Volume target is extensive enough for an explicit conservative split policy; equal binary
  division commonly halves it, while asymmetric division may use a declared partition fraction.
- Stiffness and relaxation/noise parameters are normally type or component parameters and may be
  copied or changed through ordinary property/type policy.
- Surface target is not extensive. Halving it is generally not geometrically equivalent to dividing
  volume. Similar-shape scaling by `f^((D-1)/D)` is a useful named policy, but it assumes geometry and
  metric behavior and should not become a hidden global default.

The post-division pressure or tension reset occurs only after these independent policies and derived
observables are final.

## GPU and Reproducibility Consequences

All three recommended division policies are device-local after deterministic division planning.
The default constitutive reset requires no RNG and no additional global synchronization. Stationary
redraw uses two addressed normals per binary event and compact role labels. Preservation is a scalar
copy to each descendant.

No policy requires per-event allocation, runtime dispatch, host callbacks, or new mechanical
subrounds. Policy identity belongs in model provenance and checkpoint compatibility because changing
it changes kinetics.

## Recommended Interview Decisions

1. Constitutive reset is the default division policy; preservation and stationary redraw are
   explicit alternatives.
2. Pressure and tension are intensive and never halved or conserved by default.
3. Same-component type transition, growth, and shrink death preserve state continuously; component
   addition/removal initializes or clears explicitly.
4. Immediate death/extinction clear atomically; slot reuse initializes a new generation.
5. Volume-target split, surface-target policy, stiffness/type transition, and mechanical-state reset
   remain separate policies; surface target has no hidden halving default.
