# Phase 11 stable-component coverage

Status: Passing, machine-checked on Julia 1.12.6

The source inventory is
[`phase-11-stable-component-inventory.toml`](phase-11-stable-component-inventory.toml). The test
suite verifies that every listed CorePotts symbol exists, every covered PottsToolkit spelling is
exported, every exception has a lower-level route and reason, identities are unique, and the
computed coverage meets the accepted threshold.

| Measure | Result |
|---|---:|
| Stable denominator | 52 |
| Natural Level 1 spellings | 51 |
| Stable lower-level-only exceptions | 1 |
| Coverage | 98.08% |
| Required | 95% |

The sole stable exception is `ExternalFieldOccupancyHamiltonian`. It remains fully available
through `NamedCoreComponent(name, component)` at Level 2 and directly through CorePotts at Level 3.
Freezing a Level 1 biological name before reviewing its coupling-table and sign conventions in a
representative model would create API debt for no scientific gain.

Focal-point mechanics remain the explicitly accepted experimental satellite family and therefore
do not enter the stable denominator. Reference-engine types, automatically derived tracker storage,
and forbidden legacy tracker paths are also excluded for the narrow reasons recorded in the source
inventory.
