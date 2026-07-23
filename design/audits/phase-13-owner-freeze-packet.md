# Phase 13 Owner API-Freeze Evidence Packet

Status: Approved and validated; API/version freeze complete

Date: 2026-07-23

Owner decision: Approved on 2026-07-23 in the Phase 13 working thread.

## Decision record

Decision 0028 requires the project owner to review one packet containing the API inventory,
algorithm guarantees, backend results, limitations, removals, and frozen version identities. This
packet did not treat green CI as approval and did not turn a failed equivalence analysis into a
pass. The owner reviewed the admitted CPU, Metal, and ROCm evidence and explicitly approved the
freeze below.

## Approved algorithm freeze

| Algorithm | API disposition | Paper scope | Frozen guarantee label | Evidence-supported statement |
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

The frozen metadata is:

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
| ROCm | `6f725683092909a2ac2938b2108dae934dc6450e` | 8/8 | pass |

CPU, Metal, and ROCm raw destination counts are exactly equal for corresponding rows. Every backend
also independently passes the preregistered simultaneous criteria. Authority:
`design/evidence/phase-13/empirical/{cpu,metal,rocm}/index.toml`.

### Registered realistic-scale battery

The v4 applicability amendment changed no workload, endpoint, margin, seed, sample count, estimator,
or stopping rule. It records `SequentialCPM` as the stable CPU realistic reference and qualifies
`CheckerboardSweepCPM` on CPU, Metal, and ROCm. Each applicable identity uses exactly 512 replicas
from source revision `7ed1473df38873f03247572fe94382e36f642a00`.

| Claim family | Result | Interpretation |
| --- | --- | --- |
| CPU sequential vs checkerboard | 7/42 endpoints pass; family `equivalence-fail` | Checkerboard is not observably equivalent to sequential on the bounded battery. |
| CPU vs Metal checkerboard | 26/42 endpoints pass; family `equivalence-fail` | Every retained scientific replica value is exactly equal across CPU and Metal. The 16 failures are conservative independent-sample quantile intervals wider than their preregistered margins, so statistical portability equivalence is not demonstrated. |
| CPU vs ROCm checkerboard | 26/42 endpoints pass; family `equivalence-fail` | ROCm scientific summaries are not bit-identical to CPU, although the endpoint pass/fail pattern matches CPU--Metal. Statistical portability equivalence is not demonstrated. |

The independent-backend analysis is intentionally retained even when semantic seeds coincide.
Thresholds, pairing policy, and replica counts are not changed after seeing the result. The ROCm
records and analysis came from exact source revision
`7ed1473df38873f03247572fe94382e36f642a00` on the real self-hosted runner. Authority:
`design/evidence/phase-13/realistic/index.toml`.

Eight-replica isolated CPU timing is descriptive, not qualification evidence. Median
checkerboard/sequential measured-MCS/s ratios are `0.9893` for relaxation, `0.9904` for sorting,
and `0.9549` for migration. The speed--fidelity figure combines only those timing records with the
registered 512-replica CPU family analysis.

## Public API inventory

The generated inventory is byte-reproducible, exhaustive over every non-imported export, and rejects
unknown, overlapping, undocumented-stable, and unpromoted-candidate bindings.

| Package | Stable | Limited | Experimental | Internal | Total exports |
| --- | ---: | ---: | ---: | ---: | ---: |
| CorePotts | 228 | 1 | 10 | 488 | 727 |
| PottsToolkit | 197 | 1 | 2 | 23 | 223 |

Both packages have zero undocumented stable bindings and zero unpromoted policy candidates. Export
status alone is not a compatibility promise. Authority:
`design/audits/phase-13-api-freeze-policy.toml` and
`design/audits/phase-13-api-inventory.toml`.

## Quality and installation evidence

Final local results on Julia 1.12.6:

- CorePotts package suite: 2,863/2,863;
- PottsToolkit package suite: 666/666;
- CPU integration shards: thermodynamics 7/7, biophysics 12/12, integration 8/8, conformance
  2,465/2,465;
- benchmark-harness contract suite: 71/71;
- Aqua and recursive ambiguity checks pass for both packages;
- representative public contract and constructor paths pass `@inferred`;
- zero-allocation RNG primitives and the existing zero warm-device-allocation gates pass;
- strict Documenter build and doctests pass;
- clean temporary projects independently install, load, and exercise CorePotts and PottsToolkit;
- repository structure, legacy containment, exhaustive API inventory, workflow YAML, and whitespace
  checks pass.

The retained Metal inspection at clean source revision
`7ed1473df38873f03247572fe94382e36f642a00` retained native AIR and chronological traces for both
Phase 13 algorithms. `SequentialCPM` produced one 671,691-byte native job and five device
operations; `CheckerboardSweepCPM` produced one 1,052,041-byte native job and 75 device operations.
Authority: `design/evidence/phase-13/device-code/metal/index.toml`.

The retained ROCm inspection at that same clean source revision used Julia 1.12.6, AMDGPU 2.7.0,
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

## Frozen version identities

Every identity below is frozen at `v"1.0.0"` with status `:phase13_frozen`:

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

Approval froze these exact identities; it did not revise the negative scientific evidence.

## Explicit limitations

- Neither production algorithm receives an equilibrium, detailed-balance, stationary-distribution,
  or physical-time guarantee from Phase 13.
- Checkerboard is not claimed to reproduce sequential kinetics or realistic observables.
- CPU--Metal realistic values are descriptively identical, but the preregistered independent family
  did not demonstrate equivalence.
- CPU--ROCm realistic values contain genuine backend differences. The same 26/42 endpoint pattern
  passes as CPU--Metal, but the preregistered independent family still does not demonstrate
  equivalence.
- Sequential realistic qualification applies only to CPU; its intentional one-site GPU launch
  schedule is not a production-applicable realistic identity.
- Transition qualification is limited to admitted adhesion and volume fixtures and the registered
  topology/boundary/temperature grid.
- Realistic qualification is 2D and limited to relaxation, differential-adhesion sorting, and
  single-cell migration.
- Surface, connectivity, fields, lifecycle enumeration, auxiliary mechanics, new lattices, Lottery,
  and tiled execution receive no implied Phase 13 matrix qualification.
- The admitted ROCm evidence supports only the bounded transition and checkerboard-realistic
  identities named in this packet; it does not support broader three-backend equivalence.

## Closure record

The immutable GitHub source refs resolve exactly to transition revision `6f725683...` and realistic
revision `7ed1473d...`. The ROCm transition, realistic, native-device-code, and trace archives are
admitted without changing their registrations.

The owner approved the recommended API and version freeze. The complete final validation matrix
passed on the frozen implementation source and is recorded in
`design/audits/phase-13-completion-audit.md`. No Phase 13 gate remains open.
