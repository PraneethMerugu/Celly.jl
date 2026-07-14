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

1. **`ApoptosisEvent(cell_type; trigger)`**: Instructs a cell to die. When triggered, the cell type transitions to the background `Medium` (ID 0) and its volume shrinks to 0.
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
- **`CustomTrigger(func)`**: Allows arbitrary trigger logic. The function must have the signature `(cell_id::Integer, cell_data) -> Bool`.

## Native Mask-Driven Execution Architecture

PottsToolkit leverages a novel GPU-accelerated event architecture to achieve **zero-allocation** event processing. When the simulation engine reaches a `check_interval`:

1. **Mask Evaluation**: A single GPU kernel evaluates all triggers for all cells simultaneously in parallel.
2. **Phase Ordering**: To prevent race conditions, the engine executes events in a strict phase order:
   - **Apoptosis Phase**: Dead cells are marked and removed.
   - **Transitions Phase**: Cell types change.
   - **Mitosis Phase**: Dividing cells split into daughters.
3. **Synchronization**: After all topology changes are applied via masks, trackers (volume, surface area, etc.) are re-synchronized natively.

Because triggers are evaluated in massively parallel GPU kernels and the engine statically unrolls the event loop, evaluating structural changes introduces essentially zero runtime overhead and requires no heap allocations.

*(Note: Custom triggers that cannot run on the GPU will gracefully fall back to sequential CPU evaluation, which may incur slight performance penalties).*

## Memory Safety

The `MitosisEvent` natively interacts with the `max_cells` static allocation limit defined in `PottsProblem`. If a burst of division events pushes the population beyond the pre-allocated GPU memory footprint, the toolkit will throw a hard `error` and crash the simulation to prevent memory corruption. It is highly recommended to pre-allocate a sufficiently large `max_cells` when setting up stochastic growth models to prevent unexpected aborts.

## Writing Custom Events (Declarative Dispatch)

If the built-in events do not cover your use case, you can define custom events by inheriting from `CorePotts.AbstractEvent` and implementing the declarative dispatch hooks.

**CRITICAL PERFORMANCE RULE:** Custom events must be written using raw `KernelAbstractions.@kernel` macros. By providing `CorePotts` with your kernel and its exact arguments, the engine natively handles the Deep Asynchronous Queuing and dependency chaining for you, ensuring zero-overhead GPU execution without explicitly managing `KernelAbstractions.Event` objects.

### Example Pattern

```julia
# 1. Define your Custom Event Type
struct MyGrowthEvent <: CorePotts.AbstractEvent end

# 2. Define the Trigger (Runs natively on GPU)
CorePotts.has_device_trigger(::MyGrowthEvent) = true
@inline function CorePotts.evaluate_trigger(::MyGrowthEvent, i, cd, t)
    return cd.volumes[i] > 0
end

# 3. Define the Action Kernel
@kernel function my_growth_kernel!(mask, target_volumes)
    i = @index(Global, Linear)
    if mask[i]
        target_volumes[i] += 1
    end
end

# 4. Implement the Pipeline Dispatch Hooks
CorePotts.get_event_kernel(::MyGrowthEvent, backend, block_size) = my_growth_kernel!(backend, block_size)

# Return the exact arguments expected by the kernel as a tuple
CorePotts.get_event_args(::MyGrowthEvent, mask, u, p, cache, t) = (mask, u.cell_data.target_volumes)

# (Optional) Override the execution domain size if it's not simply `length(mask)`
CorePotts.get_event_ndrange(::MyGrowthEvent, mask, u) = length(mask)
```
By returning your kernel and its arguments, the GPU natively strings together all subsequent event kernels without stalling the CPU dispatcher, unlocking maximum simulation performance.

## Complex Events via AbstractMultiEvent

For advanced use cases, an event might require multiple sequential GPU kernels (e.g. resetting an array, calculating a reduction, and applying a result). You can seamlessly chain multiple kernels together by subtyping `CorePotts.AbstractMultiEvent`.

Instead of implementing `get_event_kernel`, you define `get_sub_events` to return a tuple of simpler `AbstractEvent` instances. `CorePotts` will fully unroll these sub-events and execute them in sequence.

```julia
struct ResetEvent <: CorePotts.AbstractEvent end
CorePotts.get_event_kernel(::ResetEvent, backend, block_size) = reset_kernel!(backend, block_size)
CorePotts.get_event_args(::ResetEvent, mask, u, p, cache, t) = (mask, u.cell_data.flags)

struct ApplyEvent <: CorePotts.AbstractEvent end
CorePotts.get_event_kernel(::ApplyEvent, backend, block_size) = apply_kernel!(backend, block_size)
CorePotts.get_event_args(::ApplyEvent, mask, u, p, cache, t) = (mask, u.cell_data.flags, u.cell_data.volumes)

# The MultiEvent
struct MyComplexEvent <: CorePotts.AbstractMultiEvent end

# Return the sequence of sub-events
CorePotts.get_sub_events(::MyComplexEvent) = (ResetEvent(), ApplyEvent())
```
