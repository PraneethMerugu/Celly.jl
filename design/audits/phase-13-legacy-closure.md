# Phase 13 Legacy and Provisional-Surface Closure

Status: implemented; final Phase 13 owner approval remains separate

Date: 2026-07-22

## Decision boundary

Decision 0028 requires legacy and provisional APIs to be removed before the paper freeze unless an
explicit release decision preserves them. It also forbids compatibility shims for pre-freeze
behavior. The Phase 0 scope map defers MakiePotts migration to Phase 14 and NeuralPotts migration to
Phase 14 or later.

Accordingly, the Phase 13 workspace contains only PottsToolkit, CorePotts, and the integration
environment. MakiePotts source remains outside the workspace and outside every Phase 13 stable
claim until its Phase 14 migration. The historical NeuralPotts implementation depended entirely on
the deleted engine and has been removed; an experimental satellite may be redesigned later against
the frozen extension protocols.

## Removed implementation

- the historical CorePotts state, parameter, cache, sampler, component, tracker, training,
  initialization, lifecycle, event-kernel, Metropolis-kernel, and simulator graphs;
- the historical HDF5/Zarr state-container adapters while retaining scientific checkpoint
  payload adapters;
- legacy-only entries in the stable-component inventory;
- the mutable Mermaid coupling and its integration tests;
- the old benchmark constructor, algorithm selector, runner, and all-in-one matrix tail;
- tutorials, dashboards, examples, and API pages that executed or advertised the deleted engine;
- the pre-freeze NeuralPotts implementation and its legacy test environment;
- stale CorePotts and documentation dependencies reachable only from those paths.

No aliases, deprecated constructors, wrappers, or runtime fallbacks replace the removed behavior.

## Retained boundaries

- `AbstractPottsState`, `AbstractPottsProblem`, and `AbstractPottsAlgorithm` remain minimal SciML
  and downstream-extension foundations.
- `AbstractTracker` and `AbstractEvent` remain extension categories; the deleted concrete legacy
  implementations do not.
- Current Cartesian topology implementation types remain usable by the scientific engine. Their
  presence does not restore the historical state, sampler, or authoring paths, and export status
  alone does not grant Phase 13 stability.
- MakiePotts is deferred source, not a Phase 13 workspace package or supported release surface.

## Executable evidence

The closure is enforced by:

- `design/audits/phase-7-legacy-freeze.toml`, version 2, whose historical and consumer inventories
  are intentionally empty;
- `scripts/check_legacy_containment.jl`, which scans all production, test, integration,
  documentation, example, and benchmark Julia sources for the quarantined API vocabulary;
- `scripts/check_structure.jl`, which fixes the Phase 13 paper-core workspace and requires the
  obsolete NeuralPotts implementation to remain absent;
- strict executable documentation containing only the Phase 13 paper-core packages;
- independent CorePotts, PottsToolkit, benchmark, and integration suites.

The final completion audit must attach the exact passing commands and revisions. This document does
not substitute for the owner evidence review required by Decision 0028.
