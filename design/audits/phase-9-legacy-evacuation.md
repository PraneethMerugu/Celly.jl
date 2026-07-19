# Phase 9 Legacy Final-Name Evacuation

Status: Implemented migration record

Date: 2026-07-19

## Decision

The historical engine types formerly named `PottsProblem`, `PottsIntegrator`, and `PottsSolution`
are retained only as `LegacyPottsProblem`, `LegacyPottsIntegrator`, and `LegacyPottsSolution`.
Those names are internal, unexported, and frozen at the existing compatibility boundary. The final
public names now denote only the Phase 9 SciML interface over the qualified scientific engine.

This is a deliberate exception to the Phase 7 read-only hashes. It changes names and dispatch
targets only; it does not change the historical engine's algorithms, state transitions, RNG,
sweep semantics, or storage behavior.

## Changed frozen boundary

- `state/types.jl`: evacuates the three historical type bindings.
- `sciml/simulator.jl`: moves historical SciML dispatch to the explicit legacy types.
- `components/training.jl`: keeps its historical cache path on `LegacyPottsProblem`.
- `src/problems.jl`: keeps the current PottsToolkit bridge returning the historical problem until
  Phase 10 migrates the Toolkit compiler and DSL.
- `src/PottsToolkit.jl`: explicitly imports and re-exports the temporary historical Toolkit
  surface after CorePotts removes those names from its public export list.
- Existing tests, examples, integrations, benchmark fixtures, and the Mermaid extension now name
  the legacy types explicitly where they still exercise that frozen path.
- The legacy benchmark workload explicitly imports its frozen state, parameter, cache, and sampler
  names. This preserves the workload after export curation without restoring historical CorePotts
  exports; its mixed-source freeze signature was deliberately renewed in this audit.

## Containment enforcement

`scripts/check_legacy_containment.jl` treats the three `Legacy*` names as quarantined vocabulary,
includes package extensions in production inventory checks, and protects the Phase 9 SciML source
from all quarantined names. A new production or consumer reference therefore fails unless it is
added deliberately to the freeze manifest with another migration audit.

## Acceptance evidence

- The final names have one meaning and the legacy names are not exported.
- Historical state, sampler, cache, and algorithm names are no longer CorePotts exports; their
  remaining Toolkit compatibility surface is explicit, frozen, and assigned to Phase 10.
- The protected scientific and final SciML paths contain no quarantined vocabulary.
- The complete CorePotts test suite passes after the evacuation.
- Phase 10 owns removal of the remaining Toolkit-facing compatibility bridge; Phase 9 does not
  duplicate or reinterpret it.
