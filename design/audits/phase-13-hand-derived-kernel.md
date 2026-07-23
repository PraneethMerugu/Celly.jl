# Phase 13 hand-derived pedagogical transition kernel

Status: Reviewed reference derivation

Date: 2026-07-22

Machine-readable values:
[`phase-13-hand-derived-kernel.toml`](phase-13-hand-derived-kernel.toml)

## Fixture

The fixture is a two-site one-dimensional no-flux domain. It exists only in the independent oracle;
the production Cartesian engine intentionally supports 2D and 3D. Each site has the two directed
von Neumann offsets `-1` and `+1`. A direction crossing a no-flux face consumes proposal budget and
leaves the state unchanged.

The two distinct owners are medium `M1` and cell `C1`. There is no energy contribution and the
temperature is zero, so every actionable different-owner copy is accepted. The ordered state
catalog is

```text
1: M1 M1
2: C1 M1
3: M1 C1
4: C1 C1
```

The sequential primitive selects one of two recipients and one of two directions uniformly. Each
recipient/direction pair therefore has probability `1/4`.

## Primitive-attempt derivation

The homogeneous states are absorbing because every realized neighbor has the same owner. From
`C1 M1`, the four equiprobable paths are:

| Recipient | Direction | Result |
| ---: | --- | --- |
| 1 | left, outside | `C1 M1` |
| 1 | right, site 2 | `M1 M1` |
| 2 | left, site 1 | `C1 C1` |
| 2 | right, outside | `C1 M1` |

The reflected mixed state has the corresponding symmetric row. With rows as source states and
columns as destinations, the primitive kernel is

```text
P = [1    0    0    0;
     1/4  1/2  0    1/4;
     1/4  0    1/2  1/4;
     0    0    0    1]
```

Every row is nonnegative and sums exactly to one.

## Normalized-MCS derivation

The declared sequential time law uses exactly `N = 2` independent, state-fresh attempts per MCS,
so the complete normalized-MCS kernel is `P^2`:

```text
P_MCS = [1    0    0    0;
         3/8  1/4  0    3/8;
         3/8  0    1/4  3/8;
         0    0    0    1]
```

For example, the `C1 M1 -> M1 M1` probability is the first-attempt absorption `1/4` plus a
first-attempt self-transition followed by absorption `(1/2)(1/4) = 1/8`, totaling `3/8`.

`integration/conformance/test_phase13_oracle.jl` requires the independently generated exact
`Rational{BigInt}` primitive and MCS matrices to equal these reviewed values entry for entry.
