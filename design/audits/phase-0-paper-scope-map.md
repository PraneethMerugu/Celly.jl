# Phase 0 Paper-Scope Map

Status: Accepted scope classification for roadmap execution

This map assigns every current feature family to paper-required, deferred, experimental, replaced,
or removed scope. `Reimplement` means the scientific capability is required but the current code/API
is not authoritative. `Qualify` means implementation is conditional on a named decision/evidence
gate. `Defer` means the feature cannot block the paper release and cannot leak provisional behavior
into stable APIs.

## Package and Repository Scope

| Current area | Scope | Implementation disposition | Roadmap |
| --- | --- | --- | --- |
| Root `Potts` package | Removed | Delete umbrella and re-exports | Phase 2 |
| PottsToolkit | Required primary package | Move to root; rebuild API/compiler/DSL | Phases 2, 10, 11 |
| CorePotts | Required engine | Retain UUID; replace internals behind final protocols | Phases 4-9 |
| MakiePotts | Required optional satellite for release UX | Migrate after observation/solution freeze | Phase 14 |
| NeuralPotts | Experimental satellite | Isolate; migrate only explicitly claimed paper work | Phase 14 or later |
| Mermaid coupling | Deferred integration | Keep out of critical path; redesign over stable protocols | After Phase 13 unless paper requires |
| `TestProblems` production module | Removed from production | Move workloads to test/benchmark support | Phases 2-3 |
| Generated docs/media/data | Removed from source | Reproduce through docs/artifacts/releases | Phases 2, 14 |
| Invalid `paper.pdf` HTML | Removed | Replace only with intentional paper source/artifact | Phase 2 |

## Scientific Model Scope

| Feature | Scope | Governing contract/gate | Implementation disposition |
| --- | --- | --- | --- |
| Cartesian 2D and 3D owner grids | Required | State and topology specs | Reimplement |
| Finite cells and fixed capacity | Required | State spec | Reimplement |
| One conceptual medium with domains | Required | State/cartesian specs | Reimplement |
| Fixed owners and obstacles | Required | Cartesian spec | Reimplement |
| Symbolic cell types and compiled IDs | Required | State/API specs | Reimplement |
| Custom per-cell properties | Required | State/Toolkit/API specs | Reimplement |
| Fragmentation as valid default behavior | Required | Lifecycle/energy specs | Preserve semantics, reimplement |
| Optional connectivity prohibition | Required | Lifecycle/cartesian specs | Reimplement |
| Hexagonal/rhombic-dodecahedral domains | Deferred | SEM-TOP-006 | No stable constructor/default |
| Irregular/graph lattices | Deferred | SEM-TOP-007 | Experimental future family |
| Arbitrary custom boundaries | Deferred | Cartesian deferred scope | No paper claim |

## Component Scope

| Feature | Scope | Governing contract/gate | Implementation disposition |
| --- | --- | --- | --- |
| Conventional volume energy | Required | Energy component law | Reimplement and reference-test |
| Contact/adhesion energy | Required | Energy/cartesian specs | Reimplement and measure explicitly |
| Conventional surface constraint/energy | Required | Cartesian measure contract | Implement independently of HST |
| Chemotaxis and required field drives | Required | D3, cartesian fields | Qualify category, then reimplement |
| Focal-point spring interactions | Required | Energy/lifecycle/numerical specs | Reimplement 2D/3D |
| Length/elongation | Conditional paper requirement | Must receive non-HST semantics or explicit experimental label | Do not preserve current spelling |
| Connectivity constraint | Required optional constraint | Capability + lifecycle contract | Reimplement |
| HST volume/surface/length/focal point | Deferred family | SEM-HST-001/002/003 | Remove from stable path until accepted |
| Neural energy and training | Experimental satellite | Separate NeuralPotts contract | No primary-release guarantee |
| Crofton surface estimators | Deferred experimental | Cartesian spec | No native default |
| External-software parameter presets | Deferred | SEM-COMP-001 | No compatibility claims |

## Algorithm and Randomness Scope

| Feature | Scope | Governing contract/gate | Implementation disposition |
| --- | --- | --- | --- |
| Sequential conventional CPM | Required reference family | D1 + normalized MCS | Reimplement first |
| Parallel lottery CPM | Required candidate family | D1 lottery guarantee | Reimplement with topology-derived budget |
| Checkerboard CPM | Conditional stable family | D1 equilibrium/kinetic guarantee | Qualify before claim |
| Intrinsic checkerboard | Experimental optimization until qualified | D1 equivalence + backend evidence | Quarantine and benchmark |
| Exact and approximate named algorithms | Required API property | Algorithm charter | Separate names and reports |
| Public `active_fraction`/`sweeps_per_step` | Removed | Normalized-MCS decision | Internal lottery derivation only |
| One public step equals one MCS | Required | Time/MCS spec | Reimplement |
| PCG/Xoshiro/global RNG sequences | Replaced | RNG spec and D2 | No compatibility promise |
| Semantic master seed and named streams | Required | RNG spec | Implement in Phase 5 |
| Raw-bit cross-backend RNG identity | Required where specified | D2 | Hardware qualify |
| Distribution transforms | Required as used | D2 | Freeze only after known-answer/statistical tests |

