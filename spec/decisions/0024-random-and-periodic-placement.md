# Decision 0024: Separately Named Random and Periodic Placement Laws

Status: Accepted

Date: 2026-07-19

## Context

The historical PottsToolkit `RandomLayout` selects empty sites through Julia's default RNG and
dictionary iteration. Its scattered-sphere layout samples centers sequentially and silently
overwrites overlaps, while documentation suggests it produces packed or confluent tissues. These
behaviors are neither reproducible semantic laws nor uniform packing algorithms.

Periodic placement also needs a canonical rule so a shape crossing a boundary is not clipped on one
backend and wrapped or aliased on another.

## Decision

There is no stable unqualified random-layout algorithm. Phase 8 separately names:

- uniform labeled site seeding without replacement; and
- sequential rejection placement of shapes.

Uniform site seeding samples a uniform injection from canonical provisional entities to eligible
mutable logical sites. Obstacles, fixed owners, and prior explicit claims are excluded. Entity and
type order is canonical and independent of dictionary order. Insufficient eligible sites abort the
complete placement.

Sequential rejection processes entities in canonical order unless an addressed permutation is
explicitly selected. Candidate centers, orientations, and other stochastic parameters use semantic
addresses containing layout, entity, attempt, and draw role. Each entity has an explicit attempt
bound. Exhaustion aborts the complete layout with diagnostics; cells are never silently dropped,
shrunk, clipped, overwritten, or placed through hidden backtracking.

Sequential rejection does not claim uniform sampling over feasible non-overlapping configurations
and is not advertised as guaranteed dense or confluent packing. Such behavior requires deterministic
tiling, explicit masks, or a separately named qualified packing algorithm.

Periodic shapes use canonical coordinates and minimum-image displacement. Boundary-crossing support
wraps as one entity. Self-aliasing caused by a shape too large for the periodic domain is rejected.
Nonperiodic overflow rejects by default; explicit clipping is a distinct geometry-changing policy.

## Consequences

- Random initialization has inspectable distributions and failure behavior.
- Same-named host and device placement cannot differ because of task RNG, dictionary order, or
  scheduling.
- Rejection bias and jamming are reported honestly rather than hidden behind “random packing.”
- Periodic cells can cross boundaries without duplicate ownership or backend-dependent volume.
- Phase 8 avoids implementing a general packing framework.

## Alternatives Considered

- Retain one `RandomLayout` name for site seeds, random shapes, and future packing.
- Use Julia's task-local RNG and current dictionary iteration order.
- Retry without a bound or drop shapes that do not fit.
- Allow later shapes to overwrite earlier cells.
- Clip all boundary-crossing shapes, including on periodic axes.
- Call sequentially scattered spheres uniformly packed or confluent.

These alternatives obscure distributions, destabilize replay, create partial initialization, or
make scientific claims unsupported by the algorithm.

## Required Conformance Evidence

- Exact small-domain site-seed enumeration and statistical without-replacement tests.
- Type-count and provisional-identity invariance under dictionary and declaration permutations.
- Rejection-placement candidate-address, retry, explicit-order, and failure diagnostics.
- Whole-layout rollback after insufficient sites or exhausted attempts.
- Periodic 2D/3D boundary-crossing volumes, minimum-image geometry, and self-alias rejection.
- Nonperiodic overflow rejection and explicit clipping provenance.
- Same-profile host/device canonical-claim equality on CPU, Metal, and ROCm where device-native
  placement is claimed.
- No default/task RNG use, hidden overwrite, unbounded retry, or per-attempt host-device sync.
