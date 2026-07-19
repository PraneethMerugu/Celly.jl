# Decision 0018: Open Transactional Lifecycle Events and Division Geometry

Status: Accepted

Date: 2026-07-19

## Context

Phase 8 must add lifecycle events without turning its first schedules, triggers, effects, conflict
policies, or division orientations into the permanent scientific universe. The stable GPU path also
cannot accept arbitrary callbacks, runtime device dispatch, scheduler-defined priority, hidden host
fallback, or partially committed mutation.

Research against Julia interfaces, SciMLBase and ModelingToolkit events, GPUArrays, Adapt,
KernelAbstractions, AcceleratedKernels, CUDA device-compilation constraints, Tables, and ChainRules
supports one consistent design: open host protocols lower through a function barrier into concrete,
bounded execution descriptions with reusable conformance tests.

## Decision

Lifecycle events compose independently typed target-domain, integer-MCS schedule, trigger, and
effect values. Conflict resolution is an explicit typed phase policy. All due triggers read one
common immutable pre-event snapshot; no trigger observes another event's uncommitted result.

Schedules, target domains, triggers, effects, conflict resolvers, and division geometries are open
Julia protocols. Required built-ins do not define exhaustive behavioral enums. Stable GPU-qualified
host values lower to immutable bitstype-compatible descriptors and bounded storage; the complete
schedule-through-commit path is device-executable without runtime dispatch, allocation, hidden host
evaluation, or incidental synchronization.

Effects declare reads, writes, targets, identity changes, conflicts, capacity, workspace, RNG, and
capability requirements. They plan from the common pre-event snapshot, validate before mutation,
and commit only through transaction-category machinery. Transaction categories and ordering remain
a controlled closed taxonomy because atomicity requires exhaustive handling; implementations within
an applicable category remain open.

Resolvers must produce outcomes invariant under declaration order, tuple layout, compilation
batching, workgroup tuning, launch decomposition, thread scheduling, and atomic arrival order.
Accepted resolver meanings include ambiguity rejection, explicit stable semantic priority, and
explicit typed composition. Unresolved runtime conflicts abort before lifecycle mutation. Decision
0020 narrows the Phase 8 production built-ins to ambiguity rejection and stable semantic priority;
general composition remains permitted by the protocol but deferred until a concrete model requires
it.

Division geometry is an open partition protocol. Its compiled device operation assigns compact
descendant-region labels to parent-owned sites. Phase 8 qualifies exactly two nonempty regions and
binary parent/child identity behavior, but the representation is not permanently Boolean or
structurally limited to binary arity. Invalid geometry affects only its parent and is rejected before
child-ID allocation.

MCS `0` is the finalized initial state, not a lifecycle event boundary. Stable schedules operate on
positive integer MCS values. Initialization has its own protocol.

## Consequences

- The four required division-orientation families remain first-class built-ins without closing the
  geometry interface.
- Stable lifecycle randomness uses declared semantic operation labels and the accepted addressed
  RNG contract.
- Arbitrary imperative callbacks may exist only as explicit synchronizing host facilities outside
  the stable hardware-agnostic GPU contract.
- KernelAbstractions ordering and atomics may implement a lifecycle plan but never define biological
  precedence.
- Phase 8 implementation begins with reference interfaces and downstream fixtures before API
  spelling is frozen.
- CPU, Metal, and ROCm remain the required backend evidence under the current contract.

## Alternatives Considered

- Encode schedules, effects, resolvers, and orientations as exhaustive enums.
- Allow callbacks to mutate model state directly.
- Give earlier declarations, lower cell IDs, tuple position, or atomic winners implicit priority.
- Require every public scientific authoring value itself to be a GPU bitstype.
- Represent division partition as a Boolean forever.
- Run zero-time lifecycle callbacks during initialization.

These alternatives either close downstream extension, weaken scientific determinism, conflate host
and device representations, or make future semantics depend on execution accidents.

## Required Conformance Evidence

- Zero-core-edit downstream implementations of a schedule, trigger/effect, resolver, and division
  geometry.
- Scalar reference planning, conflict resolution, validation, and atomic-commit tests.
- Permutation tests over declarations, tuples, compiler batches, workgroup sizes, and launch
  decomposition.
- Invalid-geometry, unresolved-conflict, capacity, and rollback fixtures proving no partial
  mutation.
- Semantic RNG isolation and replay tests for stochastic triggers and geometries.
- Complete CPU, Metal, and ROCm compile-and-run evidence for GPU-qualified fixtures.
- Inference, allocation, workspace, synchronization, compile-latency, device-code-size, and
  steady-state performance evidence before API freeze.
