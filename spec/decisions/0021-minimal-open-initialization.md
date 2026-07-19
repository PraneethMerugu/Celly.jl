# Decision 0021: Minimal Open and Deterministic Initialization

Status: Accepted

Date: 2026-07-19

## Context

CorePotts exposes an abstract layout shell, but current consumers branch on only the built-in cell
and medium layout types and encode overlap as a behavioral enum. A general source/rasterizer/placer
framework would avoid that switch at the cost of several speculative abstractions. Initialization
also occurs before runtime cell IDs exist, so declaration-order identities would make composition
and semantic RNG unstable.

## Decision

Initial layouts implement one minimal open Julia protocol: declare requirements and emit provisional
entity declarations plus ownership claims into compiler-owned storage. Generic engine code owns
validation, overlap resolution, empty-entity removal, deterministic runtime ID assignment, property
initialization, derived-state reconstruction, compiled lowering, and backend adaptation.

Each provisional entity has a stable semantic identity independent of declaration order, storage,
threads, and device scheduling. After overlap resolution, empty entities are removed and survivors
receive compact runtime IDs in canonical identity order. Rejected and empty entities receive no
runtime slot or property-initialization RNG identity.

Claims are logically unordered. Overlap rejects by default. The other required Phase 8 policy uses
explicit stable semantic priority and rejects ties. Replacement and preservation never mean first-
or last-declaration wins.

Property and auxiliary initialization occurs only after ownership, capacity, runtime IDs, and slot
generations finalize. Stochastic layout placement uses stable layout and provisional identities;
property initialization uses surviving runtime identity and generation.

Host-finalized and device-native initialization are explicit capabilities. Host finalization may
transfer the compiled state once before GPU execution and is not a hidden MCS fallback. Large
built-ins gain device-native paths when benchmark evidence justifies them. A custom layout need not
be a GPU kernel unless it claims device-native initialization.

## Consequences

- Masks, labels, coordinates, procedural layouts, and downstream layouts share one path.
- CorePotts does not acquire universal rasterizer, placer, file-loader, or manager hierarchies.
- Runtime IDs are compact implementation identities rather than layout authoring inputs.
- Equivalent layout declarations do not change meaning when reordered or parallelized.
- GPU MCS residency remains strict even when one-time initialization is host-finalized.
- Device-native and host-finalized implementations sharing one algorithm name must finalize the same
  canonical logical state under the accepted profile.

## Alternatives Considered

- Add a concrete-family branch for every supported layout.
- Build separate universal source, rasterizer, placer, resolver, and manager abstractions.
- Let array position or declaration order define runtime cell identity.
- Use first-write-wins or last-write-wins overlap behavior.
- Initialize properties before knowing which provisional entities survive.
- Require every custom layout to compile and execute directly on every GPU.

These alternatives either close extension, introduce speculative machinery, destabilize identity
and RNG, or unnecessarily constrain ordinary Julia construction workflows.

## Required Conformance Evidence

- Dense-label or mask, coordinate, and paper-required procedural-layout reference fixtures.
- One downstream custom layout added without a CorePotts source edit or mandatory registry.
- Declaration and emission-order permutation tests for ownership and compact runtime IDs.
- Overlap rejection, semantic-priority selection, and priority-tie diagnostics.
- Empty-entity and capacity-failure tests proving no slot or property RNG allocation.
- Canonical logical-state and RNG-address comparison between host and device-native implementations
  sharing one algorithm profile.
- CPU reference evidence and CPU, Metal, and ROCm compile-and-run evidence for every layout claiming
  device-native initialization.
- Construction time, peak memory, transfer, allocation, and compilation measurements before adding
  device-native specializations.
