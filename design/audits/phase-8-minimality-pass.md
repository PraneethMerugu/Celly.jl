# Phase 8 Minimality Pass

Date: 2026-07-19

Status: Accepted implementation boundary

## Purpose

Phase 8 must deliver correct lifecycle, initialization, and persistence without turning the open
protocol standard into a speculative framework. This pass separates four kinds of requirement:

1. **Scientific invariant** — observable correctness that every implementation must preserve.
2. **Paper-required built-in** — concrete behavior needed by the release, tests, tutorials, or
   benchmark models.
3. **Minimal extension seam** — the smallest public Julia interface needed to prevent a built-in
   switch from becoming permanent.
4. **Deferred possibility** — allowed by the architecture but not implemented or stabilized in
   Phase 8.

Only the first three categories receive Phase 8 production code. An open protocol is not an
instruction to implement every behavior it could eventually admit.

## Governing Julia Rule

Phase 8 implements the paper-required built-ins and one meaningfully different downstream fixture.
Generic machinery is retained only when both use it or when an accepted invariant requires it.

Each protocol begins with the smallest method set that can support:

- one scalar reference implementation;
- the required production built-ins;
- one external-style extension without a CorePotts edit; and
- concrete CPU, Metal, and ROCm lowering where device capability is claimed.

Rich reports, validation, and provenance SHOULD be derived from compact schema values and generic
engine logic. They MUST NOT become a manager/factory hierarchy, a registry for ordinary behavior,
or dozens of one-bit trait methods.

## Lifecycle Scope

### Scientific invariants

- Lifecycle runs once at each due positive integer-MCS boundary from one common pre-lifecycle
  snapshot.
- Trigger evaluation is non-mutating; planning, conflict resolution, validation, and commit remain
  logically distinct.
- Biological priority is explicit and invariant under declaration, tuple, batch, workgroup, launch,
  and atomic-arrival order.
- Identity changes, property changes, capacity use, derived-state repair, auxiliary state, and
  diagnostics commit atomically.
- Fixed-capacity failure, invalid geometry, unsupported policy, and unresolved conflict cannot leave
  partial mutation.
- IDs and generations follow the accepted deterministic retirement and reuse law.
- The complete claimed GPU lifecycle path remains on device without runtime dispatch, per-event
  allocation, hidden fallback, or incidental synchronization.

### Paper-required built-ins

- Active-finite-cell and global-model event targets.
- Every-boundary, one-time, explicit finite-time, and bounded or unbounded periodic schedules.
- Growth or property update, binary division, type transition, shrink-death initiation, immediate
  death, stochastic extinction, retirement, and reuse.
- Ambiguity rejection and explicit stable semantic priority as conflict resolvers.
- Binary random-, vector-, major-axis-, and minor-axis division geometry in applicable 2D and 3D
  domains.
- The accepted division, transition, and retirement policy meanings actually used by built-in
  biological properties and paper models. Related reset/clone/asymmetric cases SHOULD share generic
  transformations rather than receive a class hierarchy.
- Lifecycle laws for the stable fluctuating-volume-pressure and fluctuating-surface-tension
  mechanical families.
- Required counters and structured bounded failure records.

### Minimal extension seam

- Small dispatch boundaries for schedule membership, trigger evaluation, effect planning, conflict
  resolution, division-region labeling, operation-specific property policies, and derived-state
  repair.
- Host values may lower to concrete device descriptors; the authoring type itself need not be a
  bitstype.
- One combined test-only downstream module adds a schedule, stochastic trigger/effect, division
  geometry, property policy, and derived observable. It should exercise composition rather than
  creating one fixture package per method.
- Interface names remain provisional until the reference implementation and downstream fixture make
  their minimal required arguments clear.

### Deferred possibilities

- Dynamic-link event targets and focal-link creation, breakage, inheritance, or persistence.
- A general algebra for composing arbitrary conflicting effects. Phase 8 can implement a specific
  composed effect when a paper model needs one; otherwise ambiguity rejection or explicit semantic
  priority is sufficient.
- Nonbinary division, lineage identity graphs, detailed per-event histories, and general death-
  program algebra beyond the accepted shrink and immediate modes.
- A catalog of asymmetric, off-center, nonplanar, field-directed, or property-directed division
  built-ins. The extension seam is tested with one non-built-in geometry only.
- Arbitrary imperative host lifecycle callbacks.
- A universal equilibrium-auxiliary framework. A future equilibrium family brings and proves its
  own lifecycle mathematics.
- GPU connectivity enforcement unless a paper workload requires and qualifies it; the explicit
  sequential constraint remains scientifically valid.

## Initialization Scope

The final initialization protocol remains subject to the active interview, but its Phase 8
implementation boundary is intentionally small.

### Scientific invariants

- Ownership claims resolve deterministically; overlap rejects by default and never silently follows
  declaration or device scheduling order.
- Zero-occupancy provisional entities are removed before runtime ID assignment and property
  initialization.
