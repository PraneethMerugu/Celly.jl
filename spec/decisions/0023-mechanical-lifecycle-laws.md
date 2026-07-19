# Decision 0023: Lifecycle Laws for Fluctuating Pressure and Tension

Status: Accepted

Date: 2026-07-19

## Context

CPM software commonly divides geometry and lets models adjust or clone cell attributes. The
literature does not establish an inheritance law for Potts.jl's non-equilibrium OU pressure or
tension. These variables are generalized forces rather than conserved cellular contents, so blind
cloning, halving, or conservation would introduce undocumented kinetics.

The supporting research is recorded in the
[Phase 8 Mechanical Lifecycle Research](../../design/audits/phase-8-mechanical-lifecycle-research.md).

## Decision

Pressure and tension are intensive and are never automatically halved or sum-conserved at division.

The default division policy resets each descendant to its post-commit constitutive mean after
geometry, type, biological target/strength policies, and derived observables finalize. Explicit
alternatives may copy the parent's intensive state to both descendants or independently redraw each
descendant from its post-division fixed-observable stationary normal law.

Stationary-redraw randomness uses a dedicated lifecycle address containing event, MCS, component,
parent generation, descendant role, child generation, and draw identity. General correlated daughter
noise is deferred until a named policy supplies a positive covariance law.

Growth, target changes, progressive shrink death, and compatible same-component type transitions
preserve mechanical state continuously and let the OU law relax toward changed parameters. Component
addition initializes, component removal clears, and an explicit transition may request reset or
redraw.

Immediate death and stochastic extinction clear state atomically. Slot reuse creates a new
generation and applies ordinary initialization; stale mechanical state is never reused.

Target and strength inheritance remain separate biological policies. Target volume may be
conservatively split. Surface target is not extensive and has no hidden halving default; a named
similar-shape scaling policy must state its geometric and metric assumptions.

## Consequences

- The stable default is deterministic, device-local, and consistent with the default constitutive-
  mean initializer.
- Users can model inherited mechanical memory or division-induced fluctuation explicitly.
- No lifecycle rule falsely inherits an equilibrium or conservation claim.
- Surface-target semantics cannot silently reuse volume-target arithmetic.
- All stable policies lower to bounded scalar device operations without host intervention.

## Alternatives Considered

- Halve pressure or tension as though it were an extensive amount.
- Conserve the sum of descendant generalized forces.
- Clone parent state silently for every division.
- Redraw division noise without a distinct semantic RNG address.
- Reset state whenever a target changes or shrink death advances.
- Halve surface target using the volume-target rule.

These alternatives change physical meaning, erase or invent temporal memory, destabilize replay, or
apply dimensionally inappropriate inheritance.

## Required Conformance Evidence

- Scalar reference values for constitutive reset and intensive preservation.
- Stationary-redraw mean, variance, independence, addressing, and replay tests.
- Post-division ordering tests proving targets and observables finalize before mechanical reset.
- Continuous same-component transition, growth, and shrink-death trajectories.
- Component addition/removal, immediate-death, extinction, retirement, and generation-reuse tests.
- Explicit target-volume split and surface-target-policy compatibility failures.
- CPU, Metal, and ROCm execution with no per-event allocation or hidden synchronization.
