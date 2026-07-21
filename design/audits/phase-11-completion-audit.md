# Phase 11 PottsToolkit Level 1 DSL completion audit

Status: Local candidate complete; authoritative protected CPU/Metal/ROCm CI pending

Date: 2026-07-20

Implementation evidence head: `5667a58`

## Verdict

The Phase 11 paper-scope implementation is locally complete. PottsToolkit now supplies one
Julia-first Level 1 authoring surface over the sole immutable Level 2 semantic path and the sole
CorePotts/SciML runtime. The implementation meets the roadmap exit gate without restoring the
historical compiler, creating a runtime wrapper, or pulling additive future language features into
the refactor.

Phase 11 is a completion candidate rather than an authoritative completion until the exact branch
head passes protected CPU, real-Metal, and real-ROCm CI. Quantitative performance qualification,
final API/version freeze, and manual tutorial/documentation migration remain owned by Phases 12,
13, and 14.

## Exit-gate evidence

| Phase 11 requirement | Evidence | Candidate result |
|---|---|---|
| Thin hygienic macros over programmatic builders | `@rule`, `@rules`, `@trigger`, typed expression nodes, macro/programmatic fingerprint fixture | pass |
| Closed Julia-first rule subset | allow/deny scalar parser inventory, exact output typing, typed draws and queries | pass for paper scope |
| Construction-only macro expansion | permanent AST and side-effect fixtures reject lowering, compilation, backend action, synchronization, and stepping | pass |
| Source, RNG, query, phase, and simultaneous-commit semantics survive lowering | source-located diagnostics, semantic RNG collision tests, query oracles, ordered/simultaneous rule execution | pass |
| Final paper-scope model spelling | immutable identities, properties, parameters, fields, layouts, fragments/roles, models, problems, rules, observables, reports, and solution-side units | pass |
| At least 95% stable-component spelling | machine-readable inventory: 72/73 | 98.63%, pass |
| Level 1/2 semantic equivalence | exact/stateful mechanics and growth fingerprints; field-bound public semantic data; exact policy and algorithm aliases | pass |
| Five paper reference families | chemotaxis, differential adhesion, monolayer growth, 2D/3D angiogenesis, fluctuation | CPU and real Metal pass |
| Downstream custom physics | zero-Core-edit energy subtype and ordinary Level 1 constructor, no registry or central type switch | CPU/real Metal 2D/3D pass |
| No duplicate or legacy modeling path | hard legacy-containment script and frozen historical inventories | pass |
| Complete-script usability | [Phase 11 usability audit](phase-11-usability-audit.md) | pass for all five families |

## Local verification

All commands used Julia 1.12.6.

| Gate | Result |
|---|---:|
| PottsToolkit package suite | 635 / 635 pass |
| CorePotts package suite | 2,988 pass, 1 declared broken, 0 fail |
| Cross-package CPU integration | 109 / 109 pass |
| MakiePotts package suite | 3 / 3 pass |
| NeuralPotts package suite | pass |
| Phase 11 CPU qualification | 2D/3D pass |
| Phase 11 real-Metal qualification | 2D/3D pass |
| Five-family CPU reference qualification | pass |
| Five-family real-Metal reference qualification | pass |
| Warm Phase 11 host synchronization / D2H transfer / device allocation | 0 / 0 / 0 |
| Structure and Julia-target check | pass |
| Hard legacy containment | pass |
| Documentation generator | completes; historical tutorial execution warnings remain assigned to Phase 14 |

The permanent Phase 11 backend workload executes the complete paper-scope scalar operation
inventory, all four addressed draw families, exact output widening, ordered and simultaneous rules,
typed fragment field coupling, downstream custom physics, and exact spatial reductions in both 2D
and 3D. CPU and Metal both report zero warm host synchronization, zero device-to-host transfer, and
zero device allocation.

The five-family reference workload separately checks ordinary model execution. Its division cases
retain exactly one declared observation boundary because lifecycle success must be observed; all
other warm paths remain zero-sync and zero-transfer. No result is implemented by silent host
fallback.

## API and architecture assessment

- Level 1 is normal Julia construction plus three thin syntax-capture macros.
- Level 2 remains the normalized semantic authority and Level 3 remains directly usable CorePotts.
- Models lower to the public CorePotts problem; no Toolkit runtime object exists.
- Stable policy vocabulary is available from one `using PottsToolkit` import.
- Fragment roles and downstream physics use immutable values and ordinary dispatch rather than
  mutable registries.
- GPU stepping receives fully resolved isbits rule effects and preallocated workspace buffers.
- Optional units are solution-side views and cannot alter model fingerprints, RNG, lowering, or
  simulation execution.

## Deliberate non-blocking work

General rule-level field sampling, broader registered trigger predicates, a convenience
`PriorityResolver`, materialized lazy query collections, richer contact observables, and
reconstructable PottsJSON are additive features not used by the five paper models. Their semantics
remain accepted, but they do not receive provisional implementations merely to inflate Phase 11.

Phase 12 must measure construction, normalization, lowering, first use, compilation, memory, and
warm execution against the Phase 10 baseline on real hardware. Phase 13 must review and freeze every
export, extension point, diagnostic, display, and contract version. Phase 14 must manually migrate
the historical tutorials and documentation; the current generator deliberately reports their old
API usage rather than reintroducing compatibility aliases.

## Final closure action

Publish this branch and require the protected CPU/package, Metal, ROCm, integration, structure,
legacy-containment, and documentation workflows on one exact head. After those checks pass, record
the workflow run and exact commit here, change the roadmap status from `Candidate` to `Complete`,
and merge before beginning Phase 12.
