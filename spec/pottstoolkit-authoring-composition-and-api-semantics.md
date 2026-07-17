# PottsToolkit Authoring, Composition, and API Semantics

Status: Accepted authoring and composition principles; exact surface syntax remains provisional

## Purpose

This document defines the durable public-language architecture of PottsToolkit. It governs how users
declare, compose, inspect, revise, serialize, and exchange models independently of the spelling of
individual macros.

Rule meaning is defined by
[PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md). Compiler
realization is governed by the
[Metaprogramming and Compiler Architecture Standard](../design/metaprogramming-and-compiler-architecture.md).

## Stability Principle

> Stable meaning precedes stable spelling.

During the research phase, authoring syntax MAY improve substantially. Once a DSL contract version
is accepted, its normalized scientific meaning, migration path, and diagnostic contract become
compatibility commitments.

Historical macro syntax is not authoritative merely because it exists. Existing syntax MAY be
retained when it lowers unambiguously to the accepted semantic model.

## Multilevel Public API

Potts.jl provides progressive disclosure through four first-class levels:

1. PottsToolkit biological DSL
2. PottsToolkit Julia-native typed modeling API
3. CorePotts scientific API
4. CorePotts execution and backend API

These levels share scientific contracts and conformance tests. They do not all pass through one
authoring compiler or one IR.

Equivalent PottsToolkit DSL and typed-modeling declarations MUST normalize to equal semantic models.
A direct CorePotts program MAY construct scientific and execution objects without producing
PottsToolkit authoring IR. It remains governed by the applicable state, time, energy, RNG,
transaction, lifecycle, numerical, and algorithm contracts.

Moving to a lower level makes more responsibilities explicit; it does not make correctness optional
or make the interface unofficial.

### Level 1: PottsToolkit biological DSL

The friendly interface optimizes readability, discoverability, and concise scientific expression.
It MAY use macros and domain-oriented syntax, but it cannot bypass builders, validation, typed IR,
or provenance.

Beginner conveniences expand to the same explicit declarations available to experts. The normalized
model report exposes every declaration, default, component, and compatibility choice introduced by
a convenience.

The closed portable expression language applies at this level.

### Level 2: PottsToolkit Julia-native typed modeling API

Every portable model construct expressible with a macro is expressible with ordinary constructors
or builder functions. The programmatic interface is the stable foundation for tests, generated
model families, parameter studies, external tools, and environments where macro syntax is
inconvenient.

Macro and programmatic forms that express the same meaning MUST produce equal normalized models.

This level uses ordinary Julia values, functions, multiple dispatch, and composition. It is not
required to mimic DSL syntax, and ordinary Julia construction logic is not parsed as rule-language
syntax. Typed rule expressions intended for portable lowering still satisfy the same semantic-node
contracts as the DSL.

### Level 3: CorePotts scientific API

CorePotts exposes stable scientific objects and protocols for state, topology, energy components,
trackers, events, algorithms, problems, integrators, and SciML integration. Advanced users and other
packages MAY use this API directly without constructing a PottsToolkit model.

A custom penalty, tracker, event, topology, or algorithm that satisfies the applicable CorePotts
protocol is a first-class extension. It is not merely a temporary escape hatch awaiting a DSL
wrapper.

PottsToolkit MAY accept CorePotts scientific objects through these public protocols and SHOULD
re-export or make discoverable the supported scientific API. Such objects declare enough metadata
for dependency, capability, provenance, and conformance reporting. A friendly DSL spelling is
optional.

### Level 4: CorePotts execution and backend API

CorePotts exposes advanced interfaces for portable kernels, workspaces, launch policy, device
adaptation, backend capabilities, specialized algorithms, and performance instrumentation. These
interfaces support engine contributors and hardware specialists.

Backend-specific implementation details remain below the scientific API. A Level 4 specialization
must preserve the Level 3 scientific contract and provide a portable reference or fallback where
required by the JuliaGPU standard.

### Interoperability instead of forced lowering

The levels interoperate through stable scientific protocols:

```text
PottsToolkit DSL ---------\
                           +--> shared scientific protocols --> CorePotts engine
PottsToolkit typed API ---/

CorePotts direct API -----------------------------------------> CorePotts engine
```

PottsToolkit authoring IR is canonical for equivalent Level 1 and Level 2 models. CorePotts
scientific protocols are canonical at Levels 3 and 4. Cross-level equivalence is judged by shared
scientific behavior and conformance evidence, not by requiring identical compiler artifacts.

