# Phase 0 Current-Code Audit

Status: Complete for the pre-refactor working tree

Audit date: 2026-07-17

Governing roadmap: [Paper-Release Refactor Roadmap](../refactor-roadmap.md)

Companion classification: [Phase 0 Paper-Scope Map](phase-0-paper-scope-map.md)

## Audit Boundary

This audit describes the repository before structural migration or engine replacement. It accounts
for authored source, tests, environments, documentation, examples, generated products, and current
uncommitted work. Existing behavior is recorded as evidence and is not promoted to accepted
semantics by inclusion here.

The audited Git revision is:

```text
commit: b315ef1aecf101663472b1f71c9fe07ecc420575
branch: main
commit date: 2026-07-16T18:05:01-04:00
commit subject: Unify test suite, resolve GPU backend CI configuration, and stabilize testing ecosystem
```

The working tree was dirty at audit time. It contained modifications to package projects, CorePotts
chemotaxis/focal-point/simulator code, PottsToolkit events/problem/system code, and the root test
runner; new specification/design files, three regression tests, and a PottsToolkit manifest were
also present. Phase 1 MUST identify a deliberate baseline revision rather than treating the audited
commit or dirty tree implicitly as the performance baseline.

The local audit runtime was Julia 1.12.6 on Darwin arm64. At audit time, package projects claimed or
intended Julia 1.10 compatibility, so successful loading on the audit runtime was not compatibility
evidence for Julia 1.10. The subsequent execution decision targets Julia 1.12.6 exclusively until
final release-compatibility CI is introduced.

## Repository Inventory

### Size and composition

The Git index contains 160 tracked files. The working tree contains 2,041 files excluding `.git`.
The difference is overwhelmingly generated Documenter output and data under `docs/build/`, plus
untracked specifications and design documents.

| Area | Authored Julia files | Approximate Julia lines | Responsibility |
| --- | ---: | ---: | --- |
| Root `src/` | 1 | 10 | `Potts` re-export umbrella |
| `lib/CorePotts/src/` | 33 | 5,142 | State, topology, engine, components, events, SciML loop |
| `lib/CorePotts/ext/` | 6 | 495 | CUDA, AMDGPU, Metal, HDF5, Zarr, Mermaid integrations |
| `lib/CorePotts/test/` | 19 | 1,479 | Core and scientific tests, without a package runner |
| `lib/PottsToolkit/src/` | 7 | 1,601 | High-level model objects, layouts, events, problem compilation, macro |
| `lib/PottsToolkit/ext/` | 1 | 31 | Mermaid bridge |
| `lib/PottsToolkit/test/` | 6 | 345 | Toolkit tests, without a package runner |
| `lib/MakiePotts/src/` | 1 | 302 | Makie recipe, explorer, recording |
| `lib/NeuralPotts/src/` | 1 | 84 | Lux-based experimental energy and loss hook |
| Root `test/` | 11 | 961 | Mixed integration, scientific, backend, and regression tests |
| `docs/tutorials/` | 17 | 2,312 | Literate tutorial sources |
| Authored examples | 8 | 2,062 | Dashboards and monolayer scripts |

CorePotts is concentrated in several oversized files:

- `Events/Kernels/mitosis_kernels.jl`: 733 lines and 24 kernels
- `Base/penalties/length.jl`: 648 lines and 5 kernels
- `Base/types.jl`: 424 lines spanning RNG, state, cache, algorithms, integrator, and solution
- `Base/penalties/focal_point.jl`: 389 lines and 4 kernels
- `Events/Kernels/property_kernels.jl`: 331 lines and 7 kernels
- `engine.jl`: 295 lines spanning proposal computation and three algorithms
- `simulator.jl`: 264 lines spanning SciML, events, saving, and observation

File size alone is not a defect, but these files mix scientific meaning, storage, launch policy,
randomness, and backend mechanics. They are high-risk baseline and decomposition targets.

### Authored and generated products

- `docs/build/` accounts for approximately 1,840 generated working-tree files and is already ignored.
- Seventeen Literate Julia tutorial sources are tracked.
- Most generated tutorial Markdown and notebooks are ignored; three historical generated Markdown
  pages remain tracked.
