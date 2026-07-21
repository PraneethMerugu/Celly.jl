# Phase 11 implementation and evidence matrix

Status: Local candidate pass; authoritative protected CI pending

This matrix translates the accepted Level 1 contracts into executable Phase 11 work. A row is
complete only when its implementation, equivalence fixture, structured diagnostic fixture, and
applicable execution evidence exist. Passing an older Level 2 test does not complete a Level 1 row.

This matrix separates the Phase 11 paper-scope refactor from additive language features and later
release gates. A deferred row preserves its accepted semantic contract but does not authorize a
placeholder implementation and does not block the Phase 11 refactor. Quantitative performance,
final API/version freeze, and documentation/tutorial migration remain owned by Phases 12, 13, and
14 respectively.

## Public authoring surface

| Contract area | Required public spelling | Required evidence | Status |
|---|---|---|---|
| Biological identities | `CellType`, `Medium`, typed roles | constructor, namespace, role-binding, collision, display tests | cell/medium plus open `AbstractFragmentRole` with built-in `CellRole` and `FieldRole`; category and identity-collision fixtures are green |
| State and data ownership | `CellProperty`, `CellParameter`, `ModelParameter` | ownership/type/lifecycle validation and callable-reference tests | immutable parameter reads lower into the typed rule program; missing per-cell-type bindings are rejected before execution |
| Exact mechanics | `Volume`, `Surface`, `Elongation`, `Adhesion`, `PreserveConnectivity` | Level 1/2 fingerprint equality plus CPU/Metal/ROCm execution | final volume/surface and pair-law spelling implemented; distinct Level 1/2 spellings have equal-fingerprint fixtures; five-family CPU/real-Metal execution covers volume, adhesion, elongation, and connectivity, with the Core family qualification retained for surface and ROCm CI pending |
| Stateful mechanics | `FluctuatingVolumePressure`, `FluctuatingSurfaceTension`, explicit noise | exact names, initialization/division policies, backend execution | final wrappers and mandatory explicit noise implemented; both wrappers have equal-fingerprint Level 2 fixtures, the fluctuating-volume paper model is CPU/real-Metal green, and the shared Core mechanical family qualification covers fluctuating surface; ROCm CI pending |
| Fields | reusable `Field`; problem binding through `field => values` | model reuse across bindings, interpolation/boundary diagnostics, backend execution | reusable declaration and problem-owned prescribed values implemented with no-flux, periodic, and fixed-value boundaries plus multilinear/nearest interpolation; exact boundary conversion is validated; CPU and real Metal 2D/3D evidence green with ROCm CI pending |
| Geometry | `CartesianDomain`, typed boundaries and spacing | 2D/3D construction, mixed-boundary and invalid-geometry diagnostics | final vocabulary implemented; Level 1 defaults to portable `Float32` spacing while preserving explicitly requested wider precision |
| Layout | `Layout`, `Place`, masks/labels/shapes, `UniformSiteSeeds`, `SequentialRejectionPlacement` | overlap policy, deterministic seed, capacity and device-residency reports | explicit masks/labels and addressed uniform/rejection procedural layouts implemented; deterministic replay, bounded failure, capacity/eligibility, provisional-ID, semantic-name, RNG-operation, and dimensional diagnostics are green; initialization remains intentionally host-finalized and produces the one backend-portable CorePotts state |
| Model/problem | flat immutable `PottsModel`; direct `PottsProblem` constructor | immutable revision, `remake`, fixed capacity/seed, no runtime wrapper | final direct constructor and problem-owned field binding implemented; returns CorePotts problem directly |
| Composition | `ModelFragment`, roles, explicit binding, `add/remove/replace/compose` | namespace, dependency, conflict, unresolved-role tests | immutable typed `bind(fragment, role => value)` substitutes through mechanics, properties, parameters, fields, and lifecycle declarations; partial/unbound roles remain inspectable but reject runnable models; explicit-model fingerprint plus CPU/real-Metal 2D/3D execution fixtures are green with zero warm-step sync/transfer/allocation |

## Rules, lifecycle, and queries

