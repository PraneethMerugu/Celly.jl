# Project Charter

Status: Accepted

## Mission

Potts.jl is a scientific simulation ecosystem for Cellular Potts Models. It is intended to combine
three equal identities:

1. A scientifically trustworthy modeling library
2. A world-leading high-performance simulation engine
3. An approachable biological modeling environment

The ecosystem MUST remain architecturally hardware agnostic. Until superseded by an accepted
semantic decision, the first-class release contract is CPU, Apple Metal, and AMD ROCm. NVIDIA CUDA
remains a deferred integration: its code MAY remain available for development, but it MUST NOT be
included in support, correctness, performance, or release claims. Stable scientific features MUST
support both two- and three-dimensional models unless explicitly documented otherwise.

## Primary User Experience

PottsToolkit is the primary public modeling interface. It SHOULD allow computational biologists,
statistical physicists, HPC researchers, and Julia developers to express models without depending
on CorePotts internals.

PottsToolkit acts as a high-level declarative language and model compiler for CorePotts. It MUST
provide an ergonomic path for ordinary users without preventing advanced users from extending or
using CorePotts directly.

## Core Engine

CorePotts defines the scientific execution contracts, fundamental state model, reference engine,
optimized engines, and extension interfaces. It MUST remain usable independently of visualization
and experimental neural-model packages.

Optimized execution MUST be judged against explicit scientific contracts. Performance improvements
MUST NOT silently redefine model behavior.

## SciML Integration

Potts.jl targets genuine SciML semantic integration rather than a merely SciML-shaped API. The
eventual stable interface is expected to support the applicable `solve`, `init`, `step!`, callback,
ensemble, saving, remake, termination, return-code, and solution conventions.

The exact supported SciML contract remains under investigation and MUST be established using the
current SciMLBase interfaces.

## Algorithms and Scientific Guarantees

Potts.jl MAY provide both reference and approximate algorithms. They MUST be separately identified
and MUST report their equilibrium, kinetic, attempt-normalization, reproducibility, topology, and
backend guarantees.

The unqualified word "exact" MUST NOT be used as a technical guarantee. Documentation MUST instead
state whether an algorithm provides reference CPM kinetics, a proven invariant equilibrium
distribution, a reference-equivalent implementation, a statistically calibrated approximation, or
experimental behavior.

All user-visible algorithms MUST use comparable normalized Monte Carlo step units.

## Performance and Hardware Portability

The project aims to be the fastest Cellular Potts implementation while remaining scientifically
auditable and approachable. Performance claims MUST be supported by reproducible benchmarks.

Hardware portability means more than successful compilation. Each supported backend MUST be covered
by a capability policy, conformance tests, numerical expectations, and performance measurements.

Backend-specific code MAY optimize a shared semantic operation. Backend-specific behavior MUST NOT
become the implicit definition of that operation.

## Package Stability

The package boundaries are open to revision. PottsToolkit is the stable public destination;
CorePotts is the stable engine and extension destination. MakiePotts should consume stable
observation interfaces. NeuralPotts is an experimental satellite until the classical simulation
foundation and differentiation contracts mature.

Auxiliary constraint and fluctuating mechanical-state components are a defining project capability.
They MUST participate through the same extensible component, algorithm-capability, backend,
randomness, checkpoint, and lifecycle interfaces as other scientific families. Historical
`HST...Penalty` names and detailed-balance claims are not normative: the Hubbard-Stratonovich name
MUST be used only when a valid transformation has been derived. Equilibrium auxiliary constraints
and nonequilibrium fluctuating-pressure or fluctuating-tension mechanics MUST be separately named.

## Compatibility and Release Goal

The immediate target is a paper-quality research release. There are no external compatibility
requirements for the current redesign. Breaking changes are permitted when they materially improve
scientific correctness, API coherence, GPU execution, extensibility, or maintainability.

Metaprogramming is an implementation tool, not a goal. It MUST be evaluated by generated-code
quality, compilation latency, clarity, extensibility, and GPU suitability.

## Quality Principles

- Scientific semantics precede optimization.
- The sequential reference engine is the executable scientific baseline.
- Public APIs require documentation, validation, and extension examples.
- State mutations require explicit ownership and invariants.
- Semantic duplication is eliminated.
- Intentional hardware specialization is documented rather than hidden behind unsuitable
  abstractions.
- Tests validate laws and observable behavior rather than incidental struct layouts.
- Current behavior, intended behavior, and compatibility behavior are documented separately.
