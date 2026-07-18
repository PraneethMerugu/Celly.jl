# Phase 4 Chunk Plan: Core State and Scientific Protocols

Status: Active — Chunk 1 complete

## Purpose

Phase 4 replaces the scientific state contract while preserving a working CPU and GPU path at every
boundary. These chunks are sequential gates, not parallel architectures: a chunk adds one final
contract and its conformance evidence before the next chunk consumes it.

| Chunk | Scope | Exit evidence |
| --- | --- | --- |
| 1. Semantic vocabulary and schemas | Stable IDs, capacities, numerical policies, property descriptors, provenance, and schema conflicts | CorePotts tests prove typed identity validity, schema deduplication/conflicts, and portable numerical defaults; no legacy storage behavior changes |
| 2. Logical CPU state | Final host state representation, owner/cell/medium accessors, active/free slots, derived-state boundary | A CPU state can satisfy every Phase 3 state invariant through public accessors only |
| 3. Initialization | Rasterization finalization, overlap policy, compact IDs, capacity validation, schema initialization, tracker reconstruction | 2D/3D initialization fixtures pass through the logical state and match reference snapshots |
| 4. Lifecycle state transitions | Retirement, reset, next-MCS reuse, deterministic allocation, property transition state | Division/death/capacity transaction references pass without duplicate state storage |
| 5. Core scientific protocols | Public component, proposal, tracker, event, topology, and algorithm extension functions | A standalone CorePotts extension example passes interface and conformance tests |
| 6. Migration qualification | Remove legacy state-field contracts, characterize public path allocations, CPU/GPU smoke qualification | CPU logical conformance plus available-GPU smoke path pass; no public path depends on legacy `PottsState` fields |

## Chunk 1 Boundaries

Chunk 1 establishes values and immutable descriptors only. It does **not** reinterpret the current
`PottsState`, change simulation results, or route existing kernels through new storage. This avoids
mixing a semantic vocabulary change with the physical-state replacement in Chunk 2.

The implementation lives in `CorePotts/state/semantics.jl` and is independent of backend runtime,
workspaces, kernels, and PottsToolkit authoring internals.

## Chunk 1 Evidence

- `julia --project=lib/CorePotts --startup-file=no -e 'using CorePotts'` performs a clean
  precompilation load on Julia 1.12.6 without method-overwrite warnings.
- `Pkg.test("CorePotts")` passes with 366 passing tests and one pre-existing documented broken
  test; the semantic tests cover stable identity validation, portable numerical defaults, schema
  provenance/deduplication, schema conflicts, and host-only initializer rejection.
