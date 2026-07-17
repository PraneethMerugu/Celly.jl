# Cell Lifecycle

Status: Accepted except HST-specific rules marked provisional

## Lifecycle Phase

Lifecycle and property events occur at integer-MCS boundaries. All event triggers for MCS `t` MUST
observe one common event-phase snapshot after the MCS proposal and auxiliary work and before any
lifecycle mutation at that boundary.

Event declaration order, tuple order, thread scheduling, and backend scheduling MUST NOT implicitly
determine biological conflict resolution.

The lifecycle engine SHOULD execute logically as follows:

1. Evaluate trigger masks from the common snapshot.
2. Resolve identity-changing conflicts.
3. Validate all proposed transactions.
4. Apply ordinary property updates.
5. Apply type transitions.
6. Initiate progressive death programs.
7. Validate division geometry.
8. Preflight division capacity.
9. Commit valid divisions.
10. Apply immediate deaths.
11. Detect and retire zero-volume cells.
12. Reset retired slots.
13. Recompute derived state for modified cells.
14. Initialize or update lifecycle-dependent auxiliary state.
15. Update diagnostics.
16. Publish the completed MCS.

IDs retired during MCS `t` MUST NOT be reused until MCS `t + 1`.

## Event Scheduling

Each event owns an integer-MCS schedule. Stable schedules MAY include periodic schedules, one-time
schedules, and bounded periodic schedules. A single global `check_interval` is not normative.

Lower-level scheduling rounds remain internal and MUST NOT be used as biological event time.

## Event Conflicts

At most one identity-changing outcome MAY apply to one finite cell at one MCS boundary. Identity-
changing outcomes include division, immediate death, and type transition.

Models with potentially overlapping identity-changing triggers MUST provide an explicit resolver or
an explicitly composed lifecycle event. Silent vector-order priority is prohibited.

A default resolver MAY define category priority, but its policy MUST be public and stable. Statically
detectable unresolved conflicts SHOULD fail model construction.

Property updates MAY coexist if their snapshot, read, write, and conflict behavior is valid under the
future rule-language specification.

## Division Eligibility

Division triggers are evaluated from the event-phase snapshot. Newly created cells MUST NOT become
eligible again during the same event phase.

Eligible parents MUST be stably compacted in ascending cell-ID order. Parent-child ID assignment MUST
be deterministic for the same model, seed, backend, and package version.

## Division Identity

For a successful division:

- The parent retains its cell ID.
- The new daughter receives the lowest available reusable ID or the next valid fresh ID.
- The child slot generation is incremented when a reusable ID is assigned.
- Both resulting cells preserve the parent's type by default.
- A division rule MAY explicitly assign different valid parent and daughter types.

No public permanent lineage identity is required in specification version `0.1-draft`.

## Division Geometry

A successful division MUST satisfy:

1. Parent and daughter each own at least one site.
2. Their combined post-division sites equal exactly the parent's pre-division sites.
3. No site is lost, duplicated, or transferred from an unrelated owner.
4. Any configured minimum daughter-volume requirement is satisfied.
5. If connectivity is required for that division, both resulting cells satisfy it.

The default minimum daughter volume is one site. Connectivity is optional and MUST NOT be imposed
unless requested by the model.

A geometrically invalid division affects only that parent. Other valid divisions MAY proceed. The
failed parent receives no child ID and remains eligible for reevaluation at a later scheduled event.
The failure MUST be recorded in diagnostics.

## Division Transaction and Capacity

Division is a transaction. Its logical order is:

1. Snapshot and stably compact eligible parents.
2. Compute and validate proposed geometry.
3. Count geometrically valid divisions.
4. Preflight fixed capacity.
5. Allocate child IDs deterministically.
6. Commit lattice ownership changes.
7. Apply biological property inheritance.
8. Recompute derived properties.
9. Initialize auxiliary properties.
10. Validate division invariants.

