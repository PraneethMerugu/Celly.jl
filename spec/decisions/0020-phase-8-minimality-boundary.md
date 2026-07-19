# Decision 0020: Phase 8 Implements the Minimum Open Vertical Slice

Status: Accepted

Date: 2026-07-19

## Context

The accepted semantics correctly prevent lifecycle, initialization, and persistence from becoming
closed around their first built-ins. They also describe many behaviors that could eventually fit
those protocols. Implementing every permitted behavior in Phase 8 would substitute a speculative
framework for Julia's usual pattern of small interfaces derived from real implementations.

## Decision

Phase 8 production code is limited to accepted scientific invariants, paper-required built-ins, one
minimal extension seam per meaningful family, and one combined downstream fixture. A protocol's
ability to admit future behavior does not make that behavior a Phase 8 deliverable.

The detailed classification and implementation order are normative for refactor execution in the
[Phase 8 Minimality Pass](../../design/audits/phase-8-minimality-pass.md).

The lifecycle paper slice implements active-cell and global targets; four integer-MCS schedule
forms; required growth, binary division, transition, death, extinction, and property effects;
ambiguity rejection and explicit stable priority; four binary division geometries; built-in
property policies; and lifecycle laws for the stable pressure and tension mechanical families.

Dynamic-link events, general resolver composition, nonbinary division, catalogs of exotic geometry,
arbitrary imperative callbacks, lineage graphs, and universal equilibrium-auxiliary machinery are
deferred. Their extension boundaries remain open but receive no speculative production framework.

Initialization should use one minimal layout interface rather than separate universal source,
rasterizer, placer, and manager abstractions. Persistence uses one canonical logical contract with
thin HDF5 and Zarr package extensions, not separate storage architectures.

## Consequences

- Semantic rigor, atomicity, GPU residency, and external extensibility are unchanged.
- Phase 8 can progress through complete vertical slices rather than horizontal framework layers.
- One combined extension fixture replaces many microscopic fixture packages.
- Interface names remain provisional until real reference, production, and downstream consumers
  establish the minimal method signatures.
- A future feature adds its mathematics and evidence when it becomes concrete; it does not force
  speculation into the paper refactor.

## Alternatives Considered

- Implement every behavior admitted by every open protocol before beginning the paper slice.
- Close the protocols around built-ins to avoid writing extension tests.
- Keep broad abstract hierarchies now and prune them after API freeze.
- Defer all extensibility until a downstream package appears.

The first and third overengineer the refactor; the second and fourth recreate the closure identified
by the open-protocol audit.

## Required Conformance Evidence

- One complete scalar lifecycle/initialization/checkpoint reference slice.
- One combined downstream module that crosses several open Phase 8 protocols without CorePotts edits.
- CPU, Metal, and ROCm qualification for every device-capable paper behavior.
- HDF5 and Zarr round-trip through one canonical logical persistence suite.
- An API inventory proving deferred possibilities did not acquire speculative public framework
  types or functions.
- Inference, allocation, synchronization, compilation, workspace, and steady-state performance
  gates before interface freeze.
