# Statistical Conformance Procedures

Statistical conformance is tiered so fast deterministic checks and expensive scientific evidence
are not confused:

- `:deterministic` covers exact scalar references, invariants, known answers, and transaction
  traces. It runs per commit and does not use a sampling tolerance.
- `:ci` requires at least 10,000 Bernoulli trials and uses a two-sided absolute z-score tolerance
  of 5.0. It is for fixed moderate CI batteries.
- `:scheduled` requires at least 1,000,000 Bernoulli trials and uses a z-score tolerance of 5.5.
  It is for scheduled or pre-release statistical runs.

`ConformanceHarness.assess_bernoulli` provides common failure shape for simple frequency claims.
Algorithm-specific equilibrium, autocorrelation, isotropy, and kinetic procedures will build on the
same tier and reproduction-record conventions rather than inventing local thresholds.
