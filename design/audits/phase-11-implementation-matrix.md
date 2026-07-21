# Phase 11 implementation and evidence matrix

Status: Active implementation gate

This matrix translates the accepted Level 1 contracts into executable Phase 11 work. A row is
complete only when its implementation, equivalence fixture, structured diagnostic fixture, and
applicable execution evidence exist. Passing an older Level 2 test does not complete a Level 1 row.

## Public authoring surface

| Contract area | Required public spelling | Required evidence | Status |
|---|---|---|---|
| Biological identities | `CellType`, `Medium`, typed roles | constructor, namespace, role-binding, collision, display tests | cell/medium plus open `AbstractFragmentRole` with built-in `CellRole` and `FieldRole`; category and identity-collision fixtures are green |
| State and data ownership | `CellProperty`, `CellParameter`, `ModelParameter` | ownership/type/lifecycle validation and callable-reference tests | immutable parameter reads lower into the typed rule program; missing per-cell-type bindings are rejected before execution |
| Exact mechanics | `Volume`, `Surface`, `Elongation`, `Adhesion`, `PreserveConnectivity` | Level 1/2 fingerprint equality plus CPU/Metal/ROCm execution | final volume/surface and pair-law spelling implemented; distinct Level 1/2 spellings have equal-fingerprint fixtures; backend matrix pending |
| Stateful mechanics | `FluctuatingVolumePressure`, `FluctuatingSurfaceTension`, explicit noise | exact names, initialization/division policies, backend execution | final wrappers and mandatory explicit noise implemented; both wrappers have equal-fingerprint Level 2 fixtures; backend matrix pending |
| Fields | reusable `Field`; problem binding through `field => values` | model reuse across bindings, interpolation/boundary diagnostics, backend execution | reusable declaration and problem-owned prescribed values implemented with no-flux, periodic, and fixed-value boundaries plus multilinear/nearest interpolation; exact boundary conversion is validated; CPU and real Metal 2D/3D evidence green with ROCm CI pending |
| Geometry | `CartesianDomain`, typed boundaries and spacing | 2D/3D construction, mixed-boundary and invalid-geometry diagnostics | final vocabulary implemented; Level 1 defaults to portable `Float32` spacing while preserving explicitly requested wider precision |
| Layout | `Layout`, `Place`, masks/labels/shapes, `UniformSiteSeeds`, `SequentialRejectionPlacement` | overlap policy, deterministic seed, capacity and device-residency reports | explicit masks/labels and addressed uniform/rejection procedural layouts implemented; deterministic replay, bounded failure, capacity/eligibility, provisional-ID, semantic-name, RNG-operation, and dimensional diagnostics are green; initialization remains intentionally host-finalized and produces the one backend-portable CorePotts state |
| Model/problem | flat immutable `PottsModel`; direct `PottsProblem` constructor | immutable revision, `remake`, fixed capacity/seed, no runtime wrapper | final direct constructor and problem-owned field binding implemented; returns CorePotts problem directly |
| Composition | `ModelFragment`, roles, explicit binding, `add/remove/replace/compose` | namespace, dependency, conflict, unresolved-role tests | immutable typed `bind(fragment, role => value)` substitutes through mechanics, properties, parameters, fields, and lifecycle declarations; partial/unbound roles remain inspectable but reject runnable models; explicit-model fingerprint plus CPU/real-Metal 2D/3D execution fixtures are green with zero warm-step sync/transfer/allocation |

## Rules, lifecycle, and queries

| Contract area | Required public spelling | Required evidence | Status |
|---|---|---|---|
| Phases | `Phase(:name; after=...)` | DAG, unordered-writer conflict, display and fingerprint tests | each phase uses global evaluate/commit launches over reusable backend buffers; simultaneous snapshots and ordered commits are CPU/real-Metal green in 2D/3D, ROCm CI pending |
| Rules | programmatic `Rule`/`RuleGroup`; `@rule`, `@rules` | closed parser, hygiene/source locations, macro/programmatic equality | thin macros, typed IR, source capture, equality, collective lowering, and GPU execution implemented for the current scalar/draw subset; queries remain |
| Rule expressions | accepted scalar Julia subset and `NoChange()` | parser allow/deny inventory, host reference evaluator, conversions | arithmetic/conditional subset, explicit no-change, arity validation, host evaluator, and device execution implemented; the compiled output policy permits only statically proven exact conversions and rejects narrowing, float-to-integer, precision loss, unresolved output types, and reliance on user `convert`; named lossy policies and the final domain inventory remain |
| Triggers | programmatic `TriggerRule`; `@trigger` | purity/read-set/source diagnostics and lifecycle lowering | typed trigger and property-threshold lifecycle lowering implemented; full predicate set pending |
| Draws | `draw`, `RandomDraw`, stable labels | unique semantic addresses, duplicates rejected, no authoring-time RNG | Bernoulli/Uniform/Normal/2D-3D unit-vector device lowering implemented; duplicate labels, literal domains, and compiled-operation collisions rejected; one permanent CPU/real-Metal 2D/3D gate executes all four families, ROCm pending |
| Queries | typed relations and lazy `neighbors`, `contacts`, `sites`, `boundary_sites` | result-domain, empty-policy, reduction and backend fixtures | typed `Contacting`, `AnyFiniteCell`, and `CellTypeFilter`; exact edge-count/contact-measure/boundary-site and distinct-neighbor count/property-sum/property-mean reductions implemented and oracle-checked on CPU/real Metal in 2D/3D; property reachability and explicit empty-mean policy are validated; lazy collection spelling and Phase 12 optimized derived buffers remain |
| Field sampling | explicit site/center/gradient sampling | implicit cell sampling rejection and interpolation fixtures | pending |
| Schedules | `EveryMCS`, `AtMCS`, `BetweenMCS` | positive integer-MCS validation and open-protocol lowering | final Toolkit spelling implemented over Core open schedule protocol |
| Lifecycle | `PropertyUpdate`, `Transition`, `Division`, `ShrinkDeath`, `ImmediateDeath` | trigger/schedule/effect inspection and transaction execution | typed public implementations exist; `Growth`/`PropertyUpdate` equivalence is fingerprinted and compiled lifecycle execution is covered; broader trigger/resolver work remains |
| Conflicts | reject ambiguity; `PriorityResolver` | order-invariance and one-identity-change-per-cell tests | numeric event priority exists; resolver pending |

