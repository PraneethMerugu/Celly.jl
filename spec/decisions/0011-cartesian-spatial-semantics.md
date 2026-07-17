# ADR 0011: Explicit Cartesian Measures, Owner Domains, Queries, and Fields

- Status: Accepted
- Date: 2026-07-17

## Context

The current implementation stores surface as an integer count over the global topology, applies an
implicit inverse-distance option only to adhesion, overloads neighbor-query names with incompatible
edge and distinct-owner meanings, and accepts an index-aligned array as a chemical field. Its
chemotaxis saturation transforms the concentration difference rather than reproducing the named
response laws documented by other CPM systems.

These choices prevent physical parameter conversion, exact tracker typing, reliable model exchange,
and independent field grids. They also make the current HST surface component appear to be the
ordinary surface constraint.

## Decision

Raw boundary-edge count, weighted boundary count, normalized boundary measure, and physical
perimeter/surface are distinct metric types. Trackers are keyed by the complete metric descriptor.
The first literature-backed physical reference is a versioned normalized-kernel measure; alternative
Crofton-style estimators remain experimental until validated.

The ordinary surface Hamiltonian is `lambda * (S - S_target)^2`. HST surface dynamics remain a
separately named experimental family. Contact and surface relations and quadratures are independently
declared.

Closed boundaries, fixed exterior owner domains, obstacles, and immobilized finite cells are
different. Exterior and obstacle walls are immutable domain owners without finite-cell lifecycle.
Excluded obstacle storage is not part of the mutable ownership site set and therefore does not
contribute to the reference MCS budget.

Spatial queries use names that reveal whether they aggregate incidences, physical measure, boundary
sites, or distinct neighboring owners. Queries in one rule phase observe one snapshot.

Fields are explicit `SpatialField` values with geometry, placement, boundaries, units, time, backend,
and interpolation semantics. Chemotaxis is a nonconservative drive by default and uses named response
functions and responding-owner modes. The historical saturation-of-difference formula is not the
native saturation law.

## Consequences

- `SurfaceAreaTracker`, `SurfaceAreaComponent`, `ContactArea`, and `ChemotaxisPenalty` require
  replacement or precise legacy names.
- Multiple metric trackers may coexist while identical descriptors are interned.
- Surface targets are no longer silently rounded to integers.
- Field arrays with mismatched geometry or boundaries fail validation unless explicit interpolation
  and boundary semantics are supplied.
- GPU field evaluation remains backend-resident during MCS execution.
- Operator splitting, secretion, uptake, and PDE integration remain for the SciML coupling contract.

## Evidence required

- Full recomputation equality for every incremental metric tracker.
- Published correction-factor and resolution-conversion fixtures in 2D and 3D.
- Rotated-shape anisotropy benchmarks for every advertised estimator.
- Exact fixtures for every spatial-query aggregation.
- Cross-backend field interpolation and chemotaxis-law tests.
- CC3D, Morpheus, and Artistoo chemotaxis compatibility fixtures where claimed.
- MCS attempt accounting with exterior ghosts and excluded obstacles.

## Specification

See [Cartesian Surface, Queries, and Fields](../cartesian-surface-queries-and-fields.md).
