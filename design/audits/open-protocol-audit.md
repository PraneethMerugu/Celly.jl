# Open-Protocol Audit

Date: 2026-07-19

Status: Current-code and specification audit; governing recommendations accepted

## Scope

This audit compares the accepted semantic and architectural promises with the current CorePotts and
PottsToolkit implementation. It focuses on whether new scientific families can be added through
ordinary Julia methods while preserving GPU compilation, performance, reproducibility, and
conformance.

The audit applies the proposed
[Open Protocol and Extensibility Standard](../open-protocol-and-extensibility-standard.md). It covers
active Phase 3--7 code, Phase 8 requirements, the quarantined historical engine, and the provisional
PottsToolkit compiler. A closed implementation inside quarantined code is still recorded because it
must not be copied into the replacement architecture.

## Executive Finding

The semantic architecture is substantially more extensible than the current implementation. The
specifications already favor ordinary immutable Julia values, multiple dispatch, typed effects,
capabilities, and package extensions. The principal risk is **first-implementation closure**: a
protocol is described openly, but the first built-ins are then encoded as an enum, method-signature
`Union`, `isa` ladder, or central compiler switch.

Current assessment:

| Layer | Assessment | Meaning |
| --- | ---: | --- |
| Accepted semantic direction | Strong | Most scientific families are described as protocols or explicitly allow additional families. |
| Core scientific component interface | Strong but incomplete | Energy, drive, constraint, tracker, event, topology, and algorithm validation use public methods; several consumers still enumerate concrete built-ins. |
| Compiled execution architecture | Promising | Concrete immutable state, workspaces, KernelAbstractions, and package extensions provide the right substrate. |
| Lifecycle and initialization readiness | Semantic protocols accepted; implementation pending | Decisions 0018--0021 resolve the P0 semantic boundaries and minimality scope; current consumers remain closed or duplicated until Phase 8 replaces them. |
| PottsToolkit extensibility | Weak, intentionally provisional | The current compiler uses `Any`, dictionaries, broad re-export, `isa` lowering, and centralized built-in knowledge. Phase 10 owns replacement. |
| Downstream extension evidence | Insufficient | Interface unit tests exist, but there is no complete external-style extension fixture crossing authoring, reference, compiled CPU, and GPU execution. |

The P0 semantic findings are resolved. Phase 8 MUST implement their minimal reference, downstream,
and compiled consumers before freezing interface names. The project does not need a universal plugin
framework. It needs small public Julia protocols, concrete lowering, and conformance fixtures.

## Phase 8 resolution note

The Phase 8 candidate resolves the lifecycle, initialization, property-policy, derived-observable,
and persistence findings below on the scientific path. A combined downstream fixture defines a
schedule, trigger, effect, division geometry, property policy, initialization layout, and maintained
derived observable without editing CorePotts; it compiles and executes in 2D/3D on CPU and Metal and
is part of the required ROCm matrix. Historical and PottsToolkit findings retain their original
classification until their owning migration phases.

## Phase 9 resolution note

The Phase 9 candidate resolves every P1 item on the replacement path:

- algorithms initialize and execute through open dispatch, with an external-style ordered
  algorithm fixture and no central concrete algorithm union;
- algorithms select proposal and acceptance laws through public methods;
- backend providers and requirements dispatch on backend and typed capability values;
- downstream RNG identities lower through a collision-checked 128-bit namespace above the closed
  v1 address ABI;
- the Phase 8 compiled-component and derived-observable fixture remains the combined lowering proof;
  and
- historical state, sampler, cache, and algorithm names are no longer exported by CorePotts.
  Backend storage and workspace values that remain exported are deliberate Level 4 execution
  interfaces under `spec/corepotts-public-interface-semantics.md`, not Level 3 scientific state.