- Tracked large products include a roughly 10 MB notebook video, three tutorial videos, multiple
  notebooks, and manifests for docs/examples/notebooks/dashboards.
- `.DS_Store` files exist in the working tree and examples.
- The root file `paper.pdf` is not a PDF. It is an 831,868-byte ScienceDirect HTML error/access page
  saved with a `.pdf` suffix. It contains no auditable manuscript and MUST be removed or replaced by
  an intentional paper source/artifact.

## Package Inventory

### Root `Potts`

The root package re-exports CorePotts, PottsToolkit, MakiePotts, and NeuralPotts. It has no scientific
or execution behavior of its own. Installing it makes optional visualization and experimental neural
work part of the ordinary dependency surface.

Disposition: remove during Phase 2. It is not a compatibility target.

### CorePotts

CorePotts currently owns nearly every layer:

- Counter-like PCG hashing and distribution helpers
- Cell/grid state, free-list capacity, dynamic StructArray cell data
- Topology types, offsets, coordinate helpers, periodic/no-flux behavior, coloring
- Algorithms, algorithm configuration, caches, and kernel launches
- Proposal, energy, acceptance, and tracker transactions
- Volume, surface, adhesion, chemotaxis, connectivity, length, focal-point, HST, and neural hooks
- Lifecycle events, property rules, mitosis kernels, death processing, and inheritance
- SciML problem, integrator, solution, callbacks, saving, and output backends
- Training helpers and Mermaid coupling

This scope is broader than the accepted CorePotts responsibility because it also exposes provisional
DSL builders, output implementation details, training helpers, and several implementation-specific
kernel controls.

CorePotts loads successfully on the local Julia 1.12.6 environment. It exposes 94 public names.
Four exported bindings are undefined after loading:

- `MitosisCallback`
- `DeathCallback`
- `LinearGrowthCallback`
- `required_fields`

`VolumeFlexTracker` and `SurfaceAreaFlexTracker` are aliases of their non-flex tracker types rather
than distinct semantics. Public `dispatch_kernel!`, `PottsCache`, `DEFAULT_BLOCK_SIZE`, rule builders,
and concrete storage/output machinery expose implementation details that the accepted Level 3/4
boundary must reconsider.

### PottsToolkit

PottsToolkit re-exports all of CorePotts and adds high-level objects. Consequently, it exposes 123
names and does not presently provide a curated high-level namespace.

Its current responsibilities are:

- Symbolic `CellType`
- Dictionary-backed volume, HST volume, surface, length, chemotaxis, and adhesion components
- `PottsSystem` tuple assembly
- Mutable CPU `LayoutContext` plus random, sphere, scattered-sphere, rectangle, and composite layouts
- Compilation of high-level components into concrete CorePotts penalty/tracker/storage objects
- Allocation and initialization of StructArray cell state
- Trigger/action/event wrappers and direct CorePotts event protocol implementations
- A single MLStyle-based `@rule` AST rewrite macro
- Production `TestProblems` constructors

PottsToolkit currently imports and calls low-level CorePotts internals, including kernel dispatch,
private property kernels, workspace construction, offsets, raw RNG helpers, storage synchronization,
and concrete tracker/penalty types. It also defines two KernelAbstractions kernels directly. This is
the central package-boundary violation to eliminate in Phases 2, 10, and 11.

High-level constructors force many values to `Float32`, `Int32`, or `UInt8`; use runtime dictionaries
and `Any`-typed staging collections; depend on global Random state for layouts; and use hashes to
canonicalize adhesion pairs. These behaviors conflict with accepted numerical, reproducibility,
declaration, and diagnostic contracts and are replacement targets.

### MakiePotts

MakiePotts contains one 302-line module providing a recipe, an interactive explorer, and recording.
It reads physical state fields directly and constructs host images with scalar loops. Interactive
recomputation reaches directly into `PottsProblem`, deep-copies state, and reconstructs problems.

