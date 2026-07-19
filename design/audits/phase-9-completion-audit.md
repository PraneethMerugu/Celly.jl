# Phase 9 Completion Audit

Date: 2026-07-19

Status: Candidate — implementation, CPU, and Metal complete; authoritative ROCm and repository CI
pending

## Verdict

Phase 9 has a complete local implementation of the accepted SciML problem, integrator, solution,
callback, observation, checkpoint, symbolic-indexing, and ensemble contract. The final interface is
a thin control and observation layer over the Phase 7--8 scientific integrator; it does not define
a second proposal, acceptance, transaction, lifecycle, mechanics, or RNG path.

The phase is not marked authoritative `Complete` until the candidate commit passes the existing
Julia 1.12.6 required repository workflow and the independent AMDGPU/ROCm runner. This is an
evidence gate, not missing design or local implementation work.

## Chunk results

| Chunk | Result | Evidence |
| --- | --- | --- |
| 9.0 legacy/open protocols | Locally complete | Final-name evacuation audit; hard containment checker; open downstream algorithm/proposal fixture; typed backend capabilities; extension RNG namespaces; curated CorePotts legacy exports |
| 9.1 model/problem/remake | Complete | Immutable typed model and problem; copy/alias/device ownership; integer MCS; fixed capacity; deterministic seed; aggregate errors; remake and explicit thread-safe trajectory-free cache |
| 9.2 integrator/MCS | Complete | `__init`, `__solve`, `init`, `solve`, `solve!`, `step!`, `terminate!`; one algorithm-owned MCS operation; strict options and retcodes |
| 9.3 observation/solution | Complete | Exact integer saving and lookup; independent backend, host, and observable snapshots; typed observable handles; stats and provenance; no-sync display |
| 9.4 callbacks/control | Complete for accepted Phase 9 scope | Standard discrete host callbacks share one declared boundary; typed device callback hook remains resident; continuous callbacks are rejected; termination and type-preserving parameter updates are tested |
| 9.5 persistence | Complete | Canonical checkpoint capture, retained checkpoint collection, exact restore, logical import, and uninterrupted-versus-restored equality |
| 9.6 ensembles/indexing | Complete | Stable Philox-derived trajectory/rerun seeds; user-managed override; `prob_func` ordering; bounded reruns; serial/threaded CPU invariance; unsafe same-device GPU threading rejected; typed parameter/observable indexing |
| 9.7 qualification/benchmarks | Local CPU and Metal complete | Same 2D/3D three-algorithm qualifier on both backends; direct/SciML launch and boundary counters; layered Phase 9 timing records; ROCm wired into the same CI matrix |

## Architectural and API evidence

The historical meanings of `PottsProblem`, `PottsIntegrator`, and `PottsSolution` were moved to
unexported `LegacyPotts*` names before the final bindings were introduced. The hard containment
checker prohibits those names on the protected scientific/SciML path and requires any remaining
production or consumer use to be frozen in the manifest.

CorePotts no longer exports historical `PottsState`, `PottsParameters`, `PottsCache`, sampler, or
Metropolis-engine names. PottsToolkit imports and re-exports that temporary surface explicitly so
the current DSL remains usable until its Phase 10 replacement. This avoids pretending that a broad
CorePotts export is stable while keeping the owning migration phase clear.

The replacement algorithm path contains no concrete algorithm union. A downstream test type
subtypes the ordered algorithm family, supplies scientific identity, guarantee, proposal-law, and
acceptance-law methods, and executes through the ordinary final `solve` interface. A separate mock
backend supplies a non-enum backend-family value and typed capabilities. Extension RNG namespaces
use stable 128-bit identities, domain-separated seeds, deterministic lowering, and collision
validation.

## SciML semantic evidence

- `solve(prob, alg)` and `solve!(init(prob, alg))` agree.
- Manual stepping, continuation, terminal errors, early termination, and `maxiters` have explicit
  tests and SciML return codes.