- Capacity is validated before compiled state is published.
- Biological and auxiliary initialization uses semantic RNG identities and does not shift unrelated
  draws.
- Derived state is reconstructed from finalized authoritative ownership, and all state invariants
  pass before execution.
- Logical finalization precedes explicit compiled-state lowering and centralized backend adaptation.

### Paper-required built-ins

- One conceptual medium.
- Dense ownership or mask input, explicit coordinate ownership, and the procedural shapes used by
  paper models and tutorials.
- Uniform site seeding without replacement and bounded sequential rejection placement as separately
  named algorithms; neither is presented as a general packing framework.
- Reject-overlap plus explicit semantic-priority replacement/preservation behavior.
- Deterministic compact runtime ID assignment and property override initialization.
- CPU reference finalization. Device-native initialization is added for required large built-ins
  when benchmarks show a material construction-time or memory benefit; it is not required merely to
  keep steady-state MCS execution on GPU.

### Minimal extension seam

- Prefer one layout protocol with conceptually two essential operations: declare requirements and
  emit claims into compiler-owned storage. Validation, overlap resolution, ID assignment, property
  initialization, derived reconstruction, and backend adaptation remain generic engine work.
- One combined downstream fixture supplies a coordinate or procedural layout without a CorePotts
  source edit.
- A layout may explicitly be host-finalized or device-native. This capability is reported rather
  than encoded in a parallel layout hierarchy.

### Deferred possibilities

- A separate universal source/rasterizer/placer framework.
- File-format-specific image loaders; ordinary Julia packages can produce arrays or coordinates.
- Multiple simultaneous medium domains in the production engine.
- Arbitrary overlap-composition algebra, stochastic overlap winners, adaptive packing, and general
  geometric constraint solving.
- General random confluent packing and backtracking placement; paper workflows use tiling or masks
  unless a separately qualified algorithm is required.
- Requiring every custom layout to compile as a GPU kernel.

## Persistence Scope

### Scientific invariants

- Observable snapshots and exact-continuation checkpoints are distinct contracts.
- A checkpoint contains or identifies all semantic, algorithm, RNG, generation, auxiliary, schema,
  version, and numerical state required by its advertised continuation profile.
- Writes publish transactionally; loads verify integrity and compatibility before mutating an
  integrator.
- Canonical logical state and fingerprints do not depend on backend storage layout, addresses, or
  launch configuration.
- Unsupported exact continuation fails explicitly; a weaker state import is a separately requested
  operation.

### Paper-required built-ins

- Immutable in-memory snapshots and canonical logical checkpoint representation.
- Exact uninterrupted-versus-restored continuation on the same compatible profile.
- Explicit backend-independent logical import with only the reproducibility claim it has actually
  qualified.
- HDF5 and Zarr package extensions that round-trip the same canonical logical contract, as already
  accepted for the paper repository.
- Schema and initial-state fingerprints, checksums, RNG continuation, and concise provenance needed
  to reproduce paper runs.

### Minimal extension seam

- One logical snapshot/checkpoint reader-writer interface owned by CorePotts; optional formats add
  methods through Julia package extensions.
- Storage adapters translate the canonical logical representation. They do not receive simulator
  internals, backend workspaces, or permission to invent scientific meaning.
- HDF5 and Zarr share one conformance suite rather than separate persistence architectures.

### Deferred possibilities

- A universal data-lake, streaming, or artifact-management framework.
- Automatic environment installation, remote checkpoint stores, and every future file format.
- Cross-backend bitwise trajectory continuation unless a later guarantee profile proves it.
- Publication-bundle automation beyond the metadata and files directly required by the paper.
- Advanced observation streaming and visualization sinks owned by later SciML/output phases.

## Phase 8 Construction Order

1. Define the minimal scalar interfaces and results needed by the accepted invariants.
2. Implement one complete CPU reference lifecycle, initialization, and checkpoint vertical slice.
3. Implement the paper-required built-ins through those same interfaces.
4. Add one combined downstream extension module and remove every central family switch it exposes.
5. Lower the required lifecycle slice to compiled CPU execution, then Metal and ROCm.
6. Add HDF5 and Zarr as thin extensions over one canonical checkpoint contract.
7. Measure inference, allocations, synchronization, compile latency, workspace size, and steady-state
   performance; specialize only demonstrated bottlenecks.
8. Freeze names only after the external fixture and backend evidence pass.

## Minimality Gate

An abstraction is removed or deferred unless at least one answer below is yes:

1. Is it required by an accepted scientific invariant?
2. Is it used differently by two real Phase 8 implementations?
3. Does it eliminate a central behavioral switch or scientifically meaningful duplication?
4. Does the downstream extension require it to avoid depending on internals?

Even then, reviewers ask whether one ordinary Julia function or one field on an existing schema is
sufficient. Future extensibility is preserved by dispatch and ownership boundaries, not by
implementing speculative families.
