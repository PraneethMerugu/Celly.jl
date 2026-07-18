# Phase 6 Chunk Plan: Topology, Components, Proposals, and Trackers

Status: Complete

## Completion Contract

Phase 6 is complete only when the final CorePotts scientific inner loop can construct one copy
proposal, evaluate its constraints, conservative energy, drives, proposal probabilities, and
acceptance inputs, and commit its ownership and derived-tracker transaction through compiled state
on CPU, Metal, and ROCm. Local values must agree with independent global reconstruction. The new
path may not depend on the historical topology, penalty, sampler, or tracker stack; that unmigrated
algorithm stack is frozen as a Phase 7 quarantine and receives no new consumers.

## Paper-Scope Inventory

| Family | Required Phase 6 status |
| --- | --- |
| Cartesian ownership domains | 2D/3D, periodic/closed/mixed faces, fixed exterior and obstacles |
| Spatial relations | Proposal, contact, surface, connectivity, query, field, conflict roles |
| Proposal laws | Uniform mutable recipient plus canonical bulk direction; complete forward/reverse multiplicities |
| Hamiltonians | Volume, unordered contact, ordinary surface, conservative external-field occupancy coupling |
| Drives and modifiers | Native chemotaxis modes and required positive-yield kinetic modifier |
| Constraints | Optional connectivity and immutable-domain mutation prohibition |
| Trackers | Volume, declared boundary measure, and moments required by accepted focal-point behavior |
| Queries and fields | Core edge/site/distinct-owner queries and read-only aligned/interpolated field sampling |
| Deferred | HST families, Crofton defaults, graph domains, PDE evolution, secretion/uptake, compatibility registry |

## Vertical Chunks

| Chunk | Scope | Exit evidence |
| --- | --- | --- |
| 1. D3 and scope freeze | Decision 0014 and this inventory | No required field coupling has an undefined scientific category |
| 2. Cartesian relation compiler | Domain, canonical static offsets, boundaries, realization, weights, owner domains | Exhaustive 2D/3D relation and invalid-periodic-domain fixtures |
| 3. Proposal and acceptance inputs | Final proposal value, null reasons, forward/reverse multiplicities, stable log-domain inputs | Hand-enumerated transition and zero-temperature fixtures |
| 4. Conservative component slice | Volume, contact, surface, external-field global/local laws | Every local delta matches full recomputation |
| 5. Transactions and trackers | Rebuild, proposal delta, staged commit, validation, exact workspace report | Cache equals reconstruction after accepted/rejected/boundary/lifecycle cases |
| 6. Remaining paper components | Connectivity, queries, fields, chemotaxis, focal-point requirements, modifier | Scalar and compiled component conformance |
| 7. GPU qualification and quarantine | CPU/Metal/ROCm device code, measured specialization, legacy dependency audit | Full matrix, zero incidental sync/allocation, no legacy dependency in the compiled scientific path |

## Phase Boundary

Phase 6 supplies proposal, evaluation, and transaction primitives. Phase 7 owns normalized-MCS
algorithm schedules, conflict ordering, checkerboard and lottery guarantees, and statistical
algorithm characterization. Phase 6 tests may execute controlled batches but do not freeze those
algorithm families.

Exact connectivity and distinct-owner queries use explicit reusable workspaces. Their generic
device implementation is intentionally one-work-item and allocation-free; Phase 7 owns per-lane
workspace partitioning or a measured parallel specialization. A workspace is never shared by
concurrent proposal evaluations.

The qualification pipeline uses ordered proposal/component, generic-evaluation, and query kernels
with one final observation synchronization. Splitting these responsibilities is part of the kernel
contract: a backend is not required to compile one unbounded monolithic probe.
