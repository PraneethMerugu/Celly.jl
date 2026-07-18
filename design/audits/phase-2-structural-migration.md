# Phase 2 Repository Structural Migration Audit

Status: In progress

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

Scientific implementation files were moved without rewriting their contents. Only include paths,
package metadata, test ownership, and two unused NeuralPotts imports changed in runtime source.
The benchmark implementation checksum now covers the root extension and separated integration
tree in addition to package source and tests.

## Local qualification

- `scripts/check_structure.jl`: pass
- PottsToolkit independent package tests: 256/256 pass
- CorePotts independent package test process: pass
- MakiePotts independent package test process: pass
- NeuralPotts independent package test process: pass
- Complete CPU cross-package integration suite: pass
- CPU benchmark smoke matrix: sequential, lottery, and checkerboard pass with invariants
- Apple Metal benchmark smoke matrix: lottery and checkerboard pass on a real device
- Documentation build: pass with historical warn-only tutorial/docstring findings
- `git diff --check`: pass

## Remaining exit work

- Qualify the exact pull-request revision on hosted Linux and native ARM64/macOS and x86_64/Linux.
- Qualify Metal and AMDGPU through the protected self-hosted workflow.
- Confirm the final reviewed diff contains no scientific implementation change.
