# Decision 0004: Transactional Deterministic Lifecycle

Status: Accepted

Date: 2026-07-17

## Context

Current lifecycle kernels allocate IDs through racing atomics, may partially handle capacity
exhaustion, retain stale property values, allocate before proving valid division geometry, and use a
global event interval.

## Decision

Lifecycle events execute at integer-MCS boundaries from one common trigger snapshot. Identity-
changing conflicts require explicit resolution. Division batches are stable and deterministic by
parent ID.

Division validates geometry before ID allocation and aborts the complete valid batch without mutation
if fixed capacity is insufficient. The parent retains its ID and the child receives the lowest
available ID. Derived state is recomputed; biological state follows schema inheritance.

Progressive shrink death and immediate death are distinct. Any zero-volume finite cell is retired.
Retirement resets all device state immediately. Retired IDs become reusable on the next MCS in
ascending order and carry an incremented slot generation.

Each event owns its integer-MCS schedule. Stable GPU lifecycle actions are device executable; host
actions are explicit synchronization boundaries.

## Consequences

- Deterministic scans/compaction replace identity-allocation races.
- Capacity failure may require a lifecycle synchronization to raise a host exception.
- `N_cells` must be replaced by separate active-count, capacity, free-slot, and high-water concepts.
- Every property needs lifecycle metadata.
- Same-MCS death-to-birth ID reuse is prohibited.

## Required Evidence

- Atomic batch-abort capacity tests
- Deterministic parent/child assignment tests on all backends
- Geometry conservation and connectivity tests
- Complete retired-slot reset tests
- Event conflict and common-snapshot tests
- Cross-backend lifecycle diagnostics
