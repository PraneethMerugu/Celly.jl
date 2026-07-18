# Phase 3 Conformance-Foundation Audit

Status: Complete

Date: 2026-07-17

## Purpose

This audit establishes the boundary between the legacy implementation and the reference semantics
that will govern its replacement. It is deliberately not an implementation redesign: Phase 3 adds
small scalar or test-only models, reusable validators, and evidence links so later phases can be
judged without treating legacy kernel behavior as normative.

## Finding

The specification suite is sufficiently developed to begin a safe refactor. The current test suite
contains valuable fixtures and regressions, but it is primarily organized around legacy structs,
kernel helpers, and historical public behavior. It cannot yet validate a replacement engine through
stable logical interfaces.

The first Phase 3 increment therefore establishes an implementation-independent conformance layer
in `integration/reference/`, `integration/conformance/`, and `integration/statistical/`. It owns
only logical scalar data and must not import GPU runtime packages or inspect GPU implementation
details.

## Legacy Behavior That Is Explicitly Not Normative

The following observations match the Phase 0 and Phase 1 audits. They are tracked as migration
targets, not preserved as passing conformance behavior:

- A public legacy step can use `active_fraction` and historical sweep assumptions rather than the
  accepted exactly-`N` reference-attempt contract.
- The legacy sequential implementation uses `Random.Xoshiro`; other paths use `pcg_hash` plus
  magic offsets. Neither defines the accepted addressed RNG contract.
- `MetropolisSampler` currently receives a Hastings ratio, so conventional Metropolis and
  Metropolis-Hastings are not separately represented scientific laws.
- Current owner encoding models a single `0` medium convention and cannot define the accepted
  multiple-medium logical state by itself.
- Current tracker updates use atomics or subgroup reductions. They are useful engineering evidence,
  but are not a proof of the accepted transactional or strict-reproducibility contract.
- Current tests directly inspect `PottsState`, `StructArray` columns, topology internals, and kernel
  helpers. Such tests remain useful regression tests but do not become the final conformance API.

## Phase 3 Architecture

The conformance foundation has four deliberately separated layers:

1. **Scalar reference semantics** define proposal probabilities, conventional and Hastings
   acceptance, normalized attempt accounting, logical snapshots, tracker recomputation, and
   all-or-nothing lifecycle validation. These values use ordinary CPU Julia data only.
2. **Conformance harnesses** provide parameterized case descriptions, invariant failures, canonical
   comparison, and a complete reproduction record. They accept an implementation adapter later;
   they do not depend on a particular state layout today.
3. **Statistical procedures** define deterministic tiers, minimum sample counts, tolerances, and
   diagnostic shape. They are procedure definitions, not accidental assertions embedded in an
   individual algorithm test.
4. **Evidence index** maps accepted documents to reference behavior, invariants, statistical
   procedures, and eventual engine adapters. A row remains visibly incomplete until its named
   conformance test exists.

## Initial Coverage and Deliberate Deferrals

The initial reference layer covers the contracts needed to safely begin Phase 4: state ownership,
active/free IDs, finite-cell occupancy, medium occupancy, property-slot shape, exact attempt
accounting, proposal probability, acceptance, tracker recomputation, and atomic lifecycle
validation.

It intentionally does not claim that the legacy algorithms conform. Algorithm-specific transition
kernel, equilibrium, kinetic, RNG known-answer, cross-backend, topology, SciML, and DSL conformance
are added incrementally as their final stable interfaces arrive. The evidence index records those
obligations rather than hiding them behind broad green test labels.

## Implemented Foundation Slice

The first implementation slice is complete and runs in the dedicated `conformance` integration
shard. It provides:

- scalar reference MCS accounting, proposal probability, conventional Metropolis, and
  Metropolis-Hastings acceptance, including explicit neighbor-owner forward/reverse multiplicities;
- internal-round plans that require exact one-MCS fraction and expected-`N` proposal-budget
  normalization while lottery topology calibration remains an explicit pending evidence item;
- exact volume-tracker deltas whose incremental application is checked against authoritative full
  lattice reconstruction;
