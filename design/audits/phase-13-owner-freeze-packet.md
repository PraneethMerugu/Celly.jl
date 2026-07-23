# Phase 13 Owner API-Freeze Evidence Packet

Status: Draft; local CPU/Metal evidence complete, real-ROCm admission and final owner approval pending

Date: 2026-07-23

## Decision requested

Decision 0028 requires the project owner to review one packet containing the API inventory,
algorithm guarantees, backend results, limitations, removals, and frozen version identities. This
packet does not treat green CI as approval and does not turn a failed equivalence analysis into a
pass. After the real-ROCm records are admitted, the owner must explicitly approve or reject the
recommended freeze below.

## Recommended algorithm freeze

| Algorithm | API disposition | Paper scope | Recommended guarantee label | Evidence-supported statement |
| --- | --- | --- | --- | --- |
| `SequentialCPM` | stable | Phase 13 core | `:unqualified` | Production execution conforms to its declared with-replacement, immediate-commit conventional CPM process on the admitted transition fixtures. No equilibrium, stationary-distribution, or physical-time interpretation is claimed. |
| `CheckerboardSweepCPM` | stable | Phase 13 core | `:unqualified` | Production execution conforms to its declared graph-colored, randomized-color, common-snapshot, deterministic-conflict process. It is not sequential CPM: the maximum retained normalized-MCS row total variation is `0.5625`, and only 7/42 CPU realistic sequential-comparison endpoints passed the preregistered equivalence margins. |
| `LotteryCPM` | limited | later protocol consumer | `:unqualified` | Execution support remains available, but it is outside the initial Phase 13 transition and realistic matrix. |
| `SequentialEquilibrium` | experimental | not admitted | `:unqualified` | The capability-qualified sampler is not part of the initial paper freeze. |
| `TiledCheckerboardCPM` | experimental | non-paper | `:unqualified` | Phase 12.5 retained the research implementation without stable API, automatic-selection, portability, or paper-performance claims. |

The closed public taxonomy describes scientific guarantees, not API stability. Exact conformance to
a declared implementation process does not by itself establish detailed balance, stationarity,
convergence under an explicit scientific limit, or observable equivalence. For that reason the two
stable algorithm names can honestly retain `:unqualified` while exposing their complete proposal,
transaction, normalization, evidence, discrepancy, and tested-backend metadata.

After ROCm admission, the recommended metadata is:

- `api_status = :stable` for `SequentialCPM` and `CheckerboardSweepCPM`;
- `evidence_version = v"1.0.0"`;
- `maximum_observed_discrepancy = 0.0` for sequential production versus its registered independent
  transition oracle, and `0.5625` for checkerboard versus sequential normalized-MCS rows;
- `tested_backends` records only backends represented by admitted Phase 13 evidence;
- `qualified_domain` distinguishes transition qualification from realistic qualification and does
  not imply surface, connectivity, field, lifecycle, auxiliary-mechanical, Lottery, tiled, or
  broader-topology coverage.

## Algorithmic evidence

### Independent exact oracle

The content-addressed exact archive contains 12 primitive, normalized-MCS, and lifted-checkerboard
records across a hand-derived 1D fixture, exhaustive 2D von Neumann and Moore fixtures, and selected
3D lowering. The generated oracle reproduces the hand derivation without importing production
proposal, delta, conflict, or commit code.

Retained results include:

- maximum sequential--checkerboard normalized-MCS row total variation: `9/16 = 0.5625`;
- maximum retained checkerboard observable drift: `0.375`;
- exact zero-discrepancy fixtures alongside the adversarial non-equivalent fixture;
- stationary, probability-current, spectral-gap, relaxation, and observable-drift inputs used by
  the generated figures.

Authority: `design/evidence/phase-13/exact/index.toml` and
`design/evidence/phase-13/figures/index.toml`.

### Fixed-source empirical transition rows

The v2 transition study uses `Float32`, exactly 262,144 independent replicas per row, fixed semantic
seeds, and the preregistered simultaneous criteria.

| Backend | Exact source revision | Applicable rows | Result |
| --- | --- | ---: | --- |
| CPU | `6f725683092909a2ac2938b2108dae934dc6450e` | 8/8 | pass |
| Metal | `6f725683092909a2ac2938b2108dae934dc6450e` | 8/8 | pass |
| ROCm | same required source | 8 required | pending real hardware |

CPU and Metal raw destination counts are exactly equal for corresponding rows. Authority:
`design/evidence/phase-13/empirical/{cpu,metal}/index.toml`.

### Registered realistic-scale battery

The v4 applicability amendment changed no workload, endpoint, margin, seed, sample count, estimator,
or stopping rule. It records `SequentialCPM` as the stable CPU realistic reference and qualifies
`CheckerboardSweepCPM` on CPU, Metal, and ROCm. Each applicable identity uses exactly 512 replicas
from source revision `7ed1473df38873f03247572fe94382e36f642a00`.

| Claim family | Result | Interpretation |
| --- | --- | --- |
| CPU sequential vs checkerboard | 7/42 endpoints pass; family `equivalence-fail` | Checkerboard is not observably equivalent to sequential on the bounded battery. |
| CPU vs Metal checkerboard | 26/42 endpoints pass; family `equivalence-fail` | Every retained scientific replica value is exactly equal across CPU and Metal. The 16 failures are conservative independent-sample quantile intervals wider than their preregistered margins, so statistical portability equivalence is not demonstrated. |
| CPU vs ROCm checkerboard | pending | No result may be inferred from compilation or CPU/Metal evidence. |

