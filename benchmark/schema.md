# Baseline Result Schema

Schema version: `1.0.0`

Each TOML record contains:

- Exact Git commit, dirty-tree flag, implementation checksum, and derived baseline ID
- Julia, OS, architecture, thread, backend, and device information
- Workload dimensions, class, initial cells, and logical initial-state checksum
- Legacy algorithm type and proposal-budget controls
- Initial and final state invariants and checksums
- Workload construction, backend adaptation, initialization, first-MCS, and steady-state timing
- Raw synchronized samples and summary statistics
- Host allocation observations reported by BenchmarkTools
- Known measurement limitations

The schema deliberately labels expected attempts rather than actual attempts because the current
engine exposes no proposal/acceptance counters. Phase 5 instrumentation will add launches,
synchronizations, transfers, device allocation, actual proposals, acceptances, conflicts, and scratch
memory without silently changing the meaning of existing fields.

Changing the meaning or units of a field requires a schema-version change. Adding an optional field
requires documenting the version in which it first appears.

