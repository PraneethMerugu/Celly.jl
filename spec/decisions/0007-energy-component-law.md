# ADR 0007: Explicit Component Categories and the Local/Global Energy Law

- Status: Accepted
- Date: 2026-07-17

## Context

CPM implementations often expose every contribution to a copy attempt as a
"constraint," "penalty," or `deltaH`. That collapses several mathematically
different ideas into one interface: conservative Hamiltonian terms,
nonconservative drives, hard admissibility constraints, derived trackers,
stochastic auxiliaries, and lifecycle operations.

This ambiguity makes it possible for a component to influence local acceptance
without having a corresponding global energy, for a hard rejection to be
encoded using a floating-point sentinel, or for cached geometry to silently
diverge from the lattice. It also makes equilibrium claims impossible to audit.

## Decision

Every model component shall declare exactly one primary semantic category:

1. Hamiltonian term
2. nonconservative drive
3. hard constraint
4. derived tracker
5. stochastic auxiliary
6. lifecycle operation

A Hamiltonian term shall provide a scalar global energy and an exact local
change satisfying

```text
local_delta(state, proposal) =
    energy(state_after_proposal) - energy(state_before_proposal)
```

for every admissible proposal. Components that cannot satisfy this law are not
Hamiltonian terms and shall not be reported as energy.

Contact energy is defined over unordered valid lattice-neighbor pairs, counted
once. Its interaction matrix and edge weights are symmetric. Interfaces between
distinct cells of the same type contribute normally; only equal cell identity
eliminates an interface.

Nonconservative drives report work or log-bias separately from Hamiltonian
energy. Chemotaxis may be implemented either as a proven conservative field
coupling or as a nonconservative drive, but those forms are distinct APIs.

Hard constraints are pure admissibility predicates. They do not return
`Inf`, `typemax`, or another numerical stand-in for rejection.

The lattice is the source of truth. Trackers are derived, read-only views.
Incremental tracker updates shall equal an independent full recomputation after
every committed transaction. A tracker delta is computed from the pre-commit
snapshot and applied exactly once if and only if the proposal commits. Silent
repair is forbidden, and integer overflow is checked.

Surface observables distinguish per-cell surface, global interface measure,
weighted measure, normalized measure, and physical measure. Invalid no-flux
directions are absent edges rather than clamped self-edges.

## Consequences

- The component API must expose category-specific interfaces and capability
  metadata instead of one catch-all penalty interface.
- Existing components require classification and, where necessary, separation
  into conservative and nonconservative variants.
- Every Hamiltonian implementation requires a full-energy oracle suitable for
  randomized local/global consistency testing.
- Every incremental tracker requires a full-recomputation oracle.
- Connectivity and other hard rules must move out of floating-point energy
  accumulation.
- Diagnostics and model reports can separately account for energy, drive work,
  constraint rejection, stochastic auxiliaries, and lifecycle events.

## Evidence required

- Randomized equality tests between every local energy delta and full
  before/after recomputation in 2D and 3D.
- Independent tracker recomputation after individual commits and parallel
  transaction batches.
- Boundary and neighborhood fixtures covering periodic, no-flux, and other
  supported boundary conditions.
- Symmetry and counting tests for contact matrices, edge weights, same-type
  interfaces, and medium interfaces.
- Equilibrium validation must reject any model containing an unproven drive,
  irreversible lifecycle operation, or state-dependent hard constraint that
  breaks reciprocity.

## Specification

See [Energy, Proposal, Acceptance, and Tracker Semantics](../energy-proposals-and-trackers.md).
