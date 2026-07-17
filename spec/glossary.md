# Glossary

Status: Accepted unless an entry is marked otherwise

## Spatial Terms

**Lattice**
: The discrete set of sites on which ownership state is represented. Its geometry and finite domain
  are declared separately.

**Lattice geometry**
: The embedding and geometric interpretation of lattice sites, offsets, distances, and physical
  measures. Cartesian, hexagonal, and graph geometries are distinct families.

**Domain**
: The realized finite set of valid lattice sites together with dimensions, boundaries, and any
  excluded sites or obstacles.

**Lattice site**
: One discrete location in the lattice. Every valid simulation site MUST have an owner.

**Spatial coordinate**
: A coordinate in model space. Public coordinate conventions remain under investigation. Internal
  array indexing conventions are not semantic.

**Neighborhood**
: A user-facing name for a spatial relation or for a constructor that produces one. The term alone
  does not identify its scientific role.

**Spatial relation**
: A named, ordered relation between lattice sites used for one declared purpose, such as proposals,
  contact energy, surface measurement, connectivity, spatial queries, or conflict exclusion.

**Stencil**
: An ordered collection of nonzero relative offsets and associated metadata used to construct a
  regular-lattice spatial relation.

**Direction ID**
: The stable one-based position of an offset in a canonical stencil. It is semantic whenever used
  for proposal probabilities, addressed randomness, provenance, or trajectory reproducibility.

**Realized relation**
: The edges obtained by applying a spatial relation to a particular finite domain and its boundary
  conditions.

## Identity Terms

**Finite cell**
: A biological cell instance with a positive, visible, reusable cell ID and finite lattice
  occupancy.

**Cell ID**
: The public integer handle identifying one active finite-cell storage slot. An ID MAY be reused only
  after its prior cell is retired.

**Slot generation**
: An internal counter incremented when a reusable cell-ID slot is assigned to a new cell. It is part
  of RNG identity and stale-handle protection, not a public lineage ID.

**Cell type**
: A symbolic biological category that determines type-level behavior and parameters. A cell type is
  not a cell ID.

**Type index**
: A dense compiled integer index used for device lookup. It is an advanced read-only implementation
  view, not the primary modeling API.

**Medium type**
: A symbolic type describing a spatially unbounded medium domain. A medium type has type-level
  behavior but no finite-cell lifecycle or per-cell instance properties.

**Medium domain**
: The single conceptual instance associated with a medium type, including all disconnected lattice
  regions owned by that type.

**Active cell**
: A finite cell that owns at least one lattice site and occupies a live cell-ID slot.

**Retired cell**
: A finite cell that no longer owns any site and whose slot has completed retirement cleanup.

## Proposal Terms

**Recipient site**
: The lattice site whose owner may be replaced by a proposal.

**Donor site**
: The selected neighboring site whose owner is proposed for copying into the recipient site.

**Removed owner**
: The recipient site's owner before an accepted proposal.

**Added owner**
: The donor site's owner, which becomes the recipient site's owner after acceptance.

**Copy attempt**
: One independent recipient-site selection followed by one donor-direction selection. Same-owner and
  invalid no-flux selections remain attempts but are no-ops.

**Proposal**
: A non-no-op candidate state transition produced by a copy attempt.

**Accepted move**
: A proposal whose lattice and derived-state transaction commits.

**No-op attempt**
: A copy attempt that cannot change the state, including same-owner selection or an invalid no-flux
  direction.

## Time Terms

**Monte Carlo step (MCS)**
: The public unit of simulation time. For a realized domain with `N` mutable ownership sites, one
  reference MCS contains exactly `N` independent copy attempts with recipient sites sampled
  uniformly with replacement.

**Internal round**
: An algorithm-specific scheduling unit. Internal rounds are not public time and MUST account for a
  defined fraction of an MCS.

**Event phase**
: The integer-MCS boundary phase in which event triggers observe a common snapshot, conflicts are
  resolved, and lifecycle/property transactions commit.

## State and Physics Terms

**Biological property**
: Per-cell model state whose initialization, inheritance, transition, retirement, and storage
  behavior is declared in the compiled property schema.

**Derived property**
: A value determined from lattice ownership or other authoritative state, such as volume, surface
  area, centroid, or inertia. It is recomputed rather than inherited.

**Tracker**
: An incremental representation of a derived property used to avoid global recomputation during
  copy attempts.

**Penalty**
: A contribution to the model's energy or proposal acceptance rule.

**Auxiliary field**
: Additional thermodynamic or algorithmic state, including HST variables. Auxiliary fields require
  explicit time-integration and lifecycle semantics.

**Snapshot**
: A synchronized observable state at a specified MCS. A snapshot is not necessarily sufficient for
  exact continuation.

**Checkpoint**
: A versioned representation containing all state required for supported continuation, including RNG
  and slot-generation state.
