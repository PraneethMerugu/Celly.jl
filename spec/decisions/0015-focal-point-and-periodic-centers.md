# Decision 0015: Focal-Point Springs and Periodic Centers

Status: Accepted

Date: 2026-07-18

## Context

The paper scope requires conventional focal-point springs. The accepted topology contract says that
incremental unwrapped moments, rather than a minimum-image shortcut or a circular-mean
approximation, are authoritative for cells crossing periodic boundaries. It did not yet specify a
unique unwrapped center for a fragmented cell. A disconnected owner has no unique relative periodic
image between its components, so silently selecting one would make its center and spring energy
depend on traversal or storage order.

The literature and established CPM software define focal-point plasticity through distances between
cell centers. CompuCell3D updates periodic centers by shifting the cell and changed site into a
common image before updating the center. Durand and Guesnet show that local connectivity tests can
preserve initially connected cells under explicitly stated neighborhood assumptions.

## Decision

The native conventional focal-point family uses an exact conservative spring Hamiltonian over an
explicit link inventory:

```text
H_link(i, j) = lambda(i, j) * (distance(center(i), center(j)) - target(i, j))^2
```

Every linked finite cell must be connected under a declared center-unwrapping relation at
initialization and must remain connected while the link exists. A model that permits a linked cell
to fragment is invalid; fragmentation remains valid for cells that do not participate in a
center-dependent component. This is an applicability condition of focal-point mechanics, not a
universal connectivity default.

For each connected participating cell, initialization assigns one canonical unwrapped image by a
stable traversal from the lowest canonical owned site. Transactions add or remove the changed site
in the image nearest the pre-transaction center, with exact deterministic half-box tie breaking.
The tracker stores volume and unwrapped coordinate sums. The wrapped public center is derived only
for observation. Spring displacement between two centers uses the declared periodic minimum-image
law after each center has been computed from its own unwrapped moments.

Local spring energy change is computed from the exact proposed centers. The historical linearized
force-times-displacement approximation is not the native `FocalPointSpring` implementation and may
exist only as a separately named approximate algorithm with measured error.

Links have stable identity, finite-capacity compiled storage, explicit endpoint generations,
strength, target length, creation/breakage policy, and lifecycle effects. Phase 6 implements fixed
links and exact proposal deltas. Dynamic link creation, breakage, inheritance, and persistence are
completed with lifecycle semantics in Phase 8.

## Consequences

- Fragmented ordinary cells remain legal unless another component requires connectivity.
- Focal-point models receive a compile-time or initialization error if participating cells lack the
  required connectivity guarantee.
- Periodic center and spring results do not depend on array order, backend scheduling, or circular
  mean degeneracy.
- Exact local/global spring conformance is possible in both 2D and 3D.
- The old sweep-level circular accumulators and linearized auxiliary force path cannot implement the
  stable native component.

## Required Conformance

- Connected cells crossing every periodic face and corner in 2D and 3D.
- Exact half-box tie fixtures.
- Exact local spring delta versus full Hamiltonian recomputation.
- Accepted, rejected, extinction, and link-endpoint retirement transactions.
- Initialization rejection for fragmented linked cells.
- CPU, Metal, and ROCm `Float32` conformance, plus CPU `Float64`.
