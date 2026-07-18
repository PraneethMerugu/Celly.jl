# Phase 2 Repository Structural Migration Audit

Status: Complete

## Authority and boundary

This phase implements the accepted repository architecture without redesigning scientific
semantics. The immutable
[`pre-refactor-baseline-2026-07-17`](https://github.com/PraneethMerugu/Potts.jl/releases/tag/pre-refactor-baseline-2026-07-17)
remains the behavior and performance comparison authority. Algorithm, MCS, RNG, energy, topology,
and DSL semantic changes are outside this phase.

## Structural changes

- `PottsToolkit` is the repository-root package and retains UUID
  `e4c62a4c-8889-4cc8-ad3a-75efc86c53b9`.
- The historical `Potts` package and four-package re-export layer are removed.
- `CorePotts`, `MakiePotts`, and `NeuralPotts` remain independent packages under `lib/`.
- Runtime dependencies point downward only; test-only dependencies are package extras.
- `CorePotts` source is organized into state, topology, components, proposals, lifecycle,
  execution, kernels, SciML, and initialization responsibilities.
- PottsToolkit source is organized around models, domains, problems, and rules while preserving
  the existing modules and behavior.
- Tests have one owner: root `test/` for PottsToolkit, package-local satellite and CorePotts tests,
  and `integration/` for cross-package behavior.
- The disconnected chemotaxis fragmentation reproducer is retained under
  `integration/known_defects/` and is not represented as a green conformance test.
- `benchmark/`, `docs/`, examples, and their manifests reference the root PottsToolkit package.
- `paper/` is a pinned Julia 1.12.6 application environment.
- Independently installable packages do not commit local manifests; generated documentation,
  benchmark, profiler, coverage, media, and paper-result products are ignored.

## Mechanical preservation

Scientific implementation files were moved without rewriting their contents. Runtime edits were
limited to include paths, removal of two unused NeuralPotts imports, and a host-side lottery-bound
type correction discovered when the disconnected mass-conservation test first ran independently.
That correction computes the topology bound in the algorithm's configured float type; it changes
neither kernel execution nor RNG behavior. The benchmark implementation checksum now covers the
root extension and separated integration tree in addition to package source and tests.

## Local qualification

- `scripts/check_structure.jl`: pass
- PottsToolkit independent package tests: 256/256 pass
- CorePotts independent package test process: 346 pass, 1 explicitly broken
- MakiePotts independent package test process: pass
- NeuralPotts independent package test process: pass
- Complete CPU cross-package integration suite: pass
- CPU benchmark smoke matrix: sequential, lottery, and checkerboard pass with invariants
- Apple Metal benchmark smoke matrix: lottery and checkerboard pass on a real device
- Documentation build: pass with historical warn-only tutorial/docstring findings
- `git diff --check`: pass

## Pull-request qualification

The Phase 2 implementation revision `875ba3e` passed every enabled gate on
[PR #8](https://github.com/PraneethMerugu/Potts.jl/pull/8):

- hosted Julia 1.12.6 package tests for PottsToolkit, CorePotts, MakiePotts, and NeuralPotts
- hosted thermodynamics, biophysics, and cross-package integration shards
- native Julia 1.12.6 CPU verification on macOS ARM64 and Linux x86_64
- protected Apple Metal and AMDGPU/ROCm smoke qualification
- documentation build, project-integrity contract, and required aggregate

CUDA remains intentionally skipped until a CUDA runner is enabled; it is not an available Phase 2
gate. The available real-GPU exit requirement is exceeded by independent Metal and ROCm passes.

## Exit-gate conclusion

- Every package loads and tests independently from its own clean environment.
- Cross-package tests execute from the dedicated integration environment.
- CPU, Metal, and ROCm workloads execute through the moved package structure.
- The structural validator proves downward-only released-package dependencies.
- The obsolete root `Potts` runtime and duplicated test ownership are absent.

All Phase 2 deliverables and exit criteria are satisfied.
