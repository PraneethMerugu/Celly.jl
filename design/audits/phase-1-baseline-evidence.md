# Phase 1 Baseline Evidence

Status: Complete for the pre-refactor preservation gate
Captured: 2026-07-17
Runtime target: Julia 1.12.6 only

## Purpose and Qualification Boundary

This document records the first reproducible performance and structural-correctness evidence for
the pre-refactor engine. It is a regression reference, not an endorsement of historical semantics.
In particular, the legacy public step does not yet satisfy the accepted normalized-MCS contract,
and the current RNG does not satisfy the accepted reproducibility contract.

The captures qualify only the exact implementation fingerprint and dependency resolutions below.
They MUST NOT be presented as algorithm-equivalence, detailed-balance, statistical-correctness, or
paper-performance evidence. Those claims require the Phase 3 reference suite and later conformance
gates.

## Baseline Identity

| Field | Value |
| --- | --- |
| Canonical release | `pre-refactor-baseline-2026-07-17` |
| Repository revision | The commit locked by the canonical release tag and GitHub release attestation |
| Branch at qualification | Protected `main` |
| Working tree | Clean; every archived benchmark record reports `git_dirty = false` |
| Implementation source SHA-256 | `570b4a5e10006c27e10f03c90365240af43160c3497b9ac8aa2da62554822055` |
| Candidate capture commit | `739d8e31aa87e12641daccf653515d83b8f5623b` |
| Candidate baseline ID | `739d8e31aa87-570b4a5e1000` |
| Julia | `1.12.6` |
| Julia threads | 1 |
| KernelAbstractions | `0.9.42` |
| KernelIntrinsics | fork commit `b3a02b6e80f0839082a02f1838af7e10e992062c` |
| KernelIntrinsics source | `https://github.com/PraneethMerugu/KernelIntrinsics.jl.git` |
| Metal | `1.10.0` |
| SciMLBase | `3.36.0` in the benchmark environment |

The KernelIntrinsics dependency is pinned to an immutable fork commit. The named branch
`fix/apple-silicon-metal-support` is useful for review but MUST NOT be used as a moving benchmark
dependency.

The canonical release is the reconstruction authority. GitHub release immutability locks its tag
and attached result archives after publication and emits a signed attestation over the tag, commit,
and assets. Candidate captures above were made from the first protected merge; the final release
captures repeat the same matrix at the canonical tag revision.

## Capture Systems

- CPU: GitHub-hosted Linux x86_64, four exposed CPU threads.
- Metal: Darwin aarch64 on an Apple M1 Pro with a 14-core integrated GPU; Metal.jl reports an
  `AGXG13XDevice`.
- AMDGPU: Linux x86_64; AMDGPU.jl reports `AMD Radeon Graphics` with architecture `gfx1100`.

The full correctness suite also runs on both self-hosted architectures independently of the
GitHub-hosted CPU shards. Hardware identifiers unique to a machine are deliberately excluded from
evidence artifacts.

## Environments and Commands

The base benchmark project and each GPU runtime have separate checked-in projects and manifests.
This prevents an unused GPU stack from changing another backend's dependency resolution.

```sh
julia --project=benchmark --startup-file=no benchmark/setup.jl

julia --project=benchmark --startup-file=no benchmark/run.jl \
  --backend=cpu --workload=volume_2d_small --algorithm=checkerboard

JULIA_LOAD_PATH="benchmark/backends/metal:benchmark:@stdlib" \
  julia --startup-file=no benchmark/run.jl \
  --backend=metal --workload=volume_2d_small --algorithm=checkerboard

julia --project=benchmark --startup-file=no benchmark/summarize.jl
```

The runner rejects every Julia runtime other than 1.12.6. Compatibility with older Julia releases
is deferred until dedicated CI lanes are created during final release qualification. Provisional
Julia 1.10.11 measurements made while bootstrapping the harness are invalidated and excluded from
this document.

## Workloads

| Workload | Shape | Initial cells | Components | Class |
| --- | ---: | ---: | --- | --- |
| `volume_2d_small` | 64 × 64 | 16 | volume | latency |
| `adhesion_2d_medium` | 128 × 128 | 64 | volume, adhesion | throughput |
| `volume_3d_small` | 32 × 32 × 32 | 8 | volume | three-dimensional |
| `adhesion_2d_publication` | 256 × 256 | 100 | volume, adhesion | publication |

All algorithms are configured to an expected proposal budget of one lattice-site proposal per
public legacy step: `active_fraction = 0.1` and `sweeps_per_step = 10` in 2D, and `0.025` and `40`
in 3D. This is a measurement normalization only. It does not repair the historical step semantics
or demonstrate that every implementation executes the expected number of proposals.

