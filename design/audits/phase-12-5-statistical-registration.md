# Phase 12.5 statistical validation registration

Status: Registered before ensemble execution

Date: 2026-07-22

## Comparison identities

`TiledCheckerboardCPM` is compared with its executable logical reference for exact CPU checks and
with `CheckerboardSweepCPM` for distributional checks. The algorithms have different proposal
processes, so trajectory equality with `CheckerboardSweepCPM` is neither expected nor tested.
Every record retains algorithm identity, tile size, switching interval, backend, precision, seed,
lattice, Hamiltonian parameters, burn-in, measured MCS, and observation boundary.

## Fixed seed sets and ensemble sizes

- smoke/development: seeds `0x12500001:0x12500010` (16 replicas);
- closure: seeds `0x12500101:0x12500140` (64 replicas);
- publication reconstruction: seeds `0x12501001:0x12501080` (128 replicas).

The closure decision uses the 64-replica set. The 16-replica set may reject a broken candidate but
cannot establish equivalence. No seed is replaced after observing an outcome; an invalid run is
retained and classified.

## Exact gates

At every observed MCS boundary: lattice occupancy equals exact volume trackers; identities are in
range; every active cell has positive volume; boundary trackers equal recomputation; proposal and
attempt counters partition exactly; and an observed run matches an otherwise identical unobserved
run on the same backend. CPU resident execution must match the logical reference trajectory for the
qualified volume/adhesion tuple in both 2D and 3D.

## Distributional gates

| Family | Observable | Closure equivalence margin |
|---|---|---|
| Proposal process | recipient frequency by tile and lattice quartile | each standardized difference <= 0.20 and aggregate total-variation distance <= 0.03 |
| Waiting time | MCS between accepted writes per site | median ratio in `[0.90, 1.10]`; 95th-percentile ratio in `[0.80, 1.20]` |
| Acceptance | realized-proposal acceptance fraction | absolute ensemble-mean difference <= 0.03 |
| Copy activity | accepted copies per MCS | standardized mean difference <= 0.25 |
| Sorting | heterotypic contact fraction after burn-in | absolute mean difference <= 0.05 and standardized mean difference <= 0.30 |
| Chemotaxis | displacement projected on the prescribed gradient | mean difference <= 0.20 initial-cell diameters |
| Persistence | velocity autocorrelation integral | relative mean difference <= 15% |
| Morphology | volume and boundary-measure quantiles | each registered quantile differs by <= 10% |
| Act-like motion | speed and polarization alignment | each standardized mean difference <= 0.30 |
| Collective order | transition midpoint and high-drive order parameter | midpoint <= 10% of scan width; order parameter absolute difference <= 0.05 |

Equivalence requires the confidence interval for the paired ensemble difference to lie inside the
registered margin; a nonsignificant difference is not evidence of equivalence. Holm correction is
applied within each observable family. Unsupported physics is reported as unqualified and cannot be
silently omitted from either algorithm.

## Standard workloads

The first two performance/statistical identities are `differential_adhesion` and
`uniform_adhesion_tiled_baseline` from the versioned benchmark matrix. Closure adds prescribed-field
chemotaxis, directional persistence, Act-like polarization, and a collective-order scan only after
their tiled component protocols qualify. Timed regions exclude construction, compilation, first
MCS, observation, and transfers; those tiers remain independently recorded.