## Lifecycle, Initialization, and Persistence Scope

| Feature | Scope | Governing contract/gate | Implementation disposition |
| --- | --- | --- | --- |
| Growth and property updates | Required | Lifecycle/Toolkit rules | Transactional reimplementation |
| Division and inheritance | Required | Lifecycle + RNG contracts | Device-capable transaction |
| Type transition | Required | Lifecycle contract | Reimplement |
| Death, extinction, retirement, slot reuse | Required | Lifecycle/state contracts | Reimplement |
| Age/volume/probability triggers | Required Level 1 candidates | Lifecycle/DSL contracts | Reimplement with semantic RNG |
| Arbitrary custom closure triggers | Replaced | Level 2/3 typed protocol | No unvalidated closure default |
| Random/sphere/rectangle/composite layouts | Required capabilities | D5 | Rebuild with explicit seed/geometry semantics |
| Snapshot | Required | D4 + SciML | Implement logical synchronized snapshot |
| Exact checkpoint continuation | Required | D4 + RNG | Implement and qualify |
| Backend-independent restart | Required where advertised | D4 | Explicit profile and tests |
| Memory saving | Required | SciML observation contract | Reimplement |
| HDF5/Zarr storage | Required optional extensions | D4 storage equivalence | Rebuild safely |
| Mermaid mutable coupling | Deferred | Future coupling contract | Not a checkpoint or core interface |

## API, Compiler, and SciML Scope

| Feature | Scope | Governing contract/gate | Implementation disposition |
| --- | --- | --- | --- |
| CorePotts direct scientific API | Required | CorePotts public-interface spec | Rebuild with ordinary functions/dispatch |
| CorePotts hardware API | Required expert level | JuliaGPU standard | Keep internal by default; document stable Level 4 hooks |
| PottsToolkit Level 2 typed API | Required | Authoring/composition spec | Implement before DSL |
| PottsToolkit Level 1 DSL | Required | Rule/model spec + D6/D7 | Thin parser over typed IR |
| Current `@rule` macro/closures | Replaced | Compiler standard | Remove after parity |
| 95% stable-component DSL spelling | Required | Accepted API target | Measure at Phase 11 gate |
| Typed semantic IR and reference evaluator | Required | Compiler standard | Implement Phase 10 |
| Semantic fingerprints/reports | Required | D6 + API specs | Implement before cache/API freeze |
| SciML problem/integrator/solution | Required | SciML spec | Reimplement/complete |
| `init`, `solve!`, `solve`, `step!`, `remake` | Required | SciML spec | Conformance-test |
| Callbacks, saving, observations | Required | SciML spec | Explicit MCS boundaries |
| Ensembles | Required | SciML/RNG specs | Semantic ensemble seeding |
| Current output backend types | Replaced | D4 + SciML spec | Final names decided with persistence API |
| Training/AD helpers in CorePotts | Experimental/removed from core | Numerical AD scope | Satellite or extension only |

## Test, Benchmark, Documentation, and Release Scope

| Area | Scope | Implementation disposition | Roadmap |
| --- | --- | --- | --- |
| Package-local unit tests | Required | Add independent runners and environments | Phase 2 |
| Shared reference/conformance suite | Required | Build backend-parameterized evidence | Phase 3 onward |
| Statistical validation tiers | Required | Deterministic/moderate/release batteries | Phase 3 onward |
| JuliaGPU benchmark suite | Required | Dedicated pinned environment and result schema | Phase 1 onward |
| External simulator comparison | Required only for paper claims | Semantically matched separate suite | Phase 12/15 |
| CPU/CUDA/AMDGPU/Metal hardware qualification | Required for claims | Separate real-hardware jobs | Phases 12-15 |
| Existing docs/tutorial prose | Replaced as API authority | Retain workload ideas, manually rewrite | Phase 14 |
| Existing videos/notebooks/dashboards | Artifact/example candidates | Remove generated products from package source | Phases 2/14 |
| Paper reproducibility project | Required | Project, Manifest, configs, analysis, archived results | Phases 2/15 |

## Scope Change Rule

A deferred or experimental feature enters paper-required scope only through an explicit roadmap and
specification update identifying its semantic decision gate, conformance evidence, performance
qualification, documentation work, and effect on release timing. Existing code or a historical
tutorial is not sufficient to change scope.

