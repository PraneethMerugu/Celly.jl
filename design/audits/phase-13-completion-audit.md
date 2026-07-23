# Phase 13 Completion Audit

Status: Complete; owner-approved API/version freeze validated

Date: 2026-07-23

This audit maps every Phase 13 roadmap deliverable and exit condition to current authoritative
evidence. “Pending” is not a pass, and an evidence result of `equivalence-fail` is preserved as a
scientific result rather than converted into an implementation failure or narrative success.

## Chunk completion

| Chunk | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| 13A | Independent primitive, sub-round, and normalized-MCS oracle; global-energy checks; hand derivation | `integration/transition/TransitionKernelOracle.jl`; 12 content-addressed records in `design/evidence/phase-13/exact/`; conformance independence guards | proved |
| 13B | Sequential declared-process and applicable reference obligations | exact sequential rows, production adapter checks, CPU/Metal/ROCm v2 empirical rows | proved |
| 13C | Lifted production checkerboard characterization and evidence-supported label | exact lifted scheduler records; maximum TV `0.5625`; probability-current, spectral, relaxation, drift, realistic analyses, and frozen `AlgorithmGuaranteeProfile` | proved; stable API with scientifically `:unqualified` label |
| 13D | Bounded fixtures and component admission | fixture manifest covers required von Neumann/Moore, periodic/no-flux, 2D/selected-3D strata; adhesion and volume admitted; exclusions explicit | proved |
| 13E | Preregistered CPU/Metal/ROCm transition rows and realistic ensembles | CPU, Metal, and ROCm transition 8/8 each; CPU v4 six identities; Metal and ROCm v4 three identities each; all fixed counts/seeds/source revisions | proved on all applicable backends |
| 13F | Versioned archives, CI tiers, figures, stale-evidence detection | exact, empirical, realistic, diagnostic, device-code, and figure indices; semantic fingerprints and source checks; scheduled workflows | proved, including real-ROCm transition, realistic, and native-profile workflows |
| 13G | API audit, quality gates, legacy removal, frozen identities, owner approval | exhaustive frozen API inventory; package/integration/docs/install checks; Metal AIR/trace and ROCm GCN/Perfetto archives; legacy closure; approved owner packet | complete |

## Roadmap deliverables

| Deliverable | Proof | Result |
| --- | --- | --- |
| Independent finite-state oracle without production proposal/delta/conflict/commit reuse | oracle source, import-independence guard, hand-derived reproduction | complete |
| Verify sequential and characterize lifted checkerboard without inherited claims | exact archive and production adapter; discrepancy and mechanism records | complete |
| Assign checkerboard an evidence-supported guarantee | stable API plus scientifically `:unqualified`; maximum discrepancy `0.5625` and limitations explicit | complete |
| Qualify applicable CPU, Metal, and ROCm transition rows; larger ensembles | CPU/Metal/ROCm transition and realistic archives | complete |
| Archive matrices, counts, thresholds, grids, provenance, programs, figure inputs | versioned machine-readable evidence trees and generators | complete |
| Review every export and public extension surface | 950-export exhaustive generated inventory; zero undocumented stable bindings and unpromoted policy candidates | complete |
| Mark stable, limited, experimental, and internal surfaces | owner-approved frozen policy and exhaustive inventory | complete |
| Aqua, ambiguity, inference, allocation, device code, doctest, clean install | owner packet quality section and final validation matrix below | complete |
| Deterministic, moderate statistical, and scheduled/pre-release tiers | 2,465-test CPU conformance shard plus CPU/Metal/ROCm empirical and realistic workflows | complete |
| Specification-to-test evidence index | `spec/conformance-evidence.md` | complete |
| Remove legacy paths, dependencies, claims, and provisional behavior | legacy closure audit and mandatory checkers | complete |
| Freeze RNG, IR, checkpoint, fingerprint, result, and algorithm versions | all identities `v"1.0.0"` with `freeze_status = :phase13_frozen` | complete |

## Exit-gate audit

1. **Sequential independent obligations:** exact and CPU/Metal/ROCm empirical evidence pass.
2. **Checkerboard scoped guarantee:** mechanism, exact discrepancy, and realistic failure are proved;
   the stable public profile is frozen with `:unqualified`, the bounded evidence domain, tested
   backends, evidence version, and maximum discrepancy `0.5625`.
3. **CPU, Metal, ROCm transition and realistic corroboration:** all three transition archives pass
   8/8 registered rows, with exact corresponding raw counts. The realistic battery is archived for
   every applicable CPU, Metal, and ROCm identity. CPU algorithm equivalence is 7/42, CPU--Metal
   independent portability is 26/42, and CPU--ROCm independent portability is 26/42; therefore no
   broader realistic-equivalence claim is permitted.
4. **All accepted core semantics have conformance evidence:** the current specification-to-evidence
   index and 2,465-test conformance shard cover the accepted paper-core contracts.
5. **Public extension functions documented and tested:** the exhaustive inventory reports zero
   undocumented stable bindings; strict docs/doctests and package protocol suites pass.
6. **Clean environments install, load, test, and exercise each package:** proved for CorePotts and
   PottsToolkit; the CI package matrix now repeats the clean temporary-project exercise.
7. **No stable API depends on deferred or historical behavior:** legacy and structure checkers pass;
   Lottery, tiled execution, MakiePotts, and other deferred scopes are explicitly non-stable or
   outside the paper workspace.
8. **Owner explicitly approves the paper API freeze:** approved on 2026-07-23 after review of
   `phase-13-owner-freeze-packet.md`.

## Final validation matrix

The post-approval frozen source passed:

- CorePotts independently: 2,863/2,863;
- PottsToolkit independently: 666/666;
- complete CPU cross-package integration: 2,492/2,492, including conformance 2,465/2,465;
- benchmark-harness contracts: 71/71;
- strict Documenter build and doctests for the frozen Phase 13 page set;
- independent temporary-project install, load, and public exercise for both packages;
- exhaustive API inventory regeneration and byte-for-byte check;
- repository structure, legacy containment, workspace resolution, Julia 1.12.6, workflow YAML,
  and whitespace checks;
- retained Metal AIR/trace and ROCm GCN/Perfetto native-profile archives; and
- all registered CPU/Metal/ROCm transition and realistic evidence archive validators.

The unlisted historical tutorial drafts remain explicitly assigned to Phase 14 and are excluded
from the frozen Phase 13 documentation surface through Documenter's `pagesonly` boundary.

Every Phase 13 deliverable and exit gate is closed. The retained algorithm-equivalence and
cross-backend realistic-equivalence failures remain authoritative limitations, not closure
failures.