The independent-backend analysis is intentionally retained even when semantic seeds coincide.
Thresholds, pairing policy, and replica counts are not changed after seeing the result. Authority:
`design/evidence/phase-13/realistic/index.toml`.

Eight-replica isolated CPU timing is descriptive, not qualification evidence. Median
checkerboard/sequential measured-MCS/s ratios are `0.9893` for relaxation, `0.9904` for sorting,
and `0.9549` for migration. The speed--fidelity figure combines only those timing records with the
registered 512-replica CPU family analysis.

## Public API inventory

The generated inventory is byte-reproducible, exhaustive over every non-imported export, and rejects
unknown, overlapping, undocumented-stable, and unpromoted-candidate bindings.

| Package | Stable candidates | Limited | Experimental | Internal | Total exports |
| --- | ---: | ---: | ---: | ---: | ---: |
| CorePotts | 228 | 1 | 10 | 488 | 727 |
| PottsToolkit | 197 | 1 | 2 | 23 | 223 |

Both packages have zero undocumented stable candidates and zero unpromoted candidates. Export status
alone is not a compatibility promise. Authority:
`design/audits/phase-13-api-freeze-policy.toml` and
`design/audits/phase-13-api-inventory.toml`.

## Quality and installation evidence

Current local results on Julia 1.12.6:

- CorePotts package suite: 2,854/2,854;
- PottsToolkit package suite: 664/664;
- CPU integration shards: thermodynamics 7/7, biophysics 12/12, integration 8/8, conformance
  2,203/2,203;
- benchmark-harness contract suite: 71/71;
- Aqua and recursive ambiguity checks pass for both packages;
- representative public contract and constructor paths pass `@inferred`;
- zero-allocation RNG primitives and the existing zero warm-device-allocation gates pass;
- strict Documenter build and doctests pass;
- clean temporary projects independently install, load, and exercise CorePotts and PottsToolkit;
- repository structure, legacy containment, exhaustive API inventory, workflow YAML, and whitespace
  checks pass.

The current Metal inspection at clean source revision
`7ed1473df38873f03247572fe94382e36f642a00` retained native AIR and chronological traces for both
Phase 13 algorithms. `SequentialCPM` produced one 671,691-byte native job and five device
operations; `CheckerboardSweepCPM` produced one 1,052,041-byte native job and 75 device operations.
Authority: `design/evidence/phase-13/device-code/metal/index.toml`.

The current ROCm inspection at that same clean source revision used Julia 1.12.6, AMDGPU 2.7.0,
and the real `rocm-runner-gpu-v1` host. `SequentialCPM` produced one 1,291,112-byte native GCN job;
`CheckerboardSweepCPM` produced eight native GCN jobs totaling 2,568,051 bytes. The authoritative
`rocprofv3` invocation captured nonempty HIP/HSA/kernel Perfetto traces. The exact profile, nine
native assembly records, two raw traces, hashes, and workflow run are retained under
`design/evidence/phase-13/device-code/rocm/index.toml`.

## Removed and excluded surfaces

Phase 13 removed the historical CorePotts engine, old component and event kernels, the historical
Toolkit compiler path, NeuralPotts from the paper workspace, stale Mermaid integration, legacy
benchmarks/examples/tutorials, and executable consumers of those paths. It did not add compatibility
shims. MakiePotts remains deferred source outside the paper workspace for Phase 14 migration.

The structural and legacy checkers reject restoration of mixed production paths. The detailed
manifest is `design/audits/phase-13-legacy-closure.md`.

## Proposed frozen version identities

Every identity below is currently `v"1.0.0"` and remains marked `:phase13_candidate` until the owner
approves this packet:

- semantic RNG;
- PottsToolkit authoring DSL;
- normalized IR;
- checkpoint schema;
- semantic fingerprint;
- execution fingerprint;
- result/evidence schema;
- sequential algorithm;
- checkerboard scheduler;
- Lottery algorithm;
- experimental tiled-checkerboard contract.

Approval freezes these exact identities; it does not revise the negative scientific evidence.

## Explicit limitations

- Neither production algorithm receives an equilibrium, detailed-balance, stationary-distribution,
  or physical-time guarantee from Phase 13.
- Checkerboard is not claimed to reproduce sequential kinetics or realistic observables.
- CPU--Metal realistic values are descriptively identical, but the preregistered independent family
  did not demonstrate equivalence.
- Sequential realistic qualification applies only to CPU; its intentional one-site GPU launch
  schedule is not a production-applicable realistic identity.
- Transition qualification is limited to admitted adhesion and volume fixtures and the registered
  topology/boundary/temperature grid.
- Realistic qualification is 2D and limited to relaxation, differential-adhesion sorting, and
  single-cell migration.
- Surface, connectivity, fields, lifecycle enumeration, auxiliary mechanics, new lattices, Lottery,
  and tiled execution receive no implied Phase 13 matrix qualification.
- Real-ROCm evidence is mandatory before any stable three-backend evidence statement.

## Remaining decisions and gates

The immutable GitHub source refs now resolve exactly to transition revision `6f725683...` and
realistic revision `7ed1473d...`; the current-source ROCm native-profile archive is admitted.

1. Complete and archive the in-progress real-ROCm transition and realistic evidence without
   changing the registration.
2. Update this packet with the ROCm statistical results and any resulting tested-backend
   limitations.
3. Ask the project owner to explicitly approve or reject the recommended API and version freeze.
4. Only after approval, change candidate statuses to final stable/limited/experimental dispositions,
   run the complete final validation matrix, and record the Phase 13 completion audit.
