# Time and Monte Carlo Steps

Status: Accepted except where marked otherwise

## Public Time Unit

The public unit of simulation time is the Monte Carlo step (MCS).

Let `N` be the number of mutable ownership sites in the realized domain. One reference MCS consists
of exactly `N` independent copy attempts. Recipient sites are sampled uniformly from those sites
with replacement. Exterior ghosts and excluded obstacle storage are not sites and do not contribute
to `N`. Ordinary mutable medium sites do contribute.

`step!(integrator)` MUST advance the simulation by exactly one MCS. Fractional public steps are not
part of specification version `0.1-draft`.

## Copy-Attempt Accounting

One reference copy attempt consists of:

1. Uniformly selecting one recipient site.
2. Uniformly selecting one direction from the proposal neighborhood.
3. Resolving the donor site or determining that the direction is invalid.
4. Producing a no-op or evaluating a proposal.

The following count toward the `N` attempts:

- A donor and recipient with the same owner
- A selected no-flux direction whose donor coordinate lies outside the domain
- A proposal rejected by the acceptance rule

Same-owner and invalid no-flux attempts MUST be no-ops and MUST NOT evaluate or commit tracker or
energy mutations.

At a no-flux boundary, invalid directions MUST become no-ops. Implementations MUST NOT clamp an
invalid coordinate onto a boundary site or silently renormalize over remaining directions.

## Removed Public Controls

`sweeps_per_step` is not part of the intended public semantics and SHOULD be removed.

`active_fraction` MUST NOT control public simulation time. An optimized algorithm MAY use an internal
activation fraction, but it MUST normalize its work to one MCS and MUST report its attempt accounting.

## Internal Rounds

An optimized algorithm MAY divide one MCS into internal rounds. Internal rounds are execution details
and MUST NOT be exposed as independent simulation time.

Every internal round MUST account for a defined MCS fraction `delta_tau`, with:

```text
sum(delta_tau for all rounds in one step) = 1 MCS
```

Algorithm kernel-launch count MUST NOT define time.

## Lottery Normalization

The lottery algorithm uses expected proposal-budget normalization. Its internal topology-dependent
activation fraction and round count MUST be calculated by the algorithm rather than supplied as
user-facing time controls.

One lottery MCS MUST produce `N` realized proposals in expectation. Actual realized proposal count
MAY fluctuate. The algorithm MUST report at least:

- Candidate attempts
- Lottery conflicts
- Realized proposals
- No-op attempts
- Rejected proposals
- Accepted moves

The equilibrium and kinetic consequences of expected normalization remain under investigation and
MUST be documented in the algorithm's guarantee profile.

## Checkerboard Scheduling

Checkerboard color classes execute sequentially. A later color observes mutations committed by
earlier colors in the same MCS.

Color order MUST be randomized once per MCS using a dedicated RNG stream. Proposals within one color
pass observe the state defined by that algorithm's accepted parallel-execution contract, which remains
under investigation.

The existence of a conflict-free lattice coloring does not by itself establish reference kinetic or
equilibrium equivalence because nonadjacent sites may modify shared cell-wide state.

## Algorithm Comparability

All public algorithms MUST express time in normalized MCS units. Each algorithm MUST expose, where
applicable:

- Equilibrium guarantee
- Kinetic guarantee
- Attempt-normalization guarantee
- Reproducibility guarantee
- Supported topology and dimensionality
- Backend capability requirements
- Evidence category: proof, reference equivalence, statistical validation, or experimental

The unqualified term "exact" MUST NOT serve as an algorithm guarantee.

## Event Time

Stable events are scheduled at integer MCS boundaries. Each event owns its own schedule. A global
system-wide check interval is not part of the intended semantics.

`Every(k; offset=o)` means the event is eligible at integer times satisfying its documented modular
schedule. Exact MCS-zero behavior will be specified with the event scheduling API.

## Parameter Time Scale

Temperature, penalty parameters, growth rates, event schedules, HST rates, and other temporal model
parameters MUST be interpreted in MCS units independently of the chosen execution algorithm.

An algorithm whose kinetics are not reference-equivalent MUST document the limitation and any
calibration. Routine runtime warnings are not required.

## Auxiliary Time Integration

Auxiliary physics MAY update between scientifically defined internal subintervals, but MUST NOT use
raw kernel launches as a time scale.

If one MCS is partitioned into auxiliary intervals `delta_tau_r`, then:

```text
sum(delta_tau_r) = 1 MCS
```

For stochastic internal-round counts, auxiliary time SHOULD use expected normalized work rather than
the realized random proposal count, so contention does not make the physical clock stochastic.

A symmetric operator-splitting strategy is the current recommendation:

```text
advance auxiliary state by delta_tau / 2
execute normalized proposal work for delta_tau
advance auxiliary state by delta_tau / 2
```

The HST integration scheme, substep policy, and proof obligations remain under investigation and are
not yet accepted semantics.
