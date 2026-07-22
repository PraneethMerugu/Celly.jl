# Phase 12.CPU specialization and scaling completion audit

Status: Completed

Date: 2026-07-22

## Scope and immutable revisions

Phase 12.CPU evaluates CPU-specific execution grain without changing the accepted scientific
algorithms. The immediate merged baseline is
`ac68b366ba33eb9edb3e87bb3a0073db445c32e6`; the fixed Phase 11 recovery baseline remains
`7eae976b77ac5095979db12db463387656f9d58c`. Qualification revision
`9914cf4302eb2306e0a1f946a952e3aec3015898` added the exact-replay analyzer and corrected shared
harness. Revision `c015f46b1f6b22779accb1175135312c04bf9638` restored Lottery execution exactly
to the accepted baseline after the first authoritative matrix exposed a reproducible ARM64
physical-core Lottery regression. The retained scientific source candidate last changed at
`ad1d4e87cd8565424566713126ff41c10e790e65`, which restricts Checkerboard auto-grain to one-thread
execution after the next matrix exposed multithreaded x86_64 Checkerboard regressions.

The candidate retains one CPU-only policy: at exactly one Julia thread, bulk Checkerboard kernels
use the KernelAbstractions CPU default grain for domains of at most 1,024 work items. Every
multithreaded execution and every larger domain retains the fixed 256-item workgroup. Fixed-size
accounting and claim-clearing kernels keep their existing launch shape. Lottery execution is
byte-for-byte identical to the accepted baseline. GPU kernel instantiation, proposal semantics, RNG
addressing, accounting, and public APIs are unchanged.

The affected algorithm loops use type-stable kernel tuples and function barriers so the policy does
not trade scheduling overhead for dynamic dispatch. There is no runtime autotuning, host fallback,
new dependency, new scientific algorithm, or backend-specific Hamiltonian implementation.

## Harness and evidence contract

The paired workflow checks out one immutable harness plus separate immutable baseline and candidate
subjects. Each record identifies and validates both subject and harness provenance. Dirty subjects
or a dirty harness are rejected. This permits the comparison and scaling analyzers to evolve without
pretending that the harness revision is the scientific implementation revision.

Each fixed thread count is an independent comparison identity. Paired baseline/candidate evidence
is required at one thread and all physical cores on both authoritative CPU systems. Independent
three-process throughput groups at intermediate powers of two complete the `1, 2, 4, ..., physical`
scaling curve. Counts exceeding a runner's physical cores are invalid rather than extrapolated.
`Float64` is qualified separately on CPU and cannot be inferred from `Float32` performance.

## Local correctness and diagnostic evidence

All commands use Julia 1.12.6.

| Gate | Evidence | Result |
|---|---|---:|
| CorePotts complete suite | local candidate qualification, repeated after final source changes | 2,995 pass; 1 intentional broken; 0 fail |
| Benchmark contract, paired schedule, and CPU-scaling analyzer | local `benchmark/test/runtests.jl` | 71 / 71 pass |
| Four-pair, eight-thread full-profile diagnostic | local counterbalanced baseline/candidate worktrees; source commit `7db13134c995414016026f3658c8dfe645496e31` | Checkerboard steady-time GM ratio 0.463; Lottery 0.666 |
| Changed-path workload verdicts | same local paired diagnostic | every Checkerboard and Lottery workload within its release threshold or improved |
| Corrected shared-harness four-pair, one-thread full profile | local absolute-harness schedule | full comparator pass; Checkerboard 0.882, Lottery 0.924, Sequential 0.986, SequentialEquilibrium 0.982 GM ratios |
| Exact one-/two-thread replay probe | local real Phase 12 records plus `cpu_scaling.jl` | identical final-state digests and complete accounting; analyzer reports `exact_cross_thread_replay = true` |

The strict whole-matrix diagnostic also flags noise in unchanged sequential paths. That raw result
does not prove a candidate regression because the source diff does not change either sequential
algorithm, while every changed-path workload improves. Authoritative runner evidence below remains
the release gate and is not replaced by this local diagnostic.

The first remote x86_64 one-thread attempt,
[29936818332](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29936818332), completed its
measurements but was correctly rejected by the comparator: changing the subprocess working
directory let a relative worker path select each subject's own harness, so baseline and candidate
had different harness digests. The launcher now uses an absolute shared worker path, has a direct
regression test, and passes a complete local four-pair schedule. Run 29936818332 and every companion
dispatch from that harness revision are superseded controls, not release evidence.

