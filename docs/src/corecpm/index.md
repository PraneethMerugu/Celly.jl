# [CoreCPM](@id corecpm-overview)

CoreCPM is the low-level physics engine that underpins the entire Celly.jl ecosystem.
It provides the lattice representation, Monte Carlo algorithms, incremental penalty
evaluation, cell-event callbacks, and I/O backends.

> [!IMPORTANT]
> **CoreCPM is an internal library.** End users should always import
> [`CPMToolkit`](@ref cpmtoolkit-overview), which re-exports CoreCPM's public API
> through a higher-level declarative interface.
> You only need to interact with CoreCPM directly when writing custom penalties,
> implementing new Monte Carlo algorithms, or exercising low-level integrator control.

---

## What CoreCPM Provides

- **Lattice representation** — sparse and dense array backends for the cell-ID grid.
- **Topology types** — Von Neumann, Moore, no-flux variants, extended-radius variants,
  and 3D topologies (see [Topology](@ref corecpm-topology)).
- **Penalty system** — volume, surface area, adhesion, length, focal-point spring,
  chemotaxis, and HST variants (see [Penalties](@ref corecpm-penalties)).
- **Trackers** — $O(1)$ incremental statistics (volume, surface area, centroid, tensor
  of inertia, …).
- **Monte Carlo engines** — `CheckerboardMetropolis`, `ParallelMetropolis`,
  `SequentialMetropolis`, `SparseLotteryMetropolis`
  (see [Algorithms](@ref corecpm-engine)).
- **Cell events** — growth callbacks, mitosis callbacks, death callbacks, composable via
  the SciML `CallbackSet` interface.
- **Backends** — `MemoryBackend`, `ZarrBackend`, `HDF5Backend`
  (see [Backends](@ref corecpm-backends)).
- **SciML integration** — `CPMProblem` / `init` / `step!` / `solve` follow the
  `SciMLBase` interface so that CPM integrators compose with the broader Julia scientific
  computing ecosystem.

---

## Internal Architecture

CoreCPM is structured in three layers:

```
┌─────────────────────────────────────────────────────────┐
│  CoreCPM  (public re-export namespace)                  │
├──────────────────────────┬──────────────────────────────┤
│  CoreCPMBase             │  CoreCPMTools                │
│  ─────────────────────── │  ──────────────────────────  │
│  • Lattice types         │  • Penalty definitions       │
│  • Tracker primitives    │  • Component constructors    │
│  • Topology types        │  • Cell-event callbacks      │
│  • Backend interfaces    │  • SciML problem/integrator  │
├──────────────────────────┴──────────────────────────────┤
│  Engine + Simulator                                     │
│  • Checkerboard colouring logic                         │
│  • Parallel copy-attempt dispatch (CPU / GPU)           │
│  • ΔH computation kernel                               │
│  • Accept/reject kernel with Hastings correction        │
└─────────────────────────────────────────────────────────┘
```

**CoreCPMBase** defines the primitive data structures and abstract interfaces.
**CoreCPMTools** builds on those primitives to provide the biological components and the
SciML integration layer.
The **Engine + Simulator** contains the hot-loop kernels — the inner loops are written to
be compatible with both CPU threading and GPU execution via KernelAbstractions.jl.

---

## When to Interact with CoreCPM Directly

Most users will never need to import CoreCPM explicitly — `using CPMToolkit` brings in
everything.
The situations where you would reach into CoreCPM are:

1. **Custom penalties** — Subtype `CoreCPM.CoreCPMBase.AbstractPenalty` and implement the
   `delta_H` method to add a new energy term.
2. **Custom trackers** — Subtype `AbstractTracker` and implement the incremental update
   interface to track new cell statistics efficiently.
3. **Advanced integrator control** — Use `init(prob, alg)` to obtain an `integrator`
   object and call `step!(integrator)` manually; inspect `integrator.u` between steps
   to implement adaptive stopping criteria.
4. **Custom backends** — Subtype `AbstractBackend` to stream simulation state to a new
   storage format (e.g. a cloud object store).

---

## Sub-pages

- [Topology](@ref corecpm-topology) — Neighbourhood topologies and boundary conditions.
- [Penalties](@ref corecpm-penalties) — Energy terms and their biological meaning.
- [Algorithms](@ref corecpm-engine) — Monte Carlo update schemes.
- [Backends](@ref corecpm-backends) — Output storage backends.
- [API Reference](@ref corecpm-api) — Full docstring index.
