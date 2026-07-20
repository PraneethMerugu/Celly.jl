# Phase 10 PottsToolkit Current-Code and Gap Audit

Status: Historical entry audit; all listed PottsToolkit gaps are resolved by the
[Phase 10 completion candidate](phase-10-completion-audit.md)

Date: 2026-07-20

Authority: [Decision 0026](../../spec/decisions/0026-phase-10-typed-api-and-compiler.md)

## Baseline

- Repository revision: `4a2ee4f1bb053abefae1d861f2ed32ae6b868302`
- Branch: `codex/phase-6-scientific-inner-loop`
- Julia: `1.12.6`
- Root package baseline: 270/270 tests pass in 11.0 seconds with
  `julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'`.
- Phase 9 CorePotts/SciML execution is the replacement target beneath PottsToolkit.
- The Phase 7 SHA/signature containment gate already makes every historical PottsToolkit source
  file and consumer read-only. New replacement files are outside that inventory; migration removes
  entries rather than changing quarantined code in place.

The passing baseline proves only that the historical package still behaves as captured. It does
not satisfy the accepted Phase 10 contract.

## Current Root Source Inventory

| File | Current responsibility | Phase 10 disposition |
| --- | --- | --- |
| `src/PottsToolkit.jl` | Blanket CorePotts re-export, legacy modules, temporary Phase 7 names | Replace with curated Level 2 surface; remove `Reexport` and every temporary engine export |
| `src/models.jl` | `CellType`, dictionary-backed component wrappers, `PottsSystem` | Replace with immutable semantic identities, bindings, laws, components, and `PottsModel`; delete file after migration |
| `src/domains.jl` | Host-mutable `LayoutContext`, task-RNG placement, private `spawn_hypersphere!` calls | Replace with typed declarations lowering to public `AbstractInitialLayout` protocols; delete file after migration |
| `src/problems.jl` | Central `compile_component`, `Any`/dictionary schema merging, private state construction, `LegacyPottsProblem` | Replace with normalization and public CorePotts model/problem lowering; delete file after migration |
| `src/rules/events.jl` | Legacy triggers/events, private kernels/workspaces, private property-update kernel | Replace with typed rule/effect/lifecycle declarations and public lifecycle lowering; delete file after migration |
| `src/rules/macros.jl` | MLStyle AST rewriting into unchecked GPU closures and provisional RNG offsets | Frozen for removal; Phase 10 has no macro authoring path |
| `src/models/test_problems.jl` | Five legacy example problem constructors | Replace with public Level 2 conformance/reference workload builders |

## Current Root Test Inventory

| File | Historical evidence | Replacement evidence required |
| --- | --- | --- |
| `test/test_reference_compilation.jl` | Volume/contact scalar reference bridge | Level 2 normalization, reference evaluation, public CorePotts lowering, and SciML problem construction |
| `test/test_flex_traits.jl` | Mutable legacy volume/adhesion arrays | Typed numerical bindings and first-class mechanical component semantics |
| `test/test_layouts.jl` | Mutable layout rasterization and task RNG | Public deterministic initialization claims, overlap policy, semantic identities, and 2D/3D validation |
| `test/test_dynamic_celldata.jl` | Dynamic legacy `StructArray` fields | Property-schema expansion, lifecycle policy, compiled scientific storage, and absence of undefined fields |
| `test/test_events.jl` | Legacy event sorting and custom closures | Open typed lifecycle protocols, dependency/effect ordering, and source-order independence |
| `test/test_gpu_closures.jl` | `isbits` legacy event wrappers | Complete CPU/Metal/ROCm device path and no host fallback or private kernel use |
| `test/test_rule_macro.jl` | MLStyle expression fallthrough | Removed in Phase 10; typed Level 2 rule nodes and host evaluator replace it |
| `test/test_macros.jl` | Empty placeholder | Removed; Phase 11 owns macro tests |
| `test/runtests.jl` | Historical test aggregation | Replacement package contract and external-extension aggregation |

## Current Architectural Violations

### Public API and ownership

