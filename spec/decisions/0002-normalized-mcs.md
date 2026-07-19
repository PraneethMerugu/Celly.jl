# Decision 0002: One Normalized MCS Equals N Attempts

Status: Accepted

Lottery details refined by Decision 0016.

Date: 2026-07-17

## Context

The existing combination of `sweeps_per_step` and `active_fraction` does not provide one consistent
Monte Carlo time unit across algorithms. Sequential, checkerboard, and lottery engines currently
interpret a sweep differently.

## Decision

For a realized domain with `N` mutable ownership sites, one reference MCS contains exactly `N`
independent recipient-site selections sampled uniformly with replacement. Exterior ghosts and
excluded obstacle storage do not contribute to `N`. `step!` advances exactly one MCS.

Same-owner and invalid no-flux selections count as no-op attempts. Invalid no-flux directions are
not clamped or renormalized.

`sweeps_per_step` is removed from the intended public API. `active_fraction` is an internal execution
detail. Lottery execution uses topology-derived expected activated-attempt normalization with equal
per-site expectation. Once activated, a same-owner, invalid-boundary, dynamic-conflict, rejected, or
accepted outcome consumes the opportunity; evolving contention does not create compensating work.
All algorithms report attempt diagnostics and use comparable MCS units.

Checkerboard colors execute sequentially in a randomized per-MCS order.

## Consequences

- Algorithm implementations must translate internal work into normalized MCS fractions.
- Lottery activated-attempt count may fluctuate around `N` while retaining an expectation of one
  opportunity per mutable site.
- Auxiliary integration must use normalized MCS fractions rather than kernel-launch count.
- Existing simulations using `sweeps_per_step * active_fraction` will change behavior during
  migration.

## Alternatives Considered

- Preserve historical sweep semantics: rejected because algorithms are incomparable.
- Treat one sweep as one pass over each site without replacement: rejected as the reference process,
  pending literature confirmation for optional algorithms.
- Count only accepted or non-no-op proposals: rejected because time would depend on model state.

## Required Evidence

- Attempt-count conformance tests
- Statistical reference tests
- Lottery normalization measurements for every supported topology
- Kinetic calibration across algorithms