### DSL registration and lower-level extension

Third-party operations and components enter through versioned registration and explicit semantic
contracts when they seek Level 1 DSL syntax, normalized serialization, or DSL compiler support. Such
an extension declares its syntax or constructor entry points, IR lowering, types and units, effects,
capabilities, reference behavior, device behavior, documentation, and conformance tests.

Direct Level 3 or Level 4 use follows the corresponding CorePotts public protocol and does not
require a PottsToolkit IR adapter. Internal, undocumented CorePotts representation details remain
outside all public levels.

## Cross-Level Coverage and Interoperability

### DSL coverage target

At least 95% of stable user-facing CorePotts scientific components MUST have a first-class
PottsToolkit DSL spelling for a paper-quality release.

The denominator includes stable user-facing:

- Energy components and constraints
- Trackers and derived scientific observables
- Biological events and lifecycle policies
- Topologies and boundary models
- Scientific algorithm families
- Spatial fields and coupling models

It excludes internal helpers, workspaces, compiled descriptors, backend kernels, and execution-only
instrumentation. Exclusions from the 95% target are limited to highly specialized research
extensions, newly introduced components awaiting DSL stabilization, experimental components, and
facilities with no meaningful biological declaration.

Every excluded stable scientific component is listed in documentation and inspection output with
its Level 2 or Level 3 construction path and reason no Level 1 spelling exists. Coverage is measured
by the conformance inventory rather than manually curated marketing counts.

### Curated re-exports and single-import use

`using PottsToolkit` remains the single-import experience for ordinary modeling. PottsToolkit
re-exports a curated stable subset of the CorePotts scientific API, not every CorePotts name.

Extension authors SHOULD use explicit `import CorePotts` when implementing CorePotts protocols so
method ownership and abstraction level remain clear. Advanced execution APIs are accessed through
qualified CorePotts names.

### Scientific metadata

Every stable CorePotts scientific component exposes sufficient public metadata or traits to report:

- Semantic identity and version
- Required and provided state
- Read, write, and effect categories
- Numerical and RNG behavior
- Backend and algorithm capabilities
- Reference or conformance behavior
- Provenance and serialization support

CorePotts uses this metadata to produce a scientific/execution report even when no PottsToolkit model
exists. PottsToolkit reports share the same vocabulary and add authoring, expansion, namespace, and
source information.

### Direct composition

Level 2 PottsToolkit models MAY directly contain conforming public Level 3 components. No adapter is
required when the object already implements the stable CorePotts scientific-component protocol. A
separate registration is required only for Level 1 syntax, PottsToolkit-specific normalization, or
portable semantic serialization not supplied by the Level 3 protocol.

Abstraction level does not determine precedence. If components from different levels provide or
write the same scientific concern, composition rejects the conflict unless an explicit accepted
combination, merge, or replacement policy resolves it. The resolution appears in provenance.

A user can replace one high-level component with a typed PottsToolkit or CorePotts component without
rewriting the rest of the model when the replacement satisfies the same declared scientific
protocol.

### Cross-level equivalence

Representative stable features have fixtures expressed through Levels 1, 2, and 3. Tests compare:

- Realized scientific configuration
- State and lifecycle invariants
- Energy and proposal behavior
- RNG and reproducibility contracts
- Numerical and statistical results
- Capability and provenance reports

Equivalent behavior is required; byte-identical internal objects are not. Compilation reuse across
levels is permitted but promised only where a shared normalized identity is explicitly defined.

### Identifier boundary

Typed semantic identifiers remain in Levels 1 through 3. Dense integer indices, device pointers,
and backend arrays are Level 4 compiled representation details. They MAY be exposed through clearly
marked expert kernel and diagnostic interfaces but are not ordinary modeling identifiers.

### Callable and extension style

Level 2 accepts typed functions and immutable callable structs. Portable device callables must make
their reads, writes, effects, RNG behavior, and capabilities derivable or explicitly declared.

Level 3 interfaces prefer small functions and traits, using abstract types only for genuine semantic
categories. Subtyping alone is not a conformance contract. Scientific extensions provide a simple
reference implementation wherever feasible; optimized implementations are tested against it.

## Stability by Level

Levels 1 and 2 receive the PottsToolkit DSL, authoring, composition, migration, and semantic
serialization contracts.