PottsToolkit explicitly imports and re-exports its frozen historical compatibility surface until
Phase 10 replaces the broad re-export and compiler. The hard legacy-containment checker now treats
the evacuated `LegacyPotts*` names as quarantined vocabulary and inventories package extensions.

## Classification Vocabulary

- **Intentionally closed** — exhaustiveness is part of a versioned semantic or internal contract.
- **Open and healthy** — a downstream implementation can be added through documented dispatch.
- **Open in specification, closed in implementation** — semantic intent is correct but a consumer
  requires central edits.
- **Accidentally closed in specification** — wording makes the first built-ins appear exhaustive.
- **Provisional or duplicated** — a replacement protocol exists alongside legacy behavior and has
  not yet become the sole path.
- **Underdefined** — openness is promised without a sufficient method, capability, or conformance
  contract.

## Protocol Matrix

| Protocol surface | Intended classification | Current evidence | Finding | Required action |
| --- | --- | --- | --- | --- |
| Scientific category taxonomy | Controlled closed taxonomy with open members | `spec/energy-proposals-and-trackers.md`; `protocols/scientific.jl` | Correct direction, but category lists across specs and exported abstract types need one canonical mapping. | Freeze the taxonomy separately from each family's method interface. Adding a family member requires no taxonomy edit; adding a new scientific category requires a decision record. |
| Energies, drives, hard constraints, kinetic modifiers | Open | Public `energy_change`, `drive_log_bias`, `is_allowed`; typed component tuples | Mostly healthy. Built-in folds are generic, but conformance helpers do not yet prove full compilation and GPU use. | Add downstream fixtures and complete required metadata/effect validation. |
| Mechanical components | Open family | `AbstractMechanicalComponent`, `mechanical_work`; `MechanicalInitialization` enum and concrete-family checks | Open work interface, closed initialization and several consumer branches. | Replace behavioral initialization enum with policy values and methods; dispatch lifecycle behavior by family and policy. |
| Trackers and observables | Open | Public reconstruction/update semantics; concrete scientific tracker storage | Scientific definition is open, compiled storage is still shaped around current tracker families. | Add a tracker lowering/workspace protocol and an external tracker fixture; permit compiler grouping without exposing cache layout. |
| Proposal processes | Open | Specs allow neighbor, distinct-neighbor, border, thinned, and future processes; `CopyAttempt` is shaped around neighbor-site copying | Underdefined and partly closed by one proposal representation. | Separate proposal-law interface, transition identity/probability interface, and local attempt-report representation. Keep `CopyAttemptOutcome` local to compatible algorithms rather than universal. |
| Acceptance laws | Open | `AbstractAcceptanceLaw` plus `acceptance_probability` dispatch | Healthy core shape. Legacy `AbstractSampler` is a competing path. | Keep acceptance laws independent of proposals; delete sampler path at the Phase 10--11 legacy gate. Add custom-law conformance. |
| Algorithms | Open | Spec requires ordinary SciML algorithm values; implementation has `Union{SequentialCPM,...}` signatures and family-specific `isa` branches | Open in specification, closed in execution consumers. | Define algorithm-owned initialization, workspace, one-MCS execution, reporting, and guarantee methods. Remove central algorithm unions before Phase 9. |
| Guarantee and capability profiles | Closed schema, open values | `AlgorithmGuaranteeProfile`; symbol-valued fields and backend tuples | Schema closure is appropriate, but free-form symbols are weakly validated and capabilities are not compositional. | Use typed semantic values for guarantee dimensions that drive behavior. Version the report schema. |
| Lifecycle schedules | Open | Decision 0018 defines pure positive integer-MCS membership, required forms, host-to-device lowering, identity, and serialization | Semantic protocol accepted; implementation absent. | Implement built-ins and a downstream schedule through dispatch, not a behavioral enum. |
| Lifecycle triggers and effects | Open | Decision 0018 defines target/schedule/trigger/effect composition, common pre-snapshot planning, declared effects, validation, and category-owned commit; legacy compiler uses a concrete event `isa` ladder | Semantic protocol accepted; provisional compiler remains closed. | Implement the accepted planning/commit protocol and delete concrete-family switching from the replacement path. |
| Lifecycle conflict resolution | Open policy under closed atomicity law | Decision 0018 requires explicit typed policies and permutation invariance; Decision 0020 limits the Phase 8 built-ins to reject and stable semantic priority | Semantic protocol accepted; implementation absent. | Implement the two paper policies plus downstream fixture and permutation suite. Defer general composition until a concrete model requires it. |
| Division geometry | Open | Decision 0018 defines host-to-compiled lowering and allocation-free descendant-region labeling; current kernel still uses a four-family `isa` ladder and `VectorOrientation` owns a heap `Vector` | Semantic protocol accepted; implementation remains accidentally closed. | Implement random, vector, major, and minor-axis built-ins plus a downstream geometry through fixed-size device values and dispatch. |
| Division arity | Extensible architecture, binary Phase 8 implementation | Decision 0018 qualifies two nonempty regions while requiring compact region labels rather than a permanent Boolean contract | Initial scope accepted without structural binary closure. | Implement and qualify binary division only; do not claim additional arity in Phase 8. |
| Property division, transition, retirement | Open policy families | Decision 0019 makes the schema sole authority with separate operation-specific policy values; implementation still has `DivisionPolicy`, `TransitionPolicy`, and `RetirementPolicy` enums plus legacy `InheritanceRule` | Semantic protocol accepted; implementation closed and duplicated. | Replace both behavioral representations rather than wrapping them. Qualify a downstream custom property and derived-property repair protocol. |
| Auxiliary lifecycle behavior | Open by scientific family | Decision 0019 requires family-owned operation laws, explicit unsupported combinations, device lowering, and distribution or mechanical evidence | Semantic protocol accepted; implementation incomplete. | Implement family dispatch and eliminate shared generic reset/clone assumptions. Qualify each supported operation independently. |
| Death and retirement | Open death programs under closed retirement invariants | Shrink and immediate death are named; retirement reset is a single enum case | Shrink/immediate are built-ins, not necessarily all future death programs. Retirement invariants should remain closed. | Separate death-program evolution from terminal removal. Make retirement cleanup schema-driven and exhaustive without pretending its one current representation is an extension protocol. |
| Initialization layouts and overlap | Open | Decision 0021 defines one claim-emission protocol, stable provisional identities, generic finalization, typed order-independent overlap, and explicit host/device capability; current consumer still branches on `InitialCellLayout` and `InitialMediumLayout` and uses an overlap enum | Semantic protocol accepted; implementation remains closed. | Implement masks/labels, coordinates, and paper shapes plus one downstream layout through the same minimal interface. Replace concrete-family and behavioral-enum switching. |
| Topology, geometry, domains, and relations | Open architecture; Cartesian 2D/3D is closed paper scope | Specs explicitly reserve graph/irregular families; `AbstractTopology`, boundary, and spatial-role types exist; many methods accept `Union{CartesianDomain,CompiledCartesianDomain}` | Good semantics, partially closed implementation. | Keep Cartesian-specific methods local and add generic protocol boundaries above them. Do not force experimental geometries through Cartesian unions. |
| Spatial roles | Open named roles | Spec explicitly permits additional roles; `AbstractSpatialRole` exists; built-in property checks use unions | Mostly healthy with a closed-default hazard. | Give unknown roles conservative trait defaults or require methods. Do not add every new role to `_requires_symmetry`/`_allows_fixed_owner` unions. |
| Boundaries, metrics, fields, interpolation, response | Open | Abstract families exist; consumers often test concrete built-ins with `isa` | Protocol shells are open, selected algorithms remain switches. | Move behavior to functions dispatched on boundary/metric/interpolation/response. Keep backend-valid compiled descriptors concrete. |
| Owner filters and spatial queries | Open | Abstract filters and query functions exist | Healthy direction; GPU compilation evidence is incomplete for external filters. | Add effect/access traits and device conformance fixture. |
| RNG bit contract | Closed within version, replaceable by new contract | `AbstractRNGContract`; `Philox4x32x10V1`; numeric encoding is versioned | Correct. | Retain exact versioned mapping and test vectors. New mappings are new contract types/versions. |
| RNG stream and entity namespace | Built-in encoding closed; component namespace open | `RNGStream` and `RNGEntityKind` enums; specs require custom stochastic components | Current address API cannot add a semantic stream family without editing the enum. | Preserve built-in tags within v1, but lower extension randomness through stable component/instance/operation identities. Prove injective packing or revise the RNG contract. |
| Backend support | Open provider protocol; qualified release set closed | Julia package extensions are correctly used; `BackendFamily` enum and symbol switch in `require_capability` centralize families and capabilities | Packaging is healthy, capability model is closed. | Dispatch capability queries on backend and typed capability values. Keep CPU/Metal/ROCm as the current qualification gate, not the global type universe. |
| Launch and synchronization policies | Open | Abstract launch/synchronization policy types and compiled plans | Healthy but only one implementation exists. | Add required methods and conservative validation before treating the abstract types as stable protocols. |
| Persistence and output backends | Open | Decision 0022 defines completed-MCS snapshot/checkpoint values, canonical logical records, exact resume/import distinction, and HDF5/Zarr package extensions; legacy methods remain state specific | Semantic protocol accepted; implementation pending. | Implement one in-memory contract and shared adapter conformance without exposing compiled workspaces or using raw Julia serialization. |
| SciML problem and algorithm integration | Open type-based interface | Specs call for `__init`/`__solve`; current algorithm init contains concrete algorithm unions | Semantics align with SciML, implementation not yet open. | Phase 9 dispatches on Potts problem and algorithm types, keeps algorithm-specific options in constructors, and uses `solve = solve!(init(...))`. |
| PottsToolkit Level 2 API | Open ordinary Julia | Current root compiler uses dictionaries, `Any[]`, central `compile_component` methods and `isa` branches | Provisional and unsuitable for freeze. | Phase 10 replaces it with immutable declarations and dispatch-based lowering. A conforming Level 3 component needs no registration unless it requests Level 1 spelling/serialization. |
| PottsToolkit Level 1 DSL | Intentionally closed and versioned | Accepted closed language boundary | Correct. | Keep macros thin over Level 2; unknown syntax fails. Extend through explicit registered syntax/IR, not arbitrary Julia evaluation. |
| Compatibility import/export | Intentionally closed supported subset | Specs require explicit compatibility profile and unsupported-feature errors | Correct. | Version each supported subset and keep native extensions visibly hybrid. |
| NeuralPotts and other satellites | Open through public protocols, experimental maturity | Satellite packages still depend partly on legacy component hierarchy | Provisional. | Migrate only after stable CorePotts extension fixtures exist; satellites must be able to extend without internal imports. |