Disposition: retain as an optional satellite, then migrate after the frozen observation/solution
interface. It MUST NOT influence CorePotts storage or introduce hidden device synchronization.

### NeuralPotts

NeuralPotts contains an experimental Lux-based local energy, a host global-energy implementation,
a thread-indexed global mutable feature cache, and an unimplemented AD loss hook. It assumes an
eight-neighbor patch and directly accesses topology/grid internals.

Disposition: keep experimental and outside paper-release blockers unless explicitly added to paper
scope. Remove neural training dependencies and exports from the primary package graph in Phase 2.

## Current Scientific Feature Inventory

### State and identity

Current state uses an owner grid, a StructArray of per-cell fields, `N_cells`, a free-list, and a
free-list count. Owner/cell/type identity is represented through several raw integer widths rather
than stable semantic identifier types. Cell type zero and owner zero commonly represent medium.
Capacity is the length of cell-data columns.

Strengths worth preserving as evidence:

- Fixed-capacity storage is already present.
- StructArray storage is compatible with a structure-of-arrays device direction.
- Free-list reuse and lifecycle tests exist.
- Required fields can be discovered from components.

Replacement requirements:

- Stable identifier types and schema descriptors
- One explicit medium-domain model
- Logical state access independent of physical columns
- Deterministic validated slot reuse
- Typed numerical policy rather than constructor-local hard-coding
- Explicit persistent versus scratch storage and reports

### Topology

Current types cover 2D/3D Von Neumann and Moore stencils, periodic and no-flux variants, plus extended
radius variants. Topology currently combines domain boundaries, proposal neighbors, energy neighbors,
surface neighbors, connectivity, conflict coloring, and query behavior. Extended offsets use two
generated functions and runtime array construction during generation.

The Cartesian capability is required, but the unified topology abstraction is replaced by compiled
role-specific relations. Hexagonal and graph families are not implemented and remain deferred.

### Components

| Current component | Current implementation | Paper disposition |
| --- | --- | --- |
| Volume | `VolumePenalty`, rigid/flex | Required; reimplement under component law |
| HST volume | `HSTVolumePenalty` | Deferred HST family |
| Surface | Only `HSTSurfaceAreaPenalty` behind ordinary-sounding Toolkit spelling | Required concept, but current HST implementation cannot define it |
| Adhesion/contact | `AdhesionPenalty`, optional isotropic and flex behavior | Required; validate measures and pair identity |
| Chemotaxis | `ChemotaxisPenalty`, saturation | Required; resolve D3 conservative/drive classification |
| Connectivity | 2D Moore-only `ConnectivityConstraint` | Required optional constraint; replace topology restriction with capabilities |
| Focal point | Conventional spring plus HST form | Conventional required; HST deferred |
| Length/elongation | HST-only `HSTLengthPenalty` exposed as `LengthComponent` | Required concept only if paper workload needs it; current semantic spelling is invalid |
| Neural energy | `LocalNeuralPenalty` plus NeuralPotts methods | Experimental satellite |

Current `AbstractPenalty` inheritance mixes Hamiltonian energy terms, constraints, nonconservative
drives, and experimental models. Phase 6 replaces this taxonomy.

### Proposals and acceptance

The engine chooses a neighbor direction through a sampler and computes local energy/tracker deltas.
`MetropolisSampler` supports a style hook, but the public proposal probability and reverse support
are not first-class. Current acceptance receives a ratio argument, yet algorithm and proposal
contracts are intertwined.

Required destination: separately modeled proposal and acceptance laws, including conventional CPM
and Metropolis-Hastings behavior, explicit forward/reverse support, zero-temperature semantics, and
reference fixtures.

### Trackers

Volume and surface trackers compute proposed deltas and update global state using direct operations,
Atomix atomics, or subgroup reductions. Initialization and local recomputation paths exist.

Evidence to preserve:

- Tracker drift tests
- Mass-conservation tests
- Local-update kernels and full recomputation behavior
- Intrinsic subgroup experiments

Replacement requirements:

