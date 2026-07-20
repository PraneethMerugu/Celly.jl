# Phase 10 PottsToolkit Typed API and Compiler Completion Audit

Status: Complete; authoritative CPU/Metal/ROCm evidence and exact-head CI passed

Date: 2026-07-20

Authority: [Decision 0026](../../spec/decisions/0026-phase-10-typed-api-and-compiler.md)

## Verdict

The Phase 10 implementation is complete. PottsToolkit now has one immutable Level 2
semantic path, one normalization and lowering path, and one CorePotts/SciML runtime problem. The
historical Toolkit compiler, rule macro prototype, Toolkit GPU kernels, blanket CorePotts re-export,
and compatibility aliases are absent. All five mandatory reference families are ordinary Level 2
compositions.

The implementation/evidence head `a75e376094e3e0c31ee85906481ed7d542eabae4` passed every required
GitHub check, including persisted reference-performance artifacts from real Metal and ROCm runners.
The documentation-only completion-record head then passed the same protected workflows before
closure was accepted. No local result substituted for either CI gate.

## Requirement-to-Evidence Map

| Decision 0026 / roadmap requirement | Direct evidence | Candidate result |
| --- | --- | --- |
| Level 2 is PottsToolkit's sole semantic path | `src/authoring/`, curated `src/PottsToolkit.jl`, `scripts/check_legacy_containment.jl` | Pass |
| Immutable semantic identities, bindings, laws, fragments, models, and persistent edits | `identities.jl`, `bindings.jl`, `models.jl`, `test/test_level2_authoring.jl` | Pass |
| Explicit `Float32` numerical default with no hidden semantic narrowing | numerical policy in `PottsModel`, normalization tests, model reports | Pass |
| Order-independent normalization, validation, provenance, dependencies, reports, and fingerprints | `normalization.jl`, `reports.jl`, declaration-permutation and conflict tests | Pass |
| Staged constructor, model, problem, and backend validation | local constructors, `validate`, `validate_problem`, `backend_report`, diagnostic tests | Pass |
| One runtime `CorePotts.PottsProblem`; no Toolkit wrapper | `lowering.jl`, integration identity checks, matched direct-Core benchmark | Pass |
| Public dispatch-based Level 3 extension; no mandatory registry or central compiler switch | `lib/CorePotts/test/test_phase10_extension_protocol.jl`, direct component lowering | Pass |
| Required first-party families | ordinary/fluctuating volume and boundary, adhesion, prescribed fields, chemotaxis, connectivity, exact elongation, property updates, growth, transition, division, shrink death, immediate death | Pass |
| 2D and 3D declarations and backend preflight | component capability checks, 2D/3D unit tests, reference qualification | Pass |
| Five OpenVT reference categories | `src/reference_models.jl`, public docs, eight smoke configurations including three field profiles and 2D/3D angiogenesis | Pass |
| Reusable small and paper-scalable configurations | explicit constructor keywords plus `smoke` and `full` benchmark profiles | Pass |
| Literature scope, parameter meaning, invariants, and observables | `docs/src/pottstoolkit/reference_models.md` | Pass for model definition; emergent ensemble claims remain Phase 15 |
| Resident CPU/Metal/ROCm execution | qualification matrix, zero undeclared warm transfer/sync, zero warm device allocation | Pass on authoritative CPU, Metal, and ROCm CI |
| Matched direct-Core runtime performance | identical problem type, launch graph, trajectory, transactions, and no runtime wrapper; synchronized Level 2/direct timing | Pass |
| Machine-readable benchmark evidence | schema `2.0.0` reference-suite TOML with provenance, stage timings, MCS/s, actual proposals/s, memory, allocation, launch, transfer, observation, and checkpoint fields | Pass; Metal and ROCm artifacts downloaded and schema/invariants independently verified |
| Curated Julia API and executable current documentation | curated exports, Level 2 overview/API/reference/lifecycle pages, docs build | Pass; full tutorial migration remains Phase 14 |
| Legacy deletion and dependency cleanup | deleted historical Toolkit sources, root runtime dependencies reduced to CorePotts/SciMLBase/SHA | Pass |

## Scientific and GPU Qualification

The eight persisted performance cases are biased migration; linear, half-normal, and exponential
chemotaxis; monolayer growth; differential adhesion; and 2D/3D angiogenesis. Timing smoke fixtures
use stable finite-cell seeds, while smaller one-MCS fixtures retain exact active-cell and lifecycle
expectations.

