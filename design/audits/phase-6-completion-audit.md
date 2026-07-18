# Phase 6 Completion Audit

Status: Candidate — authoritative ROCm CI pending

This audit uses the Phase 6 deliverables and exit gate in `design/refactor-roadmap.md` as the
definition of completion. Local CPU and Metal success are necessary but do not close the
three-backend contract in Decision 0013.

## Scientific scope and provenance

The paper slice covers two- and three-dimensional Cartesian ownership domains; distinct proposal,
contact, surface, connectivity, query, field, and conflict relations; conventional and
Metropolis-Hastings acceptance; volume, contact, surface, field, chemotaxis, focal-point,
connectivity, and positive-yield components; reusable exact query/connectivity workspaces; and
transactional volume, surface, and moment caches.

The normalized surface family implements the square order-4 and cubic order-6 neighborhoods and
axis-calibration factors 11 and 39 reported by Magno et al. It is separately named, requires
isotropic spacing, reports its calibration, and explicitly makes no general isotropy claim. The
primary publication is
<https://bmcbiophys.biomedcentral.com/counter/pdf/10.1186/s13628-015-0022-x.pdf>; the Morpheus
surface-mechanics discussion provides independent implementation context at
<https://morpheus.gitlab.io/post/2023/06/12/cell-surface-mechanics/>.

## Deliverables

| Requirement | Evidence | Verdict |
| --- | --- | --- |
| Compiled Cartesian domain and distinct relation roles | `spatial/cartesian.jl`; exhaustive 2D/3D canonicalization, realization, invalid-domain, fixed-exterior, and obstacle fixtures | Implemented |
| Proposal probabilities and acceptance families | `protocols/scientific.jl`; hand-enumerated forward/reverse multiplicities, conventional Metropolis, Hastings correction, positive yield, and zero-temperature fixtures | Implemented |
| Conservative energies | Global/local conformance for volume, unordered contact, raw/weighted/normalized surface, and external-field occupancy in 2D/3D `Float32`/`Float64` | Implemented |
| Drives, modifiers, and constraints | Typed chemotaxis modes and response laws, positive yield, exact connectivity, immutable recipients, and fixed focal endpoints | Implemented |
| Queries, fields, and focal points | Edge/site/distinct-owner queries, reusable workspaces, aligned/interpolated fields, unwrapped periodic moments, generation-safe fixed links | Implemented |
| Transactional derived state | Staged no-write rejection, accepted ownership/volume/surface/moment commit, extinction reset, reference reconstruction, device launch | Implemented |
| Generic scientific inner loop | Tuple-recursive `ScientificComponentSet` preserves energy, drive, hard-constraint, and kinetic-modifier semantics without dynamic dispatch | Implemented |
| Exact reporting | Domain, relation, surface, field, focal, query/workspace, component-set, and evaluation reports expose the scientific choices | Implemented |
| Legacy removal boundary | New scientific sources contain none of the concrete historical penalties, samplers, topology presets, trackers, closures, `PottsParameters`, or `PottsCache`; remaining algorithm code is inventoried in `phase-6-legacy-quarantine.md` | Implemented |

## Exit-gate evidence

| Gate | Current evidence | State |
| --- | --- | --- |
| Local deltas equal full reconstruction | Exhaustive/focused CPU fixtures for every required conservative family; normalized tracker mutation uses explicit floating tolerance | Complete locally |
| Proposal and acceptance fixtures | Exact forward/reverse multiplicity and acceptance-law test matrix | Complete locally |
| Trackers survive accept/reject/lifecycle/boundaries | Reconstruction matrix plus fixed exterior, obstacles, extinction, focal moments, and normalized surface | Complete locally |
| CPU `Float32`/`Float64`, 2D/3D | CorePotts: 1,745 passed, one intentional broken; PottsToolkit: 255 passed; cross-package integration: 152 passed | Complete locally |
| Available-GPU `Float32`, 2D/3D | Real Apple Metal qualification passes all component, generic evaluation, query, connectivity, transaction, and normalized-surface probes with zero internal synchronization | Metal complete; ROCm pending |
| Surface and field semantic reports | Exact metric/relation/boundary/calibration/coupling descriptors have executable report fixtures | Complete locally |
| No quarantined dependency | Static name audit over `spatial/cartesian.jl`, `protocols/scientific.jl`, and `components/scientific_*.jl` returns no historical concrete dependency | Complete locally |

## Device-path details

The qualification uses separate ordered kernels for proposal/component evaluation, generic
component folding, and queries/connectivity, followed by one observation boundary. Exact
connectivity and distinct-owner workspaces are preallocated and report 148 bytes in 2D and 532
bytes in 3D for the qualification fixtures. The compiled scientific state reports 364 bytes in 2D
and 1,092 bytes in 3D. Surface caches carry a device-safe 128-bit semantic identity so a component
cannot consume a cache compiled for a different metric or relation; hot-kernel validation is two
integer comparisons and introduces no stencil scan or host runtime call.

## Closure condition

Change this audit and the chunk plan to `Complete` only after the exact candidate commit passes the
authoritative GPU Validation Metal and ROCm jobs. Record the commit and check URLs here; do not
infer ROCm conformance from CPU or Metal.
