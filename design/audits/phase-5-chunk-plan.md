# Phase 5 Chunk Plan: Execution, RNG, Workspaces, and Backends

Status: Active — CPU/Metal execution foundation implemented; expanded ROCm qualification pending

## Governing exit gate

Phase 5 is complete only when a backend-neutral compiled execution plan launches on CPU and every
available first-class GPU, raw RNG words and required distributions pass their declared portability
profiles, qualified steady-state primitives allocate no host or device memory, internal kernel
pipelines contain no incidental host synchronization, and representative device code is valid.

## Vertical chunks

| Chunk | Scope | Exit evidence |
| --- | --- | --- |
| 1. D2 RNG qualification | Implemented; every applicable primitive is qualified on CPU and Metal, expanded ROCm pending | Random123 known answers, address vectors, raw-word probes, bitwise discrete probes, statistical batteries, capability-scoped Float64 |
| 2. Backend contract | Implemented for CPU, Metal, and ROCm; CUDA explicitly deferred by Decision 0013; ROCm RNG v1 claim withheld pending expanded evidence | Backend reports and negative tests compile without backend tests in scientific code |
| 3. Compiled state | CPU and Metal lowering, plan-instrumented Adapt, mixed-backend validation, and synchronized round trip pass | CPU and GPU snapshots agree with logical state; transfers are counted |
| 4. Plan and workspace | Persistent scratch and transaction buffers implemented; byte estimators and machine-readable probe pass | Warm repeated primitive pipeline allocates no CorePotts scratch/device memory |
| 5. Launch and synchronization | CPU and Metal ordered pipelines pass; dependency/event API removed | Two-kernel pipeline passes with one final sync and no dependency/event wrapper |
| 6. Distributions and atomics | Required normal/Poisson/categorical/permutation profiles; atomic inventory | Deterministic/statistical batteries and per-operation atomic evidence |
| 7. Migration and qualification | Replace Phase 5 legacy counters, RNG helpers, adaptation, launch wrappers | Full CPU and available-GPU matrix passes; replaced infrastructure is removed |

## Scope boundary

Phase 5 provides execution machinery and representative primitives. Phase 6 migrates complete
topology/component/proposal/tracker pipelines; Phase 7 migrates named normalized-MCS algorithms.
Historical scientific consumers may remain temporarily, but no new code may depend on their mutable
RNG counters, whole-problem adaptation, dependency tuples, or direct synchronization conventions.