## Structural Correctness Baseline

The root Julia 1.12.6 `Pkg.test()` CPU run completed in 3 minutes 55 seconds with 405 passes, one
test marked broken, and zero failures. The test entry point must be `Pkg.test()` because its runner
imports dependencies declared only as test extras.

For every successful benchmark record, both initial and final checks passed:

- tracked volume equals occupied lattice sites;
- every lattice owner is within fixed cell capacity;
- no tracked volume is negative;
- state checksums are captured before and after evolution.

These checks establish internal bookkeeping consistency only. They do not validate equilibrium
distributions, transition probabilities, detailed balance, isotropy, acceptance statistics,
algorithm comparability, or reproducibility.

The legacy root statistical suite is CPU-qualified only. Attempting to apply it wholesale to a
Metal backend exposes CPU-only setup that scalar-indexes device arrays. GPU CI therefore runs real
device smoke workloads plus explicit state invariants; it does not enable `allowscalar` or relabel
CPU-oriented tests as GPU conformance. Backend-parametric statistical conformance belongs to Phase 3.

### Protected-merge qualification

Pull request 2 qualified candidate commit `53c13526c3d2d02aa00cc5b4c6b97a576d371ef3`
before its protected squash merge:

- the stable `Required` aggregate passed after project integrity and every CPU job passed;
- the complete 405-pass, one-broken, zero-failure suite passed on native macOS ARM64 and Linux
  x86_64 self-hosted runners;
- the same suite was independently sharded across GitHub-hosted Linux runners;
- real-device Metal and AMDGPU smoke workloads passed without scalar-indexing escape hatches;
- documentation built on the pull request without permission to deploy; and
- every self-hosted job used a nested `_ci/source` checkout, leaving the developer checkout on its
  original branch and eliminating the observed worktree-mutation hazard.

The qualifying workflow runs are CI `29617503153`, GPU Validation `29617503169`, and
Documentation `29617503143`. Protected `main` requires the repository-owned `Required` check,
linear history, pull requests, resolved review conversations, and forbids force pushes and branch
deletion. Post-merge and canonical-tag workflow identifiers are recorded in the immutable release
notes.

## Performance Captures

Every steady-state GPU sample synchronizes the active KernelAbstractions backend inside the timed
region. First-MCS time includes first execution after integrator construction. Host bytes and host
allocations are BenchmarkTools observations for one evolved step; they are not device-allocation
measurements.

| Backend | Workload | Algorithm | Median MCS/s | First MCS (s) | Host bytes | Host allocs |
|---|---|---|---:|---:|---:|---:|
| CPU | `volume_2d_small` | sequential | 392.073 | 0.561314 | 1,710,448 | 32,897 |
| CPU | `volume_2d_small` | lottery | 1,104.409 | 0.490790 | 6,992 | 229 |
| CPU | `volume_2d_small` | checkerboard | 3,126.866 | 0.448036 | 28,272 | 939 |
| CPU | `adhesion_2d_medium` | sequential | 98.086 | 0.281941 | 6,824,912 | 131,247 |
| CPU | `adhesion_2d_medium` | lottery | 283.207 | 0.388847 | 7,312 | 229 |
| CPU | `adhesion_2d_medium` | checkerboard | 986.188 | 0.411498 | 30,832 | 939 |
| CPU | `volume_3d_small` | sequential | 46.284 | 0.985079 | 13,628,432 | 262,089 |
| CPU | `volume_3d_small` | lottery | 12.366 | 1.238487 | 27,152 | 889 |
| CPU | `volume_3d_small` | checkerboard | 144.852 | 1.196709 | 232,592 | 7,409 |
| CPU | `adhesion_2d_publication` | sequential | 24.226 | 0.041157 | 27,275,472 | 524,527 |
| CPU | `adhesion_2d_publication` | lottery | 73.389 | 0.013781 | 7,312 | 229 |
| CPU | `adhesion_2d_publication` | checkerboard | 271.036 | 0.003853 | 30,832 | 939 |
| Metal | `volume_2d_small` | lottery | 1,276.833 | 1.706372 | 53,920 | 1,310 |
| Metal | `volume_2d_small` | checkerboard | 508.911 | 0.444666 | 205,376 | 5,122 |
| Metal | `adhesion_2d_medium` | lottery | 811.743 | 0.416709 | 61,504 | 1,440 |
| Metal | `adhesion_2d_medium` | checkerboard | 641.129 | 0.359017 | 219,456 | 5,202 |
| Metal | `volume_3d_small` | lottery | 15.847 | 0.692342 | 190,976 | 4,682 |
| Metal | `volume_3d_small` | checkerboard | 94.393 | 0.521044 | 1,694,288 | 40,686 |
| Metal | `adhesion_2d_publication` | lottery | 741.256 | 0.001732 | 61,504 | 1,440 |
| Metal | `adhesion_2d_publication` | checkerboard | 397.446 | 0.003061 | 219,456 | 5,202 |
| AMDGPU | `volume_2d_small` | lottery | 1,362.008 | 2.253203 | 45,072 | 1,059 |
| AMDGPU | `volume_2d_small` | checkerboard | 2,923.310 | 0.731767 | 162,880 | 3,860 |
| AMDGPU | `adhesion_2d_medium` | lottery | 48.959 | 0.694350 | 55,088 | 1,361 |
| AMDGPU | `adhesion_2d_medium` | checkerboard | 1,888.604 | 0.625498 | 168,528 | 3,853 |
| AMDGPU | `volume_3d_small` | lottery | 24.271 | 0.946482 | 161,808 | 3,907 |
| AMDGPU | `volume_3d_small` | checkerboard | 46.868 | 0.762608 | 1,313,744 | 30,666 |
| AMDGPU | `adhesion_2d_publication` | lottery | 46.896 | 0.018846 | 57,904 | 1,434 |
| AMDGPU | `adhesion_2d_publication` | checkerboard | 47.135 | 0.000451 | 174,544 | 4,126 |

