# PottsToolkit Rule and Model Semantics

Status: Accepted for sections explicitly marked Accepted; otherwise Provisional

## Purpose

PottsToolkit is the primary public modeling interface for Potts.jl. It provides a high-level,
scientifically explicit language that lowers validated models to CorePotts. The same valid portable
model is intended to execute on every supported CPU and GPU backend without rewriting its scientific
definition.

This document defines what PottsToolkit models and rules mean. It does not prescribe macro expansion,
generated-function use, storage layout, or kernel organization. Those engineering constraints are
defined by the
[Metaprogramming and Compiler Architecture Standard](../design/metaprogramming-and-compiler-architecture.md).

## Design Goals

The rule and model language is:

- Scientifically explicit
- Closed and statically validated by default
- Source-located and diagnosable
- Hardware agnostic
- Compatible with device execution
- Deterministic where the selected reproducibility profile requires it
- Extensible through registered semantic operations
- Inspectable through a normalized model report

Concise syntax MUST NOT hide proposal, energy, metric, time, randomness, boundary, approximation, or
backend semantics.

## Model Layers

### Authoring Model

The authoring model contains symbolic user declarations such as:

- Cell and medium types
- Domain and geometry
- Components and parameters
- Spatial fields
- Proposal and acceptance algorithms
- Events and lifecycle policies
- Property rules
- Observation and saving requests
- Compatibility presets

Authoring objects MAY contain dictionaries, unitful quantities, symbols, ordinary host arrays, and
other ergonomic host values. They are not device objects.

### Validated Semantic Model

Validation resolves the authoring model into one normalized semantic model. It contains explicit:

- Owner and property schemas
- Component categories
- Spatial relation roles
- Metric descriptors
- Field geometry and interpolation
- Rule phases, reads, writes, and effects
- RNG streams and semantic draw identities
- Lifecycle transactions
- Algorithm capability requirements
- Units and parameter conversions
- Compatibility and approximation claims

No backend is selected by this layer. Two authoring models that normalize to equal semantic models
have the same scientific meaning within the declared numerical policy.

### Compiled Model

Compilation lowers the semantic model to concrete schemas, indices, descriptors, schedules, and
callable operations suitable for CorePotts. A compiled model is backend-adaptable but has no
unresolved symbol lookup, unit conversion, abstract container, or ambiguous effect.

Compilation MUST NOT invent missing scientific choices. It either applies a documented named preset
or reports a source-located validation error.

## Closed Rule Language

The portable rule language is closed by default. Every syntax form and operation must lower to a
registered semantic node. An unknown call or expression is an error; it is never passed through as
arbitrary Julia code.

The initial portable subset SHOULD include:

- Numeric and Boolean literals
- Symbolic property and parameter references
- Arithmetic and comparison
- Boolean short-circuiting
- Conditional expressions
- Registered pure scalar functions
- Named spatial queries
- Named random distributions
- Explicit current-value access
- Explicit no-change result

Unbounded loops, recursion, exception handling, I/O, task creation, reflection, mutation through
aliases, dynamic allocation, and runtime method definition are outside the portable rule language.
Bounded iteration MAY be added through typed combinators or statically bounded constructs after its
effect and GPU contract is accepted.

The accepted Level 1 inventory and control-flow boundary are defined below. The exact initial list
of registered mathematical methods remains a release inventory rather than an open semantic design.

## Julia-First Level 1 Rule Language

Status: Accepted

### Governing style

Level 1 rules resemble ordinary mathematical Julia. Existing Julia syntax, functions, multiple
dispatch, immutable values, and keyword arguments are preferred over custom operators or
configuration data structures.

Metaprogramming is limited to syntax that must be captured before Julia evaluates it. `@rule` and
`@rules` are thin macros that record source information and pass syntax to ordinary parser and
builder functions. They do not generate GPU kernels, define runtime methods, select a backend, or
execute the rule.

Every macro form has an ordinary programmatic representation. A constructed rule is an immutable,
reusable, displayable, inspectable value.

### Scalar rule shape

The accepted Level 1 shape is mathematically assignment-like:

```julia
growth = @rule target_volume(cell) =
    target_volume(cell) + growth_rate(cell)
```

The outer left-hand side declares one output. It does not perform immediate Julia mutation. The same
property call on the right-hand side reads the phase snapshot.

