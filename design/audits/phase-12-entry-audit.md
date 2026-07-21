# Phase 12 Performance Entry Audit

Status: In progress

Date: 2026-07-21

Entry head: `7eae976` (`Build PottsToolkit Level 1 DSL (#11)`)

## Verdict

Phase 12 may begin. Phase 11 is squash-merged into protected `main`, its exact implementation was
qualified on x86_64 CPU, ARM64 CPU, real Metal, and real ROCm, and the new branch starts from the
merged commit without source changes. The repository already has a substantial benchmark and
residency-measurement foundation. It does not yet have a Phase 12 regression decision system.

The first implementation work is therefore measurement governance, not kernel tuning. An untouched
Phase 11 baseline and a versioned comparison contract must exist before an optimization is accepted.

## Evidence already available

- The immutable `pre-refactor-baseline-2026-07-17` prerelease retains full CPU, Metal, and ROCm
  historical records plus checksums at commit `e8a0e424eaf399710c1248f89187799b8abc1fde`.
- The benchmark project pins Julia 1.12.6 and keeps Metal and AMDGPU in separate environments and
  processes.
- Schema `2.1.0` records model construction, normalization, problem binding, lowering, problem
  construction, initialization, first MCS, synchronized warm MCS samples, scientific accounting,
  memory, launches, transfers, synchronization, observation, checkpoints, fingerprints, hardware,
  environment, and source provenance.
- Smoke qualification covers the five required paper families on CPU, Metal, and ROCm. Phase 11
  additionally qualifies the complete Level 1 rule path and downstream custom physics in 2D and 3D.
- Warm qualified GPU paths already assert zero undeclared host synchronization, device-to-host
  transfer, and device allocation.

Historical pre-refactor results remain engineering evidence. They are not automatically valid direct
speed comparisons: the scientific model, proposal process, MCS normalization, numerical policy, and
observation work must match before a result enters a performance gate.

## Blocking measurement gaps

### P0: no current-head baseline

No full CPU/Metal/ROCm performance record has yet been retained for merged Phase 11 head `7eae976`.
Optimization must not begin before that record is captured under the Phase 12 contract.

### P0: no regression decision

The harness writes raw results but does not compare a candidate with an explicit baseline, apply the
per-workload 5% target, compute a core-workload geometric mean, classify incomparable records, or
require written justification for an accepted regression.

### P0: cold-process measurements are not isolated

`benchmark/matrix.jl` runs many qualifications before the reference performance suite. Timings taken
there can separate construction stages, but they cannot establish clean package-load, precompile,
first-import, or first-kernel latency. Cold measurements require fresh subprocesses with an explicit
cache state and must remain separate from warm throughput.

### P0: benchmark contract exceeds the accepted backend claim

The manual workflow still presents CUDA as an ordinary backend even though the current first-class
contract is CPU, Metal, and ROCm. Experimental CUDA plumbing may remain isolated, but it must not
appear in the required Phase 12 aggregate or the release-qualified leaderboard.

### P0: runner and repetition policy is incomplete

The historical CPU benchmark job uses only GitHub-hosted Linux x86_64. Phase 12 requires first-class
CPU evidence on x86_64 and ARM64 and real-hardware GPU evidence. A full decision also needs repeated
independent runs and historical variance; ten samples inside one process do not detect machine- or
process-level noise.

### P0: native resource capture is pending

Kernel compilation is qualified, but critical kernels do not yet retain backend-native register,
spill, occupancy, local-memory, native-code-size, or memory-traffic evidence. Unsupported metrics
must be reported as unavailable rather than inferred from unrelated counters.

## Important non-blocking debt

- `benchmark/src/PottsBenchmarks.jl` is a large qualification and measurement module. Split it only
  along stable workload, schema, measurement, and comparison boundaries encountered during Phase 12;
  do not perform a line-count-only rewrite before baseline capture.
- Schema and function names still say `phase10`. Preserve readers for retained artifacts, but emit a
  new Phase 12 schema rather than changing the meaning of `2.1.0` fields.
- The historical runner exposes legacy algorithm labels. Final performance reports use
  `SequentialCPM`, `SequentialEquilibrium`, `CheckerboardSweepCPM`, and `LotteryCPM` guarantee
  profiles. Intrinsics are implementation variants, not a separate scientific algorithm.
- Semantically matched external comparisons do not yet have an isolated suite. They are paper
  evidence and must not determine internal regression pass/fail.

## Invariants during optimization

- Model fingerprints, normalized MCS meanings, semantic RNG addresses, transaction behavior, and
  algorithm guarantee profiles do not change as performance tuning.
- Backend selection never changes the scientific algorithm.
- A backend-specific fast path retains a qualified generic path and equivalence evidence.
- Warm GPU execution retains zero undeclared allocation, transfer, and host wait.
- Conservative defaults and tuned configurations are reported separately.
- CPU, Metal, and ROCm run in separate processes with synchronized timed regions.
- A faster scientifically inequivalent workload is not a performance recovery result.

## Owner decisions before the quantitative contract freezes

The focused Phase 12 interview owns only choices that measurements cannot make:

1. the ordering of throughput, first-MCS latency, and package/model compilation latency;
2. the paper-claim workload sizes and which results are release-blocking;
3. conservative-default versus explicitly tuned claims;
4. the accepted hardware and CPU-thread configurations for the paper record;
5. the policy for accepting a measured regression in exchange for another bounded improvement;
6. the prominence of each scientific algorithm family in paper comparisons; and
7. the external simulators and exact claims that require semantically matched comparisons.

Workgroup sizes, layouts, kernel fusion, primitive choice, and intrinsic use are not interview
preferences. End-to-end profiles and backend evidence decide them.

## Entry gate

Phase 12 implementation begins with the accompanying chunk plan. Performance-changing work remains
blocked until the untouched merged-head baseline is retained for the affected backend.