Sequential is intentionally CPU-only in the current baseline. Raw timing samples, initialization,
backend adaptation, workload construction, state checksums, invariants, and full provenance are
stored using schema version 1.0.0. The candidate full captures are workflow runs `29618327286`
(CPU), `29618332623` (Metal), and `29618338692` (AMDGPU). The canonical reruns are attached to the
immutable release rather than relying on the ignored local `benchmark/results/` tree.

First-MCS is the first execution after constructing each integrator, not a fresh-process latency
for every row. Because the full matrix intentionally runs several cases in one Julia process,
later rows may reuse compiled code. Raw records preserve case order and separate workload build,
backend adaptation, integrator initialization, first execution, and warm samples.

## Defects Exposed by the Harness

1. `IntrinsicCheckerboardMetropolis` cannot execute on Metal with the resolved modern stack. It
   calls `KernelAbstractions.Event`, which no longer exists. Intrinsic results are therefore absent,
   and the algorithm is not a qualified Metal baseline. The contract suite excludes it by default;
   set `POTTS_TEST_INTRINSIC=true` to reproduce the known failure until Phase 5 replaces the
   obsolete ordering mechanism.
2. The 3D lottery implementation achieves only 12.366 MCS/s on CPU and 15.847 MCS/s on Metal,
   versus 144.852 and 94.393 MCS/s for checkerboard. AMDGPU raises lottery to 24.271 MCS/s but
   remains below its 46.868 MCS/s checkerboard result. Hardware acceleration does not remove the
   current 3D lottery bottleneck.
3. Sequential execution allocates per attempted proposal: the publication workload reports over
   27 MB and 524,527 host allocations per public step.
4. GPU first-MCS latency is order- and workload-sensitive and reaches 2.253 seconds in the AMDGPU
   capture. Compilation, launch, adaptation, and first-use costs require separate fresh-process
   treatment in future user-facing performance claims.
5. Neither GPU is uniformly faster. The AMDGPU adhesion lottery results collapse to roughly
   47-49 MCS/s while checkerboard ranges from 47 to 1,889 MCS/s, depending on workload. Backend
   selection and claims must distinguish latency, throughput, dimensionality, and algorithm family.

## Deliberate Qualification Boundary

The historical engine exposes no semantic proposal, acceptance, rejection, or conflict counters,
and no device launch, transfer, device-allocation, scratch, or peak-memory counters. The raw schema
records this absence explicitly in `known_limitations`; it MUST NOT encode inferred values as
measurements. Invasively instrumenting the old engine before freezing it would create a different
implementation and weaken the preservation baseline. The replacement engine must expose these
counters before performance qualification in Phases 3, 5, and 12.

Likewise, state invariants are not reference-model, detailed-balance, isotropy, or statistical
correctness evidence. Those remain Phase 3 conformance obligations. CUDA is recorded as unavailable,
not emulated. Whether intrinsic is repaired or excluded remains decision gate D1.

With those boundaries, the Phase 1 preservation gate is complete: a clean checkout can reproduce
the suite and benchmark matrix; CPU, Metal, and AMDGPU have hardware-backed captures; cold and warm
timings are separated; known invalid semantics are warnings rather than targets; and the canonical
revision and raw evidence are published as an immutable, attested release.