A property reference is a typed callable authoring value. Within a rule, `volume(cell)` means the
snapshot value of `volume` for the rule owner represented locally by `cell`. It is not indexing into
a backend array.

The owner argument is locally bound by the rule and may use another valid identifier. It cannot
escape into runtime host state. Rule attachment separately declares whether the owner scope is one
cell type, several types, a biological role, a medium domain, or another supported owner category.

### Simultaneous and sequential rules

Several outputs may be declared in one named phase:

```julia
growth = @rules phase = :growth begin
    target_volume(cell) = target_volume(cell) + growth_rate(cell)
    age(cell) = age(cell) + 1
end
```

All right-hand sides read one snapshot and commit together. Source order inside the block has no
semantic effect.

Sequential behavior uses separate named phases with explicit ordering or dependencies. Reordering
source lines, declarations, or container elements never creates sequential behavior.

The precise keyword spelling for phase dependencies remains subject to final API review, but phase
identity and ordering are explicit model data.

### Property, parameter, and law calls

Typed authoring values use natural call syntax according to their scientific ownership:

```julia
volume(cell)
growth_rate(cell)
temperature(model)
adhesion(type_a, type_b)
```

A per-cell property, cell-type parameter, global parameter, field, query, and pairwise law remain
different types even when their values share a Julia numeric type. Multiple dispatch implements
their construction and validation without making scientific meaning depend on accidental method
ambiguity.

### Accepted expressions

Level 1 initially accepts:

- Numeric, Boolean, enum-like, tuple, and small fixed-value literals
- Typed model references and explicitly interpolated host values
- Arithmetic and comparison
- Chained comparisons where their Julia meaning is preserved
- `if`, `elseif`, `else`, ternary expressions, and `ifelse`
- `&&`, `||`, and `!` with Julia short-circuit behavior
- `begin` and `let` blocks with local bindings
- Accepted function calls and keyword arguments
- Small tuple and StaticArray operations
- Registered random draws
- Registered spatial queries and reductions
- `NoChange()` and schema-permitted `missing`

The final value of an expression block is the rule result, as in ordinary Julia. Early `return`,
`break`, `continue`, exception handling, tasks, I/O, reflection, method definition, and mutation of
model state are not Level 1 constructs.

Plain local assignment inside a right-hand-side block creates a local calculation. Only the outer
left-hand side captured by `@rule` or an entry in `@rules` declares a model-property output.

### Mathematical functions

Appropriate methods of ordinary Julia functions are used directly. The initial supported inventory
includes, for suitable types and numerical policies:

- `+`, `-`, `*`, `/`, and `^`
- `min`, `max`, and `clamp`
- `abs`, `sqrt`, `exp`, and `log`
- Trigonometric functions
- `dot` and `norm`
- Operations on small fixed vectors

PottsToolkit does not create parallel names such as `PottsExp`. Acceptance is method-specific: the
function, argument types, units, domain, numerical behavior, and device support must all conform.

Users define helpers as ordinary Julia functions or immutable callable structs. Level 2 can accept
suitable typed callables through its ordinary Julia interface. A custom function used by serializable
Level 1 syntax is registered explicitly with stable identity, version, type and unit rules, domain,
reference behavior, and device behavior.

Registration is fundamentally an ordinary Julia function. A thin optional macro MAY capture a name
and source location. Merely importing a function or having an applicable method does not register it
for Level 1 and cannot silently change model meaning.

### Host interpolation

Julia interpolation syntax explicitly captures host values:

```julia
rate = 0.05
rule = @rule target_volume(cell) = target_volume(cell) + $rate
```

The value at construction time becomes part of the authoring model. No global or host lookup occurs
during simulation. Bare unresolved names do not capture globals implicitly.

An ordinary mutable array cannot be interpolated directly. Arrays and other resources enter through
typed immutable parameters, fields, or registered read-only resources with defined identity,
adaptation, mutation, and serialization behavior.

### Random draws

Level 1 uses familiar `rand` syntax with Potts.jl semantic RNG behavior:

```julia
@rule polarity(cell) = rand(UnitVector(2); label = :new_polarity)

@rule division_time(cell) =
    rand(Normal(mean_time(cell), std_time(cell)); label = :division_time)
```

This syntax never invokes Julia's default or task-local RNG. The distribution descriptor, owner,
rule, phase, MCS, and optional label contribute to the accepted semantic address.

