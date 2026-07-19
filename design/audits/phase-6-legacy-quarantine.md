# Legacy Engine Quarantine

Status: Machine-enforced through Phase 7; deletion owned by Phases 10--11

## Boundary

The replacement scientific path consists of:

- `algorithms/`;
- `protocols/scientific.jl` and every `components/scientific_*.jl` source;
- the Cartesian, semantic RNG, reference, logical-state, initialization, and execution contracts
  consumed by those sources; and
- the sequential, checkerboard, lottery, mechanics, and scientific backend qualifiers.

This path does not dispatch through historical concrete penalties, topology presets,
`MetropolisSampler`, positional tracker tuples, `evaluate_penalty` closures, or algorithms exposing
`active_fraction` and `sweeps_per_step`. The generic `ScientificComponentSet` folds the five
explicit semantic categories `AbstractEnergy`, `AbstractDrive`, `AbstractHardConstraint`,
`AbstractKineticModifier`, and `AbstractMechanicalComponent`.

## Quarantined inventory

The exact inventory and SHA-256 freeze are recorded in `phase-7-legacy-freeze.toml`. Twenty-two
pure historical or consumer files are frozen in full. Three files that mix replacement and legacy
code freeze only the ordered lines containing quarantined vocabulary, allowing clean scientific
exports, topology work, and qualifiers to evolve without permitting the historical region to grow.
Together they cover the component, tracker, topology, sampler, kernel, state/algorithm,
initialization, SciML, PottsToolkit compiler, satellite, and benchmark consumers that remain
executable while PottsToolkit still compiles the old API.

The inventory is a containment boundary, not an accepted compatibility surface. Historical code
may be deleted. It may not grow, gain consumers, serve as a fallback from the replacement API, or
be cited as scientific authority.

## Enforcement

`scripts/check_legacy_containment.jl` is a required CI gate and enforces three independent rules:

1. Every pure inventoried file must retain its full SHA-256 digest, and every mixed file must retain
   the digest of its ordered quarantined lines. A deliberate migration must delete the consumer or
   update the manifest together with an explicit audit; incidental edits fail.
2. Replacement scientific sources are scanned in full and must contain no quarantined vocabulary
   or fallback edge.
3. Every production file containing quarantined vocabulary must appear in the manifest, making the
   inventory exhaustive even when a workflow has no base diff.
4. Added Julia lines across packages, tests, benchmarks, integration fixtures, tutorials, and
   examples are compared with the pull-request base and may not introduce historical constructors,
   algorithms, time controls, or penalty evaluation names. Deletions remain unrestricted.

The checker is intentionally conservative and review-visible. Its own source is the sole exception
to the added-vocabulary rule because a rejection checker must spell the rejected identifiers.

## Removal owner

Phase 7 closes with containment, not deletion, because the current PottsToolkit production compiler
still consumes the historical engine. Phases 10--11 must establish typed-API/DSL conformance parity
and then delete the quarantined engine and production consumers. The Phase 11 exit gate names that
deletion explicitly; Phase 13 independently rejects any remaining legacy surface before API freeze.