## Priority Findings

### P0 — Resolve before Phase 8 implementation

1. **One lifecycle policy system — semantic protocol accepted.** Implement Decision 0019 by removing
   the competing behavioral enums and legacy `InheritanceRule` family from the future path. The
   schema owns separate dispatch-based division, transition, retirement, derived-state, and
   auxiliary-family policies.
2. **Open division geometry — semantic protocol accepted.** Replace the mitosis kernel's concrete
   orientation switch with the open compiled geometry/partition protocol in Decision 0018. Make all
   built-ins device-valid; implementation and conformance remain Phase 8 work.
3. **Typed schedules, triggers, effects, and resolvers — semantic protocol accepted.** Implement the
   common pre-snapshot, declared effects, explicit permutation-invariant resolver, and transactional
   lowering required by Decision 0018 before event kernels are written.
4. **Open initialization finalization — semantic protocol accepted.** Implement Decision 0021 so
   the consumer accepts claim-emitting layouts through dispatch rather than recognizing two concrete
   layouts through an `isa` branch. Keep finalization generic and overlap order independent.
5. **Hard GPU lifecycle contract — accepted.** Every device lifecycle extension must execute
   schedule through commit on device using compiled descriptors, bounded workspaces and error
   records, with no hidden host fallback.
6. **Correct lifecycle timing language — accepted.** Phase 8 runs once at a positive integer-MCS
   boundary after a complete proposal/mechanics MCS. MCS 0 is finalized initialization; internal
   checkerboard or lottery rounds are not lifecycle time.

