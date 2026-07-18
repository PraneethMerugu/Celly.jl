# Phase 5 Execution, Synchronization, and Atomic Audit

Status: Complete for the Phase 5 execution foundation

## Accepted execution boundary

The Phase 5 execution path has one direction of travel:

1. validate a `LogicalPottsState` on the host;
2. lower it to `CompiledStateStorage` plus a host-only `CompiledStateDescriptor`;
3. move only the storage through `adapt_execution`;
4. allocate persistent algorithm and transaction workspaces before stepping;
5. launch through an `ExecutionPlan` using KernelAbstractions 0.9 ordered asynchronous launches;
6. synchronize only through `synchronize_observation!`; and
7. reconstruct a canonical logical snapshot only at that explicit observation boundary.

The descriptor is never passed to kernels. `device_storage_valid` rejects non-isbits array leaves,
and GPU kernels receive `execution_storage(compiled)`, not the host bundle. Capability methods live
in package extensions; unsupported requirements fail before a launch.

## Current qualification evidence

- CPU logical-to-compiled-to-logical round trip preserves ownership, activity, reusable slots,
  generations, cell types, custom properties, and invariants.
- A two-kernel CPU pipeline observes the second launch's dependency on the first with no internal
  host wait and exactly one final observation synchronization.
- The same pipeline compiles and executes on a local Apple GPU through Metal.jl, producing
  `[4, 6, 8, 10]` with two instrumented launches and one observation synchronization.
- Compiled state adapts to `MtlArray`, passes device-storage validation, and round-trips to the same
  logical snapshot.
- GPU snapshots require an `ExecutionPlan`; the Metal probe records one synchronization and all
  seven device-to-host array transfers. Plan-aware adaptation records seven host-to-device
  transfers plus the persistent device allocations, and workspace allocation reports exact bytes.
- Semantic Philox and categorical primitives allocate zero host bytes after warm-up.
- The warmed, type-stable CPU execution probe records zero host allocation for its launch. A prior
  global-scope measurement included compilation/scheduling setup and is deliberately excluded from
  steady-state evidence.
- CPU and Metal emit machine-readable execution reports with two ordered launches, zero internal
  synchronizations, zero CorePotts steady-state scratch allocations, and one observation wait.

## Synchronization inventory

The new qualified path contains one synchronization site, `synchronize_observation!`, whose metric
is incremented before the backend wait. Historical code contains seventeen direct waits:

| Legacy area | Sites | Classification | Required migration |
| --- | ---: | --- | --- |
| Focal-point energy | 6 | Incidental internal waits | Compose ordered kernels in Phase 6 |
| Length energy | 4 | Incidental internal waits | Compose ordered kernels in Phase 6 |
| Property/event kernels | 4 | Mixed sort boundary and incidental waits | Qualify preallocated AcceleratedKernels operations; isolate any unavoidable synchronous primitive |
| SciML simulator saving | 3 | Valid observation boundaries | Route through execution-plan observation instrumentation in Phase 8 |

The adhesion inspection path also materializes GPU arrays on the host. It is a diagnostic
observation and must not be reachable from steady-state scientific execution.

## Atomic inventory

There are 43 executable Atomix update expressions in legacy production code. A raw text search finds
44 occurrences because one is an explanatory comment. The pinned Atomix 1.1.3 behavior
was checked directly: compound `+=` and `-=` expressions return the new value. Sequential
consistency remains the required ordering until a narrower ordering has a written happens-before
proof and cross-backend tests.