- `remake` preserves problem immutability; explicit initial-state aliasing has a lease preventing
  concurrent live integrators.
- Saving occurs only at exact integer MCS values. No interpolation exists and requesting an
  unsaved time throws a structured error.
- Observable indexing reads retained named values only. It never recomputes or transfers an
  unsaved observable.
- Host callbacks use one logical snapshot per completed-MCS boundary. Device callbacks execute
  through a typed bounded hook without a host callback boundary.
- Parameter changes preserve the concrete parameter, problem, and compiled-component structure;
  structural changes require `remake` and `init`.
- Live final or direct scientific integrators reject raw Julia serialization and direct users to
  canonical checkpoints; host problems remain distributable.
- Checkpoints retain exact continuation semantics and logical import remains a visibly weaker,
  separate operation.
- Ensemble seeds depend on the master seed, trajectory identity, and rerun identity rather than
  scheduling, worker assignment, or completion order.
- Generic adaptive, continuous-time, continuous-callback, interpolation, and `sensealg` concepts
  are rejected rather than silently accepted.

## GPU and performance evidence

The Phase 9 qualifier constructs one semantic fixture in 2D and 3D and runs `SequentialCPM`,
`CheckerboardSweepCPM`, and `LotteryCPM` through both direct and SciML paths. On local CPU and real
Apple Metal:

- direct and wrapped launches per MCS are identical: 1 for sequential, 16 for checkerboard, and
  42/58 for 2D/3D lottery on the qualification fixture;
- a warm unobserved wrapper MCS adds zero synchronization and zero device-to-host transfer;
- ownership trajectories agree after explicit observation;
- exact wrapper checkpoint continuation agrees;
- default GPU snapshots remain backend resident and do not alias;
- the typed device callback records zero host callback boundaries;
- an explicit observable-only host policy returns the declared value; and
- type-preserving parameter updates remain GPU compatible with no synchronization or
  device-to-host transfer; and
- serial GPU ensemble trajectories receive the specified semantic seeds.

The layered timing function records construction plus synchronized direct and wrapped steady MCS
times separately. Tiny smoke-fixture timing is diagnostic and is not used to claim speedups or
regressions; the accepted 5% gate applies to dedicated paper workloads on frozen runners. Structural
counters are the authoritative zero-extra-work evidence for the wrapper.

## Local verification

- Julia target: 1.12.6 only.
- Focused Phase 9 interface suite: 108 passes, including concurrent compilation-cache access and
  independent trajectory-state ownership.
- Complete CorePotts suite through canonical `Pkg.test()`: 2,885 passes and one intentional broken
  test.
- PottsToolkit post-curation suite through canonical `Pkg.test()`: 219 passes; randomized layout
  assertions make the historical raw count input dependent.
- Complete cross-package CPU integration suite: 155 passes, including three real one-worker
  distributed-ensemble assertions.
- Phase 9 CPU qualification and measurement: green.
- Exact Apple Metal CI smoke matrix, including Phase 9 qualification, measurement, and legacy
  benchmark workloads: green.
- Hard legacy containment: green with 22 frozen files, 5 mixed production signatures, 57 frozen
  consumer signatures, and a clean protected path.

## Remaining authoritative gate

The existing `gpu-validation.yml` Metal and ROCm jobs call `benchmark/matrix.jl`; the matrix now
requires `PHASE9_QUALIFICATION` and `PHASE9_PERFORMANCE` in addition to all earlier phase records.
The candidate becomes complete only after a pushed commit passes:

1. project structure, hard containment, whitespace, package, integration, macOS ARM64, and Linux
   x86_64 required CI;
2. real Apple Metal smoke qualification; and
3. independent real AMDGPU/ROCm smoke qualification using the same Phase 9 code and fixtures.

CUDA and evolving PDE-field execution remain explicitly deferred. Tutorial and paper-facing API
migration remain assigned to Phases 10--11 after the typed PottsToolkit compiler and DSL are final.