## Inspection, results, and exchange

| Contract area | Required public spelling | Required evidence | Status |
|---|---|---|---|
| Validation | `validate`, `isvalid`, structured exceptions | staged, accumulated, source-located diagnostics | accumulated source-located DSL diagnostics cover declaration reads, parameter scope, draw identity/domain, scalar arity, query owners/filters, output type/conversion, phase cycles, duplicate writers, and unordered hazards; final invariant/domain coverage remains |
| Inspection | `normalize`, `explain`, `dependencies`, `capabilities`, `provenance`, `lower` | immutable typed reports with consequential choices | complete typed inspection surface; `ModelCapabilityReport` aggregates per-declaration dimension/portability limits, invalid fragments remain inspectable, and `provenance(model)` is available without manual normalization |
| Display | compact and bounded `text/plain` model/rule displays | snapshot tests without compiler dumps or synchronization | compact model summaries plus bounded rich model, capability, rule-group, rule, and trigger displays are implemented; invalid models show structured diagnostics without lowering or execution |
| Observables | scientific observable declarations and solution access | volume/surface/contact/table examples; no tracker-cache names required | identity-aware volume/type/boundary/property series, snapshot policy, and tables implemented; richer contact observables pending |
| Units | optional solution-side metadata/view only | proof fingerprints/lowering/RNG are unchanged; Unitful extension test | lazy solution-side `PhysicalScale` view and Unitful extension implemented; model fingerprint invariance tested |
| Manifest | versioned `semantic_manifest` | deterministic order-independent manifest/fingerprint tests | implemented at Level 2; version/final inventory audit pending |
| Model persistence | `PottsJSON`, `save_model`, `load_model` | no `eval`, portability blockers, semantic round-trip equality | pending |

## Freeze evidence

| Gate | Evidence artifact | Status |
|---|---|---|
| Five paper models have natural Level 1 spellings | chemotaxis, differential adhesion, monolayer growth, angiogenesis, fluctuation scripts and tests | all five reference builders migrated and execute on CPU; documentation and GPU evidence pending |
| Equivalent Level 1/2 meaning | fingerprints for model declarations and public semantic-data comparisons for problem-bound declarations | distinct exact/stateful mechanics and growth spellings have equal fingerprints; reusable Level 1 fields and explicit Level 2 prescribed fields realize equal CorePotts semantic data; curated direct policies and algorithms are exact constructor aliases |
| CPU, Metal, and ROCm complete paths | CI jobs plus backend qualification scripts | permanent Phase 11 rule/query qualification is green on CPU and real Metal in 2D/3D with zero warm-step sync/transfer/allocation; ROCm CI pending |
| Custom physics remains first class | direct Level 3 component and downstream Level 1 constructor fixtures | a zero-Core-edit downstream energy implements public CorePotts methods, is returned by an ordinary Julia constructor, composes directly into the high-level model, and is permanently qualified on CPU/real Metal in 2D/3D; no mutable registry or compiler switch exists |
| Stable-component DSL coverage is at least 95% | conformance inventory with justified exclusions | machine-checked inventory passes at 51/52 = 98.08%; the sole stable lower-level-only exception is `ExternalFieldOccupancyHamiltonian`; focal-point mechanics remain the accepted experimental satellite |
| No legacy or duplicate modeling path | containment script, source/test/docs search, deleted inventory | hard containment passes: the Toolkit compiler is absent, 19 historical Core/satellite files remain frozen, four mixed signatures and 47 historical consumers remain inventoried, and the replacement scientific path is clean |
| Required tests/docs/tutorials use replacement API | repository-wide consumer audit | pending |
| Performance is no worse than Phase 10 baseline | compilation and execution benchmark comparison | pending |
| Complete-script usability audit passes | reviewed scripts and accepted defect log | pending |

## Working order

Implementation proceeds in vertical slices: differential adhesion (declarations/domain/layout/problem),
monolayer growth (phases/rules/triggers/lifecycle), chemotaxis (field declaration and problem binding),
angiogenesis (queries/custom mechanics), and fluctuation (stateful mechanics/noise). Each slice must
normalize through the existing Level 2 compiler and reach the single CorePotts runtime path before
the next slice expands the language.