## Authoritative CPU matrix

The first exact matrix at `9914cf4302eb2306e0a1f946a952e3aec3015898` proved exact scientific
replay and strong aggregate gains, but its ARM64 physical-core confirmation reproduced Lottery
chemotaxis regressions above 5%. Revision `c015f46b1f6b22779accb1175135312c04bf9638`
restored Lottery, but its x86_64 physical-core matrix reproduced Checkerboard regressions when the
auto-grain policy was used with many Julia threads. Those raw runs remain investigation evidence and
are not release evidence. Revision `ad1d4e87cd8565424566713126ff41c10e790e65` retains the proven
one-thread Checkerboard specialization and restores every multithreaded path to the accepted grain.

The corrected immutable paired matrix uses four pairs at one thread and five pairs at physical
cores so the noisy-hardware confirmation is part of the primary evidence:

| System | Precision | 1 thread | Physical cores | Result |
|---|---|---:|---:|---|
| ARM64 | `Float32` | [29948401547](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29948401547) | [29948403286](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29948403286) | changed-path pass; physical confirmation [29949840340](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29949840340) |
| ARM64 | `Float64` | owner-waived after cross-system and physical-core evidence | [29951113391](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951113391) | changed-path pass in confirmation [29952071958](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29952071958) |
| x86_64 | `Float32` | [29948409039](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29948409039) | [29948410727](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29948410727) | changed-path pass; physical confirmation [29950525816](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29950525816) |
| x86_64 | `Float64` | [29951017421](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951017421) | [29951026334](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951026334) | aggregate changed-path improvement; owner-accepted noisy workload diagnostic |

The corrected exact-replay scaling curve uses one `Float32` throughput profile and three fresh
candidate processes at every admitted count:

| System | 1 | 2 | 4 | 8 | physical |
|---|---:|---:|---:|---:|---:|
| ARM64 | [29951110184](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951110184) | owner-waived | owner-waived | same as physical (8) | [29951111900](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951111900) |
| x86_64 | [29948425909](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29948425909) | [29951023548](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951023548) | [29951021550](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951021550) | [29951020178](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951020178) | [29951020962](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29951020962) |

The x86_64 scaling analyzer accepts all five counts, reports complete compatible identities, and
proves `exact_cross_thread_replay = true`. Its algorithm geometric-mean speedups are:

| Threads | Checkerboard | Lottery | Sequential | Sequential equilibrium |
|---:|---:|---:|---:|---:|
| 1 | 1.000 | 1.000 | 1.000 | 1.000 |
| 2 | 0.277 | 0.437 | 0.998 | 0.994 |
| 4 | 1.707 | 1.142 | 1.000 | 0.937 |
| 8 | 3.190 | 3.545 | 0.994 | 0.997 |
| 16 physical | 2.346 | 3.745 | 0.973 | 0.939 |

The non-monotonic two-thread and physical-core points are retained as measured diagnostics; the
contract requires a complete exact-replay curve, not a monotonicity claim. The accepted ARM64
endpoint analyzer also reports compatible identities and `exact_cross_thread_replay = true`, with
physical-core (8-thread) geometric-mean speedups of 1.136 for Checkerboard, 1.827 for Lottery, 0.998
for Sequential, and 0.991 for SequentialEquilibrium. The owner waived the redundant ARM64 2- and
4-thread diagnostics after reviewing the complete x86_64 curve and exact ARM64 endpoints.

The completed one-thread `Float32` evidence reports Checkerboard paired geometric-mean steady-time
ratios of 0.882 on ARM64 and 0.877 on x86_64. Every Checkerboard workload improves and every
workload in the full matrix remains inside the 5% release threshold. The literal x86_64 comparator
retains a raw `FAIL` because byte-identical `SequentialEquilibrium` records have a 1.022 paired
geometric-mean ratio. As required by the accepted Phase 12 precedent, this sub-threshold unchanged-
path diagnostic is preserved rather than relabeled; it is not evidence of a candidate-caused
regression.