### P1 — Resolve before Phase 9 and the Level 3 API candidate

1. Replace central algorithm `Union` signatures with algorithm dispatch.
2. Separate proposal-law interfaces from the current neighbor-copy attempt representation.
3. Replace backend capability symbols and the central backend-family assumption with typed
   capability dispatch while preserving the current three-backend qualification gate.
4. Define an extensible semantic RNG namespace above the closed v1 numeric stream tags.
5. Finish compiled tracker, metric, field, query, and mechanical lowering protocols.
6. Reduce the CorePotts export surface to deliberate stable scientific and extension names; keep
   workspaces, storage layouts, kernels, and provisional legacy types internal or experimental.

### P2 — Resolve during Phases 10--13

1. Replace PottsToolkit's broad `@reexport using CorePotts` with a curated high-level surface and
   explicit expert access to CorePotts.
2. Delete dictionary/`Any`-based execution lowering and central `isa` component compilation.
3. Add versioned registration only for DSL spelling, serialization, and compatibility boundaries.
4. Create external-style extension fixture packages covering scientific, lifecycle, algorithm,
   initialization, persistence, and GPU operations.
5. Measure specialization count, invalidations, compile latency, device code size, register use, and
   steady-state performance for heterogeneous extension models.
6. Freeze stable/experimental/internal API classifications only after the zero-core-edit tests pass.