- Transactional snapshot/commit contract
- Reference recomputation for every derived cache
- Atomic/reduction reproducibility classification
- Explicit surface measure rather than dissimilar-neighbor count as an implicit universal meaning

### Algorithms and time

Current algorithm names are aliases over one `MetropolisAlgorithm` with strategy type parameters:

| Name | Current behavior | Audit result |
| --- | --- | --- |
| `SequentialMetropolis` | CPU loop; `round(N * active_fraction)` randomly selected proposals using Xoshiro | Required reference family, but time/RNG semantics are replaced |
| `ParallelMetropolis` | PCG-ticket local lottery with neighbor exclusion | Required lottery candidate; D1 must qualify kinetics and normalization |
| `CheckerboardMetropolis` | Colored passes with optional activation | Candidate stable family; exact/equilibrium claims are unproven pending D1 |
| `IntrinsicCheckerboardMetropolis` | Checkerboard plus KernelIntrinsics subgroup reduction | Experimental optimization until equivalence and backend evidence pass D1 |

All algorithms expose `active_fraction` and `sweeps_per_step`. `step!` performs
`sweeps_per_step` internal calls and increments public time once, so the current default proposal
budget is controlled by the product of two unrelated public knobs. This directly violates the
accepted normalized-MCS contract.

Current docstrings claim checkerboard mathematical equivalence and intrinsic detailed balance
without the required derivation/statistical evidence. Those claims MUST be removed from stable
documentation until D1 passes.

### Lifecycle and rules

Current lifecycle functionality includes volume/age/probability/custom triggers, mitosis,
apoptosis-through-target-volume, type transition, death ID reclamation, orientations, inheritance
rules, and property updates. Mitosis uses a large preallocated workspace and a multi-kernel pipeline.

Useful evidence exists for full capacity, free-list reuse, inheritance, 2D/3D orientation, GPU death,
and property updates. However, event ordering is tuple order, conflict policy is not a complete
transaction model, deletion is coupled to `target_volume <= 0`, and parts of the pipeline return
`nothing` after internal processing rather than a composable completion dependency.

The current `@rule` macro rewrites recognized expressions but passes unknown syntax through. It
creates a closure over `cell_data`, `cell_id`, `ctx`, and `current_val`, assigns the same RNG offset
to repeated random operations, and relies on an `isbits` runtime rejection inside `step!`. It has no
typed IR, source map, effect analysis, semantic fingerprint, or independent reference evaluator.

Disposition: preserve scientific fixtures, replace the event/rule architecture completely.

### Initialization and layouts

Initialization builds a mutable CPU grid through layout objects, discovers required fields, creates
StructArray columns, and later adapts state. Random layouts and scattered spheres consume Julia's
global RNG. Rectangle layout creates one new cell per site, while sphere layout creates one owner
over many sites; this semantic difference is not made prominent by a shared layout vocabulary.

Coordinate indexing, overlap behavior, periodic placement, random sampling, capacity failure, and
seed ownership require D5 before the replacement API freezes.

### SciML and persistence

The current package subtypes SciMLBase problem, algorithm, and timeseries-solution abstractions and
implements `init`, `step!`, `solve!`, `solve`, callbacks, saving, and basic indexing. This is useful
prototype evidence but not yet the accepted contract:

- Public time depends on legacy sweep controls.
- `terminate!` changes `t_end` but ignores its `retcode` argument.
- `PottsSolution` fakes several properties through `getproperty`.
- `remake`, observations, ensembles, checkpoint semantics, and provenance are incomplete.
- Saving snapshots physical state but does not implement exact continuation.
- Host callbacks and saving synchronize explicitly at MCS boundaries, which is legitimate only when
  declared by the final observation contract.

Memory, HDF5, and Zarr output backends exist. HDF5/Zarr adapt complete state to the host. The Zarr
initializer recursively deletes an existing user-provided path without an explicit overwrite
contract. HDF5 resource closing and failure behavior are not defined. These APIs cannot be retained
without D4 and destructive-action safeguards.

## Randomness Audit

Current randomness is split across unrelated mechanisms:

