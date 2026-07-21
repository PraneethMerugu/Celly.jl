# Phase 11 complete-script usability audit

Status: Complete; exact-head CPU/Metal/ROCm CI pass

Date: 2026-07-21

## Scope

This audit reviews complete construction and execution paths for the five paper families: biased
migration/chemotaxis, differential adhesion, monolayer growth, elongation-driven angiogenesis, and
single-cell fluctuation. It evaluates the Phase 11 paper-scope API as ordinary Julia used through
`PottsToolkit`; it does not pull Phase 12 performance tuning, Phase 13 API/version freeze, or Phase
14 documentation migration into the DSL refactor.

## Verdict

No material paper-scope API defect remains in the reviewed scripts. Each family has a reusable,
immutable model constructor and an explicit problem constructor. The scientific declaration is
separate from domain, layout, field realization, capacity, time span, and seed. Every problem is
the single public `CorePotts.PottsProblem`; PottsToolkit adds no runtime wrapper, registry lookup,
host callback, or backend-specific model spelling.

The review found and corrected four concrete defects:

- reference builders still exposed the lower-level `CellLayout`/`CellLabelLayout` vocabulary;
- lifecycle and mechanical policies sometimes required `CorePotts` qualification despite the
  single-import Level 1 goal;
- the stable-component inventory omitted property, transition, HST, and mechanical-noise policies;
- one integration fixture relied on an ambiguous unqualified `CartesianDomain` import.

The corrected builders now use `Layout`, `Place`, `LabelledCells`, `PropertyAtLeast`, and the
curated policy spellings. Stable single-import coverage is 72/73 (98.63%). The sole stable
lower-level-only component, `ExternalFieldOccupancyHamiltonian`, retains explicit Level 2/3 escape
routes rather than receiving a premature biological name.

## Script-level findings

| Family | Natural Level 1 construction | Runtime evidence | Finding |
|---|---|---|---|
| Biased migration and three chemotaxis profiles | reusable `Field`, explicit problem binding, `Volume`, `Adhesion`, `Chemotaxis`, `Layout` | CPU, real Metal, real ROCm | pass |
| Differential adhesion | two `CellType`s, complete symmetric `PairwiseLaw`, labelled deterministic seed | CPU, real Metal, real ROCm | pass |
| Monolayer growth | `Growth`, typed division geometry and threshold, explicit capacity | CPU/Metal/ROCm, one declared division-observation boundary | pass |
| Elongation-driven angiogenesis | exact `Elongation`, optional `PreserveConnectivity`, 2D/3D labelled seeds | CPU/Metal/ROCm in 2D/3D | pass |
| Single-cell fluctuation | explicit stateful mechanical family and explicit noise policy | CPU, real Metal, real ROCm | pass |

Ordinary warm MCS paths introduce zero host synchronization, zero device-to-host transfer, and zero
device allocation. Workloads that must observe division success retain exactly one declared host
observation boundary. This is an explicit lifecycle contract, not hidden fallback.

## Julia and extension quality

- Models, fragments, phases, rules, queries, layouts, and reports are immutable typed values.
- Multiple dispatch distinguishes scientific categories; symbols select identities, not behavior.
- `@rule`, `@rules`, and `@trigger` are optional thin syntax capture over programmatic builders.
- Macro expansion is tested to perform no lowering, compilation, backend selection, synchronization,
  or simulation execution.
- The complete paper-scope scalar operation inventory compiles and executes in the permanent 2D/3D
  CPU/Metal/ROCm rule qualification with zero warm host synchronization, transfer, or device
  allocation.
- Downstream custom physics uses ordinary CorePotts subtyping and public methods, composes through
  an ordinary Level 1 constructor, and executes on CPU, real Metal, and real ROCm without a central
  type switch.
- Typed fragment roles are reusable and resolve before lowering; no mutable global registry exists.

## Deliberately deferred additions

General field sampling inside property rules, broader trigger predicates, a convenience
`PriorityResolver`, richer contact observables, and reconstructable PottsJSON are not required by
the five paper models. Their accepted contracts remain in the semantics suite, but Phase 11 does
not ship provisional implementations merely to mark them present. They can be added vertically
with CPU/GPU conformance evidence without changing the current architecture.

Final quantitative regression budgets, export/version freeze, and tutorial/documentation migration
remain the explicit responsibilities of Phases 12, 13, and 14. Exact-head authoritative CPU,
Metal, and ROCm CI is recorded in the Phase 11 completion audit.