## Concrete Hotspots

The following current files are important evidence, not necessarily direct patch targets before
their owning phase:

- `lib/CorePotts/src/algorithms/sequential.jl` — central algorithm `Union` methods and concrete
  capability branches.
- `lib/CorePotts/src/state/semantics.jl` and `state/lifecycle.jl` — behavioral lifecycle enums and
  switch-based application.
- `lib/CorePotts/src/lifecycle/nodes/properties.jl` — a second, legacy inheritance hierarchy.
- `lib/CorePotts/src/kernels/events/mitosis_kernels.jl` — closed division-orientation `isa` ladder.
- `lib/CorePotts/src/lifecycle/core_events.jl` — heap-backed `VectorOrientation` and legacy event
  execution.
- `lib/CorePotts/src/initialization/logical.jl` — abstract layout input consumed by a concrete
  two-family `isa` branch.
- `lib/CorePotts/src/rng/semantic.jl` — closed v1 stream/entity numeric namespace.
- `lib/CorePotts/src/execution/contracts.jl` — central backend-family enum and capability-symbol
  switch.
- `lib/CorePotts/src/components/scientific_components.jl` and `scientific_mechanics.jl` — closed
  mechanical initialization and concrete metric/noise branches.
- `lib/CorePotts/src/spatial/cartesian.jl` and scientific field/query files — good abstract shells
  with several built-in unions and concrete branches that must remain local, not universal.
- `src/problems.jl`, `src/rules/events.jl`, and `src/models.jl` — provisional PottsToolkit compiler
  built around `Any`, dictionaries, broad categories, and concrete lowering branches.
- `lib/CorePotts/src/CorePotts.jl` and `src/PottsToolkit.jl` — oversized export/re-export surfaces
  that expose both future and quarantined APIs simultaneously.

## Required Extension Fixtures

