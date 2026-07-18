# Phase 5 Completion Audit

Status: Not complete — approved code follow-up and expanded ROCm qualification pending

This audit uses the Phase 5 deliverables and exit gate in `design/refactor-roadmap.md` as the
authoritative definition of completion. A green subset or an available-backend reinterpretation is
not sufficient to close the phase.

## Deliverables

| Requirement | Current evidence | Verdict |
| --- | --- | --- |
| Execution plans, persistent state, reusable workspaces, launch/sync policy, transactions, capabilities | `execution/contracts.jl`; 49 focused CPU checks; real Metal adaptation, workspace, snapshot, and launch probes | Implemented; expanded ROCm rerun pending |
| KA 0.9 ordering without obsolete events/dependencies | No `dependencies=` or `KernelAbstractions.Event` remains in CorePotts source; CorePotts 568/1 and PottsToolkit 276/0 passed locally | Implemented; CI rerun pending |
| Semantic counter RNG, named streams, versioning | Philox v1 implementation; three Random123 vectors; frozen packing/address vectors | Implemented |
| Every required distribution on CPU/AMDGPU/Metal | Expanded 4,096-sample battery covers bounded integer, Bernoulli, categorical, permutation, normal, exact Poisson, approximate Poisson, and capability-scoped Float64; CPU and Metal pass locally | Incomplete: expanded ROCm evidence pending |
| Centralized Adapt and device-valid state | `adapt_execution`; descriptor/storage split; mixed-backend validation; plan-required GPU snapshot | Implemented on CPU/Metal; expanded ROCm rerun pending |
| Remove migrated legacy execution infrastructure | Dependency/event infrastructure removed; historical scientific `PottsState` remains only for Phase 6–9 consumers | Phase 5-owned migration implemented |
| Atomic contract for every site | 43 executable sites mapped exactly to eight contracts with ordering, overflow, contention, reproducibility, backend status, and owning migration phase | Implemented as an audit; unqualified atomics are explicitly not accepted production paths |
| Scratch outside steady state and memory reporting | Reusable execution/transaction buffers; exact byte functions; plan-aware allocation metrics | Implemented for Phase 5 primitives |
| Launch/allocation/sync/transfer instrumentation | Execution metrics plus machine-readable CPU/Metal reports, including adaptation and snapshot transfers | Implemented; expanded ROCm rerun pending |
| Explicit pre-launch unsupported failures | Typed capability reports and `UnsupportedBackendCapability`; Metal Float64 is rejected/skipped by capability before construction | Implemented |

## Exit gate

| Gate | Required proof | Current state |
| --- | --- | --- |
| Backend-neutral plan launches CPU and available GPUs | Correct two-kernel ordered pipeline, compiled-state round trip, workspace report | CPU and Metal complete; earlier ROCm pipeline passed; expanded ROCm rerun pending |
| RNG vectors and semantic addresses across claimed backends | Raw identity plus distribution-specific contract | CPU/Metal complete; earlier ROCm subset passed; expanded ROCm rerun pending |
| No steady-state host/device allocation | Warm function-barrier host allocation plus no CorePotts allocation in launch region | CPU reports zero; GPU kernels use only preallocated arrays; ROCm expanded rerun pending |
| No incidental host synchronization | Two launches followed by exactly one external observation wait | CPU/Metal complete; earlier ROCm report complete |
| Valid representative device code | Real device compilation of RNG, distributions, permutation, ordered pipeline, compiled storage | Metal complete; earlier ROCm subset complete; expanded ROCm rerun pending |

## Backend-contract decision

Decision 0013 defines CPU, Metal, and ROCm as the current first-class backend contract. CUDA remains
present as a deferred integration but is excluded from Phase 5 and release claims. A functional
deferred backend fails execution-plan preflight before adaptation or launch. Reinstating CUDA
requires a later semantic decision and the full real-hardware qualification battery.

## Current code/CI follow-up

The approved local follow-up has:

1. removed the two trailing spaces identified by Project integrity;
2. qualified the seven names shared by CorePotts and the independent `ReferenceSemantics` module,
   with the conformance shard passing 79/79;
3. passed the expanded RNG and execution-state qualification on CPU and real Metal; and
4. prepared the combined change for an authoritative CPU, Metal, and ROCm CI rerun. The AMDGPU RNG
   v1 capability remains deliberately withheld until that expanded ROCm job passes.