Level 3 is a stable CorePotts scientific extension API. Direct state, problem, algorithm, and
integrator construction is supported without PottsToolkit.

Level 4 is divided into:

- A small stable execution-extension protocol for custom kernels, workspaces, capabilities, and
  algorithm specializations
- Explicitly experimental compiler, backend, workspace-layout, and kernel implementation internals

Backend-specific Level 4 algorithms are allowed when they declare their capability set and preserve
the corresponding Level 3 scientific algorithm contract. Backend specialization does not create a
new scientific algorithm unless its observable transition law differs.

Closed-AST restrictions apply to the Level 1 portable DSL, not to ordinary Julia Level 2–4 APIs.
Device code at every level still satisfies inference, effect, allocation, capability, and backend
requirements.

## Serialization by Level

Serialization guarantees are level-specific:

- Registered Level 1 and Level 2 models support full semantic serialization and round-tripping.
- Level 3 objects support provenance and descriptor serialization where declared by their protocol.
- Level 4 compiled kernels, live workspaces, streams, device handles, and backend resources have no
  general serialization guarantee.

An object that prevents a stronger level's promised serialization is accepted only when that
limitation is visible before execution and in model provenance.

## Documentation by Progressive Disclosure

Documentation leads with PottsToolkit and is organized so a concept can expose, as applicable:

1. Biological DSL usage
2. Typed PottsToolkit construction
3. CorePotts scientific protocol and direct use
4. Execution-extension details

Level 1 users need not understand CorePotts representation types. Inspection MAY separately show
the resulting CorePotts scientific or execution plan.

The current `CellType -> Component -> PottsSystem -> Problem` hierarchy is not automatically
preserved. Its scientific concepts remain candidates, but constructor shapes, nesting, ownership,
and responsibilities require evaluation against the accepted multilevel API.

## Level 1 Object Model

### Construction style

Level 1 does not require a top-level model macro. Ordinary immutable Julia constructors are the
default for model structure. Macros are reserved for contexts where syntax materially improves
clarity, source mapping, or safety, especially rule expressions. A future top-level macro requires
usability evidence and must lower through the same Level 1 authoring model.

### Cell types and media

`CellType` is a central biological declaration representing a named finite-cell category with
parameters, lifecycle policies, and component participation. It is not a dense storage index or an
individual cell.

Medium is not permanently modeled as a special cell type. Level 1 exposes an explicit medium-domain
concept. The semantic object model permits multiple named medium domains even while an initial
engine capability supports only one conceptual medium. Compatibility syntax MAY interpret a
historical background `CellType` as a medium after explicit validation and reporting.

### Model and problem

The primary immutable scientific model is conceptually `PottsModel`; the final exported name is
confirmed with the API inventory. A model contains biological declarations, components, rules,
scientific relations, field coupling, and capability requirements.

`PottsProblem` is the SciML problem object. It binds a model to a concrete experiment, including:

- Lattice dimensions, spacing, and realized geometry
- Initial ownership and cell placement
- Initial property values
- Cell capacity and allocation policy
- Time span
- Problem-level observation or solve configuration

Layouts and initial placement belong to the problem rather than the reusable scientific model.

Scientific relation definitions and boundary semantics belong to the model or its domain
specification. Concrete lattice sizes, spacing realization, and storage belong to the problem. A
model can be reused across compatible geometries and initial conditions; dimension-, topology-, or
field-specific components expose their requirements explicitly.

### Algorithms and temperature

The Monte Carlo algorithm is normally supplied through `solve(problem, algorithm)` or
`init(problem, algorithm)` rather than stored in the model. Algorithm family remains scientifically
consequential: validation, provenance, guarantee profiles, and reproducibility include it.

Acceptance-law temperature belongs to the algorithm configuration. Biological parameters or fields
that happen to use temperature terminology remain distinct semantic declarations.

### Components

Level 1 components are immutable ordinary Julia values named for their biological or scientific
meaning. A universal `Component` suffix is not required. Preferred names distinguish constraints,
energies, couplings, and processes where the distinction is scientifically meaningful.

A Level 1 component need not correspond one-to-one with a CorePotts penalty. It MAY provide several
properties, penalties, trackers, rules, events, or capability requirements. Inspection exposes the
complete expansion.

