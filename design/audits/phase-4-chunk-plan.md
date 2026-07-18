# Phase 4 Chunk Plan: Core State and Scientific Protocols

Status: Complete — all six chunks satisfy the revised ADR 0012 gate

## Purpose

Phase 4 establishes the scientific state contract while leaving the historical CPU and GPU paths
working until their deliberate migration. These chunks are sequential gates: a chunk adds one
contract and its conformance evidence before the next executable slice consumes it.

| Chunk | Scope | Exit evidence |
| --- | --- | --- |
| 1. Semantic vocabulary and schemas | Stable IDs, capacities, numerical policies, property descriptors, provenance, and schema conflicts | CorePotts tests prove typed identity validity, schema deduplication/conflicts, and portable numerical defaults; no legacy storage behavior changes |
| 2. Logical CPU state | Final host state representation, owner/cell/medium accessors, active/free slots, derived-state boundary | A CPU state can satisfy every Phase 3 state invariant through public accessors only |
| 3. Initialization | Rasterization finalization, overlap policy, compact IDs, capacity validation, schema initialization, tracker reconstruction | 2D/3D initialization fixtures pass through the logical state and match reference snapshots |
| 4. Lifecycle state transitions | Retirement, reset, next-MCS reuse, deterministic allocation, property transition state | Division/death/capacity transaction references pass without duplicate state storage |
| 5. Core scientific protocols | Public component, proposal, tracker, event, topology, and algorithm extension functions | A standalone CorePotts extension example passes interface and conformance tests |
| 6. Reference vertical-slice qualification | Sequential 2D CPU engine, volume and contact terms, normalized MCS, semantic replay, observation, and one PottsToolkit compilation path | End-to-end reference tests pass; allocations are characterized; remaining production-runtime migration is explicitly assigned to later phases |

Chunk 6 supersedes the original runtime-migration closeout. Production CPU/GPU execution migration
remains mandatory in Phases 5–7, but is not evidence for whether the Phase 4 scientific protocols
compose into a correct runnable model.

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

## Chunk 2 Evidence

- `LogicalPottsState` is the CPU logical-state boundary: it stores explicit tagged cell/medium
  owners, fixed capacity, active and reusable slots, generation and type tables, schema-backed
  properties, and derived finite/medium occupancy.
- Its public accessors expose the accepted state-model meanings without referring to legacy
  `PottsState` fields. `assert_valid_state` checks ownership, active/free slots, capacity, property
  coverage/reset state, and tracker-equivalent occupancy against a full lattice recomputation.
- Focused tests cover 2D, 3D, multiple medium domains, stale-derived-state detection, and invalid
  owner/free-slot rejection. `Pkg.test("CorePotts")` passes with 396 passing tests and one
  pre-existing documented broken test on Julia 1.12.6.

## Chunk 3 Evidence

- `finalize_initial_state` finalizes 2D or 3D host layouts into `LogicalPottsState` through an
  explicit overlap policy (`ErrorOnOverlap` by default, `ReplaceOnOverlap`, or
  `PreserveOnOverlap`), zero-occupancy removal, ascending deterministic compaction, fixed-capacity
  preflight, schema initialization, and derived-state reconstruction.
- Initialization reports preserve provisional-to-runtime ID mapping and explicitly report discarded
  zero-occupancy finite cells. Undeclared media, incompatible provisional type declarations, shape
  mismatches, overlaps, and capacity exhaustion fail before a result is returned.
- Focused tests cover 2D/3D layouts, multiple media, compaction, overlap modes, vanished cells,
  schema defaults, and capacity errors. `Pkg.test("CorePotts")` passes with 417 passing tests and
  one pre-existing documented broken test on Julia 1.12.6.

## Chunk 4 Evidence

- `apply_division_batch` validates all daughter geometry from one snapshot, stably orders parents,
  preflights the complete batch against fixed capacity, and commits only a private candidate. It
  applies schema-defined clone/split/reset policies, recomputes derived occupancy, and reports
  deterministic parent-child assignments.
- Immediate death transfers ownership to a declared medium, retires the now-empty cell, resets its
  schema properties, and deliberately withholds its slot from division until
  `release_retired_slots` at the next MCS boundary. Reuse advances the slot generation.
- Type transitions are transactional and respect preserve/reset/recompute property policies.
  Focused tests cover all of these transactions, invalid geometry, and atomic capacity abort.
  `Pkg.test("CorePotts")` passes with 444 passing tests and one pre-existing documented broken test
  on Julia 1.12.6.

## Chunk 5 Evidence

- CorePotts now exposes additive ordinary-Julia extension protocols for typed copy proposals,
  conservative energies, nonconservative drives, hard constraints, trackers, events, algorithms,
  and topology. Stable identity, typed requirements, capabilities, and category validators are
  public rather than implicit kernel conventions.
- The protocol layer also provides semantic logical-state property accessors and focused conformance
  helpers. It leaves legacy penalties, trackers, kernels, and their performance paths untouched
  until their deliberate migration.
- A standalone extension fixture defines immutable concrete implementations of every category using
  only documented CorePotts functions. `Pkg.test("CorePotts")` passes with 456 passing tests and
  one pre-existing documented broken test on Julia 1.12.6.

## Chunk 6 Evidence

- `SequentialReference` executes exactly one integer MCS as `N` semantically addressed candidate
  attempts over `LogicalPottsState`. Its report partitions every attempt into no-op, constraint
  rejection, energy rejection, or accepted copy and records retirement.
- `ReferenceVolumeEnergy` and `ReferenceContactEnergy` satisfy local-delta versus complete
  Hamiltonian tests, including finite-cell extinction. Same-seed runs produce equal reports and
  logical ownership snapshots; retirement reuse occurs only at the following MCS boundary.
- PottsToolkit `CellType`, `PottsSystem`, rigid `VolumeComponent`, `AdhesionComponent`, and a
  deterministic layout compile through `reference_integrator` into the CorePotts reference path.
  Unsupported components, stochastic legacy layouts, flexible parameters, events, and extra media
  fail explicitly rather than falling back to historical execution.
- The executable slice exposed and corrected the parametric-extension subtype direction in the
  public scientific interface validator.
- On Julia 1.12.6, the full CorePotts suite passes with 481 tests and one pre-existing documented
  broken test; the full PottsToolkit suite passes with 269 tests.
- After warmup, the checked second MCS of the documented 16-by-16, one-cell PottsToolkit fixture
  infers `ReferenceMCSReport` and allocates 39,104 host bytes. This characterizes the copy-on-commit
  scalar oracle; it is not a production performance acceptance threshold.

## Deferred production obligations

The runtime migration inventory remains in `phase-4-runtime-migration-audit.md`. Compiled execution
state, counter-RNG backend qualification, allocation-free steady-state kernels, zero-sync GPU
execution, and replacement of historical `PottsState` consumers are mandatory Phase 5–7 work and
are not implied by this Phase 4 completion.