A label is optional only when the draw has one stable unambiguous identity. It is required when an
identity would otherwise be ambiguous. Publication-oriented diagnostics encourage explicit labels
where they improve edit-stable provenance.

Level 1 users do not pass an RNG object. Lower levels MAY expose addressed RNG objects and functions
under the accepted randomness contract.

### No change and missingness

`NoChange()` explicitly reports that no update occurred. `nothing`, `missing`, a failed rule, and
returning the old value are not synonyms.

Returning the old snapshot value is a successful write of that value. `NoChange()` records no write;
the distinction may appear in diagnostics, effect handling, and downstream scheduling.

Ordinary Julia `missing` is accepted only for a property schema that explicitly permits missingness.
Device storage MAY compile it to another representation without changing its public meaning.

### Spatial collections and reductions

Neighbor queries produce lazy bounded scientific collections, not allocated vectors. They support
familiar reductions such as:

- `sum`
- `mean`
- `minimum` and `maximum`
- `count`
- `any` and `all`
- An explicitly supported `mapreduce`

Query options use readable keyword arguments for relation, filters, weighting, metric, and empty
behavior. A scientifically meaningful option has no implicit default unless it belongs to a named,
versioned preset.

General user-written iteration over neighbors or populations is not accepted in Level 1 initially.
Level 2 and CorePotts extensions may use ordinary loops when bounds, storage, and device behavior are
valid.

### Loops, comprehensions, broadcast, and indexing

`while` and general `for` loops are not Level 1 constructs. A future version MAY admit finite
iteration over tuples, static axes, or other compile-time-bounded values after demonstrated use cases
and device tests.

Comprehensions that create dynamic collections are rejected. Small fixed tuple construction MAY be
added explicitly.

A scalar cell rule is already applied across its owner population, so broadcasting is not its
population-iteration mechanism. Broadcast remains available for genuinely small accepted fixed
values where it retains ordinary Julia meaning.

Indexing is accepted for tuples, StaticArrays, and declared read-only tables with validated bounds.
Arbitrary indexing into engine state or backend arrays is not a Level 1 operation. Mutable local
arrays are initially excluded; Level 1 favors immutable fixed-size calculations.

### Multiple writers and combination

Two rules cannot write the same property in one phase unless an explicit combination law is
declared. Common laws MAY use ordinary operators such as `+`, `min`, or `max` when registered for the
types involved. Priority is a separately named policy.

A combination law declares its identity and required algebraic properties. Associativity,
commutativity, determinism, and safe reordering are never inferred merely because a Julia function
is callable.

### Runtime failures and assertions

Host-detectable invalid constants, units, types, and domains fail during validation. Exceptions are
not Level 1 simulation control flow.

A device-time domain or bounds failure uses the accepted device error mechanism and aborts the
affected transaction without partial writes. A future debugging assertion must define GPU,
transaction, and reporting behavior; assertions are not required for ordinary model validity.

### Types, units, and output conversion

Julia inference and promotion are used where their scientific meaning is unambiguous. Consequential
ambiguity is an error.

Exact safe conversion MAY be automatic. Numeric narrowing, integer rounding, saturation, unit
conversion, missing-value conversion, and precision loss require an explicit accepted policy. Rule
output does not blindly call `convert` and accept any available user method as scientific meaning.

### Reference evaluation and display

Every rule has an ordinary host reference evaluator for small tests and examples. Scientists can
evaluate rule meaning without starting a simulation or compiling a GPU kernel.

`show(rule)` displays a concise readable target, owner scope, phase, and expression. Detailed
inspection separately reports reads, writes, units, random draws, spatial queries, dependencies,
capabilities, and lowering information. Ordinary display does not print compiler internals.

## Rule Targets and Results

A property update rule targets exactly one declared property and evaluates to one of:

- A value convertible under the property's explicit conversion policy
- `NoChange`, preserving the snapshot value
- A typed error produced during validation or execution

`nothing` MUST NOT ambiguously mean both missing data and no change. The primary API uses an explicit
`NoChange` semantic node.

Ordinary rules do not mutate arbitrary state. Assignment syntax, if offered as sugar for a model
block, lowers to explicit rule targets rather than device-side mutation statements.

Lifecycle actions, field source accumulation, tracker commits, and ordinary property updates are
distinct effect categories.

## Snapshot and Commit Semantics

All rules in one declared evaluation phase read the same immutable snapshot of:

- Lattice ownership
- Cell and medium properties visible to that phase
- Derived query buffers
- Spatial fields and their time stamps
- Public simulation time

