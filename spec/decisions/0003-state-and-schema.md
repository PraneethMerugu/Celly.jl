# Decision 0003: Symbolic Types and Compiled Property Schemas

Status: Accepted

Date: 2026-07-17

## Context

The current state assumes one medium encoded by cell ID zero and builds per-cell fields by silently
merging symbol/type dictionaries. This cannot represent multiple media safely and cannot diagnose
property conflicts or lifecycle behavior.

## Decision

Users model with symbolic cell and medium types. Dense type indices are compiled read-only details.
Cell IDs remain public reusable finite-cell handles.

Multiple medium types may simultaneously own lattice sites. Each medium type is one conceptual
domain across all disconnected regions, has type-level behavior and measurable in-domain occupancy,
but has no finite-cell instance properties or lifecycle.

All per-cell properties are compiled through a provenance-aware schema containing type,
initialization, mutation, inheritance, transition, retirement, and storage information.
Incompatible requirements fail model construction. Arbitrary GPU-compatible user properties are a
first-class PottsToolkit feature.

Layout overlap defaults to an error. Runtime IDs are assigned after rasterization, and provisional
zero-volume cells are discarded.

## Consequences

- The lattice representation must distinguish finite cells and multiple media.
- Components cannot communicate through undocumented symbol conventions alone.
- Property fields can be lowered to backend-appropriate physical storage.
- Existing last-write-wins schema construction must be replaced.
- Initialization becomes a compile/finalize/validate pipeline.

## Required Evidence

- Schema conflict tests with provenance
- Multiple-medium conformance tests
- Logical-property/physical-storage round trips
- Initialization invariants and overlap-policy tests
- GPU compilation tests for supported property types
