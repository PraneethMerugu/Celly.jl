# Biological Events API

The `PottsToolkit` includes a highly optimized, statically allocated event system that handles biological discrete events like cell death (Apoptosis), cell-type transitions, and cell division (Mitosis). 

The event system uses a declarative API attached to the `PottsSystem`. When you declare events, the framework compiles them into a unified, high-performance callback loop that operates seamlessly alongside the continuous Potts physics.

## Declaring Events

You can declare events by passing an array of `AbstractEvent` structs to the `events` keyword argument of your `PottsSystem`. 

```julia
sys = PottsSystem(
    cell_types = [Medium, Epithelial],
    penalties = [ ... ],
    check_interval = 10, # Evaluate events every 10 Monte Carlo Steps (default is 10)
    events = [
        # Mitosis Event
        MitosisEvent(Epithelial,
            trigger = VolumeRatioTrigger(2.0f0),
            orientation = CorePotts.RandomOrientation(),
            inheritance = (target_volumes = CorePotts.Split(0.5f0),)
        ),
        
        # Apoptosis Event
        ApoptosisEvent(Epithelial, 
            trigger = ProbabilityTrigger(0.005f0)
        )
    ]
)
```

## Supported Events

The toolkit ships with three primary event types:

1. **`ApoptosisEvent(cell_type; trigger)`**: Instructs a cell to die. When triggered, the cell type transitions to the background `Medium` (ID 0) and its volume shrinks to 0. (A subsequent `DeathCallback()` will reap the cell's ID to recycle memory.)
2. **`TransitionEvent(from_type => to_type; trigger)`**: Changes a cell's type ID to a new target type ID. Useful for differentiation cascades.
3. **`MitosisEvent(cell_type; trigger, orientation, inheritance, action)`**: Instructs a cell to divide. 
   - `orientation`: Determines the cleavage plane (e.g. `RandomOrientation()` or `MajorAxisOrientation()`).
   - `inheritance`: A NamedTuple declaring how scalar properties are passed down (e.g. `Split(0.5f0)` to halve volume, or `Clone()` to duplicate parameters).
   - `action`: An optional custom callback function for post-division logic.

## Event Triggers

Every event requires a **Trigger**, which is a logical predicate evaluated to determine if the event should fire for a specific cell. Available triggers:

- **`VolumeRatioTrigger(factor)`**: Fires when `actual_volume >= target_volume * factor`. Commonly used for G2/M size checkpoints (e.g., `factor = 2.0`).
- **`AgeTrigger(max_age)`**: Fires when `cell_ages >= max_age`.
- **`ProbabilityTrigger(prob)`**: Fires randomly with probability `prob` at every check interval. Useful for stochastic transitions or cell death.
- **`CustomTrigger(func, required_vars)`**: Allows arbitrary trigger logic. The function must have the signature `(cell_id::Integer, cell_data, u, cache) -> Bool`.

## Event Execution Architecture

To prevent race conditions and physical inconsistencies, the internal callback loop strictly enforces the following phase ordering every `check_interval`:

1. **Apoptosis Phase**: Dead cells are marked and shrink.
2. **Transitions Phase**: Cell types change. (Dead cells bypass this step.)
3. **Mitosis Phase**: Dividing cells split. (Transitioned cells use their new physics properties; dead cells cannot divide.)
4. **Synchronization Phase**: All topological cell trackers (surface area, volume, major axes) are forcibly re-synchronized to guarantee the physics energy engine doesn't receive corrupted metrics from topological tears.

## Memory Safety

The `MitosisEvent` natively interacts with the `max_cells` static allocation limit defined in `PottsProblem`. If a burst of division events pushes the population beyond the pre-allocated GPU memory footprint, the toolkit will cleanly halt the excess divisions and issue a soft `@warn` instead of crashing the Julia process.
