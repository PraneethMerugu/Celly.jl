# Decision 0014: Field-Coupling Scientific Categories

Status: Accepted

Date: 2026-07-18

## Context

CPM software and literature commonly add a donor-to-recipient concentration difference to the
quantity used by Metropolis acceptance and call it a chemotaxis energy change. That local spelling
does not by itself prove the existence of one global scalar Hamiltonian, especially when response
depends asymmetrically on extension, retraction, interface filters, cell state, or field-update
history. Potts.jl must not infer an equilibrium claim from familiar terminology.

The accepted Cartesian field specification already distinguishes native chemotaxis from a globally
integrable external-field coupling. This decision closes D3 for the Phase 6 paper scope.

## Decision

Native donor-to-recipient chemotaxis is a nonconservative drive. For response function `phi`, donor
site `x_d`, recipient site `x_r`, and dimensionless sensitivity `beta_lambda`, its acceptance log
bias is

```text
beta_lambda * (phi(c(x_r)) - phi(c(x_d))).
```

Extension, retraction, reciprocal, and interface-filtered modes are separately represented and
report that they do not contribute to the conservative Hamiltonian.

A conservative external-field coupling is separately named. Its global energy is an occupancy
potential of the form

```text
H_field(state) = -sum(beta_inverse * lambda(owner(x)) * phi(c(x)) for mutable sites x)
```

under one immutable field snapshot. Its local delta for replacing the recipient owner is the exact
difference of the gaining and losing occupancy potentials at the recipient site. It does not use a
donor-to-recipient difference as a substitute for that global/local identity.

Fields are immutable within one transaction round. Field evolution, secretion, uptake, PDE solver
choice, and operator splitting remain deferred to the SciML coupling phase. Phase 6 implements
aligned and explicitly interpolated read-only sampling without host synchronization during device
execution.

## Consequences

- `ChemotaxisDrive` participates through `drive_log_bias`, never through conservative energy sums.
- `ExternalFieldHamiltonian` implements both global energy and exact local energy change.
- Conventional CPM compatibility reports may describe a chemotactic acceptance contribution but
  may not claim that it samples the conservative Potts Hamiltonian.
- A field mode whose global energy or update-time relation is undefined fails model compilation.
- Saturating response functions do not change category by themselves; response asymmetry and the
  existence of a global scalar law determine the category.

## Alternatives Considered

- Classify every quantity historically called `deltaH` as Hamiltonian energy.
- Classify every field coupling as active chemotaxis, excluding valid occupancy potentials.
- Delay all field sampling until the SciML phase, leaving Phase 6 component categories incomplete.

## Required Conformance Evidence

- Exact named response-law fixtures and domain validation.
- Extension, retraction, reciprocal, and interface-filtered drive fixtures.
- Global/local recomputation identity for `ExternalFieldHamiltonian`.
- Aligned and independent-resolution field-sampling fixtures in 2D and 3D.
- Immutable-snapshot, backend-residency, and forbidden-synchronization checks.