Every reference measurement enforces:

- one sequential MCS candidate and activated-attempt budget per mutable lattice site;
- `accepted_copies <= realized_proposals <= activated_attempts`;
- unchanged semantic identity through lowering;
- no warm device allocation or host-to-device transfer;
- no warm host synchronization or device-to-host transfer except the explicitly declared
  monolayer lifecycle capacity-failure observation;
- diagnostic report and logical-snapshot work only after the timed region; and
- no finite-cell loss in the timing smoke fixture.

Local CPU and Metal executions pass all eight cases. Metal runs with scalar indexing disabled and
reports zero undeclared warm synchronization, transfer, and device allocation; only the monolayer's
declared lifecycle observation records two synchronizations and two D2H transfers across two timed
MCS. GitHub GPU Validation run `29783107146` passed on the real Metal and ROCm self-hosted runners.
Its uploaded schema `2.0.0` artifacts were downloaded and parsed independently: both contain all
eight workloads and satisfy the fingerprint, proposal-budget, residency, transfer, synchronization,
allocation, and finite-population invariants. Because this is a pull-request workflow, artifact
provenance records the tested merge revision while workflow metadata records head `a75e376`.

## Benchmark and Resource Boundary

Schema `2.0.0` separates model construction, normalization, lowering, problem construction,
backend initialization, first MCS, and synchronized warm MCS. It retains raw samples, MCS/s,
activated-attempt and realized-proposal throughput, accepted-copy throughput, host allocations,
engine launch/transfer/synchronization/allocation deltas, scientific-state, adapted component-array,
and workspace bytes, explicit observation cost, checkpoint capture/restore, exact provenance, and
the matched direct CorePotts comparison.

Kernel compilation and rejection of dynamic device invocation are Phase 10 gates and have real
Metal/ROCm evidence. Numeric register counts are not invented: KernelAbstractions exposes no
portable register-count interface, and Metal occupancy is not a register count. Backend-native
register, spill, occupancy, native-code-size, and tuning budgets remain the explicit Phase 12
profiling gate. This preserves the resource requirement without coupling Level 2 semantics to
fragile backend-private reflection.

## Legacy-Containment Gate

The hard gate currently proves:

- the seven historical Toolkit compiler/event/extension paths remain deleted;
- MLStyle, Reexport, Adapt, and Random are absent from PottsToolkit runtime dependencies;
- no production source restores the deleted Toolkit vocabulary;
- 19 historical Core/satellite files remain SHA-frozen;
- four mixed production signatures and 47 historical consumer signatures remain frozen; and
- protected scientific source contains no fallback edge into the legacy engine.

Historical Core and satellite implementations are quarantined evidence, not a second
PottsToolkit semantic path. Phase 10 does not authorize their reuse. Their owning later migrations
must remove freeze entries explicitly rather than modifying them in place.

## Deliberate Later-Phase Work

The following work does not reopen Phase 10 architecture:

- Phase 11 adds the thin Level 1 DSL and solution-side units over this exact Level 2 model;
- Phase 12 profiles and optimizes end-to-end workloads and freezes quantitative native resource
  and regression budgets;
- Phase 13 freezes exports and performs final release-grade ambiguity/inference audits;
- Phase 14 manually migrates every historical tutorial and satellite; and
- Phase 15 performs literature-parameterized ensembles and paper statistical acceptance tests.

None may introduce another PottsToolkit compiler, runtime problem, semantic RNG, kernel path, or
compatibility layer.

## Closure Evidence

The completion gate required one exact branch head to pass:

1. PottsToolkit, CorePotts, MakiePotts, and NeuralPotts package checks;
2. all integration shards and repository/project-integrity checks;
3. Linux x86_64 and macOS ARM64 CPU lanes on Julia 1.12.6;
4. real Metal and ROCm validation with the schema `2.0.0` artifact uploaded;
5. documentation build;
6. structure and hard legacy-containment scripts; and
7. a clean worktree after publishing the completion update.

All seven gates passed. CI run `29783107208` covers package, integration, integrity, and both CPU
architectures; GPU Validation run `29783107146` covers Metal and ROCm plus artifact publication;
Documentation run `29783107162` covers the executable docs build. CUDA is intentionally outside the
current three-backend contract and is therefore skipped, not counted as a missing Phase 10 result.
