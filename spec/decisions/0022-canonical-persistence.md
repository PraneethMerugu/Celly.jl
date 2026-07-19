# Decision 0022: Completed-MCS Canonical Persistence

Status: Accepted

Date: 2026-07-19

## Context

Snapshots, checkpoints, and persistence requirements were distributed among RNG, SciML, and roadmap
documents. Without one canonical contract, a backend workspace or Julia serializer could
accidentally become the durable scientific format. Capturing arbitrary in-flight GPU execution
would also require storing backend-specific temporary state with little paper value.

## Decision

Stable checkpoints are created only at finalized MCS `0` or after a completed positive integer MCS.
Mid-MCS and partially committed capture are outside the paper contract. Replaceable workspaces,
caches, kernels, queues, and device machinery are reconstructed rather than serialized.

Snapshots and checkpoints are distinct immutable semantic values. A snapshot contains selected
observable state. A checkpoint contains or identifies all state required by one declared exact-
continuation profile.

Every checkpoint uses a versioned backend-independent canonical logical schema with state,
identities, generations, auxiliary values, model/schema fingerprints, algorithm and RNG contracts,
numerical requirements, ancestry, provenance, and integrity checks. Raw Julia object serialization
is not a durable paper format.

The minimum restore API accepts a compatible explicit problem or model and verifies its fingerprint.
Standalone reconstruction is available only when every component provides qualified semantic
serialization. Arbitrary extension objects are never silently omitted.

Exact resume requires a validated compatible profile. A changed backend, device constraint,
numerical mode, algorithm, or incompatible environment is an explicit logical import with rebuilt
derived state and execution machinery, preserved ancestry, and a reported weaker guarantee unless a
stronger profile has been proven.

CorePotts owns one logical reader-writer protocol. HDF5 and Zarr are thin Julia package extensions
over the same canonical in-memory contract and share one conformance suite.

## Consequences

- Persistence is portable scientific data rather than a memory dump.
- GPU workspaces and scheduling do not become public compatibility obligations.
- Exact continuation claims remain narrow, testable, and honest.
- Custom scientific extensions remain usable without requiring arbitrary executable serialization.
- HDF5 and Zarr do not become competing simulator architectures.
- Mid-MCS checkpoint complexity is deferred without weakening completed-MCS research workflows.

## Alternatives Considered

- Serialize the complete integrator or compiled backend state with Julia `Serialization`.
- Support checkpoint capture at arbitrary kernel or internal-round positions.
- Treat every saved observation as resumable.
- Reconstruct arbitrary extension types from names without a compatible model.
- Maintain separate logical schemas for HDF5 and Zarr.
- Silently resume exactly after changing execution profile.

These alternatives weaken durability, portability, integrity, or the meaning of exact continuation.

## Required Conformance Evidence

- Completed-MCS boundary and in-flight rejection tests.
- Same-profile uninterrupted-versus-restored trajectory equality.
- Cache/workspace reconstruction and full invariant validation.
- Fingerprint compatibility, explicit import, ancestry, and guarantee-report tests.
- Corruption, incomplete publication, unknown version, and capacity mismatch failures.
- Canonical equality and shared conformance across in-memory, HDF5, and Zarr storage.
- Optional-dependency/package-extension loading and clean CorePotts dependency tests.
- Paper-workload save/load performance and storage-size reports.
