# Phase 8 Implementation Chunk Plan

Date: 2026-07-19

Status: Candidate implemented; authoritative ROCm and repository CI pending

## Objective

Replace the remaining lifecycle, initialization, and persistence behavior on the scientific path
with the accepted minimal open protocols, complete CPU/Metal/ROCm qualification, and preserve the
Phase 7 legacy-containment gate until the historical engine can be deleted in its owning phase.

## Current Evidence

The repository already contains useful scalar foundations:

- `LogicalPottsState`, invariant validation, slot generations, derived occupancy reconstruction, and
  compiled state lowering;
- copy-on-commit scalar division, type transition, immediate death, retirement, and next-boundary
  reuse;
- mask-based logical initialization with capacity validation;
- semantically addressed Philox streams and stable pressure/tension mechanics; and
- package-extension shells for HDF5, Zarr, Metal, and AMDGPU.

The candidate now implements all eight chunks. The detailed evidence and remaining authoritative
hardware/CI closure condition are recorded in the
[Phase 8 completion audit](phase-8-completion-audit.md). Historical event, output, and PottsToolkit
implementations remain quarantined; they are not fallback paths for the scientific implementation.

## Chunk 8.1 — Scalar Protocol Cutover

Deliver:

- replace division, transition, and retirement enums with small typed policy values and dispatched
  public operations;
- make unspecified custom-property lifecycle behavior explicitly unsupported;
- define positive integer-MCS schedules, target domains, pre-lifecycle snapshots, trigger/effect
  declarations, and reject/stable-priority resolvers;
- define the open binary region-label geometry boundary and scalar validation results; and
- add downstream-style policy/schedule/trigger/geometry unit fixtures.

Gate:

- no scientific-path lifecycle consumer branches on a concrete policy family;
- existing logical lifecycle behavior passes through dispatched policies; and
- structure, ambiguity, inference, and legacy containment remain green.

## Chunk 8.2 — Deterministic Initialization Replacement

Deliver:

- stable provisional identities and one requirement/claim-emission layout protocol;
- generic unordered claim collection, reject/stable-priority overlap, empty-entity removal, compact
  ID assignment, property initialization, and finalization reports;
- dense labels/masks, coordinates, procedural paper shapes, uniform site seeds, bounded sequential
  rejection placement, and periodic minimum-image rasterization; and
- one custom downstream layout fixture.

Gate:

- declaration/emission permutations preserve ownership and IDs;
- random laws, retry addresses, atomic failure, periodic wrapping, and self-alias rejection pass; and
- no replacement-path use of task-local RNG, dictionaries for scientific ordering, or concrete
  layout switching remains.

## Chunk 8.3 — Scalar Lifecycle Transactions

Deliver:

- one common `PreLifecycleSnapshot` and completed-MCS lifecycle phase;
- trigger masks, explicit conflicts, planning, validation, and atomic commit;
- property update, type transition, shrink-death initiation, immediate death, extinction,
  retirement, and reuse effects;
- open random/vector/major/minor binary division geometries with per-parent invalid-geometry records
  and all-or-nothing capacity preflight; and
- deterministic counters and bounded structured failures.

Gate:

- permutation, contention, invalid geometry, capacity, rollback, fragmentation, and optional
  connectivity reference fixtures pass.

## Chunk 8.4 — Mechanical and Derived Lifecycle

Deliver:

- constitutive-reset, intensive-preservation, and independently addressed stationary-redraw policies
  for volume pressure and surface tension;
- transition/growth/shrink continuity, component addition/removal, immediate-death/extinction clear,
  and generation-safe reuse;
- target-volume conservative split and explicit surface-target compatibility; and
- generic derived-property invalidation/reconstruction through the property transaction.

Gate:

- scalar law, distribution, ordering, RNG isolation, atomicity, and derived repair evidence passes.

## Chunk 8.5 — Compiled CPU and Integrator Connection

Deliver:

- bounded lifecycle workspaces and compiled descriptors;
- KernelAbstractions CPU detection, planning, compaction, resolution, validation, and commit;
- completed-MCS integration with sequential, checkerboard, and lottery algorithms; and
- one combined downstream extension fixture crossing schedule, trigger/effect, geometry, property,
  derived observable, and layout protocols.

Gate:

- no per-event steady-state allocation or hidden synchronization;
- reference and compiled CPU canonical states/counters agree; and
- declaration, tuple, compilation-batch, and workgroup permutations are invariant.

## Chunk 8.6 — Metal and ROCm Qualification

Deliver:

- device lowering and complete schedule-through-commit execution on Metal and ROCm;
- portable AcceleratedKernels operations or explicit qualified alternatives with caller-owned
  temporary storage;
- bounded device failure records surfaced only at permitted boundaries; and
- backend reports covering compilation, device code, allocation, synchronization, workspace,
  replay, and throughput.

Gate:

- required 2D/3D lifecycle and initialization fixtures pass on CPU, Metal, and ROCm with no hidden
  host fallback.

## Chunk 8.7 — Canonical Persistence

Deliver:

- immutable snapshots and canonical completed-MCS checkpoints;
- fingerprints, integrity, same-profile exact resume, explicit logical import, cache/workspace
  reconstruction, and failure injection;
- in-memory reference storage; and
- thin HDF5 and Zarr package extensions over the same logical reader/writer interface.

Gate:

- uninterrupted/resumed trajectories agree under each exact profile;
- memory/HDF5/Zarr canonical records agree; and
- incomplete, corrupt, incompatible, and wrong-capacity records never mutate a live integrator.

## Chunk 8.8 — Completion and Performance Audit

Deliver:

- full package, integration, documentation-structure, legacy-containment, and required backend CI;
- construction, first-use, steady-state, workspace, transfer, checkpoint, and lifecycle throughput
  comparisons against Phase 1/7 evidence;
- public/internal/experimental API inventory and zero-core-edit audit; and
- Phase 8 completion audit linked from the roadmap and conformance index.

Gate:

- every Phase 8 roadmap deliverable and exit criterion has direct executable evidence;
- no obsolete replacement-path enum, concrete-family switch, hidden fallback, or duplicate
  lifecycle authority remains; and
- no required performance or scientific regression is unexplained.

## Working Rule

Each chunk removes the obsolete scientific-path representation once its replacement passes. New
protocol names remain provisional until their scalar, compiled, downstream, and device consumers
agree. Deferred features listed in Decision 0020 do not acquire production scaffolding during this
phase.
