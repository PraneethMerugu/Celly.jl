# Phase 12.5 completion audit

Status: In progress; no disposition recorded

Date: 2026-07-22

## Decision boundary

This audit evaluates the accepted
[`phase-12-5-tiled-checkerboard-contract.md`](phase-12-5-tiled-checkerboard-contract.md)
without narrowing its scope around the implementation that happens to exist. Phase 12.5 is not
complete until this document records one disposition (`release-eligible`, `experimental`, or
`rejected`), every retained claim has exact-revision evidence, protected CI is green, and the
resulting branch is merged.

Evidence statuses used below are `proved`, `contradicted`, `incomplete`, and `missing`.

## Chunk audit

| Chunk | Requirement | Current evidence | Status |
|---|---|---|---|
| 12.5A | Published assumptions and matched baselines | `phase-12-5-sultan-assumption-ledger.md` separates published facts, reconstruction choices, and unavailable details. Differential- and uniform-adhesion fixtures are in the backend matrix. | incomplete: publication-scale CPU/Metal/ROCm raw baselines are not yet archived |
| 12.5B | Executable semantics independent of optimization | Versioned algorithm identity, topology-derived coloring, semantic RNG addresses, logical reference, exact report partition, replay, observation invariance, and registered statistical design are tested. | proved for the implemented component set on CPU |
| 12.5C | Resident 2D volume/adhesion with shared and global storage | Device-global and cooperative `@localmem` paths share the ordered tile proposal core. CPU tests require exact lattice, tracker, and report identity with the logical reference. | incomplete: real Metal/ROCm exact-revision execution is running |
| 12.5D | Open physics and 3D | Qualified: volume, exact edge-count surface/perimeter, adhesion, prescribed-field occupancy energy, chemotaxis, `PositiveYield`, and 2D/3D global/local storage. Unsupported access fails at construction. | incomplete: directional motility, Act-like state, applicable HST state, and downstream custom-component optimization evidence are absent |
| 12.5E | At least two representative GPU workloads improve by 2x | CPU 256² ablation measured Checkerboard at about 2.22 ms/MCS, tiled global at 8.67 ms/MCS, and tiled local at 9.34 ms/MCS. CPU is not the GPU gate. | missing: no passing real-GPU tiled performance record yet |
| 12.5F | Registered scientific and Sultan comparison battery | Seed sets, observables, exact gates, and equivalence margins are registered before closure runs. | missing: the registered ensembles and external reconstruction measurements have not run |
| 12.5G | Toolkit, docs, disposition, protected revision, merge | Ordinary Toolkit `solve` coverage passes; experimental documentation explains semantics, controls, provenance, and failures. PR #15 is open. | incomplete: audit/disposition/protected checks/merge remain |

## Exact implementation evidence retained so far

- Phase 12.CPU prerequisite merged at `160d7addc36b5454e0edcbe206930eb6d40275a5`.
- Portable fields/reconciliation checkpoint: `ed09db6691aa834c0f91acc85ecc4fc8d89ed1e4`.
- Cooperative local-memory checkpoint: `aa39f626cf79b041dcdcbf775046ebc1971f275c`.
- Surface/reducer checkpoint: `48e998c9f3d45172a3779321501d2bb3146fd341`.
- Current local CorePotts suite: 3,132 passed and one pre-existing broken test.
- Current focused tiled suite: 137 passed, including logical/global/local equality for surface
  reconciliation.
- Current Toolkit Level 1 integration: 4 passed.

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

## Closure actions still required

1. Obtain passing exact-revision Metal and ROCm execution plus raw tiled/checkerboard measurements.
2. Decide from those profiles whether further workgroup/intrinsic optimization is justified or the
   performance gate is contradicted.
3. Run the registered exact/statistical battery at the tier required by the retained disposition.
4. Resolve every missing initial-physics item or record it as a failed release gate in an explicit
   experimental/reject disposition.
5. Update Phase 13 entry guidance, make documentation match the disposition, pass protected checks,
   merge PR #15, and replace this status with final retained evidence.
