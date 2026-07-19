# State Model

Status: Accepted

## Abstract State

A Potts simulation state contains at least:

```text
S = (L, C, M, A, F, G, P, D)
```

where:

- `L` maps every lattice site to a finite cell or medium domain.
- `C` stores finite-cell biological properties.
- `M` stores medium-type behavior and finite-domain occupancy.
- `A` identifies active finite-cell IDs.
- `F` identifies reusable finite-cell slots.
- `G` stores the generation of each finite-cell slot.
- `P` stores auxiliary physics state required by the model.
- `D` stores derived state or its incrementally maintained tracker representation.

This definition is logical. It does not require a particular Julia struct or physical storage
layout.

## Site Ownership

Every lattice site MUST have exactly one owner. Its owner MUST be either:

- One active finite cell, or
- One declared medium domain.

An empty or unassigned owner is not a valid simulation state.

The physical lattice encoding MUST distinguish all medium types that can simultaneously occupy the
lattice. The historical convention that one integer value denotes all medium sites is insufficient
for multiple media and is not normative.

## Finite Cells

A finite cell:

- MUST have a positive public cell ID.
- MUST own at least one lattice site while active.
- MUST have exactly one declared cell type.
- MUST occupy exactly one live storage slot.
- MUST NOT appear in the reusable-slot collection while active.
- MAY be disconnected unless a model explicitly applies a connectivity constraint.

Cell IDs are visible to users and MAY be used for selection and analysis. They are reusable storage
handles rather than permanent lineage identities.

## Cell Types and Compiled Type Indices

Biological models refer to symbolic cell types. Dense numerical type indices are assigned during
model compilation for device lookup.

User-facing biological rules SHOULD use symbolic cell types. An advanced read-only type-index query
MAY be provided for diagnostics and low-level extension work. Model semantics MUST NOT depend on a
user hardcoding an internal type index.

Changing a model's declaration order MAY change compiled indices but MUST NOT change rules expressed
using symbolic types.

## Medium Domains

Multiple medium types MAY exist simultaneously. Each medium type corresponds to one conceptual
medium domain, even if its lattice occupancy consists of disconnected regions.

A medium domain:

- MAY define adhesion, chemotaxis, external-field, custom-penalty, and property-rule behavior at the
  type level.
- MUST NOT define finite-cell instance properties such as target volume, finite volume, age, or
  pressure.
- MUST NOT divide, die, grow as a finite cell, or participate in finite-cell lifecycle transitions.
- MUST have measurable occupancy within the finite simulated lattice.
- Is conceptually spatially unbounded even though its in-domain occupancy is finite.

Medium occupancy is not finite-cell volume and MUST be exposed separately.

## Cell Counts and Capacity

The following quantities are semantically distinct:

- Active finite-cell count
- Fixed cell capacity
- Number of reusable slots
- Cell-ID high-water mark

`n_cells(state)` MUST mean the number of active finite cells. It MUST NOT mean capacity or the largest
cell ID ever allocated.

GPU execution uses fixed finite-cell capacity. Exceeding that capacity during a lifecycle transaction
MUST raise a structured capacity error and MUST NOT partially commit the transaction.

## Slot Reuse

After retirement, a finite-cell ID MAY be reused. Reusable IDs MUST be selected in deterministic
ascending order.

Every slot maintains an internal generation counter. Assigning a retired slot to a new cell MUST
increment the counter. RNG streams for cell-specific behavior MUST distinguish different generations
of the same cell ID.

Slot generation is not a public lineage identifier in specification version `0.2-draft`.

## Property Schema

The model compiler constructs a complete property schema before runtime execution. Every device
property declaration MUST identify at least:

- A logical name or key
- A GPU-compatible logical type
- Initialization behavior
- Mutability
- Division inheritance behavior
- Type-transition behavior
- Retirement/reset behavior
- Whether it is biological, derived, auxiliary, or transient
- The component or extension that requested it

Compatible requests for the same property MUST be deduplicated. Incompatible types, initializers,
inheritance rules, or transition rules MUST produce a model-construction error containing request
provenance. Silent last-write-wins merging is prohibited.

Stable device properties MAY include fixed-width scalars, isbits enums, tuples or named tuples of
supported values, small fixed-size vectors or tensors, and GPU-compatible immutable isbits structs.
Heap-backed or dynamically sized object graphs are not valid device state.

Logical fixed-size vectors and tensors MAY be lowered to component-wise physical storage. Physical
storage choices are implementation details provided that logical values and mutation semantics are
preserved.

## State Realization Layers

Potts.jl distinguishes three state layers:

1. **Logical state** is the authoritative scientific representation used for construction,
   validation, scalar reference execution, snapshots, and portable inspection.
2. **Compiled execution state** is an explicit lowering of logical state into backend-valid arrays,
   indices, and layouts. It MAY be specialized, but MUST round-trip to the same canonical logical
   snapshot under the applicable numerical contract.
3. **Execution workspace** contains scratch storage, queues, counters, launch resources, and other
   replaceable mutable machinery. Workspace content is not scientific state and MUST NOT be needed
   to interpret a saved model state.

The host logical state MUST NOT be adapted wholesale to a GPU. Compilation constructs the explicit
execution representation, and backend movement is centralized at that boundary. Optimized engines
MAY keep compiled state resident across steps and observations.

## Custom Properties

PottsToolkit MUST support user-declared custom per-cell properties through the same compiled schema
as built-in components. Custom properties MUST NOT bypass type, lifecycle, initialization, or GPU
compatibility validation.

Rich host-only metadata MAY be associated with cells through a separate facility. Host-only metadata
MUST NOT be visible to device-executed rules unless an explicit synchronizing transfer is performed.

## State Invariants

A conforming state MUST satisfy:

1. Every site has exactly one valid owner.
2. Every finite owner in the lattice is active.
3. Every active finite cell owns at least one site.
4. Every active finite cell has exactly one valid cell type.
5. No cell ID is both active and reusable.
6. No reusable ID occurs more than once.
7. Active count equals the cardinality of the active-ID set.
8. Tracked occupancy equals full lattice recomputation.
9. All required properties exist for every finite-cell slot.
10. Retired slots contain their schema-defined reset state.
11. Medium-domain occupancy equals full lattice recomputation.
12. No medium domain has finite-cell lifecycle or instance-property state.

The conformance suite MUST provide full-state validators for these invariants.

## Initialization Finalization

Initialization MUST proceed logically as follows:

1. Rasterize all layouts.
2. Apply an explicit overlap policy.
3. Determine which provisional finite cells own at least one site.
4. Remove zero-occupancy provisional cells.
5. Assign compact runtime cell IDs to surviving cells.
6. Validate fixed capacity.
7. Initialize schema-defined biological and auxiliary state.
8. Recompute derived state from the finalized lattice.
9. Validate all state invariants.
10. Lower the finalized logical state into an explicit compiled execution representation when an
    execution engine requires one.
11. Adapt only that compiled representation through the centralized backend boundary.

Layout overlap MUST default to an error. Replacement or preservation behavior MUST be explicitly
requested. Silent overwrite is prohibited.