- `@reexport using CorePotts` exposes the entire engine and creates name ambiguity.
- `PottsSystem` duplicates the accepted model concept.
- PottsToolkit extends `CorePotts.PottsProblem` with a legacy system and returns
  `LegacyPottsProblem`, bypassing the Phase 9 problem.
- The model owns an event `check_interval` although schedules belong to individual events.
- Background is encoded as a `CellType` flag instead of a distinct medium declaration.

### Type and composition semantics

- Component mappings use `Dict`, losing source identity and accepting overwrite by insertion.
- Values are silently narrowed to `Float32`, targets are silently rounded to `Int32`, and types are
  split across host declarations and device arrays without one numerical policy.
- Adhesion canonicalization compares process-randomized hashes rather than semantic identities.
- Cell types are stored in mutable vectors, and duplicate names/background declarations are not
  normalized through one semantic namespace.
- `compile_penalties` accumulates `Any[]`, `Dict{Symbol,Any}`, `Set{DataType}`, `isa` branches, and
  mutation-based property merges. Conflicting schemas overwrite silently.
- Direct CorePotts penalties bypass the same validation and provenance as wrapped components.

### GPU and public-boundary violations

- Layouts call `CorePotts.spawn_hypersphere!`, and the problem compiler calls private state,
  tracker, cache, and synchronization constructors.
- Events call private `_kernel_property_update!` and internal spatial-buffer/workspace functions.
- Random layouts use task-local `shuffle!` and `rand`, outside the semantic RNG contract.
- `ResolvedMitosisEvent` documents an internal synchronization and therefore is not a qualified
  zero-sync Level 2 path.
- Late `isbits` testing substitutes for declared effects, capabilities, and backend preflight.

### Rule and lifecycle semantics

- Unknown AST forms fall through unchanged.
- `nothing` means no change, contrary to the explicit `NoChange` contract.
- Every random draw reuses one numeric offset and calls historical RNG helpers.
- Assignment-like syntax emits a closure rather than a typed target and transaction.
- Spatial queries call private getters and encode raw numeric type IDs.
- Event resolution silently drops events whose cell type is absent.
- A single global check interval and category sort replace explicit schedules, priorities,
  dependencies, and conflict policies.

## Dependencies

| Dependency | Current use | Phase 10 decision |
| --- | --- | --- |
| `CorePotts` | Required | Retain, but use curated public Level 3/SciML interfaces only |
| `SciMLBase` | Imported only by legacy events | Retain only if PottsToolkit owns direct `remake`/problem integration methods; otherwise remove |
| `MLStyle` | Legacy rule macro | Remove at legacy deletion |
| `Reexport` | Blanket CorePotts export | Remove at curated-surface switch |
| `KernelAbstractions` | Private event kernels | Remove from PottsToolkit; kernels belong in CorePotts |
| `Adapt` | Legacy event wrappers | Remove unless a final PottsToolkit-owned compiled descriptor genuinely adapts on device |
| `Random` | Task-RNG layouts | Remove; semantic placement lowers through CorePotts RNG contracts |

The target root package should initially need only CorePotts and small host-side standard-library
support for canonical fingerprints or reports. Low-level JuliaGPU libraries remain CorePotts
dependencies.

## Existing CorePotts Foundation

Phase 9 already provides the final runtime ownership:

- `CorePotts.PottsModel` with typed parameterization into `ScientificComponentSet`;
- one `CorePotts.PottsProblem` with integer MCS `tspan`, fixed capacity, seed, and SciML `remake`;
- public Cartesian domains and relations;
- public logical initialization declarations and finalization;
- public property schemas and lifecycle policies;
- volume, contact, boundary, field, chemotaxis, focal, connectivity, mechanical volume/surface,
  algorithm, RNG, persistence, and lifecycle scientific protocols;
- CPU, Metal, and ROCm scientific execution qualification.

PottsToolkit must construct these public values; it must not reproduce their execution machinery.

## CorePotts Gap-Resolution Ledger

