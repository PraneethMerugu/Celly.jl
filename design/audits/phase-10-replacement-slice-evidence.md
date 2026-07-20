# Phase 10 Replacement-Slice Evidence

Status: Replacement slice complete; legacy deleted; superseded by the
[Phase 10 completion audit](phase-10-completion-audit.md)

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
| Focused immutable authoring, exact elongation, and vertical-slice tests | included in 129/129 PottsToolkit tests |
| Full PottsToolkit test suite | 129/129 pass on Julia 1.12.6 after legacy-test deletion |
| Full CorePotts test suite | 2,983 pass; one intentional broken research test |
| CPU qualification | 2D and 3D pass; direct/Core equality; 63/83 warm launches; zero warm synchronization, D2H transfer, and device allocation |
| Metal qualification | 2D and 3D pass with scalar indexing disabled; same semantic fingerprint and the same direct/Core equality and residency counters |
| ROCm qualification | Real AMDGPU PR CI and independently parsed schema `2.0.0` artifact pass for implementation/evidence head `a75e376` |
| Hosted and self-hosted CPU validation | Linux x86_64 and macOS ARM64 Julia 1.12.6 lanes pass at commit `a52bef0` |
| Documentation | Documentation build passes at commit `a52bef0` |
| Matched runtime structure | both paths are exactly `CorePotts.PottsProblem`; no PottsToolkit runtime wrapper |
| Inspection | structured construction/normalization/problem diagnostics, provenance, dependency/expansion reports, semantic/execution fingerprints, and non-executable semantic manifest |
| Legacy containment | Toolkit compiler absent; 19 frozen historical files, four mixed production signatures, 47 frozen consumer signatures, clean scientific path |

The benchmark matrix now writes schema `2.0.0` machine-readable evidence for all five families in
addition to the matched direct-Core comparison. Quantitative paper-hardware regression and native
resource budgets remain Phase 12, while Phase 15 owns emergent literature-result claims.

## Closure Result

1. The schema `2.0.0` benchmark-evidence commit was published.
2. Every package, integration, CPU, Metal, ROCm, documentation, integrity, and containment check
   passed for the implementation/evidence head.
3. The Metal and ROCm artifacts were downloaded and their schema and enforced invariants were
   independently verified.
4. The completion record was published and required to pass the same exact-head workflow set.

This document remains historical slice evidence. The completion audit is the authoritative Phase 10
verdict.
