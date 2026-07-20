# PottsToolkit lifecycle declarations

The historical `PottsSystem` event compiler, closure-based `@rule` prototype, and Toolkit-owned GPU
kernels were removed in Phase 10. They are not compatibility APIs.

The current Level 2 lifecycle surface consists of ordinary immutable declarations:

- `Growth` and `PropertyUpdate` for deterministic property transactions;
- `StochasticPropertyUpdate` for semantically addressed stochastic transactions;
- `Transition` for cell-type changes;
- `Division` with an explicit schedule, trigger, geometry, and property inheritance;
- `ShrinkDeath` and `ImmediateDeath` for the two distinct death laws.

These declarations lower into CorePotts' public compiled-lifecycle protocols. Rules due at one
integer-MCS boundary read one pre-event snapshot and commit according to the accepted transaction
contract. GPU execution never falls back silently to a host callback. Capacity exhaustion is
reported at the declared safe observation boundary and does not grow or overwrite device storage.

```julia
using PottsToolkit
import CorePotts

medium = Medium(:Medium)
cell = CellType(:Cell)
volume = VolumeConstraint(cell => (target = 8.0, strength = 2.0))
growth = Growth(volume, cell; rate = 1.0)
division = Division(cell;
    trigger = CorePotts.PropertyAtLeast(:volume__target, 16.0f0),
    geometry = CorePotts.RandomOrientationDivision(0))
model = PottsModel(medium, cell, volume, growth, division)
```

Phase 11 will add the thin Level 1 rule DSL over these same semantic values. It will not restore a
second event engine or permit arbitrary Julia closures inside portable GPU stepping.
