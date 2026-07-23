# Phase 13 Completion Audit

Status: In progress; local requirements proved, real-ROCm evidence and owner freeze approval pending

Date: 2026-07-23

This audit maps every Phase 13 roadmap deliverable and exit condition to current authoritative
evidence. “Pending” is not a pass, and an evidence result of `equivalence-fail` is preserved as a
scientific result rather than converted into an implementation failure or narrative success.

## Chunk completion

| Chunk | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| 13A | Independent primitive, sub-round, and normalized-MCS oracle; global-energy checks; hand derivation | `integration/transition/TransitionKernelOracle.jl`; 12 content-addressed records in `design/evidence/phase-13/exact/`; conformance independence guards | proved |
| 13B | Sequential declared-process and applicable reference obligations | exact sequential rows, production adapter checks, CPU/Metal v2 empirical rows | proved locally; ROCm empirical rows pending |
| 13C | Lifted production checkerboard characterization and evidence-supported label | exact lifted scheduler records; maximum TV `0.5625`; probability-current, spectral, relaxation, drift, and realistic analyses | characterization proved; final public metadata pending owner approval |
| 13D | Bounded fixtures and component admission | fixture manifest covers required von Neumann/Moore, periodic/no-flux, 2D/selected-3D strata; adhesion and volume admitted; exclusions explicit | proved |
| 13E | Preregistered CPU/Metal/ROCm transition rows and realistic ensembles | CPU and Metal transition 8/8; CPU v4 six identities; Metal v4 three identities; all fixed counts/seeds/source revisions | CPU/Metal proved; ROCm pending |
| 13F | Versioned archives, CI tiers, figures, stale-evidence detection | exact, empirical, realistic, diagnostic, device-code, and figure indices; semantic fingerprints and source checks; scheduled workflows | proved locally; ROCm workflow execution pending |
| 13G | API audit, quality gates, legacy removal, frozen identities, owner approval | exhaustive API inventory; package/conformance/docs/install/device-code checks; legacy closure; owner packet | candidate proved; ROCm, final status changes, and owner approval pending |

## Roadmap deliverables

| Deliverable | Proof | Result |
| --- | --- | --- |
| Independent finite-state oracle without production proposal/delta/conflict/commit reuse | oracle source, import-independence guard, hand-derived reproduction | complete |
| Verify sequential and characterize lifted checkerboard without inherited claims | exact archive and production adapter; discrepancy and mechanism records | complete |
| Assign checkerboard an evidence-supported guarantee | owner packet recommends stable API plus scientifically `:unqualified`; maximum discrepancy and limitations explicit | pending owner approval |
| Qualify applicable CPU, Metal, and ROCm transition rows; larger ensembles | CPU/Metal transition and realistic archives | ROCm pending |
| Archive matrices, counts, thresholds, grids, provenance, programs, figure inputs | versioned machine-readable evidence trees and generators | complete for CPU/Metal; ROCm pending |
| Review every export and public extension surface | 950-export exhaustive generated inventory; zero undocumented stable and unpromoted candidates | complete |
| Mark stable, limited, experimental, and internal surfaces | candidate policy and inventory | final status pending owner approval |
| Aqua, ambiguity, inference, allocation, device code, doctest, clean install | owner packet quality section and current test runs | complete locally |
| Deterministic, moderate statistical, and scheduled/pre-release tiers | 2,203-test CPU conformance shard plus empirical/realistic workflows | local tiers complete; ROCm scheduled tier pending |
| Specification-to-test evidence index | `spec/conformance-evidence.md` | closure candidate; ROCm/final metadata pending |
| Remove legacy paths, dependencies, claims, and provisional behavior | legacy closure audit and mandatory checkers | complete |
| Freeze RNG, IR, checkpoint, fingerprint, result, and algorithm versions | all candidate identities `v"1.0.0"` | final freeze pending owner approval |

## Exit-gate audit

1. **Sequential independent obligations:** exact and CPU/Metal empirical evidence pass; real-ROCm
   empirical evidence remains pending.
2. **Checkerboard scoped guarantee:** mechanism, exact discrepancy, and realistic failure are proved;
   final public profile is pending owner approval.
3. **CPU, Metal, ROCm transition and realistic corroboration:** CPU and Metal are archived; ROCm is
   pending. CPU algorithm equivalence is 7/42 and CPU--Metal independent portability is 26/42,
   therefore no broader realistic-equivalence claim is permitted.
4. **All accepted core semantics have conformance evidence:** the current specification-to-evidence
   index and 2,203-test conformance shard cover the accepted paper-core contracts.
5. **Public extension functions documented and tested:** the exhaustive inventory reports zero
   undocumented stable candidates; strict docs/doctests and package protocol suites pass.
6. **Clean environments install, load, test, and exercise each package:** proved for CorePotts and
   PottsToolkit; the CI package matrix now repeats the clean temporary-project exercise.
7. **No stable API depends on deferred or historical behavior:** legacy and structure checkers pass;
   Lottery, tiled execution, MakiePotts, and other deferred scopes are explicitly non-stable or
   outside the paper workspace.
8. **Owner explicitly approves the paper API freeze:** pending.

Phase 13 must not be marked complete until items 1, 3, and 8 are closed, the final public metadata
matches the admitted evidence, and the complete validation matrix passes on that exact final source.