Components support homogeneous declarations across several cell types and explicit heterogeneous
per-type values. `CellType => parameters` pairs MAY be concise Level 1 sugar but normalize
immediately to typed bindings. Pair order never supplies priority or scientific identity.

### Pairwise laws

Pairwise interactions use a dedicated typed table or law abstraction rather than a raw matrix whose
indices depend on declaration order. It declares:

- Symmetric or directed behavior
- Medium participation
- Default and missing-pair behavior
- Types and units
- Canonical pair identities
- Conflict and override policy

A raw matrix remains available at a lower level or through an explicitly indexed compatibility
constructor.

### Properties and observables

Custom properties are declared independently of rules. A property schema declares owner, type,
units, initialization, lifecycle inheritance, visibility, and conversion policy.

Built-in components MAY supply common schemas without verbose user declarations. Supplied schemas
appear in `explain`, participate in conflict detection, and cannot silently override explicit user
schemas.

Level 1 ordinarily exposes scientific observables rather than tracker-cache implementation names.
Advanced users MAY request a tracker explicitly when it is itself a stable scientific API, but
volume, surface, contacts, and related quantities remain the primary vocabulary.

### Events and schedules

Events are ordinary model components participating in dependency, effect, capability, provenance,
and composition analysis. Growth, division, death, transition, property update, and field coupling
retain distinct effect semantics despite sharing the component framework.

Schedules are reusable typed values. Periodic integer-MCS schedules, one-time schedules, conditional
schedules, and future accepted schedules are inspectable independently of an event.

### Rule ownership and roles

Rules declare an owner scope rather than requiring one duplicated rule object per concrete type. A
scope MAY identify one type, several types, a fragment-provided biological role, a medium domain, or
global state where supported.

Reusable fragments can declare roles such as a proliferating or chemotactic cell population and
bind those roles explicitly to concrete cell types during application. Roles are typed requirements,
not implicit tags inferred from component names.

### Persistent construction and incompleteness

Adding, removing, or replacing a model declaration returns a new model. A transient builder MAY
collect declarations efficiently within one construction operation but does not become durable
mutable model state.

Incomplete Level 1 models are represented as fragments or explicitly draft models. Inspection lists
unresolved roles, declarations, and capabilities prominently. An incomplete model cannot construct a
runnable problem.

### Current API migration

The historical `CellType -> Component -> PottsSystem -> Problem` API is compatibility syntax rather
than the architectural constraint for the new object model. Concepts with accepted meaning MAY be
retained, while constructors, nesting, ownership, and names are redesigned where necessary.

Unambiguous historical syntax SHOULD receive a documented deprecation or adapter path. Behavior
that conflicts with accepted media, state, time, algorithm, or composition semantics is rejected or
requires an explicitly named compatibility mode.

## Model, Problem, and Execution State

A PottsToolkit `Model` is an immutable declarative scientific value. It contains authoring or
normalized meaning, not evolving simulation state.

A `Problem` binds a model to initial state, geometry, time span, and solve-level configuration. An
integrator or engine owns mutable execution state. Mutation of an integrator MUST NOT retroactively
change its source model or problem.

Model changes use persistent builder operations or `remake`. A revision produces a new model value.
Implementations MAY share immutable internal structure.

## Declaration and Resolution

### Order independence

Declarations resolve by semantic identity rather than incidental textual order. Cell types,
properties, parameters, fields, components, and relations MAY be written in any order when their
dependencies can be resolved after collection.

Order has meaning only inside an explicitly ordered construct, including named phases, priority
lists, or another accepted sequential form. Accidental vector order, dictionary order, macro
expansion order, and module load order are not scientific semantics.

### Prior schema declaration

Every rule-visible state item has a schema declaration before normalized compilation. A property,
parameter, field, or relation declares as applicable:

- Stable identity and owner
- Semantic type and units
- Default or initialization requirement
- Mutability and effect category
- Lifecycle behavior
- Storage and conversion policy where observable

A misspelled reference MUST NOT create state implicitly.

### Name resolution

Scientific ambiguity is never resolved solely by Julia method dispatch. Ownership, units, relation
roles, effects, algorithm identities, and model names are represented explicitly in the semantic
model.

Unknown, ambiguous, private, or category-incompatible references are structured validation errors.

## Ordinary Julia and the Closed Language Boundary

Ordinary Julia MAY construct models, generate declarations, iterate over cell types, select
components, load data, and organize experiments.

