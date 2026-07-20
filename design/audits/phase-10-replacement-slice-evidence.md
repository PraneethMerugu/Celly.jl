# Phase 10 Replacement-Slice Evidence

Status: CPU/Metal/ROCm replacement slice complete; legacy deletion gate open

Date: 2026-07-20

## Slice Under Test

The replacement slice is a Level 2 `PottsToolkit.Authoring.PottsModel` containing one medium,
one finite cell type, quadratic volume, unordered adhesion, fluctuating-volume mechanics, a custom
bounded cell property, two stochastic property transactions, and an independently defined external
CorePotts energy. It lowers to the one public `CorePotts.PottsProblem`; PottsToolkit owns no runtime
wrapper, kernel, workspace, or random state.

The same fixture runs in two and three dimensions. It exercises public initialization claims,
property-schema expansion, lifecycle effects, mechanical evolution, semantic RNG identities,
fingerprints, provenance, reports, and SciML initialization.

## Local Evidence

| Gate | Result |
| --- | --- |
| Focused immutable authoring and vertical-slice tests | 48/48 and 24/24 pass |
| Full PottsToolkit test suite | 354/354 pass on Julia 1.12.6 |
| Full CorePotts test suite | 2,908 pass; one intentional broken research test |
| CPU qualification | 2D and 3D pass; direct/Core equality; 63/83 warm launches; zero warm synchronization, D2H transfer, and device allocation |
| Metal qualification | 2D and 3D pass with scalar indexing disabled; same semantic fingerprint and the same direct/Core equality and residency counters |
| ROCm qualification | Fresh PR CI passes on the AMDGPU runner at commit `e551a9d`; the same package, integration, and project-integrity revision is green |
| Hosted and self-hosted CPU validation | Linux x86_64 and macOS ARM64 Julia 1.12.6 lanes pass at commit `e551a9d` |
| Documentation | Documentation build passes at commit `e551a9d` after resolving the Julia 1.12.6 documentation environment |
| Matched runtime structure | both paths are exactly `CorePotts.PottsProblem`; no PottsToolkit runtime wrapper |
| Inspection | structured construction/normalization/problem diagnostics, provenance, dependency/expansion reports, semantic/execution fingerprints, and non-executable semantic manifest |
| Legacy containment | signature gate passes; the accepted hard legacy-deletion gate is now open, but deletion is not yet complete |

The benchmark matrix now records construction, normalization, lowering, initialization, and
backend-synchronized warm-MCS timing separately. Its direct comparison is diagnostic at smoke size;
paper workload thresholds remain a separate Phase 10 completion requirement.

## Remaining Gates

1. Migrate every active root caller and test that still depends on the historical authoring path.
2. Delete the legacy compiler, temporary re-export surface, and unjustified root dependencies under
   the accepted hard legacy-deletion gate.
3. Qualify every required 10.5 component and the five 10.6 reference workloads on CPU, Metal, and
   ROCm, followed by paper-grade performance evidence.

This document is a checkpoint, not a claim that Phase 10 is complete.