| Contract area | Required public spelling | Required evidence | Status |
|---|---|---|---|
| Phases | `Phase(:name; after=...)` | DAG, unordered-writer conflict, display and fingerprint tests | each phase uses global evaluate/commit launches over reusable backend buffers; simultaneous snapshots and ordered commits are CPU/real-Metal green in 2D/3D, ROCm CI pending |
| Rules | programmatic `Rule`/`RuleGroup`; `@rule`, `@rules` | closed parser, hygiene/source locations, macro/programmatic equality | thin macros, typed IR, source capture, equality, collective lowering, and GPU execution implemented for the paper-scope scalar/draw/query subset; macro expansion is permanently checked to construct authoring values without lowering, compilation, backend selection, or execution |
| Rule expressions | accepted scalar Julia subset and `NoChange()` | parser allow/deny inventory, host reference evaluator, conversions | paper-scope arithmetic, comparison, Boolean, conditional, elementary-function, query, draw, and explicit no-change inventory is allow/deny tested and device executable; outputs permit only statically proven exact conversions and reject narrowing, float-to-integer, precision loss, unresolved types, and reliance on user `convert`; no provisional lossy policy is shipped |
| Triggers | programmatic `TriggerRule`; `@trigger` | purity/read-set/source diagnostics and lifecycle lowering | typed trigger and exact property-threshold lifecycle lowering implemented for the paper scope; additional registered predicates are additive and deferred |
| Draws | `draw`, `RandomDraw`, stable labels | unique semantic addresses, duplicates rejected, no authoring-time RNG | Bernoulli/Uniform/Normal/2D-3D unit-vector device lowering implemented; duplicate labels, literal domains, and compiled-operation collisions rejected; one permanent CPU/real-Metal 2D/3D gate executes all four families, ROCm pending |
| Queries | typed relations and lazy `neighbors`, `contacts`, `sites`, `boundary_sites` | result-domain, empty-policy, reduction and backend fixtures | typed `Contacting`, `AnyFiniteCell`, and `CellTypeFilter`; exact edge-count/contact-measure/boundary-site and distinct-neighbor count/property-sum/property-mean reductions implemented and oracle-checked on CPU/real Metal in 2D/3D; property reachability and explicit empty-mean policy are validated; materialized lazy collections are deferred until a required model justifies their storage and performance contract |
| Field sampling | explicit site/center/gradient sampling | implicit cell sampling rejection and interpolation fixtures | deferred additive rule operator; paper chemotaxis uses the explicit typed field-coupling component and is backend-qualified |
| Schedules | `EveryMCS`, `AtMCS`, `BetweenMCS` | positive integer-MCS validation and open-protocol lowering | final Toolkit spelling implemented over Core open schedule protocol |
| Lifecycle | `PropertyUpdate`, `Transition`, `Division`, `ShrinkDeath`, `ImmediateDeath` | trigger/schedule/effect inspection and transaction execution | typed public implementations exist; `Growth`/`PropertyUpdate` equivalence is fingerprinted and compiled lifecycle execution is covered; broader registered predicates and resolvers are additive deferred work |
| Conflicts | reject ambiguity; `PriorityResolver` | order-invariance and one-identity-change-per-cell tests | ambiguity rejection and one-outcome lifecycle transactions are implemented; the convenience resolver is deferred until a required overlapping-event model exists |

## Inspection, results, and exchange

