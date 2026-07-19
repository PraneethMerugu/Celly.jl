# Phase 7 Completion Audit

Status: Pending ROCm qualification

This audit uses the Phase 7 deliverables and exit gate in `design/refactor-roadmap.md` as the
definition of completion. Implementation, CPU qualification, and real Metal qualification are
complete. Decision 0013 requires a real ROCm pass before Phase 7 can close.

## Stable scientific scope

Phase 7 stabilizes four explicitly distinct processes: `SequentialCPM`,
`SequentialEquilibrium`, `CheckerboardSweepCPM`, and `LotteryCPM`. They share normalized MCS units,
but do not claim identical kinetics. `SequentialCPM` is the backend-independent default;
checkerboard is a randomized, once-per-site colored sweep; and lottery uses a realized-graph
`Delta + 1` schedule with one activated opportunity per mutable site in expectation.

The stable mechanical slice contains `FluctuatingVolumePressure` and
`FluctuatingSurfaceTension`. These are real, non-equilibrium OU mechanical processes, not
Hubbard--Stratonovich representations of the classical quadratic Hamiltonians. The exact
quadratic volume and surface energies remain the equilibrium reference families.

The accepted component boundary is capability-qualified rather than universal. Exact connectivity
and unwrapped moment/focal coupling are stable sequential capabilities and explicit checkerboard
and lottery initialization errors. Length and focal auxiliary mechanics remain experimental.

## Deliverables

| Requirement | Evidence | Verdict |
| --- | --- | --- |
| Conventional sequential reference | `algorithms/sequential.jl`; exactly `N` recipient selections with replacement, conventional no-op accounting, and 2D/3D fixtures | Implemented |
| Separately named algorithm processes | Four public algorithm values return validated `AlgorithmGuaranteeProfile` values covering proposal process, equilibrium, kinetics, transactions, MCS normalization, reproducibility, component scope, evidence, backend contract, and dimensions | Implemented |
| Backend-independent default | No-algorithm initialization selects `SequentialCPM`; GPU execution emits one informational message without changing the process | Implemented |
| One normalized MCS per public step | Sequential performs exactly `N` attempts; checkerboard visits every mutable site once; lottery exposes expected per-site activation and fluctuating realized attempts | Implemented |
| Topology-derived lottery schedule | Realized CSR conflict graph, `Delta + 1` rounds, exact rational eligibility, collision-free 128-bit tickets, randomized round order, and no compensating work | Implemented |
| Checkerboard schedule | Realized finite-graph coloring, randomized color order, common-snapshot color evaluation, and exact once-per-site accounting | Implemented |
| Race-free parallel transaction | Fixed-capacity device claim storage, atomic maximum priority plus minimum canonical tie break, explicit conceptual-medium rule, and tracker reconciliation | Implemented |
| First-class mechanical state | Fifth scientific component category, exact OU transition, separate mechanical copy work, semantic initialization/evolution streams, and symmetric normalized sub-round integration | Implemented |
| Explicit capability rejection | Undeclared/private parallel access, connectivity, and moment/focal state fail during initialization with a compatible sequential alternative | Implemented |
| Diagnostics | Reports expose rounds, scheduler candidates, activated attempts, no-ops, conflicts, rejections, accepted moves, and guarantee profile | Implemented |
| Historical-engine quarantine | A SHA-256 manifest exhaustively inventories and freezes 22 pure production/consumer files plus quarantined-line signatures in 3 mixed files; the required checker scans the complete replacement path and rejects added legacy references across packages, tests, benchmarks, integration, tutorials, and examples | Implemented and machine-enforced |

## Exit-gate evidence

| Gate | Current evidence | State |
| --- | --- | --- |
| Attempt accounting | Focused fixtures reconcile every outcome partition; CPU and Metal qualifiers cover all three schedules in 2D and 3D | Complete on CPU and Metal |
| Same-run reproducibility | Strict same-seed report, ownership, volume, and surface replay on each tested backend | Complete on CPU and Metal |
| Stable statistical batteries | CPU schedule tests prove every checkerboard/lottery order is a permutation and observe semantic order variation; lottery tests additionally cover boundary-degree uniformity, repeated activation, inactive waiting times, and nearest-neighbor covariance; CPU and Metal mechanical tests cover stationary initialization and finite-time OU moments | Complete for CPU schedules and CPU/Metal mechanics; ROCm mechanics pending |
| Visible non-equivalence | Checkerboard and lottery are separately named and report `equilibrium = :not_claimed`; neither can replace the sequential default silently | Complete |
| Removed time controls | The scientific algorithm API has no public `sweeps_per_step` or `active_fraction` | Complete |
| Stable mechanical law and clock | Volume pressure and surface tension pass exact transition, work-sign, initialization, one-MCS composition, replay, and transaction fixtures | Complete on CPU and Metal |
| No incidental host synchronization | Algorithm and mechanics qualifiers report zero synchronization inside an MCS; observation remains explicit | Complete on CPU and Metal |
| Current backend contract | CPU and real Metal pass; the repository workflow is wired to run the same matrix on AMDGPU | **ROCm pending** |
| Quarantine discipline | `scripts/check_legacy_containment.jl` validates frozen digests, a clean replacement path, and no base-diff consumer additions; final atomic deletion remains owned by the PottsToolkit compiler migration in Phases 10--11 | Complete |

## Local and Metal evidence

The authoritative local package test on Julia 1.12.6 reports 2,628 passed tests and one intentional
broken test. The CPU smoke matrix passes the 2D/3D sequential, checkerboard, lottery, mechanics,
scientific-inner-loop, and existing workload qualifiers. `git diff --check` is clean.

A real Apple Metal run passes every Phase 7 algorithm and both stable mechanical families in 2D and
3D. Reports replay exactly for the same seed, mechanics remain device-resident, and internal host
synchronization is zero. The statistical probes report stationary variance approximately 12.286
for an expected 12 and finite-time evolution variance approximately 10.343 for an expected
`12 * (1 - exp(-2))`.

## Exact remaining closure action

Push a candidate commit and let `.github/workflows/gpu-validation.yml` execute
`benchmark/matrix.jl --backend=amdgpu --profile=smoke` on the self-hosted ROCm runner. The workflow
already uses Julia 1.12.6, the pinned KernelIntrinsics fork revision, the dedicated AMDGPU
environment, bounds checking, and artifact upload. Phase 7 closes only if the ROCm report passes the
algorithm and mechanics sections in both dimensions with zero internal synchronization.

No broader checkerboard/lottery equilibrium-equivalence claim is required for closure: these
processes explicitly make no such claim. Broader comparative kinetics and performance studies are
paper characterization work and must precede any later equivalence or superiority claim, but are
not missing semantics or implementation in this phase.
