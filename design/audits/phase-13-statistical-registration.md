# Phase 13 statistical and empirical evidence registration

Status: Registered before Phase 13 qualification results

Date: 2026-07-22

Machine-readable contract:
[`phase-13-statistical-registration.toml`](phase-13-statistical-registration.toml)

## Scope and immutability

This registration fixes the statistical design for the initial Phase 13 qualification of
`SequentialCPM` and `CheckerboardSweepCPM` on the admitted adhesion-and-volume domain. It was
written before inspecting any Phase 13 transition-row or realistic-scale result. `LotteryCPM` and
the experimental `TiledCheckerboardCPM` are not qualified by this study.

The committed TOML file is the executable authority for constants. A change to a threshold, seed,
sample count, fixture selection rule, stopping rule, or primary observable creates a new study
version and invalidates results produced under this version. Correcting an implementation or
analysis defect does not permit silent reuse of the version: the defect, affected records, new
revision, and complete rerun are retained.

## Statistical families and confidence

The familywise type-I error rate is `0.01`, giving 99% simultaneous confidence for each declared
qualification family. Exact oracle identities and deterministic invariants are pass/fail and do not
consume statistical error. The two empirical families are:

1. fixed-source transition rows across the complete registered CPU, Metal, and ROCm row set; and
2. realistic-scale primary observables, separately for backend portability and
   sequential--checkerboard observable-comparability claims.

Transition rows use a fixed Bonferroni allocation over at most 144 rows: 24 source states, two
algorithms, and three backends. The per-row error budget is therefore
`0.01 / 144 = 6.944444444444444e-5`, even when fewer rows are applicable. Realistic-scale
equivalence uses two one-sided tests with Holm correction across every applicable primary endpoint
in its claim family. Applicability is frozen from model/component support before execution; an
endpoint cannot be removed because its result is inconvenient. Secondary exploratory observables
receive point estimates and 95% intervals but cannot support a stable claim.

## Fixed transition-row design

The empirical subset contains at most 24 source states per algorithm. The fixture manifest must be
committed before sampling and must span the registered topology, boundary, occupancy, temperature,
energy-scale, deterministic-limit, and scheduler-phase strata. A source row is admitted to this
empirical study only when the independent oracle gives it at most 64 destinations. Larger exact
rows remain valid exhaustive evidence but require a separately versioned empirical design.

Each `(source state, lifted scheduler phase, algorithm, backend)` row uses exactly 262,144
independent replicas. Replica `i` uses semantic ensemble seed
`0x1300000000000000 + (i - 1)`, for `i = 1:262144`. Every replica starts from the same source state;
no correlated trajectory is substituted for independent initialization. CPU, Metal, and ROCm use
the same seed set, RNG contract, source-state encoding, and fixture identity. Bitwise cross-backend
trajectory identity is neither required nor used as a pass criterion.

For a row with oracle probabilities `p`, empirical frequencies `p_hat`, support size `K <= 64`, and
`n = 262144`, the simultaneous total-variation radius is the Weissman multinomial bound

```text
r_TV(K, n, alpha_row) = sqrt((log(2^K - 2) + log(1 / alpha_row)) / (2n)).
```

At the worst registered support, `K = 64`, this is `0.010142757248393525`. The simultaneous
per-destination Hoeffding radius is

```text
r_abs(K, n, alpha_row) = sqrt(log(2K / alpha_row) / (2n)),
```

which is `0.005245697756318495` at `K = 64`. The registered sample count also gives an expected
log-likelihood separation of at least `n * 2 * TV^2 = 209.7152` against a distribution at total
variation `0.02`, using Pinsker's inequality. The scientific minimum detectable discrepancies are
therefore conservatively registered as TV `0.03` and maximum absolute destination-probability
difference `0.015`; the bounds, rather than a post-hoc p-value, control qualification.

A transition row passes only when all of the following hold:

- every observed destination has nonzero oracle support;
- `TV(p_hat, p) + r_TV <= 0.03`;
- `maximum(abs.(p_hat - p)) + r_abs <= 0.015`;
- the self-transition residual plus its `r_abs` bound is at most `0.015`; and
- raw counts sum to exactly 262,144 and all state, accounting, and scheduler-phase invariants pass.

CPU, Metal, and ROCm each pass independently. Compilation on a backend, agreement between two
backends, or a pooled three-backend result cannot substitute for that backend's oracle comparison.
An unsupported fixture produces an explicit limited-domain result, not an inferred pass.

## Bounded realistic-scale battery

The initial battery contains exactly three two-dimensional adhesion-and-volume workload families.
Their final model fingerprints and parameter tables must be committed before ensemble execution.
Changing a model fingerprint creates a new study version.

The first diagnostic preflight of `phase13-realistic-workloads-v1` showed complete finite-cell
retirement during burn-in because dense multi-cell layout lowering emitted ownership but omitted
the model-bound target-volume and strength properties. No v1 qualification ensemble was run. That
workload version is retained as a failed diagnostic and superseded by
`phase13-realistic-workloads-v2`, which requires the corrected lowering source revision. Analysis
preflight then found that the already-declared mean-squared-displacement endpoint had no numerical
margin; no qualification ensemble had run. `phase13-realistic-workloads-v3` therefore adds the
missing absolute margin of 0.20 initial-cell-diameters squared before qualification. The registered
model parameters, workload dimensions, schedules, seeds, and other observables and margins remain
unchanged.