Level 1 portable rule expressions remain a closed semantic language. Only accepted syntax and
registered operations may occur inside that boundary. Arbitrary Julia execution, global lookup,
reflection, dynamic dispatch, and unchecked closure capture are not admitted merely because the
surrounding model was built with ordinary Julia.

Level 2 typed modeling code and direct Level 3 or Level 4 CorePotts code are ordinary Julia APIs,
not closed AST languages. Device-executed functions still obey device compatibility, effect,
capability, and inference requirements.

This boundary allows the host authoring experience to remain Julian without making device behavior
or scientific meaning depend on arbitrary AST execution.

## Reusable Model Fragments

A model fragment is a first-class immutable declaration bundle. It declares:

- Required inputs and semantic capabilities
- Exported names
- Private names
- Properties, parameters, fields, and relations it provides
- Components and rules it contributes
- Effects and phase requirements
- Compatibility and portability constraints
- Version and provenance

Applying a fragment returns a new model and produces an inspectable composition result.

### Namespaces and binding

Fragments have lexical namespaces by default. Internal names are private unless explicitly exported.
The applying model binds fragment requirements and MAY explicitly rename exports.

String concatenation, gensymmed public symbols, and global naming conventions are not substitutes
for namespaces.

### Collision behavior

Composition does not resolve conflicting definitions silently. Two declarations MAY be deduplicated
only when their normalized definitions and identities are equal under the applicable DSL version.

Otherwise the user must explicitly rename, replace, override, or reject the declaration. An
override is recorded in the composition report and semantic fingerprint.

### Dependencies

Fragments and components expose provided and required declarations. Removing or replacing one must
preserve the dependency graph. A removal that leaves an unsatisfied dependency is an error unless a
replacement is supplied in the same model revision.

## Components

Component attachment is declarative. A component declares what it provides, requires, reads,
writes, constrains, observes, and which backend or numerical capabilities it needs.

Attaching a component produces a new model and runs composition validation. Components have stable
identities so models support identity-based operations conceptually equivalent to:

- `with(model, component)`
- `without(model, component_id)`
- `replace(model, component_id => replacement)`
- `remake(model; ...)`

The exact spelling remains provisional. These operations MUST NOT depend on object position or
vector order.

## Defaults, Presets, and Convenience

Harmless representational defaults MAY be implicit. A default that can change scientific
interpretation, dynamics, numerical behavior, reproducibility, or compatibility comes from a named,
versioned preset or an explicit declaration.

Every realized default appears in the normalized model report. A convenience constructor may expand
multiple declarations but cannot create an invisible execution path.

Changing the meaning of a named preset requires a new preset version or an explicit semantic
migration.

## Rules, Phases, and Transactions

Multiple property targets MAY be declared as one atomic rule group. All targets in that group read
one accepted phase snapshot and commit together according to
[PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md).

Sequential dependence requires separate explicitly ordered phases. Assignment-like syntax, if
offered, is sugar for declared targets and does not imply statement-by-statement mutation.

Phase and transaction structure is visible through model inspection.

## Staged Validation

Validation occurs at the earliest layer with sufficient information:

1. Constructors validate local structure, literal domains, and immediately knowable invariants.
2. Model normalization resolves names, types, units, effects, dependencies, and composition
   conflicts.
3. Problem construction validates geometry, capacity, initial state, and model-state compatibility.
4. Backend preflight validates capabilities, device lowering, resource constraints, and kernel
   compilation.

Local independent errors SHOULD be accumulated and returned together. A stage stops early when
continuing would make subsequent diagnostics misleading, unsafe, or excessively duplicative.

Validation MUST NOT defer a host-detectable semantic error until GPU execution.

## Inspection Interface

Users can inspect every meaningful compilation stage through stable semantic reports. PottsToolkit
provides operations conceptually equivalent to:

- `validate(model)`
- `normalize(model)`
- `explain(model)`
- `dependencies(model)`
- `capabilities(model)`
- `lower(model; backend)`
- `provenance(model)`

The exact names and return types remain provisional. Internal compiler objects need not be public,
but reports MUST expose scientific choices, expansion of conveniences, dependencies, effects,
capability requirements, defaults, approximations, and portability limitations.

Inspection does not require executing an MCS.

## Revision, Remake, and Compilation Reuse

Model revisions distinguish numerical and structural changes.