- A custom `pcg_hash` used as a stateless hash in parallel proposals and events
- `Random.Xoshiro` created per sequential proposal
- Global default RNG used by PottsToolkit layouts
- Box-Muller-like `randn_pcg`
- Normal approximation or iterative multiplication for Poisson
- Manually chosen numeric offsets for HST, mitosis, and rule operations
- Separate `step_counter` and `noise_counter`

There is no public master seed in the principal constructors, no RNG contract version, no named
semantic streams, no ensemble seed derivation, and no checkpoint continuation contract. Repeated DSL
random expressions can reuse the same `(cell, step, offset)` address. D2 and Phase 5 replace all of
this; current sequences are not compatibility targets.

## GPU and Performance Audit

### Kernel inventory

There are 48 KernelAbstractions kernel definitions across CorePotts and PottsToolkit:

- 24 mitosis kernels
- 7 property/death/HST kernels
- 5 length kernels
- 4 focal-point kernels
- 3 generic engine kernels
- 2 intrinsic engine kernels
- 2 tracker kernels
- 2 PottsToolkit event kernels
- 1 unified event-trigger kernel
- 1 initialization/synchronization kernel

### Atomics

Static inspection finds at least 44 Atomix atomic sites:

- 18 in length accumulation
- 8 in mitosis allocation/accumulation
- 6 in property/death/spatial operations
- 6 in trackers
- 6 in focal-point accumulation

No centralized atomic contract currently records operation, type, returned-value assumption,
ordering, overflow, contention, or reproducibility. Comments disagree with the need for formal
verification. Every site is a Phase 5/6/8 audit target.

### Host synchronization

Production code contains at least 18 explicit synchronization/wait sites:

- 6 in focal point
- 4 in length
- 4 in property/death/HST kernels
- 3 in the SciML simulator
- 1 in sequential engine handoff

The SciML saving/callback sites are potential declared observation boundaries. Component and property
pipeline waits are presumptive engineering debt. The current mitosis path also contains comments
that contradict whether internal synchronization remains. Phase 1 instrumentation must measure
actual waits and transfers, not only these static calls.

### Launch and dependency model

`dispatch_kernel!` conditionally passes a `dependencies` keyword and backend extensions merely set
`requires_explicit_dependencies(::Backend) = false`. Current KernelAbstractions 0.9.42 removed the
old event model assumed by parts of this abstraction. The intrinsic engine directly constructs and
passes KernelAbstractions events, creating a second launch path.

Disposition: replace in Phase 5 and prove ordering independently on each backend.

### AcceleratedKernels, KernelIntrinsics, and layout

- AcceleratedKernels is used for a spatial-edge sort immediately followed by host synchronization.
- KernelIntrinsics is used only by the intrinsic checkerboard/tracker reduction and calls the private
  `_warpsize` API elsewhere in tracker code.
- StructArrays is used for cell data, but layout choice has not been justified with access-pattern,
  register, or memory-traffic evidence.
- StaticArrays is a CorePotts dependency but current principal kernel types and use require a focused
  inventory during Phase 1 dependency qualification.
- Adapt reconstruction calls `Base.typename(...).wrapper`, a reflective private implementation
  technique that must be removed.

## Metaprogramming Audit

The repository has one public macro and four generated functions:

- PottsToolkit `@rule`
- Generated extended Von Neumann offsets
- Generated extended Moore offsets
- Generated reduce-rule evaluation
- Generated map-rule evaluation

Tuple recursion and type parameters also perform substantial implicit staging. Current issues are:

- The macro contains semantic lowering instead of thin parsing.
- Unknown AST forms pass through instead of failing closed.
- Source locations and semantic identities are lost.
- Generated functions have no documented necessity or code-size budget.
- Runtime dictionaries/`Any` staging and closure capture precede type specialization.
- There is no normalized typed IR, reference evaluator, effect analysis, cache fingerprint, or
  invalidation model.

All current metaprogramming is replace/review scope under Phases 10 and 11. Ordinary functions are
the default replacement.

## Dependency and Environment Audit

### CorePotts