| Contract area | Required public spelling | Required evidence | Status |
|---|---|---|---|
| Validation | `validate`, `isvalid`, structured exceptions | staged, accumulated, source-located diagnostics | the paper-scope inventory has accumulated source-located diagnostics for declaration reads, parameter scope, draw identity/domain, scalar arity, query owners/filters, output type/conversion, phase cycles, duplicate writers, and unordered hazards; additive operations must add their own domain diagnostics before admission |
| Inspection | `normalize`, `explain`, `dependencies`, `capabilities`, `provenance`, `lower` | immutable typed reports with consequential choices | complete typed inspection surface; `ModelCapabilityReport` aggregates per-declaration dimension/portability limits, invalid fragments remain inspectable, and `provenance(model)` is available without manual normalization |
| Display | compact and bounded `text/plain` model/rule displays | snapshot tests without compiler dumps or synchronization | compact model summaries plus bounded rich model, capability, rule-group, rule, and trigger displays are implemented; invalid models show structured diagnostics without lowering or execution |
| Observables | scientific observable declarations and solution access | volume/surface/contact/table examples; no tracker-cache names required | identity-aware volume/type/boundary/property series, snapshot policy, and tables implemented; richer contact observables are additive and deferred |
| Units | optional solution-side metadata/view only | proof fingerprints/lowering/RNG are unchanged; Unitful extension test | lazy solution-side `PhysicalScale` view and Unitful extension implemented; model fingerprint invariance tested |
| Manifest | versioned `semantic_manifest` | deterministic order-independent manifest/fingerprint tests | implemented at Level 2; final public contract versions freeze in Phase 13 |
| Model persistence | `PottsJSON`, `save_model`, `load_model` | no `eval`, portability blockers, semantic round-trip equality | deferred additive exchange format; Phase 8 exact runtime checkpoints and the non-reconstructive semantic manifest remain distinct and complete |

## Freeze evidence

| Gate | Evidence artifact | Status |
|---|---|---|
| Five paper models have natural Level 1 spellings | chemotaxis, differential adhesion, monolayer growth, angiogenesis, fluctuation scripts and tests | all five reference builders use the Level 1 layout, trigger, and policy vocabulary and execute on CPU and real Metal; ordinary warm MCS paths have zero host synchronization, device-to-host transfer, and device allocation, while division workloads retain exactly their declared observation boundary; documentation migration remains |
| Equivalent Level 1/2 meaning | fingerprints for model declarations and public semantic-data comparisons for problem-bound declarations | distinct exact/stateful mechanics and growth spellings have equal fingerprints; reusable Level 1 fields and explicit Level 2 prescribed fields realize equal CorePotts semantic data; curated direct policies and algorithms are exact constructor aliases |
| CPU, Metal, and ROCm complete paths | CI jobs plus backend qualification scripts | permanent Phase 11 rule/query qualification is green on CPU and real Metal in 2D/3D with zero warm-step sync/transfer/allocation; ROCm CI pending |
| Custom physics remains first class | direct Level 3 component and downstream Level 1 constructor fixtures | a zero-Core-edit downstream energy implements public CorePotts methods, is returned by an ordinary Julia constructor, composes directly into the high-level model, and is permanently qualified on CPU/real Metal in 2D/3D; no mutable registry or compiler switch exists |
| Stable-component DSL coverage is at least 95% | conformance inventory with justified exclusions | machine-checked inventory passes at 72/73 = 98.63%, now including stable property lifecycle, HST initialization/division, and mechanical-noise policies; the sole stable lower-level-only exception is `ExternalFieldOccupancyHamiltonian`; focal-point mechanics remain the accepted experimental satellite |
| No legacy or duplicate modeling path | containment script, source/test/docs search, deleted inventory | hard containment passes: the Toolkit compiler is absent, 19 historical Core/satellite files remain frozen, four mixed signatures and 47 historical consumers remain inventoried, and the replacement scientific path is clean |
| Required package tests use replacement API | repository-wide package-test audit | complete for the Level 1 suite; manual documentation/tutorial migration remains Phase 14 |
| Performance is no worse than Phase 10 baseline | compilation and execution benchmark comparison | owned by the quantitative Phase 12 gate; Level 1 currently lowers to the same runtime problem and matched launch/residency contract |
| Complete-script usability audit passes | reviewed scripts and accepted defect log | complete for all five paper families; see the [Phase 11 usability audit](phase-11-usability-audit.md) |

## Working order

Implementation proceeds in vertical slices: differential adhesion (declarations/domain/layout/problem),
monolayer growth (phases/rules/triggers/lifecycle), chemotaxis (field declaration and problem binding),
angiogenesis (queries/custom mechanics), and fluctuation (stateful mechanics/noise). Each slice must
normalize through the existing Level 2 compiler and reach the single CorePotts runtime path before
the next slice expands the language.
