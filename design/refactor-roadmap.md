# Paper-Release Refactor Roadmap

Status: Working execution roadmap derived from accepted specifications and engineering standards

## Execution Status

| Phase | Status | Evidence |
| --- | --- | --- |
| Phase 0: Scope Freeze and Current-Code Audit | Complete | [Current-code audit](audits/phase-0-current-code-audit.md), [paper-scope map](audits/phase-0-paper-scope-map.md) |
| Phase 1: Correctness and Performance Baselines | Complete | [Baseline evidence](audits/phase-1-baseline-evidence.md), [GitHub and JuliaGPU governance](github-and-ci-governance.md), protected `main`, pinned benchmark harness, and immutable attested release |
| Phase 2: Repository Structural Migration | Complete | [Structural migration audit](audits/phase-2-structural-migration.md) and [PR #8](https://github.com/PraneethMerugu/Potts.jl/pull/8) |
| Phase 3: Reference Semantics and Conformance Foundation | Complete | [Conformance-foundation audit](audits/phase-3-conformance-foundation-audit.md), [specification-to-test evidence index](../spec/conformance-evidence.md), and integration `conformance` shard |
| Phases 4-15 | Not started | Blocked by preceding phase gates |

## Objective

This roadmap takes the current repository to the paper-quality `PottsToolkit` and `CorePotts`
architecture without preserving legacy APIs. It sequences semantic decisions, reference evidence,
repository migration, engine replacement, API construction, optimization, documentation, and paper
qualification so that correctness and performance remain measurable throughout the refactor.

The destination is the accepted architecture, not an intermediate compatibility layer. A phase is
complete only when its exit gate passes and its obsolete path is removed.

## Governing Rules

1. Accepted specifications govern observable behavior; existing code is evidence, not authority.
2. Scientific meaning is established in reference code and conformance tests before optimized
   implementation.
3. GPU validity is maintained throughout engine work and is not postponed to final optimization.
4. Structure-only moves are separated from scientific rewrites whenever practical.
5. Package code and tests precede full documentation and tutorial migration.
6. Performance is measured from the beginning; optimization follows profiling and preserves the
   accepted contract.
7. Breaking changes are allowed until the paper API freeze. No migration layer is required.
8. One migrated subsystem has one implementation. Temporary comparison code lives in test,
   benchmark, or archival baselines rather than the released package.

## Scope Classification

### Required for the paper refactor

- Cartesian 2D and 3D domains
- Finite cells, one conceptual medium, fixed owners, and obstacles
- Accepted topology roles, spatial queries, fields, surface measures, and connectivity
- Conventional sequential CPM plus every algorithm family claimed in the paper
- Normalized MCS accounting
- Volume, surface, contact, chemotaxis, focal-point, and other paper components
- Growth, division, type transition, death, extinction, and deterministic lifecycle transactions
- Semantically addressed RNG and reproducibility reports
- CPU, AMDGPU, and Metal qualification for claimed features; CUDA is deferred by Decision 0013
- CorePotts Level 3 and Level 4 interfaces
- PottsToolkit Level 2 typed modeling and Level 1 DSL
- SciML problem, integrator, solution, callback, saving, observation, remake, and ensemble behavior
- Snapshots, checkpoints, initialization, paper workloads, and archived benchmark evidence

### Deferred without blocking the paper release

- HST dynamics, until its Hamiltonian, integration, and lifecycle distributions are accepted
- Hexagonal, rhombic-dodecahedral, irregular, and graph-lattice engines
- Crofton surface estimators
- Validated CC3D, Morpheus, and Artistoo compatibility presets
- Additional query operators, arbitrary custom boundaries, and unclaimed satellite features

Deferred features MUST NOT leak provisional semantics into stable constructors, defaults, reports,
or extension interfaces. A placeholder type or generic protocol is allowed only when it is already
the simplest final design for required features.

## Decision Gates

Open questions are resolved immediately before the first phase that needs them. They do not block
unrelated earlier work.

| Gate | Required decision or evidence | Blocks |
| --- | --- | --- |
| D1 | Paper algorithm inventory and guarantee profile for sequential, checkerboard, lottery, and intrinsic families | Algorithm replacement |
| D2 | Philox qualification and exact portable transforms for every distribution used by required features | RNG engine freeze |
| D3 | Conservative versus nonconservative classification of required field couplings | Energy/component freeze |
| D4 | Snapshot, exact checkpoint, backend-independent restart, storage equivalence, and schema/RNG provenance | Persistence and SciML saving |
| D5 | Coordinates, rasterization, random placement, periodic placement, and initialization finalization | Initialization replacement |
| D6 | Extension registration, semantic fingerprints, cache invalidation, and expert escape-hatch contract | Compiler/API freeze |
| D7 | Final Level 1 model declarations, fragments, phase spelling, displays, and Level 2 constructor names | PottsToolkit API candidate |

Every gate produces an accepted specification update or decision record plus its required evidence.
Implementation convenience MUST NOT decide a gate implicitly.

## Phase Overview

```text
0. Scope and audit
       |
1. Baselines and harnesses
       |
2. Repository structure
       |
3. Reference semantics and conformance foundation
       |
4. Core state and scientific protocols
       |
5. Execution, RNG, workspaces, and backend layer
       |
6. Topology, components, proposals, and trackers
       |
7. Algorithms and normalized MCS
       |
8. Lifecycle, initialization, and persistence
       |
9. SciML integration
       |
10. PottsToolkit typed API and compiler
       |
11. PottsToolkit Level 1 DSL
       |
12. Performance recovery and backend qualification
       |
13. API freeze and full conformance
       |
14. Documentation, tutorials, and satellites
       |
15. Paper reproduction and release qualification
```

Phases are ordered by architectural dependency. Work inside a phase MAY proceed in parallel when
its inputs are stable, but a later phase MUST NOT freeze an interface whose prerequisite gate has
not passed.

## Phase 0: Scope Freeze and Current-Code Audit

### Deliverables

- Freeze additions unrelated to the accepted refactor, conformance, or paper qualification.
- Produce an inventory of packages, exported names, extensions, algorithms, components, trackers,
  lifecycle operations, kernels, synchronization sites, atomics, generated functions, and direct
  low-level dependency calls.
- Classify every current feature as required, deferred, experimental, replaced, or removed.
- Map required current behavior to an accepted specification or an explicit investigation.
- Inventory documentation/tutorial workloads that must later be migrated.
- Record the exact current dependency resolution, Julia version, drivers, devices, OS, compiler
  settings, and repository revision.
- Establish issue or checklist identifiers for phases, decision gates, and conformance evidence.

### Exit gate

- No required implementation area is unowned by a roadmap phase.
- No historical behavior is labeled stable merely because it exists.
- Deferred and removed features are visible and cannot enter paper claims accidentally.

## Phase 1: Correctness and Performance Baselines

### Deliverables

- Preserve the current implementation revision as the comparison baseline without retaining its
  engine in the final source tree.
- Create the pinned `benchmark/` project and machine-readable result schema.
- Define canonical 2D and 3D workloads covering small latency, medium, and publication-scale cases.
- Record initialization, first-MCS, warm steady-state, memory, allocation, synchronization,
  transfer, compilation, and kernel metrics.
- Capture CPU results and hardware-backed results for every locally or remotely available GPU.
- Establish minimal reference models and initial-state checksums.
- Record known scientific defects separately from valid baseline behavior.
- Add repeatable commands that emit provenance and raw measurements without modifying package code.

### Exit gate

- A clean checkout of the baseline revision can reproduce the correctness and performance captures.
- Every performance comparison can distinguish setup, compilation, first MCS, and steady state.
- Invalid historical behavior is not used as a correctness-qualified performance target.

## Phase 2: Repository Structural Migration

### Deliverables

- Move `PottsToolkit` to the repository root while preserving its UUID.
- Remove the `Potts` umbrella package and its re-export behavior.
- Retain `CorePotts`, `MakiePotts`, and `NeuralPotts` as independent packages under `lib/`.
- Enforce the accepted dependency direction and remove unnecessary low-level dependencies from
  `PottsToolkit`.
- Establish package-local test ownership, `integration/`, `benchmark/`, and `paper/` environments.
- Apply the accepted manifest policy and complete compatibility bounds for the frozen dependency
  set.
- Ignore generated documentation, media, data stores, profiler traces, and benchmark results.
- Rewrite CI paths and setup scripts for the new package locations.
- Move files into the accepted responsibility-oriented source directories without redesigning
  their behavior in the same changeset.

### Exit gate

- Each package loads and tests independently from a clean environment.
- Cross-package integration tests run from their own environment.
- CPU and one available real-GPU smoke workload execute through the structurally moved code.
- No released package depends on an upward layer or satellite.
- There is no root `Potts` runtime package and no duplicated test ownership.

## Phase 3: Reference Semantics and Conformance Foundation

### Deliverables

- Build small, clear CPU reference implementations for proposal probabilities, local energy
  changes, acceptance, tracker updates, lifecycle transactions, and normalized attempt accounting.
- Implement canonical state snapshots and logical comparison helpers independent of physical array
  layout.
- Create reusable invariant tests for ownership, IDs, capacity, properties, topology, trackers, and
  transaction atomicity.
- Define statistical test procedures, sample sizes, tolerances, failure reports, and tiering.
- Parameterize conformance cases over numeric policy, algorithm, dimension, and backend.
- Add semantic seed, model fingerprint, initial checksum, backend report, and reproduction command
  to randomized test failures.
- Create the specification-to-test evidence index.

### Exit gate

- A new implementation can be evaluated without inspecting the old engine's internals.
- Reference and conformance layers do not import GPU implementation details.
- All accepted state, time, topology, numerical, and transaction invariants have executable homes,
  even when some optimized implementations remain pending.

## Phase 4: Core State and Scientific Protocols

Execution chunks: [Phase 4 chunk plan](audits/phase-4-chunk-plan.md).

### Deliverables

- Implement stable owner, cell, cell-type, medium-domain, property, component, relation, event, and
  algorithm identifiers.
- Implement immutable schemas, descriptors, requirements, capabilities, and numerical policies.
- Replace current state storage with a logical interface that permits backend-specific physical
  layouts without exposing them publicly.
- Implement fixed capacity, deterministic slot reuse, exact integer state, and initialization
  finalization invariants.
- Establish public state accessors and ordinary Julia multiple-dispatch protocols for components,
  proposals, trackers, events, topology, and algorithms.
- Add conformance helpers for third-party scientific extensions.
- Implement the accepted sequential CPU reference vertical slice over the logical state.
- Compile one public PottsToolkit volume-plus-contact model spelling to that reference path.
- Record remaining legacy execution dependencies without exposing them as the new public contract.

### Exit gate

- CorePotts can construct and inspect a valid CPU state solely through final protocols.
- Stable extension examples pass conformance without depending on PottsToolkit.
- Public types do not encode a particular GPU backend or mutable compilation cache.
- A complete normalized MCS runs through the reference engine with deterministic replay, exact
  attempt accounting, local-delta checks, extinction handling, and invariant validation.
- One PottsToolkit model compiles to and executes through that CorePotts path.
- Representative public calls are type-stable and allocation behavior is characterized; reference
  allocations are recorded without being treated as production performance acceptance.

## Phase 5: Execution, RNG, Workspaces, and Backends

### Required gate

Complete D2 before freezing the RNG engine and distribution interface.

### Deliverables

- Introduce explicit execution plans, persistent state, reusable workspaces, launch policy,
  synchronization policy, transactions, and backend capability reports.
- Replace the obsolete KernelAbstractions dependency/event wrapper with ordering valid for the
  supported KA API.
- Implement semantically addressed counter-based randomness with named streams and contract
  versioning.
- Qualify raw RNG bits and every required distribution on CPU, AMDGPU, and Metal.
- Centralize Adapt-based movement and ensure adapted state contains device-valid values only.
- Remove migrated legacy state types, exports, and direct field contracts as their production
  consumers move to compiled execution state.
- Inventory and specify every atomic operation, overflow rule, memory-ordering need, contention
  behavior, and reproducibility class.
- Move scratch allocation out of steady-state paths and expose required memory in reports.
- Instrument launches, allocations, host synchronization, and transfers.
- Implement explicit failure before launch for unsupported capability/backend combinations.

### Exit gate

- A backend-neutral execution plan can be adapted and launched on CPU and available GPUs.
- RNG known-answer vectors and semantic-address tests pass across claimed backends.
- Qualified steady-state primitives allocate no host or device memory.
- There is no incidental host synchronization in a qualified internal execution path.
- Device-code checks show no invalid dynamic dispatch or host-only values in representative kernels.

## Phase 6: Topology, Components, Proposals, and Trackers

### Required gate

Complete D3 for every required field coupling before freezing its scientific category.

### Deliverables

- Implement compiled Cartesian domain, proposal, energy, surface, connectivity, query, field, and
  conflict relations as distinct roles.
- Implement canonical offsets, periodic realization, weights, owner domains, obstacles, and 2D/3D
  measures.
- Implement required energy, constraint, drive, and kinetic-modifier component categories.
- Implement neighbor-site proposals, forward/reverse proposal probabilities, conventional and
  Metropolis-Hastings acceptance, and zero-temperature behavior.
- Implement derived trackers as transactional cached state with reference recomputation.
- Implement surface, contact, spatial-query, field-sampling, chemotaxis, and focal-point contracts.
- Establish generic implementations first, then isolated measured specialization using
  AcceleratedKernels, KernelIntrinsics, Atomix, or backend extensions where justified.
- Remove migrated legacy penalties, samplers, topology structures, tracker paths, and closures.

### Exit gate

- Local delta calculations match full reference recomputation.
- Forward/reverse proposal and acceptance fixtures pass.
- Tracker caches match recomputation after accepted, rejected, lifecycle, and boundary cases.
- Required 2D/3D cases pass CPU `Float32`/`Float64` and available-GPU `Float32` conformance.
- Surface and field reports expose the exact measure, relation, boundary, and coupling semantics.

## Phase 7: Algorithms and Normalized MCS

### Required gate

Complete D1 for every algorithm intended for implementation or a paper claim.

### Deliverables

- Implement the conventional sequential reference algorithm first.
- Implement separately named exact and approximate parallel families only with explicit guarantee
  profiles.
- Make every public step advance exactly one normalized MCS.
- Make lottery algorithms derive active fraction and internal sweep count from compiled topology and
  expected proposal-budget normalization.
- Update time-dependent quantities between internal sub-rounds at their accepted rate without
  exposing sweeps as public time.
- Implement conflict handling, acceptance, tracker commits, and RNG addressing without scheduling
  races.
- Prove or statistically characterize checkerboard, lottery, and intrinsic behavior before naming
  equilibrium, kinetic, or equivalence guarantees.
- Report internal rounds, attempts, acceptances, conflicts, and guarantee profile.

### Exit gate

- Attempt accounting equals the normalized MCS contract for every algorithm.
- Same-run reproducibility passes at each algorithm's accepted guarantee level.
- Statistical reference batteries pass for every stable algorithm and required workload.
- Approximate algorithms are visibly named and cannot be selected by an unlabeled exact default.
- No algorithm relies on a public `sweeps_per_step` or `active_fraction` control.

## Phase 8: Lifecycle, Initialization, and Persistence

### Required gates

Complete D4 and D5 before freezing persistence or initialization APIs.

### Deliverables

- Implement deterministic event detection, ordering, conflict resolution, validation, and atomic
  commit between internal sub-rounds.
- Implement growth, division, inheritance, transition, death, extinction, retirement, capacity
  failure, fragmentation policy, and optional connectivity constraint.
- Keep lifecycle detection, planning, and commit device-resident where supported, with explicit
  bounded error reporting rather than hidden host polling.
- Implement public coordinate, rasterization, placement, and initialization semantics.
- Implement logical snapshots, exact continuation checkpoints, backend-independent restart where
  promised, schema fingerprints, RNG continuation, and provenance.
- Define and test equivalent logical storage through memory and required HDF5/Zarr extensions.
- Remove HST-specific behavior from the stable path until HST gates are accepted.

### Exit gate

- Lifecycle transaction tests pass under contention, full capacity, invalid plans, fragmentation,
  and all required backends.
- Checkpoint continuation meets the advertised exactness profile.
- Backend-independent restart and storage-equivalence fixtures pass where claimed.
- Initialization is reproducible under its semantic seed and finalizes every required invariant.
- No required lifecycle path introduces incidental per-event host synchronization.

## Phase 9: SciML Integration

### Deliverables

- Implement final model/problem ownership and `PottsProblem` construction.
- Implement `init`, `solve!`, `solve`, integer-MCS `step!`, stopping, return codes, and mutation rules.
- Implement `remake` with correct reuse and invalidation of compilation products and workspaces.
- Implement MCS-boundary saving, observations, callbacks, snapshots, and checkpoints.
- Implement `PottsSolution` indexing, interpolation restrictions, metadata, display, and provenance.
- Implement ensembles with independent semantic seeds, backend selection, output functions, and
  failure handling.
- Ensure qualified device observations remain resident and host observations synchronize only at
  declared boundaries.

### Exit gate

- `solve(prob)` is behaviorally equivalent to `solve!(init(prob))`.
- SciMLBase interface tests and Potts-specific conformance tests pass.
- Saving, callbacks, displays, and ensemble execution introduce no hidden observation points.
- Remake and checkpoint tests prove correct cache, RNG, and workspace invalidation or reuse.

## Phase 10: PottsToolkit Typed API and Compiler

### Required gate

Complete the non-surface-syntax portions of D6 before compiler identities become stable.

### Deliverables

- Implement immutable Level 2 model, domain, cell, medium, property, component, rule, phase, and
  problem builders using ordinary Julia functions and structs.
- Implement namespaced fragments, binding, override rules, provenance, and order-independent
  declarations outside explicit phases.
- Introduce source-located typed semantic IR, host reference evaluation, staged validation, effect
  analysis, dependency analysis, and simultaneous property transactions.
- Lower normalized IR into concrete CorePotts descriptors and callable structs.
- Implement stable semantic fingerprints, compilation reports, source maps, and invalidation.
- Bound specialization and replace unnecessary generated functions with ordinary implementations.
- Establish canonical `show`, inspection, semantic serialization, and diagnostic behavior.
- Remove closure-first and MLStyle-dependent prototype paths once conformance parity is reached.

### Exit gate

- Representative models can be written entirely through the Level 2 API.
- Host reference evaluation and compiled CPU/GPU evaluation agree under the applicable numerical
  contract.
- Invalid models fail before backend launch with source-located, actionable diagnostics.
- Compile time, native code size, allocations, and representative device register use meet budgets.
- CorePotts remains directly usable without PottsToolkit IR.

## Phase 11: PottsToolkit Level 1 DSL

### Required gates

Complete D6 and D7 before declaring the public API candidate.

### Deliverables

- Implement thin, hygienic macros over the complete programmatic builder interface.
- Implement the accepted closed Julia-first rule subset and reject unknown syntax.
- Preserve source locations, semantic RNG identities, query meanings, effects, phases, and
  simultaneous commit behavior through lowering.
- Implement final model declaration, fragment, binding, rule, phase, interpolation, and display
  spelling.
- Generate the stable-component inventory and measure DSL coverage.
- Provide explicit Level 2/3 escape routes for the components not representable at Level 1.
- Exercise representative ordinary, advanced, and extension models before freezing names.

### Exit gate

- At least 95% of stable components have a natural Level 1 spelling.
- Level 1 and equivalent Level 2 models normalize to the same semantic fingerprint.
- Macro expansion contains no engine execution and diagnostics identify user source.
- The complete API candidate has no legacy aliases, constructors, or duplicate modeling paths.

## Phase 12: Performance Recovery and Backend Qualification

### Deliverables

- Profile canonical end-to-end workloads and identify actual launch, synchronization, memory,
  reduction, atomic, layout, register, occupancy, and compilation bottlenecks.
- Qualify AcceleratedKernels primitives and reusable scratch behavior before adoption.
- Isolate KernelIntrinsics use behind generic fallbacks and equivalence tests.
- Tune operation-specific workgroups and layouts rather than impose one universal configuration.
- Add separately optimized CPU implementations where evidence justifies them under the same
  scientific contract.
- Run the full benchmark matrix in separate backend processes with synchronized timing.
- Compare against the frozen baseline and retain raw, versioned results.
- Run semantically matched external comparisons separately from internal regression gates.

### Exit gate

- No representative core workload regresses by more than 5% without accepted written justification.
- The geometric mean across core workloads does not regress.
- Qualified steady-state GPU workloads allocate no memory and introduce no internal host wait.
- Compilation latency, first-MCS latency, memory, and steady-state throughput pass independent gates.
- CPU, AMDGPU, and Metal claims are backed by real hardware results rather than compilation
  alone.

## Phase 13: API Freeze and Full Conformance

### Deliverables

- Review every export, extension point, constructor, report, display, and error type.
- Mark the final stable, experimental, and internal surfaces explicitly.
- Run Aqua, ambiguity checks, representative JET/inference checks, allocation assertions, device
  code inspection, doctest candidates, and clean-environment installation tests.
- Run deterministic, moderate statistical, and large scheduled/pre-release conformance tiers.
- Complete the specification-to-test evidence index and close every required decision gate.
- Remove every remaining legacy path, stale dependency, unqualified claim, and provisional behavior
  from the stable surface.
- Freeze the RNG, IR, checkpoint, model-fingerprint, and result-schema contract versions used by the
  paper release.

### Exit gate

- All accepted core semantics have conformance evidence.
- Every required public extension function is documented by its contract and tested.
- Clean environments can install, load, test, and exercise each package independently.
- No stable API depends on a deferred feature or undocumented historical behavior.
- The project owner explicitly approves the paper API freeze.

After this gate, incompatible API changes require an explicit release decision. Before this gate,
compatibility shims remain unnecessary.

## Phase 14: Documentation, Tutorials, and Satellites

### Deliverables

- Rebuild conceptual documentation in Level 1 through Level 4 progression.
- Manually migrate every tutorial and example to the frozen API, correcting historical scientific
  mistakes rather than translating syntax mechanically.
- Make numerical tutorial assertions runnable in CI and expensive rendering independently runnable.
- Generate API documentation and ensure no exported stable symbol is unexplained.
- Replace tracked generated documentation and large media with reproducible artifact references.
- Migrate MakiePotts against the frozen observation and solution APIs.
- Migrate only the NeuralPotts features that are explicitly in paper scope; leave the remainder
  Experimental without constraining stable packages.

### Exit gate

- Every documentation example and tutorial uses only the final API and passes from a clean setup.
- No generated `docs/build` product is tracked in the source branch.
- MakiePotts does not cause hidden synchronization beyond requested observations.
- Documentation states guarantee profiles, backend support, precision, and algorithm family
  wherever results could otherwise be misinterpreted.

## Phase 15: Paper and Release Qualification

### Deliverables

- Freeze the paper Project and Manifest, experiment configurations, semantic seeds, model
  fingerprints, initial checksums, and analysis programs.
- Re-run publication workloads on recorded CPU and GPU systems.
- Archive raw conformance, benchmark, profiler, environment, and hardware reports.
- Produce paper figures and tables only from archived machine-readable results.
- Re-run clean-install, checkpoint/restart, documentation, tutorial, and backend smoke tests from
  release candidates.
- Audit paper claims against exact versus approximate algorithms and semantically matched external
  comparisons.
- Tag package versions and archive the reproducibility bundle only after every release gate passes.

### Exit gate

- Publication workloads reproduce from a clean environment.
- CPU, AMDGPU, and Metal claims have current real-hardware evidence.
- Paper tables and figures trace to archived raw results and code.
- Documentation, packages, manifests, and paper describe the same frozen API and semantics.
- No legacy engine or DSL path remains.

## Continuous Validation Matrix

The minimum validation run grows with the implementation:

| Change class | Required validation |
| --- | --- |
| Specification or decision | Consistency review, affected evidence mapping, decision record |
| Repository or dependency | Independent load/test, clean instantiate, extension load, smoke workload |
| State or scientific protocol | Unit, invariant, reference comparison, inference check |
| Kernel or execution | CPU plus available GPU, allocation, synchronization, device code, benchmark |
| RNG or algorithm | Known-answer, schedule identity, reproducibility profile, statistical battery |
| Lifecycle or persistence | Transaction faults, capacity, continuation, corruption/failure cases |
| DSL/compiler | Parser/IR round trip, reference evaluator, diagnostics, cache identity, device compile |
| SciML | Interface behavior, saving/callback boundaries, remake, ensemble, failure codes |
| Performance optimization | Full applicable conformance plus before/after raw measurements |
| Documentation/tutorial | Executable assertions, clean environment, generated-output check |

No performance result excuses a conformance failure. No CPU result qualifies a GPU backend.

## Phase Tracking

Each phase is tracked with:

- `Not started`, `In progress`, `Blocked`, or `Complete`
- The governing specification and decision gates
- A short list of concrete deliverables
- The baseline and candidate revision identifiers
- Commands and environments used for validation
- Links to machine-readable conformance and benchmark artifacts
- Known exclusions and their effect on claims

Only one phase SHOULD own a structural concept at a time. A phase MAY have several active work
streams, but the roadmap MUST make their shared interface boundary explicit.

## Initial Critical Path

The first executable sequence is:

1. Complete Phase 0 inventory and paper-scope classification.
2. Create the baseline benchmark/result infrastructure and capture Phase 1 evidence.
3. Perform the Phase 2 repository migration without broad semantic rewrites.
4. Build Phase 3 reference and conformance foundations.
5. Resolve D2 while implementing Phase 4 state and protocols.
6. Begin the new execution layer only after Phase 4 interfaces are executable.

The refactor MUST NOT begin by rewriting the DSL, tuning individual kernels, or reorganizing every
source file at once. Those actions depend on interfaces and evidence established earlier in this
critical path.

## Completion Definition

The roadmap is complete only when every required phase exit gate passes. “Mostly refactored” does
not qualify. Explicitly deferred or experimental features do not block completion when they remain
outside stable APIs and paper claims.

This roadmap is maintained as execution evidence. If implementation reveals that a phase boundary
is wrong, the roadmap MAY be revised, but accepted semantics and scientific guarantees require the
normal specification decision process.
