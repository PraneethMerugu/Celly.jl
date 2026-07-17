# ADR 0008: Separate Conventional CPM and Equilibrium Sampling Families

- Status: Accepted
- Date: 2026-07-17

## Context

The conventional modified-Metropolis CPM update chooses a recipient lattice
site and then a neighboring donor site. This proposal is generally asymmetric:
the number of neighbor directions carrying the losing identity need not equal
the number carrying the gaining identity. Widely used CPM packages commonly
apply an uncorrected Metropolis-style acceptance rule, while detailed-balance
sampling requires the proposal ratio.

The current engine hides a neighbor-multiplicity correction inside a class named
`MetropolisSampler`. That name does not reveal whether the algorithm is intended
to reproduce conventional CPM kinetics or sample a stated equilibrium
distribution. Border-list and checkerboard algorithms introduce additional
proposal and clock semantics and cannot be treated as mere accelerations.

## Decision

Conventional CPM dynamics and equilibrium sampling are separate, prominently
named algorithm families.

The conventional family uses a `NeighborSiteCopy` proposal: choose a recipient
uniformly from all lattice sites and a direction uniformly from its proposal
neighborhood. Invalid no-flux directions and same-identity copies are no-op
attempts. Its modified-Metropolis acceptance ignores the proposal ratio. This is
the compatibility-oriented biological CPM default, but it makes no Boltzmann or
detailed-balance claim.

The equilibrium family uses explicit Metropolis-Hastings acceptance. For the
neighbor-site proposal, its forward and reverse probabilities are derived from
direction multiplicities of the gaining and losing identities. A missing
forward probability is an internal error; zero reverse probability is a
Metropolis-Hastings rejection.

Acceptance calculations use the log domain:

```text
logR = -delta_energy / temperature
       + log(q_reverse) - log(q_forward)
       + drive_log_biases
       + kinetic_modifiers
```

Only terms permitted by the selected algorithm may appear. A random variate is
drawn on the open interval `(0, 1)` and compared stably in log space.

At zero temperature, conventional modified Metropolis accepts
`delta_energy <= 0`. Metropolis-Hastings accepts downhill moves only when reverse
support exists, accepts neutral moves with `min(1, q_reverse/q_forward)`, and
rejects uphill moves. Barker acceptance is a separately named algorithm.

Yield barriers, acceptance offsets, and similar compatibility rules are
separately named kinetic modifiers, not Hamiltonian terms. Border-list,
distinct-neighbor, checkerboard, and lottery methods are separate algorithms
whose proposal law and MCS normalization must be specified and validated.

Cell extinction in conventional dynamics invokes lifecycle semantics. A
fixed-population equilibrium model rejects final-site deletion unless extinction
and birth are part of an explicitly reversible proposal family.

## Consequences

- The ambiguous `MetropolisSampler` API must be removed or renamed during the
  breaking redesign.
- PottsToolkit should offer clear presets such as `CPMDynamics()` for
  conventional kinetics and `EquilibriumCPM()` for corrected sampling.
- Proposal probabilities belong to the proposal implementation rather than the
  energy model or a hidden sampler heuristic.
- Equilibrium construction requires capability checks over the complete model,
  proposal family, constraints, lifecycle behavior, and parallel scheduler.
- Parallel algorithms need equilibrium proofs for the transition kernel of a
  complete pass or round, not only for isolated candidate moves.

## Evidence required

- Exhaustive proposal-probability enumeration on small lattices.
- Exact small-state transition matrices checking normalization, invariant
  distribution, detailed balance when claimed, irreducibility, and
  aperiodicity.
- Fixtures reproducing the documented conventional behavior of compatibility
  targets.
- Statistical validation of 2D and 3D implementations on every supported
  backend.
- A proof or explicit non-equilibrium classification for each parallel update
  schedule and each distinct-neighbor or border-list proposal.

## Specification

See [Energy, Proposal, Acceptance, and Tracker Semantics](../energy-proposals-and-trackers.md).