Every rule output is evaluated before any output in that phase becomes visible. After successful
evaluation and conversion, outputs commit simultaneously as one property transaction.

Consequently, if rules target `a` and `b`, the rule for `b` reads the old `a`, not the newly computed
`a`. Sequential behavior requires two explicitly ordered phases.

If one output fails validation or execution under the selected error policy, the phase MUST NOT
partially commit for that owner.

The model report lists phase order, synchronization points, and visible state.

## Types, Units, and Conversion

Every property and parameter has a declared semantic type. Device storage types are compiled
representations rather than the public scientific type.

Host-side unitful quantities are checked before lowering. Unit conversion, numeric narrowing,
rounding, saturation, overflow handling, and missing-value behavior are explicit policies. In
particular:

- Integer targets are not silently rounded.
- Floating-to-integer conversion requires a named rule.
- Overflow follows the numerical contract.
- `missing`, `NoChange`, and numerical zero are distinct.
- Type instability in authoring code does not authorize dynamic device dispatch.

## Symbol and Property Resolution

Cell types, media, properties, fields, relations, and components are referenced symbolically in the
authoring model. Validation resolves each reference in lexical model scope and reports unknown,
ambiguous, or category-incompatible names.

Dense device indices are generated only after validation. Users MUST NOT need to encode a cell type,
medium, property, or RNG stream as a magic integer.

Property reads declare whether they target:

- The current finite cell
- Another explicitly identified finite cell
- A cell type parameter
- A medium or wall domain parameter
- Global model state
- A field sample

An integer cannot ambiguously represent both cell identity and cell type.

## Spatial Queries

Portable rules use the explicit query vocabulary defined by
[Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md):

- `contact_edge_count`
- `contact_measure`
- `boundary_site_count`
- `neighbor_cells`
- `neighbor_cell_count`
- `neighbor_property_sum`
- `neighbor_property_mean`
- `global_interface_measure`

Each query records its relation, filter, aggregation, metric, empty behavior, and result type in the
semantic model. Equivalent query descriptors are interned and computed once per snapshot when
profitable. Interning MUST NOT change query meaning or visibility.

The compiler derives spatial dependencies from semantic query nodes, not by rediscovering them from
generated Julia code.

## Random Expressions

Every stochastic expression is a typed semantic node containing:

- Distribution family and parameters
- RNG stream
- Rule and event identity
- Semantic phase
- Draw identity
- Result type and domain

The compiler assigns distinct addressed random coordinates to distinct draw nodes. Multiple calls to
`rand` or another distribution in one rule MUST NOT reuse one numeric offset accidentally.

Users MAY provide a stable draw label when reproducibility should survive unrelated edits to the
rule. Duplicate labels in one semantic scope are validation errors.

Random expression lowering follows
[Randomness and Reproducibility](randomness-and-reproducibility.md). A source-code traversal counter
alone is insufficient checkpoint provenance unless its canonicalization version is recorded.

Distribution parameters are validated before execution when possible. Invalid runtime parameters
follow the declared transaction error policy and never silently clamp.

## Scalar Functions and Purity

A portable scalar function must be registered with:

- Symbolic name and version
- Argument and result type rules
- Unit rules
- Purity and effect classification
- Domain restrictions
- Host reference implementation
- Device-lowering implementation or proof of portable ordinary dispatch
- Backend support
- Differentiability metadata when claimed
- Numerical conformance level

Calling an arbitrary function merely because it exists in the macro invocation module is forbidden.
Registration does not imply scientific validity; model-level capability checks still apply.

## Interpolation of Host Values

Syntax interpolation captures a host value into the authoring model. It does not splice arbitrary
runtime code directly into a device kernel.

An interpolated value must lower to one of:

- An immutable scalar or small isbits value
- A symbolic model reference
- A validated parameter object
- A backend-adaptable read-only resource with explicit identity

Captured mutable host objects, functions with unchecked closure environments, pointers, I/O handles,
and backend-specific arrays are rejected by the portable path unless a registered lowering handles
them.

The compiled model report records interpolated semantic values or stable resource fingerprints. It
MUST NOT expose secrets or irrelevant host object internals.

## Events and Effects

Triggers are pure predicates over one declared snapshot. Actions are typed effects. The following
remain distinct:

- Property transaction
- Type transition
- Birth or division
- Death or retirement
- Field source or sink accumulation
- Observation
- Termination request