CorePotts directly depends on AcceleratedKernels, Adapt, ArgCheck, Atomix, ChainRulesCore,
ConstructionBase, Functors, KernelAbstractions, KernelIntrinsics, Mermaid, Random, SciMLBase,
StaticArrays, Statistics, StructArrays, and LinearAlgebra.

Compat bounds are missing for most direct dependencies, including the central JuliaGPU stack.
Mermaid is a direct dependency even though its implementation is in an extension. ChainRules and
training responsibilities inflate the engine. The frozen Phase 1 environment currently observed
through PottsToolkit resolves at least AcceleratedKernels 0.4.3, Adapt 4.7.0, Atomix 1.1.3,
KernelAbstractions 0.9.42, and KernelIntrinsics 0.1.8.

### PottsToolkit

PottsToolkit directly depends on AcceleratedKernels, Adapt, CommonSolve, CorePotts,
KernelAbstractions, MLStyle, Mermaid, Random, Reexport, SciMLBase, and StructArrays. Several are used
only because Toolkit currently performs engine, kernel, storage, or prototype-macro work. Phase 2
must reduce this set after confirming actual final responsibilities.

### Satellites and applications

MakiePotts and NeuralPotts lack comprehensive compat bounds. Test is listed as a runtime dependency
in both satellite project files. Docs load every package and expensive integration. Examples,
dashboards, and notebooks maintain overlapping projects and manifests. No dedicated benchmark or
paper application project exists.

## Test and CI Audit

### Test ownership

No package under `lib/` has `test/runtests.jl`. The root runner reaches into CorePotts test files,
but does not invoke PottsToolkit or NeuralPotts package tests. MakiePotts has no package test suite.

The root runner also leaves these tracked tests disconnected:

- `lib/CorePotts/test/test_mass_conservation.jl`
- `lib/CorePotts/test/test_sciml_saving.jl`
- All six `lib/PottsToolkit/test/*.jl` files
- `lib/NeuralPotts/test/test_lux.jl`
- `test/PottsToolkit/test_dynamic_celldata.jl`

At audit time, three new untracked regression files were also not included by the root runner:

- `test/test_chemotaxis_fragmentation.jl`
- `test/test_focal_point_3d_fix.jl`
- `test/test_isbits_blocker.jl`

Current tests mix unit, integration, scientific-statistical, backend, out-of-core, Mermaid, Makie,
and regression concerns in one process. Many assert physical fields directly. There is no reusable
backend-neutral conformance suite, reference implementation layer, seed/provenance failure report,
or performance regression suite.

### CI

CI defines CPU, Metal, CUDA, and AMDGPU jobs using the same root suite. GPU jobs add packages into the
root environment at runtime. Julia is specified as unconstrained version `1`, so CI does not prove
the Julia 1.10 floor claimed at audit time. CUDA installs toolkit 12.3. There is no version matrix, dependency
upgrade test, coverage, Aqua, JET/inference, allocation, device-code, statistical tier, or benchmark
job.

The format job installs JuliaFormatter globally and runs it in mutation mode before checking Git
status. The formatter is also an unnecessary root runtime dependency. Documentation runs all
tutorial preprocessing but uses `execute = false`, `warnonly = true`, and unlimited size thresholds;
therefore it does not establish tutorial execution or documentation-warning conformance.

## Documentation and Example Audit

The documentation is broad and useful as a workload inventory, but it describes provisional APIs
and unqualified claims. The seventeen tutorial sources cover:

- First simulation and cell sorting
- Chemotaxis/directed migration
- Epithelial sheets and 3D spheroids
- CPU/GPU algorithm comparison
- Growth, mitosis, death, and homeostasis
- HST, elongation, and polarity
- HDF5/Zarr saving
- Parameter sweeps and boundary conditions
- Interactive exploration, the current DSL, visualization, and neural EBM

Paper-required tutorials become manual Phase 14 migrations and workload candidates. HST and neural
tutorials remain experimental unless scope changes. Existing generated Markdown, videos, notebooks,
and dashboards are not API authority.