A numerical change updates values while preserving the normalized schema, rule graph, component
graph, algorithm structure, and required capabilities. It SHOULD reuse compilation when safe.

A structural change includes changes to topology, dimension, schema, rule/effect graph, algorithm
family, compiled query set, or other specialization-relevant structure. It invalidates affected
compiled plans.

The compiler determines and reports whether a revision is numerical or structural. It MUST NOT reuse
a compiled plan merely because two Julia objects have the same concrete type.

Parameter sweeps and SciML `remake` behavior must respect this classification.

## DSL and IR Versioning

DSL/IR contract versions are independent of package versions. A normalized model records:

- Authoring DSL contract version
- Normalized IR contract version
- Registry and operation versions
- Fragment and component versions
- Preset and compatibility versions
- RNG and numerical contract versions
- Semantic fingerprint

A package upgrade MUST NOT silently reinterpret a serialized model. Unsupported historical versions
produce a migration diagnostic or require an explicit migration tool.

## Serialization and Exchange

Source code is not the only durable representation. PottsToolkit provides a versioned data-oriented
serialization of the normalized semantic model for provenance, exchange, validation, and
reconstruction.

The guarantee is semantic round-tripping: loading a supported serialized model reconstructs an
equivalent normalized model and fingerprint under the recorded contract versions.

The project does not promise to reproduce original source formatting, comments, macro choice, or
declaration order. A pretty-printer MAY emit canonical authoring code.

Arbitrary closures, host resources, secret-bearing objects, and backend-specific handles prevent
portable serialization unless a registered resource representation exists. The model report labels
such a model non-portable and explains why.

## Diagnostic Contract

Composition and authoring diagnostics include as applicable:

- Source locations and model paths
- Namespace and fragment paths
- Stable declaration or component identities
- Expected and actual types, units, owners, or capabilities
- Competing definitions in a collision
- Dependency paths preventing removal or replacement
- The preset or convenience that introduced a declaration
- Suggested explicit bindings, renames, or replacements

Diagnostics distinguish invalid syntax, unresolved meaning, incompatible composition, unsupported
backend capability, and migration failure.

## Conformance Requirements

- Friendly and programmatic authoring forms normalize to equal meaning.
- The multilevel API shares scientific contracts without requiring direct CorePotts use to produce
  PottsToolkit authoring IR.
- CorePotts remains independently usable through stable scientific and execution interfaces.
- A conforming custom CorePotts component is a first-class extension rather than a provisional escape
  hatch.
- At least 95% of the stable user-facing CorePotts scientific inventory has a Level 1 DSL spelling,
  with every exclusion reported and justified.
- The curated CorePotts scientific subset is available through the PottsToolkit single-import
  experience; execution extensions remain clearly qualified.
- Cross-level fixtures establish scientific equivalence without requiring equal internal objects.
- Mixed-level conflicts require explicit combination, replacement, or rejection.
- Level 3 objects expose scientific metadata even when no PottsToolkit authoring model exists.
- Level 4 clearly separates stable extension protocols from experimental implementation internals.
- A model is immutable and separate from mutable execution state.
- Declaration order is irrelevant outside explicitly ordered constructs.
- Misspelled references cannot create state.
- Ordinary Julia construction cannot bypass the closed portable rule boundary.
- Fragment namespaces prevent accidental global collisions.
- Conflicting declarations require explicit resolution.
- Convenience APIs reveal their complete normalized expansion.
- Component removal and replacement preserve declared dependencies.
- Atomic rule groups read one snapshot and commit together.
- Validation occurs in the accepted stages and reports multiple independent errors where safe.
- Inspection exposes all consequential normalized choices without simulation execution.
- Numerical revisions reuse compilation only when structure and capability requirements permit it.
- Serialized models record independent DSL and IR versions.
- Round-tripping preserves normalized meaning rather than incidental source spelling.
- Documented CorePotts public protocols interoperate with PottsToolkit without exposing internal
  storage representations.

## Exact Surface Syntax Still to Define

The following remain provisional until dedicated syntax and usability interviews are accepted:

- Model, type, property, parameter, field, component, and relation declaration grammar
- Rule, transaction, conditional, random draw, and query grammar
- Namespace, fragment application, binding, and override spelling
- Constructor names and builder return types
- Inspection result types and display conventions
- Canonical pretty-printing
- Deprecation syntax and migration tooling
- IDE, completion, formatting, and documentation integration
