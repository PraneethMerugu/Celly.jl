# Unresolved Semantic Questions

Status: Under Investigation

This registry prevents open questions from being silently resolved by implementation convenience.
Identifiers remain stable when a question is moved into an accepted specification or decision
record.

## Randomness and Reproducibility

Public seed ownership, named semantic streams, scheduling-independent draws, distribution contracts,
checkpoint requirements, and cross-backend raw-stream guarantees are accepted in
[Randomness and Reproducibility](randomness-and-reproducibility.md).

### SEM-RNG-004: Algorithm trajectory-reproducibility profiles

Classify each algorithm by whether identical trajectories are guaranteed across workgroup sizes,
device models within one backend family, deterministic optimization changes, and package versions.
This classification must account for reductions, atomics, floating-point modes, and state races in
addition to random-number generation.

### SEM-RNG-005: Portable distribution transforms

Select and validate the exact normal, Poisson, permutation, bounded-integer, and categorical
transforms. Specify which transforms are bitwise portable and which are only statistically portable.

### SEM-RNG-006: Default generator implementation

Validate Philox4x32-10 performance, compilation, known-answer vectors, and raw-bit identity on CPU,
CUDA, Metal, and AMDGPU before making it the accepted default implementation.

## Energy, Proposals, and Trackers

The neighbor-site proposal ratio, conventional and Metropolis-Hastings acceptance, zero-temperature
limits, component taxonomy, local/global energy law, and tracker transaction are accepted in
[Energy, Proposals, Acceptance, and Trackers](energy-proposals-and-trackers.md).

### SEM-ENG-004: Symmetric distinct-neighbor proposal

Derive the exact selection probability, reverse-support conditions, extinction behavior, and
connectivity requirements for a proposal that samples distinct neighboring owner identities.

### SEM-ENG-005: Conservative field couplings

Classify chemotaxis and other field interactions into globally integrable Hamiltonian couplings and
nonconservative directional drives, including saturation and extension/retraction variants.

### SEM-COMP-001: Cross-simulator conversion registry

Validate versioned CC3D, Morpheus, and Artistoo parameter conversions, acceptance variants,
neighborhood conventions, and fixture corpora before advertising compatibility presets.

## HST Semantics

### SEM-HST-001: Augmented Hamiltonian

Derive and document the augmented Hamiltonian and stationary distribution for each HST family.

### SEM-HST-002: MCS integration

Define the stochastic integration scheme, operator splitting, noise variance, and algorithm-
independent substep policy.

### SEM-HST-003: Lifecycle distributions

Derive division, transition, death, and initialization distributions for HST auxiliary state.

## Topology

### SEM-TOP-001: Neighborhood purposes

Resolved by [Topology and Spatial Relations](topology-and-spatial-relations.md): lattice geometry,
domain, proposal, energy, surface, connectivity, spatial-query, field, and conflict relations are
separate semantic roles.

### SEM-TOP-002: Offset ordering and weights

Resolved in part by [Topology and Spatial Relations](topology-and-spatial-relations.md): explicit
stencils, distance-shell constructors, canonical direction ordering, relation-specific weights,
periodic displacement, and alias rejection are accepted. Numerical quadrature choices remain under
`SEM-TOP-004`.

### SEM-TOP-003: Custom topology interface

Resolved in part by [Topology and Spatial Relations](topology-and-spatial-relations.md): custom
regular stencils and explicit graph lattices are separate compiled families with common relation
laws. Detailed graph capabilities remain under `SEM-TOP-007`.

### SEM-TOP-004: Surface quadrature and isotropy presets

Resolved semantically by
[Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md): raw, weighted,
normalized-kernel, and physical measures are separate; the literature-backed normalized-kernel
family is the native reference; Crofton estimators remain Experimental. Exact calibration tables
and anisotropy results are required conformance evidence rather than open semantics.

### SEM-TOP-005: Obstacles and exterior ownership

Resolved for the paper Cartesian engine by
[Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md). Arbitrary custom
boundaries remain Deferred.

### SEM-TOP-006: Hexagonal geometry

Define canonical 2D hexagonal and 3D rhombic-dodecahedral coordinates, boundaries, site measures,
distance shells, direction IDs, and compatibility conversions.

### SEM-TOP-007: Irregular and graph lattices

Define graph construction, embedding, edge measures, proposal probabilities, boundary meaning,
device representation, and statistical conformance for experimental graph-lattice CPMs.

### SEM-TOP-008: Spatial-query relations

Resolved for the core query vocabulary by
[Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md). Additional query
operators require their own explicit aggregation semantics.

### SEM-TOP-009: Field-discretization relations

Resolved for field identity, geometry, sampling, boundary independence, and immutable transaction
snapshots by [Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md).
Operator splitting, secretion, uptake, and PDE substeps remain under the SciML coupling phase.

## Algorithms

### SEM-ALG-001: Checkerboard equilibrium guarantee

Determine whether each checkerboard algorithm preserves the intended invariant distribution in the
presence of shared cell-wide state.

### SEM-ALG-002: Lottery equilibrium and kinetic guarantee

Derive or statistically characterize expected-budget lottery sampling and normalized MCS kinetics.

### SEM-ALG-003: Intrinsic implementation equivalence

Determine the exact operation implemented by subgroup reductions and establish equivalence to a
named generic algorithm before making scientific claims.

## PottsToolkit Rule Language

