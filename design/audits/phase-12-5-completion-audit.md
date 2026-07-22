# Phase 12.5 completion audit

Status: Completed; experimental disposition

Date: 2026-07-22

## Decision boundary

This audit evaluates the accepted
[`phase-12-5-tiled-checkerboard-contract.md`](phase-12-5-tiled-checkerboard-contract.md)
without narrowing its scope around the implementation that happens to exist. Phase 12.5 is not
complete until this document records one disposition (`release-eligible`, `experimental`, or
`rejected`), every retained claim has exact-revision evidence, protected CI is green, and the
resulting branch is merged.

Evidence statuses used below are `proved`, `contradicted`, `incomplete`, and `missing`.

## Owner disposition

The recorded disposition is **experimental**. On 2026-07-22 the owner authorized proceeding toward
closure after reviewing the current architecture and negative performance evidence. The retained
algorithm is a research surface for tiled semantics, portable workgroup-local storage, and future
architecture experiments. It is not release-eligible, is never selected automatically, and is not
part of the stable performance or paper-claim surface.

This disposition follows from four independent boundaries:

1. CPU measurements materially regress the ordinary checkerboard engine, and ROCm smoke evidence
   does not show an end-to-end benefit.
2. The exact snapshot/reconciliation schedule has repeated global kernel boundaries; the local
   kernel cooperatively loads the halo but deliberately executes ordered proposals in one lane.
3. Directional motility, Act-like state, applicable HST state, and custom optimized component
   evidence remain unqualified.
4. The registered closure ensembles and paper-scale repeated GPU performance matrix have not run.
   Therefore no statistical-equivalence, 2x speedup, fastest-engine, or production-readiness claim
   can be made.

## Chunk audit

| Chunk | Requirement | Current evidence | Status |
|---|---|---|---|
| 12.5A | Published assumptions and matched baselines | `phase-12-5-sultan-assumption-ledger.md` separates published facts, reconstruction choices, and unavailable details. Differential- and uniform-adhesion fixtures are in the backend matrix. | incomplete: publication-scale CPU/Metal/ROCm raw baselines are not yet archived |
| 12.5B | Executable semantics independent of optimization | Versioned algorithm identity, topology-derived coloring, semantic RNG addresses, logical reference, exact report partition, replay, observation invariance, and registered statistical design are tested. | proved for the implemented component set on CPU |
| 12.5C | Resident 2D volume/adhesion with shared and global storage | Device-global and cooperative `@localmem` paths share the ordered tile proposal core. CPU tests require exact lattice, tracker, and report identity with the logical reference. Exact revision `4c66d92...` passed the tiled gate and full backend matrix on Metal and ROCm in run `29962724775`. | proved for the retained experimental component set |
| 12.5D | Open physics and 3D | Qualified: volume, exact edge-count surface/perimeter, adhesion, prescribed-field occupancy energy, chemotaxis, `PositiveYield`, and 2D/3D global/local storage. Unsupported access fails at construction. | incomplete: directional motility, Act-like state, applicable HST state, and downstream custom-component optimization evidence are absent |
| 12.5E | At least two representative GPU workloads improve by 2x | CPU 256² ablation measured Checkerboard at about 2.22 ms/MCS, tiled global at 8.67 ms/MCS, and tiled local at 9.34 ms/MCS. In exact-revision 24² smoke artifacts, tiled was 3.313 versus 1.164 ms/MCS on Metal and 20.809 versus 9.740 ms/MCS on ROCm for differential adhesion. Uniform adhesion was 3.523 versus 0.679 ms/MCS on Metal and 21.224 versus 0.112 ms/MCS on ROCm. | contradicted at smoke scale; paper-scale repeated performance gate was not run and no speedup claim is retained |
| 12.5F | Registered scientific and Sultan comparison battery | Seed sets, observables, exact gates, and equivalence margins are registered before closure runs. | missing: the registered ensembles and external reconstruction measurements have not run |
| 12.5G | Toolkit, docs, disposition, protected revision, merge | Ordinary Toolkit `solve` coverage passes; experimental documentation explains semantics, controls, provenance, failures, and nonclaims. The owner disposition is experimental and Phase 13/15 guidance excludes stable or paper claims. Exact protected checks passed and PR #15 merged. | proved for the experimental disposition |

## Exact implementation evidence retained so far

- Phase 12.CPU prerequisite merged at `160d7addc36b5454e0edcbe206930eb6d40275a5`.
- Portable fields/reconciliation checkpoint: `ed09db6691aa834c0f91acc85ecc4fc8d89ed1e4`.
- Cooperative local-memory checkpoint: `aa39f626cf79b041dcdcbf775046ebc1971f275c`.
- Surface/reducer checkpoint: `48e998c9f3d45172a3779321501d2bb3146fd341`.
- ROCm run `29960853761`, job `89061287751`, passed on the exact source tree for the surface/reducer
  checkpoint. Its retained artifact is
  `gpu-smoke-rocm-ed1115d2fc28ef826f1cb58b36c277f690d4e4fe`; the `ed1115d2...` identity is the
  GitHub pull-request merge revision, while the job metadata records head SHA `48e998c...`.
