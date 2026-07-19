# Decision 0017: Open Scientific Protocols with Concrete Device Lowering

Status: Accepted

Date: 2026-07-19

## Context

Potts.jl aims to be a high-performance, hardware-agnostic scientific library rather than a closed
application containing a fixed inventory of Cellular Potts features. The accepted specifications
largely use Julia types, functions, capabilities, and package extensions, but the current
implementation still contains behavioral enums, concrete `Union` signatures, `isa` ladders, and
central compiler switches. These constructs can accidentally make the first built-ins the permanent
scientific universe.

GPU execution creates a real constraint: kernels cannot rely on arbitrary runtime dispatch, host
callbacks, heap-backed policy objects, or unbounded allocation. That constraint does not require a
closed scientific API. Julia can specialize ordinary generic functions on concrete compiled policy
types after a host-side lowering boundary.

## Decision

Scientific invariants, transaction laws, controlled category taxonomies, versioned RNG encodings,
portable DSL syntax, and compatibility subsets MAY be closed when exhaustiveness is documented and
semantically necessary.

Scientific families and execution mechanisms are open protocols by default. A downstream package
adds a family member by defining owned types and methods on documented CorePotts functions. It does
not edit a central enum, concrete-family `Union`, `isa` switch, or mandatory runtime registry.

CorePotts separates host scientific openness from compiled execution. Model construction may use
ordinary flexible Julia values. Compilation validates and lowers them through a function barrier
into concrete, bounded, device-valid descriptors, tuples, groups, and workspaces. GPU kernels
specialize on those concrete values without dynamic device dispatch.

Direct CorePotts use relies on multiple dispatch. Registration is reserved for Level 1 DSL spelling,
semantic serialization, compatibility translation, and other durable naming boundaries.

Every stable extension protocol requires public validation and a downstream-style fixture. The
fixture must add a non-built-in implementation without modifying CorePotts and exercise reference,
compiled, and claimed backend behavior. Stable GPU-capable protocols require real CPU, Metal, and
ROCm compile-and-run evidence under the current backend contract.

The accepted implementation rules and audit gates are defined in the
[Open Protocol and Extensibility Standard](../../design/open-protocol-and-extensibility-standard.md)
and [Open-Protocol Audit](../../design/audits/open-protocol-audit.md).

## Consequences

- Required built-ins remain finite and paper-scoped without becoming exhaustive APIs.
- Phase 8 must revise lifecycle policies, division geometry, schedules/effects, and initialization
  before freezing their interfaces.
- Phase 9 must remove central algorithm-family dispatch and establish typed SciML extension paths.
- Phase 10 replaces PottsToolkit's provisional `Any`/dictionary/`isa` lowering rather than polishing
  it into the final compiler.
- Backend qualification remains strict even though the backend provider protocol is open.
- Open protocols do not imply arbitrary host callbacks or runtime GPU polymorphism.
- Conformance and bounded compilation behavior become part of the extension contract.

## Alternatives Considered

- Treat every current built-in list as exhaustive until a future feature forces redesign.
- Use a universal runtime plugin registry for all scientific behavior.
- Permit arbitrary host callbacks and silently fall back to CPU for unsupported GPU components.
- Expose one deep inheritance hierarchy spanning every component and capability.
- Delay extensibility review until the final API-freeze phase.

These alternatives either make extension require CorePotts edits, weaken GPU residency, obscure
scientific categories, or defer structural failures until the most expensive stage of the refactor.

## Required Conformance Evidence

- Zero-core-edit downstream fixtures for every stable scientific protocol.
- Zero-compiler-switch PottsToolkit Level 2 fixture for conforming CorePotts objects.
- Reference execution and invariant tests for every fixture.
- CPU plus claimed GPU compile-and-run tests with no hidden fallback or synchronization.
- Construction-time diagnostics for missing methods and incompatible capabilities.
- Ambiguity, inference, allocation, compile-latency, code-size, and device-resource checks before API
  freeze.