The dashboard/notebook scripts contain valuable medium-scale workloads but also direct engine
access, local backend assumptions, and duplicated model code. Phase 1 may extract workload shapes
and metrics; it MUST NOT copy their APIs into the new design.

## Priority Findings

### P0: must be addressed before or during baseline/structure phases

1. Choose a reproducible baseline revision from the dirty working tree.
2. Create a real benchmark environment; no benchmark suite currently exists.
3. Wire independent package tests and identify disconnected scientific fixtures.
4. Remove the root umbrella and prevent satellites from contaminating primary dependencies.
5. Replace the obsolete/split KernelAbstractions launch dependency model before trusting zero-sync
   claims.
6. Resolve normalized MCS accounting; current public defaults encode the known sweep/fraction defect.
7. Treat current checkerboard/intrinsic exactness claims as unqualified until D1.
8. Replace or remove the invalid `paper.pdf` HTML artifact.

### P1: must be measured and replaced in engine phases

1. Eighteen explicit production synchronization/wait sites and additional implicit transfers.
2. At least 44 atomic sites without operation/reproducibility contracts.
3. Fragmented PCG/Xoshiro/global RNG with reused semantic offsets and no public seed.
4. PottsToolkit direct kernel/storage/internal CorePotts coupling.
5. HST implementations exposed through ordinary surface/length names.
6. Undefined exports and excessive re-exported implementation surface.
7. Reflective `Base.typename.wrapper`, private KernelIntrinsics calls, `Any` staging, hard-coded
   numeric types, and unbounded closure specialization.
8. Destructive Zarr overwrite behavior and undefined HDF5 resource/checkpoint semantics.

### P2: must be completed before API freeze

1. Missing compat bounds and unconstrained CI Julia versions.
2. Incomplete SciML remake, ensemble, observation, checkpoint, provenance, and return-code behavior.
3. No semantic reports, fingerprints, source diagnostics, or typed compiler IR.
4. No package hygiene, ambiguity, inference, device-code, or allocation gates.
5. Generated assets and duplicated application environments in the repository.
6. Makie direct physical-state assumptions and NeuralPotts global mutable cache.

## Phase 0 Exit Assessment

Phase 0 passes for roadmap execution because:

- Every package, source subsystem, extension, test area, documentation/tutorial group, environment,
  and generated-product group has an owner and disposition.
- Required, deferred, experimental, replaced, and removed features are classified in the companion
  scope map.
- Current behavior is explicitly separated from accepted semantics.
- High-risk correctness and performance paths are identified for Phase 1 measurement.
- Unresolved decisions are attached to the phase they block rather than allowed to arise implicitly.

Phase 1 is now unblocked, but it MUST begin by selecting the exact baseline tree and preserving its
environment before measurements are interpreted.

## Authored File Responsibility Index

### Root and repository configuration

- `src/Potts.jl`: umbrella re-export module; remove in Phase 2.
- `Project.toml`: umbrella runtime and mixed integration-test environment; replace with PottsToolkit.
- `.github/workflows/tests.yml`: combined CPU/GPU root-suite CI; replace with package/conformance jobs.
- `.github/workflows/docs.yml`: unified docs build; retain concept, revise environments and gates.
- `.github/workflows/FormatCheck.yml`: formatter check; revise to pinned repository tooling.
- `.JuliaFormatter.toml`: retain as repository style input after review.
- `.gitignore`, `docs/.gitignore`, `lib/CorePotts/.gitignore`: consolidate generated-product policy.
- `paper.pdf`: invalid HTML artifact; remove or replace.

### CorePotts source