| Family | Sites | Types and invariant | Contention and overflow | Reproducibility contract | Qualification matrix |
| --- | ---: | --- | --- | --- | --- |
| Volume and surface trackers | 6 | `Int32 += delta`; exact cached occupancy/surface | Same-cell boundary contention; host preflight must prove lattice-derived totals fit `Int32` | Strict only when no intermediate read observes a partial transaction; otherwise replace with staged commit | CPU tests and Metal/ROCm smoke |
| Focal-point circular sums | 6 | `Float32 += term`; per-cell center accumulator | Potentially every site in one cell; finite lattice bounds but floating order varies | Tolerant/statistical only; strict mode requires a fixed reduction tree | CPU tests only; all GPU families unqualified |
| Length circular and inertia sums | 18 | `Float32 += term`; per-cell center and inertia tensors | High same-cell contention; squared-coordinate bounds require numerical preflight | Tolerant/statistical only; strict mode requires canonical fixed-tree reduction | CPU tests only; all GPU families unqualified |
| Spatial property accumulators | 3 | `Float32` or `UInt32 += term`; per-cell relation result | Boundary-edge contention; count/product capacity must be checked | Integer count may be strict if no partial reads; floating sum is tolerant only | CPU tests only; all GPU families unqualified |
| Edge and retirement counters | 2 | `UInt32`/`Int32 += 1`; reserve unique output slot | Global contention; workspace capacity and signed-count bounds must be checked | Returned new value defines a unique slot, but output order is schedule-dependent | CPU tests only; all GPU families unqualified |
| Mitosis allocation counters | 3 | `Int32 +=/-= 1`; free-list and next-ID reservation | Global contention with underflow/recovery branch; fixed capacity is mandatory | Not strict: allocation identity depends on arrival order; replace with deterministic scan/compaction | CPU tests only; all GPU families unqualified |
| Division candidate counter | 1 | `UInt32 += 1`; reserve candidate slot | Global contention; candidate capacity checked before launch | Not strict: candidate order is schedule-dependent; replace with canonical scan | CPU tests only; all GPU families unqualified |
| Mitosis center/covariance sums | 4 | `Int32` count plus `Float32` sums | High same-cell contention; count bounded by lattice, floats order-sensitive | Count can be strict after overflow proof; floating outputs are tolerant only | CPU tests only; all GPU families unqualified |

### Exact source-to-contract map

Every executable site maps to exactly one row above:

| IDs | Source locations | Family |
| --- | --- | --- |
| A01–A06 | `components/energies/length.jl:155-157,165-167` | Length circular and inertia sums |
| A07–A18 | `components/energies/length.jl:356-359,366-368,373-374,377-379` | Length circular and inertia sums |
| A19–A24 | `components/energies/focal_point.jl:123-126,131-132` | Focal-point circular sums |
| A25–A30 | `components/trackers/trackers.jl:37,45,70,88,218,244` | Volume and surface trackers |
| A31 | `kernels/events/property_kernels.jl:30` | Edge and retirement counters |
| A32–A34 | `kernels/events/property_kernels.jl:99,108,116` | Spatial property accumulators |
| A35 | `kernels/events/property_kernels.jl:203` | Edge and retirement counters |
| A36–A38 | `kernels/events/mitosis_kernels.jl:60,66-67` | Mitosis allocation counters |
| A39 | `kernels/events/mitosis_kernels.jl:292` | Division candidate counter |
| A40–A43 | `kernels/events/mitosis_kernels.jl:324,329-330,346` | Mitosis center/covariance sums |

The inventory is a migration contract, not an endorsement of every current atomic. Phase 6 owns
component/tracker reductions; Phase 7 owns proposal ordering and deterministic conflict resolution;
Phase 9 owns compiled lifecycle scans. Phase 5 provides the capability, workspace, launch,
instrumentation, and failure machinery those replacements must use.

## Closure and downstream obligations

- Real-hardware ROCm RNG/distribution and ordered-pipeline qualification is green for `8379eb2`.
- Phase 6 must extend the current exact primitive-workspace byte report to the complete compiled
  model once the first production component pipeline exists.
- Full regression and GPU tests confirm the completed removal of dependency tuples and direct
  construction of obsolete KernelAbstractions events.
- The passing expanded hardware job authorizes the ROCm semantic RNG v1 capability claim.
- CUDA is deferred by Decision 0013 and MUST fail first-class execution-plan preflight.
