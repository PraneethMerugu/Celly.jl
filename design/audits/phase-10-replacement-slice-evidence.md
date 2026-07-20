# Phase 10 Replacement-Slice Evidence

Status: Local CPU/Metal evidence complete; ROCm CI and legacy deletion pending

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
| Matched runtime structure | both paths are exactly `CorePotts.PottsProblem`; no PottsToolkit runtime wrapper |
| Inspection | structured construction/normalization/problem diagnostics, provenance, dependency/expansion reports, semantic/execution fingerprints, and non-executable semantic manifest |
| Legacy containment | signature gate passes; legacy remains quarantined rather than deleted |

The benchmark matrix now records construction, normalization, lowering, initialization, and
backend-synchronized warm-MCS timing separately. Its direct comparison is diagnostic at smoke size;
paper workload thresholds remain a separate Phase 10 completion requirement.

## Remaining Gates

1. Run the identical qualification and benchmark lane on the ROCm runner.
2. Preserve that evidence at one committed revision.
3. Complete the final 10.2–10.3 breadth audit, then pass the hard legacy-deletion gate before adding
   broad component/workload coverage.
4. Qualify every required 10.5 component and the five 10.6 reference workloads on CPU, Metal, and
   ROCm, followed by paper-grade performance evidence.

This document is a checkpoint, not a claim that Phase 10 is complete.