| Workload family | Required primary observables | Sampling window |
| --- | --- | --- |
| Adhesion/volume relaxation | energy per mutable site; cell-volume and boundary-measure morphology; energy and morphology autocorrelation; mixing time; effective sample size | fixed burn-in followed by an evenly sampled stationary window |
| Differential-adhesion sorting | energy per mutable site; heterotypic-contact fraction; segregation index; volume and boundary morphology; sorting autocorrelation; mixing time; effective sample size | fixed presorting burn-in and fixed sorting window |
| Single-cell migration | net displacement in initial-cell diameters; mean-squared displacement; speed; persistence; volume and boundary morphology; velocity autocorrelation; effective sample size | fixed equilibration followed by a fixed migration window |

Each algorithm/backend/workload identity uses 512 independent replicas. Replica seeds are
`0x1301000000000000:0x13010000000001ff`. Initial-layout randomness and simulation randomness are
domain-separated. Algorithm comparisons share the registered initial-layout identity and are
paired by replica; backend-portability comparisons are analyzed conservatively as independent
samples even when semantic seeds coincide.

For at most 96 primary hypotheses in a realistic-scale claim family, the smallest Holm comparison
has alpha at least `0.01 / 96`. With 512 replicas, 90% power, and a normal approximation, the
worst-case detectable standardized effect is approximately `0.23` for paired comparisons and
`0.33` for independent equal-size comparisons:

```text
paired d = (z_(1-alpha/2) + z_0.90) / sqrt(512)
independent d = sqrt(2) * (z_(1-alpha/2) + z_0.90) / sqrt(512).
```

The registered cross-backend minimum detectable standardized effect is `0.35`; the paired
sequential--checkerboard minimum is `0.25`. Equivalence is never inferred from a nonsignificant
difference. A claim passes only when every Holm-adjusted 99% equivalence interval lies wholly inside
its scientific margin:

| Observable | Registered equivalence margin |
| --- | --- |
| Mean energy per mutable site | relative difference at most 5% and standardized difference at most 0.25 |
| Volume/boundary morphology means and registered quartiles | relative difference at most 10% and standardized mean difference at most 0.25 |
| Heterotypic-contact fraction and segregation index | absolute difference at most 0.05 and standardized difference at most 0.25 |
| Net and mean-squared migration displacement | at most 0.20 initial-cell diameters or initial-cell-diameters squared, respectively, and standardized difference at most 0.25 |
| Migration speed and persistence | relative difference at most 10% and standardized difference at most 0.25 |
| Integrated autocorrelation time | log-ratio within `[-log(1.15), log(1.15)]` |
| Mixing time | log-ratio within `[-log(1.20), log(1.20)]` |
| Effective sample size per measured MCS | ratio in `[0.80, 1.25]` |

Means use replica-level studentized intervals. Registered quartiles use exact binomial
order-statistic intervals. Positive time and ESS measures are analyzed on the log scale. The
autocorrelation estimator, maximum lag, initial-positive-sequence truncation, mixing definition,
burn-in, observation cadence, and measured MCS counts belong in the immutable workload manifest;
they are not selected from observed curves.

This battery can support only the bounded domain it executes. It does not imply realistic-scale 3D,
surface, connectivity, field, lifecycle, auxiliary-mechanical, Lottery, or tiled-algorithm
qualification.

## Stopping and rerun rules

- Every admitted transition row runs exactly 262,144 replicas and every realistic-scale identity
  runs exactly 512 replicas. There is no precision-based early success, optional stopping, or
  sampling until a test passes.
- A deterministic invariant, impossible destination, malformed record, or oracle mismatch stops
  the affected job for safety and is a failed qualification result.
- Infrastructure interruption may rerun only the identical missing seeds on the same declared
  identity. The interrupted attempt and reason remain in the evidence record. Completed seeds are
  not discarded or replaced.
- A statistical failure is retained and diagnosed under this plan. More samples, a wider margin,
  removal of an endpoint, or a changed estimator requires a new versioned registration and a full
  affected-family rerun.
- An implementation correction requires a new source revision and complete affected-family rerun;
  pre-correction evidence remains archived and cannot be pooled with corrected evidence.
- Numerical oracle convergence failure is not an empirical statistical failure and cannot be
  bypassed with backend samples; the row remains unqualified until the independent numerical gate
  passes under its own fixed precision schedule.

## Forensic failure artifacts

Every failed or interrupted row retains the source-state encoding and fingerprint, lifted scheduler
phase, complete oracle row and precision record, raw destination counts, empirical row, absolute and
TV residuals, confidence radii, failed criteria, uncertainty, algorithm/scheduler/RNG/model/backend
identities, semantic seed range, source revision, environment, and one reproduction command.
Realistic-scale failures additionally retain all replica-level primary summaries, workload
fingerprint, burn-in and observation schedule, estimator version, adjusted confidence results, and
the exact endpoint family. Red results without these artifacts do not constitute a release gate and
cannot be converted to passes by narrative review.

## Qualification interpretation

Passing every registered backend row permits only the stated empirical transition claim on the
registered source states. Passing the realistic-scale battery permits only the corresponding
bounded observable-comparability or backend-portability claim. Mathematical labels such as
detailed-balance preserving or stationary-distribution preserving continue to require the exact
oracle evidence specified separately. Unexpected sequential--checkerboard differences, including
maximum-discrepancy states, remain reportable scientific results and are not defects merely because
they exceed an equivalence margin.