- canonical logical snapshots and SHA-256 checksums independent of property declaration order;
- state ownership, active/free-slot, generation, property-slot, finite-cell-volume, and medium
  occupancy validators;
- all-or-nothing logical copy and lifecycle transactions plus a generic local-energy-delta oracle;
- quadratic-volume and unordered-edge contact Hamiltonian references, including symmetric weighted
  contact edges and medium interactions;
- geometry-first division batches with stable parent ordering, lowest-slot allocation, whole-batch
  capacity abort, explicit property inheritance, schema-defined retirement reset, and next-MCS slot
  release;
- explicit Cartesian-stencil validation and closed/periodic boundary realization, where closed
  departures are null rather than clamped self-edges;
- versioned, generator-independent semantic RNG addresses and common failure reproduction records;
- validated algorithm guarantee profiles that keep proposal, equilibrium, kinetic, transaction,
  attempt-normalization, reproducibility, and evidence claims distinct;
- a test-only `AbstractConformanceAdapter` through which replacement CPU/GPU state can be checked
  without exposing physical layouts, with failures wrapped in complete reproduction records;
- a reusable `ReferenceStateAdapter` that qualifies that adapter boundary without importing or
  inspecting any legacy engine type;
- an explicit numerical-policy fixture covering real and accumulation types, math, reductions, and
  overflow choices; and
- fixed deterministic, CI, and scheduled statistical-procedure metadata.

Qualification command:

```sh
POTTS_TEST_SHARD=conformance julia --project=integration --startup-file=no integration/runtests.jl
```

The hosted CI integration matrix includes this shard. It is intentionally small and must remain
free of GPU-runtime imports; device implementations are compared through adapters in later phases.

## Entry Criteria Met

- Accepted documents define a target logical state, reference MCS, proposal/acceptance law,
  transaction behavior, numerical policy direction, and reproducibility vocabulary.
- Phase 1 records a reproducible historical baseline without mistaking it for semantic evidence.
- Phase 2 provides a package-local test layout and an `integration/` environment in which the
  shared suite can live independently of package tests.

## Phase 3 Exit Evidence

Phase 3 completes only when the following are true:

- Every accepted semantic invariant has a named validator or a documented pending adapter in the
  specification-to-test evidence index.
- Reference code has no GPU-runtime dependency and can evaluate logical states without legacy
  kernels.
- Randomized and statistical failures carry a semantic seed, model fingerprint, initial checksum,
  backend report, and executable reproducer.
- The shared case matrix can exercise CPU `Float32` and `Float64`, two and three dimensions,
  named algorithms, and each available backend through one adapter contract.
- At least one new implementation can be evaluated through this layer without inspecting the old
  engine's private storage or kernel functions.

## Completion Evidence

All Phase 3 deliverables and exit conditions have executable evidence:

- `ReferenceSemantics` supplies scalar CPU references for proposal mass, acceptance, local energy,
  volume tracking, lifecycle transactions, normalized attempts, and internal-round budgets.
- Canonical snapshots, checksums, and state validators operate only on logical arrays and schema
  values; `ReferenceStateAdapter` qualifies a complete independent scalar implementation through
  the same adapter boundary that later CPU/GPU engines use.
- The conformance suite validates ownership, IDs, capacity, property coverage/reset, topology,
  tracker reconstruction, atomic transaction behavior, numerical policies, guarantee profiles,
  reproduction records, and statistical tiers.
- The `conformance` shard statically rejects GPU-runtime imports in both reference modules.
- The evidence index distinguishes completed Phase 3 foundations from deliberately later engine,
  DSL, SciML, and component adapters rather than calling future work complete.

Qualification commands:

```sh
POTTS_TEST_SHARD=conformance julia --project=integration --startup-file=no integration/runtests.jl
julia --project=integration --startup-file=no integration/runtests.jl
```

Final qualification on 2026-07-17 passed the dedicated `conformance` shard with 79 assertions and
the complete CPU cross-package integration suite with 152 passing assertions in 3 minutes 5.8
seconds.