- `CorePotts.jl`: module assembly and broad export surface.
- `Base/types.jl`: RNG, state, cache, algorithm, integrator, solution; split across Phases 4, 5, 7, 9.
- `Base/topology.jl`: combined spatial roles; replace in Phase 6.
- `Base/samplers.jl`: acceptance prototype; replace in Phase 6.
- `Base/dispatch.jl`: obsolete launch/dependency wrapper; replace in Phase 5.
- `Base/trackers.jl`: volume/surface transactions and subgroup/atomic paths; replace in Phase 6.
- `Base/penalties.jl`: mixed component taxonomy and auxiliary HST update; replace in Phase 6.
- `Base/penalties/volume.jl`: required conventional volume plus deferred HST.
- `Base/penalties/surface_area.jl`: deferred HST surface, not a conventional surface implementation.
- `Base/penalties/adhesion.jl`: required contact energy plus AD prototype.
- `Base/penalties/chemotaxis.jl`: required field coupling pending D3.
- `Base/penalties/connectivity.jl`: required optional 2D connectivity constraint.
- `Base/penalties/focal_point.jl`: required conventional spring plus deferred HST and synchronization debt.
- `Base/penalties/length.jl`: deferred HST elongation and heavy atomic/synchronization debt.
- `Base/penalties/neural.jl`: experimental extension hook.
- `Base/training.jl`: experimental training helper; move out of core stable surface.
- `Base/backends.jl`: memory plus output descriptors; replace with observation/persistence contracts.
- `Tools/initialization.jl`: cell-data allocation and metric synchronization; replace in Phases 4/8.
- `Events/base.jl`: prototype rule categories.
- `Events/builder.jl`: closure-first rule/event builders; replace in Phase 10.
- `Events/closures.jl`: compiled closure wrapper; replace in Phase 10.
- `Events/core_events.jl`: property event and orientation prototypes; replace in Phase 8.
- `Events/spatial_rules.jl`: contact/count/sum descriptors; replace through accepted query IR.
- `Events/Nodes/properties.jl`: inheritance descriptors; retain meanings, replace architecture.
- `Events/Nodes/mapreduce.jl`, `Events/Nodes/spatial.jl`: empty placeholders; remove.
- `Events/Kernels/evaluation.jl`: random/query/update evaluation; replace in Phases 5/10.
- `Events/Kernels/property_kernels.jl`: property/spatial/death/HST kernels; split by responsibility.
- `Events/Kernels/mitosis_kernels.jl`: lifecycle pipeline; baseline and replace in Phase 8.
- `engine.jl`: proposal/acceptance plus sequential/lottery/checkerboard; replace in Phases 6/7.
- `engine_intrinsics.jl`: intrinsic experimental specialization; quarantine pending D1 evidence.
- `simulator.jl`: SciML loop and event orchestration; replace in Phases 8/9.

### CorePotts extensions

- CUDA, AMDGPU, and Metal extensions currently only alter launch-dependency behavior; replace with
  capability/preflight specializations.
- HDF5 and Zarr extensions implement snapshots, not accepted checkpoints; rebuild after D4.
- Mermaid extension exposes direct state/parameter mutation and host transfer; defer until stable
  observation/coupling interfaces exist.

### PottsToolkit source

- `PottsToolkit.jl`: blanket CorePotts re-export; replace with curated primary API.
- `system.jl`: high-level cells/components/system prototype; replace with immutable typed Level 2 API.
- `layouts.jl`: CPU mutable/random layout prototype; rebuild after D5.
- `events.jl`: user events plus direct engine kernels/internal extensions; replace in Phases 8/10.
- `problem.jl`: runtime dictionary compilation and state construction; replace in Phase 10.
- `macros.jl`: open-ended AST rewrite macro; replace with thin closed parser in Phase 11.
- `TestProblems.jl`: move canonical workloads to test/benchmark support, not production API.
- Mermaid extension: rebuild only over stable PottsToolkit/CorePotts coupling protocol.

### Satellites, tests, docs, and examples

- `lib/MakiePotts/src/MakiePotts.jl`: retain optional satellite, migrate in Phase 14.
- `lib/NeuralPotts/src/NeuralPotts.jl`: experimental satellite; no core-release guarantee.
- All root and package test files are scientific/engineering evidence to classify into package unit,
  integration, reference, statistical, backend, persistence, or satellite suites in Phases 2/3.
- All seventeen `docs/tutorials/*.jl` files are migration/workload inventory; none defines API.
- Dashboard and notebook scripts are candidate workload evidence; none defines package semantics.
