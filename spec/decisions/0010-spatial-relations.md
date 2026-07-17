# ADR 0010: Separate Spatial Roles and Compile Realized Domain Relations

- Status: Accepted
- Date: 2026-07-17

## Context

The current engine uses one topology object to determine proposal neighbors, contact and surface
neighbors, spatial queries, connectivity, periodic displacement, parallel conflict exclusion, and
boundary behavior. These relations need not be scientifically equal. Their conflation also causes
invalid no-flux directions to be clamped onto boundary sites, makes conventional neighborhood
orders ambiguous, and makes checkerboard validity depend only on a stencil rather than the actual
finite periodic domain.

CPM packages use different proposal, interaction, and surface neighborhoods. Neighborhood range
affects anisotropy, parameter interpretation, computational cost, and even which cells interact.
The engine therefore cannot infer all spatial behavior from a single named topology without hiding
scientifically consequential choices.

## Decision

Lattice geometry, finite domain, and named spatial relations are independent semantic objects.
Proposal, contact, surface, connectivity, spatial-query, field-discretization, and parallel-conflict
relations are declared separately. Equal relations may share one compiled descriptor.

Regular-lattice relations compile from explicit ordered offset stencils. Named neighborhood orders
are constructors using geometric distance shells. Direction IDs follow a versioned canonical order
and symmetric relations provide verified opposite directions. Zero and duplicate offsets are
invalid.

Boundary conditions are declared per face. A closed boundary removes an interaction edge; it does
not clamp it onto the boundary site. Conventional bulk-direction proposal algorithms may still draw
an out-of-domain direction as a null attempt when their clock contract requires it.

Periodic configurations that map an offset onto the source or map distinct offsets onto the same
neighbor are invalid unless an explicit multigraph relation is selected. Coloring and conflict
independence are validated on the realized finite domain graph.

The paper-quality native scope is Cartesian 2D and 3D. Hexagonal and irregular graph lattices are
architecturally supported but remain experimental until their own semantic and conformance
contracts are accepted.

Custom relations are validated on the host and compiled into concrete isbits or backend-resident
read-only descriptors. Static versus dynamic storage is an implementation choice and MUST NOT
change the relation's scientific meaning.

## Consequences

- The current topology type hierarchy must be replaced or lowered through a new spatial compiler.
- Components must request a relation by semantic role instead of reading a global topology.
- Compatibility presets become visible bundles of geometry, domain, relation, metric, and
  normalization choices.
- Parallel algorithms must derive and validate conflict relations from full model read/write
  footprints.
- Small periodic domains and odd-size periodic checkerboards that are currently accepted may become
  compile-time errors or require a different schedule.
- Mixed boundaries no longer require bespoke topology subtypes.
- Relation metadata becomes part of model reports, checkpoints, and reproducibility profiles.

## Evidence required

- Exhaustive realized-neighbor enumeration on small 2D and 3D domains.
- Reverse-edge, direction-order, no-self-edge, no-alias, and boundary invariants.
- Local/global energy and full tracker-recomputation agreement for every relation bundle.
- Verified coloring and conflict independence on realized periodic and mixed-boundary domains.
- Rotational anisotropy and physical-measure benchmark suites.
- Identical compiled relation meaning across CPU and supported GPU backends.
- Cross-simulator fixtures for every compatibility relation bundle.

## Specification

See [Topology and Spatial Relations](../topology-and-spatial-relations.md).
