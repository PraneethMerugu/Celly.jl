# Phase 13 API Freeze Audit

Status: candidate inventory complete; owner approval and final evidence admission remain pending

Date: 2026-07-22

## Boundary

Decision 0028 makes stability an explicit evidence decision. Export status alone is not a
compatibility promise. The authoritative candidate policy is
`phase-13-api-freeze-policy.toml`; the exhaustive generated inventory is
`phase-13-api-inventory.toml`. The consolidated evidence and decision surface is
`phase-13-owner-freeze-packet.md`; it remains a draft until real-ROCm evidence is admitted and the
project owner explicitly approves the final dispositions.

Every non-imported export in CorePotts and PottsToolkit is content-addressed and classified as one
of:

- `stable`: documented paper-core or extension contract;
- `limited`: retained public protocol consumer outside the initial paper-core qualification;
- `experimental`: reachable but outside compatibility and paper guarantees;
- `internal`: implementation export with no compatibility guarantee.

The generator fails on unknown or overlapping policy names. The checker regenerates the complete
inventory byte-for-byte, requires every export to have exactly one classification, and rejects any
stable binding without documentation.

## Candidate inventory

At the current candidate:

| Package | Stable | Limited | Experimental | Internal | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| CorePotts | 228 | 1 | 10 | 488 | 727 |
| PottsToolkit | 197 | 1 | 2 | 23 | 223 |

PottsToolkit's stable surface is the documented portion of its intentionally curated Level 1/2
authoring and inspection exports. Its remaining internal exports are abstract grammar or
representation building blocks, not an alternate public authoring path.

CorePotts uses an explicit stable-candidate list plus the Phase 11 admitted component inventory.
All other implementation exports remain internal even when technically reachable. This preserves
the documented scientific state, component, algorithm, persistence, RNG, validation, conformance,
and downstream extension protocols without freezing compiled layouts, kernels, workspaces, or
historical topology conveniences.

## Algorithm classifications

- `SequentialCPM` and `CheckerboardSweepCPM` are stable API candidates in the initial paper-core
  evidence matrix.
- `LotteryCPM` is limited and remains a later protocol consumer.
- `SequentialEquilibrium` is experimental/not admitted to the initial paper scope.
- `TiledCheckerboardCPM` and its configuration types are experimental and non-paper.

Scientific guarantee labels remain separate from API stability. A stable algorithm name may carry
an evidence-supported `:unqualified` scientific label; API stability must not be misread as
sequential-equivalence, equilibrium, or kinetic qualification.

## Version identities

The candidate inventory includes the versioned RNG, authoring DSL, normalized IR, checkpoint,
semantic fingerprint, execution fingerprint, result/evidence schema, sequential algorithm,
checkerboard scheduler, Lottery, and experimental tiled identities. They remain reported as
`:phase13_candidate` until the final owner evidence review. Approval changes freeze status; it does
not rewrite inconvenient evidence or silently change a semantic version.

## Reproduction

```sh
julia --project=. --startup-file=no scripts/generate_phase13_api_inventory.jl --force
julia --project=. --startup-file=no scripts/check_phase13_api_inventory.jl
```

CI runs the checker on Julia 1.12.6. Final Phase 13 closure must attach package, ambiguity,
inference, allocation, device-code, clean-install, documentation, backend-evidence, and owner-review
results; this inventory does not replace those gates.