If capacity cannot accommodate the complete valid batch, the complete batch MUST abort without
mutation and a structured `CellCapacityError` MUST be raised. Committing only a deterministic subset
is prohibited.

A synchronization required to surface a capacity exception is permitted. Zero-sync execution MUST
NOT leave a partially committed biological transaction.

## Property Inheritance

Every biological property has a schema-level division policy. Division events MAY explicitly
override compatible policies.

Supported policy families MAY include:

- Clone parent state to the child
- Preserve parent and reset child
- Reset both
- Asymmetrically reset parent and child
- Conservatively split
- Apply an explicit device-compatible transformation

Arbitrary user properties MUST NOT receive an undocumented global inheritance default.

Derived properties, including volume, surface area, centroid, inertia, current length, contact
counts, and neighbor summaries, MUST be recomputed from the committed post-division lattice.

For conserved integer properties split by a fraction, the default policy SHOULD use keyed stochastic
rounding while preserving the exact total. The draw MUST use the lifecycle RNG stream and remain
repeatable under the accepted reproducibility contract. A deterministic remainder policy MAY be
available explicitly.

## HST State After Division

Status: Provisional

Each HST family MUST define an explicit division policy. Candidate policies include conditional-
equilibrium sampling, resetting to the post-division mean, conservative splitting, and cloning.

The intended default is a sample from the scientifically correct post-division conditional
distribution. This distribution MUST be derived and validated before it becomes accepted semantics.
Until then, resetting to the post-division thermodynamic mean MAY be used only as a documented
provisional policy. Cloning an HST field MUST NOT be assumed correct by default.

## Type Transitions

A type transition is transactional. Before mutation, the engine MUST:

1. Validate the destination type.
2. Resolve transition behavior for every affected property.
3. Verify destination requirements.
4. Compute transformed or reset values.
5. Commit the type and property changes together.

Property transition policies include preserving the current value, resetting to the destination
type's default, applying an explicit transformation, invalidating an unsupported transition, or
recomputing derived state.

Type-level rigid parameters use the destination type immediately after commit. Per-cell flexible
parameters follow their property transition policies.

## Death Modes

Progressive shrink death and immediate death are distinct public concepts.

**Shrink death** initiates a model-defined progressive process, commonly by reducing target volume
and optionally changing mechanical properties. The cell remains active until its occupancy reaches
zero or an explicit terminal condition invokes immediate removal.

**Immediate death** removes all ownership of the cell at one MCS boundary and retires its slot as a
single transaction.

The generic term apoptosis MUST NOT obscure which death mode is being modeled.

## Extinction and Retirement

Any active finite cell with zero lattice occupancy at the lifecycle boundary MUST be retired,
regardless of its target volume. If no explicit death program caused the disappearance, diagnostics
classify it as stochastic extinction.

Retirement MUST:

1. Remove the ID from the active set.
2. Reset all device properties to their schema-defined retired state.
3. Preserve no stale biological values visible in snapshots.
4. Increment or prepare the slot generation for future reuse according to the chosen representation.
5. Add the ID to the next-MCS reusable collection exactly once.

Retirement causes SHOULD distinguish programmed death, immediate death, completed shrink death, and
stochastic extinction.

## Lifecycle Execution Locations

The stable GPU lifecycle path accepts compiled device-executable triggers, transformations, and
actions. Host actions MAY be offered only as explicitly synchronizing alternatives and MUST be
identified as such in the API.

An arbitrary host callback MUST NOT hide synchronization inside an otherwise device-resident event.

## Diagnostics

Lifecycle diagnostics MUST expose inexpensive counters including, where applicable:

- Births
- Death-program initiations
- Immediate deaths
- Completed shrink deaths
- Stochastic extinctions
- Successful divisions
- Failed division geometry
- Capacity failures
- Type transitions
- Active finite cells
- Free slots

Detailed event logs and lineage histories MAY be optional output backends rather than mandatory
in-memory state.
