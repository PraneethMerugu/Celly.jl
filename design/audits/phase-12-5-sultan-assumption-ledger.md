# Phase 12.5 Sultan comparison assumption ledger

Status: Published facts extracted; reconstructed fixtures pending measurement

Date: 2026-07-22

## Sources and comparison boundary

The primary source is Sultan et al., *A parallelized cellular Potts model that enables simulations
at tissue scale* ([arXiv:2312.09317](https://arxiv.org/abs/2312.09317)). The associated public
implementation is [shabaz/gpu-cpm](https://github.com/shabaz/gpu-cpm). Published ratios remain
descriptive unless model semantics, proposal process, MCS definition, precision, hardware, lattice,
and timing boundary are matched. Phase 12.5 does not infer absolute Potts.jl throughput from a
published ratio.

## Published facts

| Topic | Recorded fact | Use in Phase 12.5 |
|---|---|---|
| 2D scaling model | Cell sorting; lattice sizes from `128^2` through `8192^2`; results normalized to the `2048^2` case | Reconstruct a separately named 2D sorting fixture and retain every absolute Potts.jl measurement |
| 3D scaling model | Collective model; sizes normalized to the `256^3` case | Reconstruct only after every required parameter and state variable is classified |
| Measurement schedule | 100 burn-in MCS followed by 100 measured MCS | Use this as the publication reconstruction boundary; keep compile and first-MCS tiers separate |
| Repetition | 2D averages five runs; 3D averages two runs | Potts.jl release gates still require its own independent-process repetition contract |
| Proposal/acceptance family | Moore-neighborhood copy attempts with Metropolis acceptance | Record all differences from Potts.jl proposal and normalized-MCS semantics |
| Tile mechanism | 2D work assigns a `4 x 4` local area per thread and uses a `2 x 2` checkerboard arrangement | Seed the explicit 2D tile policy; it is not accepted as an unmeasured default |
| Synchronization | Workgroup barriers occur after copy attempts in the shared-memory implementation | Treat barrier count as a measured implementation property, not scientific time |
| Mechanism attribution | Shared memory alone is reported near `1.2x`, specialization near `3.9x`, and their combination near `10.3x` in the stated experiment | Require end-to-end ablations; no isolated mechanism inherits the combined claim |
| 3D storage | The paper reports that the 3D implementation could not use the same shared-memory strategy | Qualify a separately labeled device-global or streamed-halo 3D policy |
| Reference hardware | Reported experiments include an NVIDIA Titan V GPU and AMD Ryzen Threadripper 2950X CPU | Never compare those ratios directly with the Potts.jl Metal and ROCm runner measurements |

## Explicit reconstruction choices

These are Potts.jl choices, not claims about unavailable source details:

1. `TiledCheckerboardCPM` is a distinct algorithm with exact mutable-site attempt-budget MCS
   normalization.
2. Active tiles have disjoint writes and topology-derived read halos. A deterministic greedy color
   schedule handles odd periodic tile grids rather than assuming an even lattice.
3. Random identities include MCS, tile-color subround, tile ID, local proposal index, and draw
   purpose. GPU launch geometry cannot enter the address.
4. Volume and unordered adhesion form the first 2D vertical slice. Other physics enters only through
   the open tiled-access and reconciliation protocol.
5. `Float32` is the cross-backend performance precision. CPU `Float64` is a separately reported
   reference and is never substituted into a GPU comparison.
6. Publication-scale timing excludes compilation, initialization, observation, and host transfer;
   those remain separately measured tiers.

## Details not established by the paper alone

- exact initial lattice labels and per-cell geometry for every scaling point;
- every Hamiltonian coefficient, type-interaction matrix entry, and temperature used by each figure;
- the complete RNG mapping and whether schedules reproduce across launch geometry;
- the exact normalization of attempted copies to one public MCS in every kernel variant;
- compiler, driver, clock, thermal, and power-state details sufficient for an absolute rerun;
- all boundary-condition and halo behavior at partial edge tiles; and
- enough 3D shared/global-memory implementation detail to claim source identity.

Missing details remain `unavailable` until recovered from a versioned source artifact. A calibrated
approximation is labeled `reconstructed`, never `exact`.

## Potts.jl baseline identities

The immediate algorithm baseline is Phase 12.CPU merge
`1bc97348057ea1fb3fa238731e16058c560843ab`; its scientific source last changed at
`ad1d4e87cd8565424566713126ff41c10e790e65`. Baseline capture uses
`CheckerboardSweepCPM` and records:

- activated attempts/s, realized proposals/s, accepted copies/s, and time/accepted copy;
- MCS/s with the exact algorithm-specific normalization attached;
- warm steady time, compilation, first MCS, and observation cost as independent tiers;
- host allocations, backend-resident bytes, transfers, launches, and synchronization; and
- backend, precision, tile/storage policy, seed set, software commit, hardware ID, and power mode.

The first publication-scale baseline record will advance this ledger from “facts extracted” to
“matched baseline captured.” No performance conclusion is permitted before that record exists.
