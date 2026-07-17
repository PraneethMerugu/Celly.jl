# Phase 1 Baseline Evidence

Status: In progress
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
| Repository commit | `b315ef1aecf101663472b1f71c9fe07ecc420575` |
| Branch at capture | `main` |
| Working tree | Dirty; implementation changes predated this capture |
| Implementation source SHA-256 | `d73c5805a1b05a0c14e134610743a390cc98f5b17229cb1b300ea6edd2995e7a` |
| Tracked implementation diff SHA-256 | `c88775d69d3b69af242b780f3a526f6562691bfb14ff0fcfcefaf8d167096498` |
| Baseline ID | `b315ef1aecf1-d73c5805a1b0` |
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

The dirty implementation is fingerprinted but cannot yet be reconstructed from the repository
commit alone. Phase 1 cannot pass its clean-checkout exit gate until this exact baseline state is
committed or archived as an immutable snapshot.

## Capture Machine

- macOS 15.6.1, build 24G90, Darwin arm64
- MacBook Pro 18,3 with Apple M1 Pro
- 8 CPU cores: 6 performance and 2 efficiency
- 16 GB unified memory
- 14-core integrated Apple GPU; Metal supported
- Metal device reported by Metal.jl as `AGXG13XDevice`

Hardware identifiers unique to the machine are deliberately excluded from evidence artifacts.

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

## Performance Captures

Every steady-state GPU sample synchronizes the active KernelAbstractions backend inside the timed
region. First-MCS time includes first execution after integrator construction. Host bytes and host
allocations are BenchmarkTools observations for one evolved step; they are not device-allocation
measurements.

| Backend | Workload | Algorithm | Median MCS/s | First MCS (s) | Host bytes | Host allocs |
|---|---|---|---:|---:|---:|---:|
| CPU | `volume_2d_small` | sequential | 810.482 | 0.301455 | 1,710,448 | 32,897 |
| CPU | `volume_2d_small` | lottery | 1,234.949 | 0.413144 | 11,568 | 317 |
| CPU | `volume_2d_small` | checkerboard | 4,461.378 | 0.390558 | 32,848 | 1,027 |
| CPU | `adhesion_2d_medium` | sequential | 210.133 | 0.341605 | 6,824,912 | 131,247 |
| CPU | `adhesion_2d_medium` | lottery | 328.486 | 0.461016 | 17,872 | 427 |
| CPU | `adhesion_2d_medium` | checkerboard | 1,361.818 | 0.407237 | 41,392 | 1,137 |
| CPU | `volume_3d_small` | sequential | 101.902 | 0.803781 | 13,628,432 | 262,089 |
| CPU | `volume_3d_small` | lottery | 14.367 | 0.988119 | 27,152 | 889 |
| CPU | `volume_3d_small` | checkerboard | 248.154 | 0.868659 | 232,592 | 7,409 |
| CPU | `adhesion_2d_publication` | sequential | 52.619 | 0.349384 | 27,275,472 | 524,527 |
| CPU | `adhesion_2d_publication` | lottery | 82.479 | 0.468762 | 17,872 | 427 |
| CPU | `adhesion_2d_publication` | checkerboard | 363.851 | 0.431273 | 41,392 | 1,137 |
| Metal | `volume_2d_small` | lottery | 1,262.559 | 2.416549 | 53,920 | 1,310 |
| Metal | `volume_2d_small` | checkerboard | 496.535 | 2.431005 | 209,952 | 5,210 |
| Metal | `adhesion_2d_medium` | lottery | 775.269 | 2.431465 | 61,504 | 1,440 |
| Metal | `adhesion_2d_medium` | checkerboard | 624.724 | 2.488170 | 230,016 | 5,400 |
| Metal | `volume_3d_small` | lottery | 14.803 | 2.598735 | 190,976 | 4,682 |
| Metal | `volume_3d_small` | checkerboard | 91.307 | 2.588544 | 1,694,288 | 40,686 |
| Metal | `adhesion_2d_publication` | lottery | 421.585 | 2.450630 | 61,504 | 1,440 |
| Metal | `adhesion_2d_publication` | checkerboard | 311.393 | 2.457818 | 230,016 | 5,400 |

Sequential is intentionally CPU-only in the current baseline. Raw timing samples, initialization,
backend adaptation, workload construction, state checksums, invariants, and full provenance are
stored in the ignored `benchmark/results/` tree using schema version 1.0.0.

## Defects Exposed by the Harness

1. `IntrinsicCheckerboardMetropolis` cannot execute on Metal with the resolved modern stack. It
   calls `KernelAbstractions.Event`, which no longer exists. Intrinsic results are therefore absent,
   and the algorithm is not a qualified Metal baseline. The contract suite excludes it by default;
   set `POTTS_TEST_INTRINSIC=true` to reproduce the known failure until Phase 5 replaces the
   obsolete ordering mechanism.
2. The 3D lottery implementation achieves only 14.367 MCS/s on CPU and 14.803 MCS/s on Metal,
   versus 248.154 and 91.307 MCS/s for checkerboard. Hardware acceleration does not address the
   current 3D lottery bottleneck.
3. Sequential execution allocates per attempted proposal: the publication workload reports over
   27 MB and 524,527 host allocations per public step.
4. GPU first-MCS latency is approximately 2.2–2.6 seconds for these cases. Compilation, launch,
   adaptation, and first-use costs require separate treatment in future user-facing performance
   claims.
5. Metal is not uniformly faster at small scale. Backend selection and benchmark claims must
   distinguish latency, throughput, dimensionality, and algorithm family.

## Missing Evidence Before the Phase 1 Exit Gate

- Commit or immutably archive the exact dirty baseline implementation.
- Add actual proposal, acceptance, rejection, conflict, launch, synchronization, transfer, device
  allocation, scratch-memory, and peak-memory counters without changing engine semantics.
- Add reference-model and statistical correctness captures in Phase 3; current state invariants are
  insufficient for scientific qualification.
- Capture CUDA and AMDGPU on real compatible hardware. No such hardware is available on this host.
- Archive raw machine-readable results in a durable paper or CI artifact store rather than relying
  on the intentionally ignored local result directory.
- Decide whether intrinsic is repaired and retained as a paper algorithm or excluded at decision
  gate D1.

Phase 1 remains in progress. The harness and first CPU/Metal evidence are usable immediately for
regression detection, but the roadmap's clean-checkout reproducibility gate has not yet passed.