### SEM-DSL-001: Rule snapshot behavior

Resolved by
[PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md): all outputs in one
rule phase read one snapshot and commit simultaneously after successful validation.

### SEM-DSL-002: Supported language subset

Resolved by the accepted Julia-first Level 1 language in
[PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md). Rules use thin
`@rule`/`@rules` syntax over ordinary builders, callable typed references, Julia conditionals and
local expressions, explicit interpolation, semantic `rand`, lazy query reductions, and no general
dynamic loops or collections. The exact registered method list is maintained as a release inventory.

### SEM-DSL-003: Spatial query definitions

Resolved for the core vocabulary by
[Cartesian Surface, Queries, and Fields](cartesian-surface-queries-and-fields.md) and incorporated
into [PottsToolkit Rule and Model Semantics](pottstoolkit-rule-and-model-semantics.md).

### SEM-DSL-004: Extension and escape-hatch contract

Finalize registration, versioning, capability declarations, source diagnostics, and portability
guarantees for third-party IR nodes, registered scalar functions, host-only rules, and expert device
rules.

### SEM-DSL-005: Compilation cache identity

Define the stable semantic fingerprint used for compiled-model caches, checkpoints, provenance,
precompilation, and invalidation across Julia, package, extension, and backend versions.

### SEM-DSL-006: Authoring and composition architecture

Resolved by
[PottsToolkit Authoring, Composition, and API Semantics](pottstoolkit-authoring-composition-and-api-semantics.md):
macros are optional sugar over a complete programmatic interface; models are immutable; declarations
are order-independent outside explicit phases; fragments are namespaced and composable; validation
is staged; inspection and semantic serialization are required; and DSL/IR versions are independent
of package versions. PottsToolkit DSL and typed authoring forms share normalized semantic IR;
CorePotts remains an independently usable, first-class scientific and execution API governed by the
same scientific contracts rather than forced through PottsToolkit IR.

### SEM-DSL-007: Exact surface syntax and usability contract

Define the concrete grammar, programmatic constructor names, fragment binding syntax, rule and phase
spelling, canonical displays, IDE expectations, and deprecation/migration experience. Surface syntax
must realize `SEM-DSL-006` and normalize to the accepted semantic model. The Level 1 rule-language
shape and behavior are now accepted; remaining work concerns top-level model declarations, final
constructor and phase-dependency names, fragment spelling, canonical formatting, and migration.

## CorePotts Public Interfaces

### SEM-API-001: Scientific and execution extension protocols

Resolved by
[CorePotts Public Scientific and Execution Interfaces](corepotts-public-interface-semantics.md).
CorePotts uses meaningful scientific categories, immutable structs, ordinary public functions,
multiple dispatch, typed requirements and capabilities, stable state accessors, reference behavior,
package extensions, centralized workspaces, preflight validation, and category conformance helpers.
Direct CorePotts use is first-class and does not require PottsToolkit authoring IR.

## SciML Integration

### SEM-SCI-001: Supported SciMLBase contract

Resolved by
[SciML Problem, Integrator, Solution, and Ensemble Semantics](sciml-interface-semantics.md):
Potts problems and solutions participate in SciMLBase; `solve` is behaviorally `solve!(init(...))`;
public stepping uses integer MCS; `remake`, callbacks, saving, return codes, and ensembles follow the
accepted Potts-specific SciML contract.

### SEM-SCI-002: Observation synchronization

Resolved by
[SciML Problem, Integrator, Solution, and Ensemble Semantics](sciml-interface-semantics.md): host
callbacks and observations synchronize only at declared MCS boundaries when their requested data
requires materialization; qualified device observations may remain resident; displays never trigger
hidden synchronization.

## Persistence and Initialization

### SEM-IO-001: Snapshot versus checkpoint

Define synchronized snapshots, exact continuation checkpoints, backend-independent restart, schema
fingerprints, and RNG state.

### SEM-IO-002: Storage equivalence

Define logical equivalence among memory, Zarr, HDF5, and future output backends.

### SEM-INIT-001: Coordinate and rasterization semantics

Define public coordinate indexing, shape rasterization, random-layout sampling, periodic placement,
and initial HST state.

## Numerical and Backend Semantics

### SEM-NUM-001: Precision policy

Resolved by
[Numerical and Cross-Backend Semantics](numerical-and-cross-backend-semantics.md): generic Julia
source lowers to concrete compiled types; the visible portable default is `Float32`; explicit wider
precision is preserved or rejected; storage, accumulation, integer widths, overflow, mixed precision,
and conversions are governed by a typed numerical policy.

### SEM-NUM-002: Cross-backend conformance

Resolved by
[Numerical and Cross-Backend Semantics](numerical-and-cross-backend-semantics.md): exact integers,
raw RNG output, semantic IDs, schedules, and canonical topology data match bit-for-bit; floating
state follows per-quantity numerical, invariant, trajectory, or statistical contracts; every
release backend runs the same visible conformance matrix.

### SEM-NUM-003: Reduction ordering

Resolved by
[Numerical and Cross-Backend Semantics](numerical-and-cross-backend-semantics.md): every reduction
defines types, initial and neutral values, empty behavior, algebraic requirements, and ordering;
deterministic state-affecting reductions fix the contracted grouping independently of workgroup
decomposition; schedule-dependent floating atomics are excluded from strict paths.