1. `ScientificComponentSet` construction validates concrete category supertypes, but hot proposal
   evaluation still contains built-in-specific `_copy_*` method tables. Phase 10 needs a public,
   dispatch-based proposal-evaluation seam that an external component can implement without using a
   private name or modifying a central switch.
2. Host scientific metadata lacks one public aggregate component protocol carrying semantic
   identity, required/provided properties, relations, effects, RNG, dimensions, backend
   capabilities, reference behavior, and fingerprint material.
3. CorePotts reports and structural cache keys need a stable public contribution from external
   components rather than relying on unstable object hashing.
4. The scientific engine has no final elongation/major-axis Hamiltonian or mechanical family.
   Elongation-driven angiogenesis therefore cannot be a runnable Level 2 reference workload while
   the historical HST length penalty remains quarantined. A new scientific component must be
   implemented from the accepted moment/auxiliary protocols; the historical penalty is evidence,
   not the implementation.
5. Typed property-rule transactions need a public compiled lifecycle/effect route sufficient for
   the Phase 10 vertical slice. PottsToolkit may describe rules but cannot launch its own kernels.
6. Public model construction currently requires an already finalized logical state. PottsToolkit
   must provide a clean host lowering from its problem layouts and per-cell bindings through the
   existing public initialization-claim protocol.

These are lower-layer extension-seam completions within Phase 10 scope. They preserve dependency
direction and do not move engine code into PottsToolkit.

Current resolution status:

| Gap | Status | Evidence |
| --- | --- | --- |
| Public proposal evaluation | Implemented locally | public category dispatch plus external energy through `evaluate_copy` |
| Aggregate component metadata | Partially implemented | requirements, provisions, effects, RNG streams, capabilities, and semantic data are public; dimension/backend reporting remains to be completed |
| External semantic fingerprint material | Implemented for the replacement slice | `component_semantic_data` participates in stable Level 2 fingerprints; broad first-party coverage remains a 10.5 gate |
| Elongation/major-axis family | Open | owned by Chunk 10.5; legacy HST length remains quarantined |
| Public compiled property effects | Implemented for the replacement slice | typed custom-property and volume-target updates execute through CorePotts lifecycle kernels on CPU and Metal |
| Public initialization lowering | Implemented for the replacement slice | typed cell/medium layouts lower through public initial claims in 2D and 3D |

## Consumer Inventory and Migration Ownership

- Root package tests and relevant integration tests migrate during Phase 10 before deletion.
- `ext/PottsToolkitMermaidExt.jl` migrates to the public model/problem inspection interface or is
  removed if the extension cannot represent the final API without legacy access.
- `src/models/test_problems.jl` becomes Level 2 reference workload declarations.
- Benchmark legacy baselines remain quarantined evidence until Phase 12, but no active Phase 10
  benchmark may add a legacy consumer.
- MakiePotts and NeuralPotts use public solution/model interfaces. Any remaining direct
  `LegacyPottsProblem` tests are satellite migration work, not a reason to preserve PottsToolkit's
  compiler.
- Full tutorial and documentation migration remains Phase 14. Phase 10 updates only API pages and
  runnable examples needed to prevent the deleted path from being presented as current.
- Historical notebooks and dashboards are evidence, not compatibility requirements; they migrate
  manually after the library and tests stabilize.

## Accepted Replacement Boundary

The final root package must contain only:

- immutable semantic identities, bindings, pairwise laws, fragments, components, rules, and model;
- one normalized typed representation with provenance, diagnostics, fingerprints, and reports;
- public lowering into CorePotts scientific objects, initialization declarations, and the Phase 9
  problem;
- no root-owned GPU kernel, device workspace, task RNG, private CorePotts invocation, blanket
  re-export, legacy alias, MLStyle path, or dictionary/`Any` semantic state.

## Audit Exit Evidence

This audit is complete as an implementation input when the capability ledger in the Phase 10 chunk
plan maps every required legacy behavior and accepted contract item to a replacement chunk, test,
or explicit deferral. Phase 10 completion requires the separate completion audit to prove the
replacement rather than relying on this gap inventory.
