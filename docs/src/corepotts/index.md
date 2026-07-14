# [CorePotts](@id corepotts-overview)

CorePotts is the low-level physics engine that underpins the entire Potts.jl ecosystem.
It provides the lattice representation, Monte Carlo algorithms, incremental penalty
evaluation, native mask-driven events, and I/O backends.

> [!IMPORTANT]
> **CorePotts is an internal library.** End users should always import
> [`PottsToolkit`](@ref pottstoolkit-overview), which re-exports CorePotts's public API
> through a higher-level declarative interface.
> You only need to interact with CorePotts directly when writing custom penalties,
> implementing new Monte Carlo algorithms, or exercising low-level integrator control.

---

## What CorePotts Provides

- **Lattice representation** — sparse and dense array backends for the cell-ID grid.
- **Topology types** — Von Neumann, Moore, no-flux variants, extended-radius variants,
  and 3D topologies (see [Topology](@ref corepotts-topology)).
- **Penalty system** — volume, surface area, adhesion, length, focal-point spring,
  chemotaxis, and HST variants (see [Penalties](@ref corepotts-penalties)).
- **Trackers** — $O(1)$ incremental statistics (volume, surface area, centroid, tensor
  of inertia, …).
- **Monte Carlo engines** — `CheckerboardMetropolis`, `ParallelMetropolis`,
  `SequentialMetropolis`, `SparseLotteryMetropolis`
  (see [Algorithms](@ref corepotts-engine)).
- **Native events** — structurally composable `AbstractEvent` and `AbstractMultiEvent` types that execute via zero-allocation static unrolling on the GPU.
- **Backends** — `MemoryBackend`, `ZarrBackend`, `HDF5Backend`
  (see [Backends](@ref corepotts-backends)).
- **SciML integration** — `PottsProblem` / `init` / `step!` / `solve` follow the
  `SciMLBase` interface so that Potts integrators compose with the broader Julia scientific
  computing ecosystem.

---

## Internal Architecture

CorePotts is structured in three layers:

```
┌─────────────────────────────────────────────────────────┐
│  CorePotts  (public re-export namespace)                  │
├──────────────────────────┬──────────────────────────────┤
│  CorePottsBase             │  CorePottsTools                │
│  ─────────────────────── │  ──────────────────────────  │
│  • Lattice types         │  • Penalty definitions       │
│  • Tracker primitives    │  • Component constructors    │
│  • Topology types        │  • Native event interfaces   │
│  • Backend interfaces    │  • SciML problem/integrator  │
├──────────────────────────┴──────────────────────────────┤
│  Engine + Simulator                                     │
│  • Checkerboard colouring logic                         │
│  • Parallel copy-attempt dispatch (CPU / GPU)           │
│  • ΔH computation kernel                               │
│  • Accept/reject kernel with Hastings correction        │
└─────────────────────────────────────────────────────────┘
```

**CorePottsBase** defines the primitive data structures and abstract interfaces.
**CorePottsTools** builds on those primitives to provide the biological components and the
SciML integration layer.
The **Engine + Simulator** contains the hot-loop kernels — the inner loops are written to
be compatible with both CPU threading and GPU execution via KernelAbstractions.jl.

---

## When to Interact with CorePotts Directly

Most users will never need to import CorePotts explicitly — `using PottsToolkit` brings in
everything.
The situations where you would reach into CorePotts are:

1. **Custom penalties** — Subtype `CorePotts.CorePottsBase.AbstractPenalty` and implement the
   `delta_H` method to add a new energy term.
2. **Custom trackers** — Subtype `AbstractTracker` and implement the incremental update
   interface to track new cell statistics efficiently.
3. **Advanced integrator control** — Use `init(prob, alg)` to obtain an `integrator`
   object and call `step!(integrator)` manually; inspect `integrator.u` between steps
   to implement adaptive stopping criteria.
4. **Custom backends** — Subtype `AbstractBackend` to stream simulation state to a new
   storage format (e.g. a cloud object store).
5. **Testing** — If you are writing tests for the physics engine, rely on `PottsToolkit.TestProblems`
   to instantiate reproducible `PottsProblem`s rather than manually assembling arrays.

---

## Sub-pages

- [Topology](@ref corepotts-topology) — Neighbourhood topologies and boundary conditions.
- [Penalties](@ref corepotts-penalties) — Energy terms and their biological meaning.
- [Algorithms](@ref corepotts-engine) — Monte Carlo update schemes.
- [Backends](@ref corepotts-backends) — Output storage backends.
- [API Reference](@ref corepotts-api) — Full docstring index.
