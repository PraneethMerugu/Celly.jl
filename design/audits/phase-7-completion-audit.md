# Phase 7 Completion Audit

Status: Complete

This audit uses the Phase 7 deliverables and exit gate in `design/refactor-roadmap.md` as the
definition of completion. Implementation and real CPU, Metal, and ROCm qualification are complete
under the three-backend contract in Decision 0013.

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
| Historical-engine quarantine | A SHA-256 manifest exhaustively freezes 22 pure production files, quarantined-line signatures in 3 mixed production files, and ordered signatures for 57 test/tutorial/example consumers; the required checker independently scans the complete replacement path and rejects uninventoried legacy references | Implemented and machine-enforced |

## Exit-gate evidence

| Gate | Current evidence | State |
| --- | --- | --- |
| Attempt accounting | Focused fixtures reconcile every outcome partition; CPU, Metal, and ROCm qualifiers cover all three schedules in 2D and 3D | Complete |
| Same-run reproducibility | Strict same-seed report, ownership, volume, and surface replay on CPU, Metal, and ROCm | Complete |
| Stable statistical batteries | CPU schedule tests prove every checkerboard/lottery order is a permutation and observe semantic order variation; lottery tests additionally cover boundary-degree uniformity, repeated activation, inactive waiting times, and nearest-neighbor covariance; CPU, Metal, and ROCm mechanical tests cover stationary initialization and finite-time OU moments | Complete |
| Visible non-equivalence | Checkerboard and lottery are separately named and report `equilibrium = :not_claimed`; neither can replace the sequential default silently | Complete |
| Removed time controls | The scientific algorithm API has no public `sweeps_per_step` or `active_fraction` | Complete |
| Stable mechanical law and clock | Volume pressure and surface tension pass exact transition, work-sign, initialization, one-MCS composition, replay, and transaction fixtures | Complete |
| No incidental host synchronization | CPU, Metal, and ROCm algorithm and mechanics qualifiers report zero synchronization inside an MCS; observation remains explicit | Complete |
| Current backend contract | CPU, real Apple Metal, and real AMDGPU/ROCm pass the same Julia 1.12.6 smoke contract | Complete |
| Quarantine discipline | `scripts/check_legacy_containment.jl` validates frozen production digests, frozen consumer signatures, an exhaustive inventory, and a clean replacement path independently of pull-request history; final atomic deletion remains owned by the PottsToolkit compiler migration in Phases 10--11 | Complete |

## Local and hardware evidence

The authoritative local package test on Julia 1.12.6 reports 2,628 passed tests and one intentional
broken test. The CPU smoke matrix passes the 2D/3D sequential, checkerboard, lottery, mechanics,
scientific-inner-loop, and existing workload qualifiers. `git diff --check` is clean.

A real Apple Metal run and an independent real AMDGPU/ROCm run pass every Phase 7 algorithm and both
stable mechanical families in 2D and 3D. Reports replay exactly for the same seed, mechanics remain
device-resident, and internal host synchronization is zero. Both statistical probes report
stationary variance approximately 12.286 for an expected 12 and finite-time evolution variance
approximately 10.343 for an expected `12 * (1 - exp(-2))`.

## Authoritative closure evidence

Candidate commit `895ea54` passed the authoritative
[CI run](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29689911385) and
[GPU Validation run](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29689911390):

- [Metal / Apple Silicon](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29689911390/job/88200690577)
  passed in 1m46s;
- [ROCm / AMDGPU](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29689911390/job/88200690589)
  passed in 1m57s;
- both logs contain `SEQUENTIAL_QUALIFICATION`, `CHECKERBOARD_QUALIFICATION`,
  `LOTTERY_QUALIFICATION`, and `MECHANICS_QUALIFICATION` records for 2D and 3D `Float32`, strict
  same-backend replay, normalized MCS accounting, tracker/mechanics conformance, and
  `internal_host_synchronizations = 0`; and
- Linux x86_64, macOS ARM64, all package suites, all integration shards, project integrity, build,
  and the aggregate required gate passed on Julia 1.12.6.

This closes the Phase 7 three-backend contract. CUDA remains deferred by Decision 0013; no CUDA
claim is inferred.

No broader checkerboard/lottery equilibrium-equivalence claim is required for closure: these
processes explicitly make no such claim. Broader comparative kinetics and performance studies are
paper characterization work and must precede any later equivalence or superiority claim, but are
not missing semantics or implementation in this phase.