- Current local CorePotts suite: 3,132 passed and one pre-existing broken test.
- Current focused tiled suite: 137 passed, including logical/global/local equality for surface
  reconciliation.
- Current Toolkit Level 1 integration: 4 passed.
- Exact implementation revision: `4c66d929f90388a7ce2bf4fb2890930ba8ff3be4`.
- CI run `29962724740` passed hosted packages and integration, Linux x86_64 CPU, macOS
  ARM64 CPU, project integrity, and the aggregate required gate.
- Documentation run `29962724854` passed.
- GPU run `29962724775` passed the early tiled workgroup-local gate and the full backend matrix on
  Metal job `89067284790` and ROCm job `89067284857`; CUDA was skipped by the declared unavailable-
  runner policy.
- Exact GPU artifacts are
  `gpu-smoke-metal-ac8644a57b95d5b55a23101b4513f15332588409` with SHA-256
  `10b1a06432bea3a3c0f2ca8c2190bd41bac0b301d88388ed1928178a30d9c349`, and
  `gpu-smoke-rocm-ac8644a57b95d5b55a23101b4513f15332588409` with SHA-256
  `79b4fcb709969f25961d4a5eb6712add616a66cbd44e049fbff6696c010c7162`. The artifact
  name contains GitHub's pull-request merge revision; workflow metadata records head SHA
  `4c66d92...`.
- Implementation PR #15 merged as `aa3ca6f767cccb255e3f6bbf76bf9bcc283552f4`.

## Known failures and non-claims

1. A prior real-ROCm run proved that the cooperative tiled kernel compiled but the first report
   reducer did not: dynamic `ntuple` indexing produced invalid AMDGPU IR. Commit `48e998c` replaces
   that reducer with eight explicit scalar accumulators. The failed revision is not correctness or
   performance evidence for the replacement.
2. The CPU candidate is materially slower than `CheckerboardSweepCPM` at 256² and allocates
   hundreds of kilobytes of host launch bookkeeping per MCS in the current KernelAbstractions CPU
   path. No CPU speedup is claimed.
3. Published Sultan ratios are descriptive only. Potts.jl has not reproduced identical model,
   hardware, and timing identities and makes no cross-hardware fastest claim.
4. No GPU ≥2x gate, statistical-equivalence gate, or release-eligible disposition is currently
   proved.
5. Earlier Metal job `89061287742` is not negative device evidence. Its sole GitHub annotation says
   the self-hosted runner lost communication with the service; no failed kernel or test log was
   produced. Exact-revision Metal job `89067284790` subsequently passed.

## Retained surface and nonclaims

- `TiledCheckerboardCPM` remains explicitly selected and documented as experimental.
- `shared_memory = :auto`, `:required`, and `:disabled` remain available for research ablation.
- Unsupported physics continues to fail during construction rather than disappearing in a kernel.
- No automatic GPU policy may select the tiled engine.
- No stable API, detailed-balance, statistical-equivalence, 2x speedup, Sultan reproduction,
  production-backend, or fastest-engine claim is retained.

## Exact-revision protected qualification

PR #15 carried the implementation and experimental disposition. Revision
`4c66d929f90388a7ce2bf4fb2890930ba8ff3be4` passed CI
[`29962724740`](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29962724740),
documentation [`29962724854`](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29962724854),
and Metal plus ROCm validation
[`29962724775`](https://github.com/PraneethMerugu/Potts.jl/actions/runs/29962724775). It merged as
`aa3ca6f767cccb255e3f6bbf76bf9bcc283552f4`. This closeout changes only the audit record after that
scientific source revision.

## Closure checklist

- [x] A serious portable tiled candidate, executable reference, and open component protocol exist.
- [x] Device-global and cooperative `@localmem` paths agree for the retained component set.
- [x] CPU, Metal, and ROCm compile and execute the exact retained implementation.
- [x] Warm GPU execution asserts zero device allocation and host synchronization.
- [x] Raw matched smoke artifacts and negative performance evidence are retained.
- [x] Missing physics, statistical ensembles, and paper-scale performance remain explicit failed
  release gates rather than implied claims.
- [x] Documentation and Phase 13/15 guidance match the experimental disposition.
- [x] Exact protected CI, documentation, Metal, and ROCm validation pass.
- [x] PR #15 is merged and its immutable merge commit is recorded.

Phase 13 is unblocked from merge commit `aa3ca6f767cccb255e3f6bbf76bf9bcc283552f4` with
`TiledCheckerboardCPM` outside the stable and automatic-selection surfaces.