The conformance suite should contain small downstream-style modules or test packages. Each fixture
must use only public imports and own its types.

| Fixture | Minimum proof |
| --- | --- |
| Custom Hamiltonian | Reference `energy_change`, full-energy delta check, compiled CPU and GPU tuple fold |
| Custom hard constraint | Access/conflict declaration, sequential execution, parallel rejection or qualification |
| Custom tracker/observable | Reconstruction, incremental equality, workspace lowering, checkpoint behavior |
| Custom proposal and algorithm | `init`, one MCS, guarantee profile, report, reproducibility, no central union edit |
| Custom division geometry | Non-built-in partition, deterministic plan, binary invariants, CPU/Metal/ROCm execution |
| Custom property lifecycle policy | Division/transition/retirement behavior, schema lowering, device execution |
| Custom schedule/trigger/effect | Integer-MCS timing, snapshot semantics, conflict resolution, atomic commit |
| Custom initialization source | Coordinate/raster emission, overlap policy, deterministic finalization |
| Custom RNG-using component | Stable namespace, reordering isolation, same-backend replay, GPU bit tests |
| Custom storage backend | Canonical snapshot round-trip, checkpoint metadata, package-extension loading |
| Test backend capability provider | New backend-like type recognized through methods without editing a family enum |
| PottsToolkit Level 2 component | Direct normalization/lowering without an `isa` compiler switch; optional registered DSL spelling |

At least one fixture should combine several extensions in one model. Isolated method-shape tests do
not expose composition, ambiguity, specialization, or conflict-analysis failures.

## Steering Rules for the Remaining Refactor

1. **Protocol before built-ins.** Write the minimal interface, reference law, and conformance helper;
   then implement the first built-in through that same interface.
2. **First consumer before freeze.** Exercise each protocol in a complete scalar MCS and, where
   promised, a complete compiled GPU path before stabilizing names.
3. **No central edit as acceptance evidence.** The second implementation of every important family
   should live in a test-only downstream module.
4. **Host flexibility, compiled concreteness.** Dynamic construction is allowed before compilation;
   compiled state and hot kernels are concrete, bounded, and device-valid.
5. **Traits for orthogonal capabilities.** Do not encode backend, serialization, dimensionality,
   access, or determinism into a combinatorial subtype hierarchy.
6. **No silent fallback.** Unsupported algorithm/component/backend combinations fail during
   construction with compatible alternatives. A CPU fallback is a visible execution choice.
7. **Registries only at naming boundaries.** Direct CorePotts behavior uses dispatch. DSL and
   serialization identities may use versioned registries.
8. **Reference and optimized implementations share the protocol.** Backend specializations do not
   become new scientific types unless their transition law differs.
9. **Bound specialization deliberately.** Group heterogeneous components, use function barriers,
   and measure compilation as well as runtime.
10. **Remove the old path when the vertical slice is complete.** Do not leave duplicate inheritance,
    event, proposal, or algorithm architectures available at API freeze.

## Exit Gate

The open-protocol audit is closed only when:

- every P0 item has an accepted protocol before its Phase 8 implementation;
- every P1 item is resolved before the Phase 9/Level 3 API candidate;
- the required downstream fixtures pass without CorePotts source edits;
- claimed device fixtures compile and run on CPU, Metal, and ROCm;
- no stable protocol consumer enumerates all implementations through central `Union` or `isa`
  switching;
- closed public sets document their exhaustiveness and versioning rationale;
- PottsToolkit registration is limited to naming and serialization boundaries; and
- compilation latency and device/runtime performance remain inside the paper-release budgets.

## Conclusion

Potts.jl does not need more abstraction for its own sake. It needs disciplined placement of
abstraction. Closed scientific meaning, open family membership, concrete compiled plans, and strong
conformance tests are compatible. That combination is the Julia-native path to a library that is
both extensible and capable of world-class GPU execution.