Event conflicts and lifecycle commits follow
[Lifecycle](lifecycle.md). Event ordering, schedules, and RNG identity are explicit. A closure that
mutates cell data directly is not a portable action.

## Portability and Capability Profiles

Every semantic node declares capability requirements. Model compilation produces a capability
profile covering:

- Dimension and topology family
- Required numerical types
- Atomics and reductions
- Field interpolation
- Dynamic memory requirements
- Backend support
- Determinism and reproducibility
- Equilibrium compatibility
- Differentiability

A model unsupported on a selected backend fails before MCS execution. Silent host fallback inside a
GPU solve is forbidden.

## Nonportable and Expert Rule Paths

This section concerns rules embedded in a PottsToolkit semantic model. It does not classify direct
use of the public CorePotts scientific or execution APIs as an escape hatch.

### Host Rule

A host-only rule MAY use ordinary Julia under a named `HostRule` interface. It synchronizes only at a
declared boundary, is excluded from zero-synchronization GPU claims, and is labeled host-only in the
model report. This is an explicit nonportable escape hatch and reduces guarantees visibly.

### Expert Device Rule

An expert device rule supplies registered read/write footprints, capabilities, reference behavior,
and backend compilation evidence. It bypasses friendly syntax but not semantic effect, RNG,
transaction, or provenance requirements.

An expert device rule is a first-class advanced interface when it satisfies these contracts. It MAY
have a narrower declared backend capability set, but it does not receive weaker scientific
correctness requirements. It is not accepted merely because a closure is `isbits`.

Detailed third-party registration, expert-rule stability, and host escape-hatch behavior remain
under `SEM-DSL-004`.

## Diagnostics

Every validation and lowering error includes, where applicable:

- Source file and line
- Rule, component, and model path
- Offending syntax or semantic node
- Expected and actual types or units
- Backend or capability involved
- A concise correction

Errors are reported at the earliest layer with enough information to fix the authoring model. Raw
GPU compiler errors are supplemented with the originating semantic node and source location.

Warnings are reserved for valid but scientifically consequential choices. Unsupported semantics are
errors, not warnings followed by approximation.

## Model Report and Fingerprint

The normalized model report includes:

- Rule phases and targets
- Read/write/effect sets
- Spatial and field dependencies
- Random streams and draw labels
- Function and IR-node versions
- Unit and storage lowering
- Compatibility choices
- Backend capability profile
- Host-only or expert escape hatches
- Approximations and evidence status

A semantic fingerprint is derived from normalized meaning rather than raw authoring syntax. Its exact
cache and checkpoint stability contract remains under `SEM-DSL-005`.

## Conformance Requirements

- Macro and programmatic APIs normalize to equal semantic models.
- Equivalent syntax produces equal typed IR and reports.
- Unknown syntax and functions fail with source-located errors.
- Multiple outputs observe one snapshot and commit simultaneously.
- No rule phase partially commits after failure.
- Every stochastic node has a unique semantic RNG address.
- Spatial dependencies match the normalized query nodes.
- Host reference evaluation equals CPU and supported GPU lowering within the numerical contract.
- Unsupported backends fail before simulation work begins.
- Host-only rules create visible synchronization and provenance.
- Model reports contain all observable semantic choices.

## Current API Migration

The current `@rule` implementation is a prototype and is not authoritative. Migration must replace:

- Arbitrary AST fallthrough with a closed parser
- Closure-first compilation with typed semantic IR
- Reused numeric RNG offsets with semantic draw identities
- `nothing` as no-change with explicit `NoChange`
- Ambiguous spatial query names with the accepted query vocabulary
- Late `isbits` validation with staged semantic and backend validation
- Direct mutation actions with typed effects and transactions

Existing syntax MAY be retained where it lowers unambiguously to the new model. Historical behavior
that violates an accepted semantic contract is removed rather than preserved silently.

## Literature and Language Basis

- [Julia metaprogramming and macro hygiene](https://docs.julialang.org/en/v1/manual/metaprogramming/)
- [Julia performance and specialization guidance](https://docs.julialang.org/en/v1/manual/performance-tips/)
- [KernelAbstractions kernel programming](https://juliagpu.github.io/KernelAbstractions.jl/stable/kernels/)
- [CUDA.jl kernel compilation requirements](https://cuda.juliagpu.org/stable/development/kernel/)