The completed x86_64 one-thread `Float64` evidence reports a 0.878 paired Checkerboard geometric
mean. Every Checkerboard workload improves and passes its release threshold. Its literal aggregate
comparator preserves small unchanged-path Lottery and sequential-equilibrium movements above 1.0,
while all individual workload gates pass. The first ARM64 physical-core `Float64` run improves the
raw Checkerboard geometric mean to 0.881 and the paired geometric mean to 0.957, but one paired
Checkerboard workload and several byte-identical paths move above 5%. Confirmation 29952071958
reports a 0.975 paired Checkerboard geometric mean, every Checkerboard workload within threshold,
and different large movements in byte-identical algorithms. The earlier Checkerboard outlier does
not repeat.

The x86_64 physical-core `Float64` run reports a 0.861 raw and 0.909 paired Checkerboard geometric
mean. Its raw differential-adhesion ratio is 1.059 while its paired ratio improves to 0.901; its
paired monolayer ratio is 1.107 while its raw ratio improves to 0.969. Byte-identical Lottery and
sequential paths contain much larger sign-changing movements. The inconsistent estimators, strong
changed-path aggregate improvement, clean x86_64 one-thread evidence, and independent ARM64
confirmation support the owner's explicit decision to accept this retained noisy diagnostic without
another confirmation. The ARM64 one-thread `Float64` repeat was waived by the same decision; CPU
`Float64` correctness remains covered by the complete local suite and both physical-core systems.

The first physical-core runs contained large sign-changing ratios in both changed and byte-identical
paths, so the accepted noisy-hardware rule required five-pair confirmations. On ARM64 the
confirmation reports a 0.957 Checkerboard paired geometric mean and every Checkerboard workload is
inside threshold; the earlier unchanged `SequentialEquilibrium` outlier does not repeat. On x86_64
the first and confirmation Checkerboard paired geometric means are 0.937 and 0.977. The first run's
only pair-level Checkerboard regression above 5% is differential adhesion at 1.084; the confirmation
measures that workload at 0.882, while its different Checkerboard outliers did not appear in the
first run. Unchanged paths show the same moving, sign-changing outlier pattern. The raw comparator
failures remain retained, while the counterbalanced confirmation evidence passes the changed-path
release decision.

## Owner closure decision

On 2026-07-22, after reviewing the exact-replay analyzers, complete x86_64 scaling curve, ARM64
endpoint scaling, both `Float32` physical-core confirmations, x86_64 one-thread `Float64` result,
ARM64 physical-core `Float64` confirmation, and the raw x86_64 physical-core `Float64` diagnostic,
the project owner determined that the phase had proved enough and directed closure. Remaining ARM64
intermediate scaling, ARM64 one-thread `Float64`, and the additional x86_64 physical-core `Float64`
confirmation were stopped. This is an explicit evidence-backed acceptance, not a relabeling or
deletion of failing raw comparisons. The retained policy is conservative: specialization is limited
to small one-thread Checkerboard launches, while all multithreaded launches keep the accepted grain.

## Exact-revision protected qualification

[PR #13](https://github.com/PraneethMerugu/Potts.jl/pull/13) carried the candidate and merged as
`1bc97348057ea1fb3fa238731e16058c560843ab`. Exact audit revision
`78b34d04b09ee61044df3f85de3fc234ba611604` passed package, integration, and both authoritative CPU
jobs in [CI 29952868778](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29952868778),
documentation in [29952868775](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29952868775),
and Metal plus ROCm validation in
[29952868781](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29952868781). CUDA was skipped by
the repository's declared unavailable-runner policy. The completion audit was the only change after
scientific source revision `ad1d4e87cd8565424566713126ff41c10e790e65` produced its authoritative
performance evidence.

## Closure checklist

- [x] CPU grain policy is isolated from GPU execution and public scientific semantics.
- [x] Fixed-configuration replay, accounting, RNG, and execution-contract tests pass locally.
- [x] Shared-harness provenance and dirty-tree rejection are executable and tested.
- [x] CPU scaling analysis rejects incompatible systems, implementations, and workload matrices.
- [x] ARM64 and x86_64 paired `Float32` gates pass at one and all physical cores.
- [x] The complete x86_64 curve and owner-accepted ARM64 endpoint curve prove exact cross-thread replay.
- [x] CPU `Float64` correctness/performance evidence is accepted with the raw owner-reviewed diagnostics above.
- [x] Scaling summaries and raw artifact identities are recorded below the release revision.
- [x] Exact final revision passes protected CI, documentation, Metal, and ROCm validation.
- [x] PR #13 is merged and its immutable merge commit is recorded.

Phase 12.5 implementation is unblocked from merge commit
`1bc97348057ea1fb3fa238731e16058c560843ab`.
