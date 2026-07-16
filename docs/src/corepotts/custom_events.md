# Custom Events & Zero-Sync Lifecycles

In Potts.jl, cell behaviors (like division, death, and differentiation) are handled by the **Events API**. The standard events like `MitosisEvent` and `PropertyUpdateEvent` run entirely natively on the GPU without requiring expensive trips back to the CPU.

## The Zero-Sync Event Lifecycle

The Potts.jl engine strictly adheres to a **Zero-Sync GPU execution model**. This means that during a simulation step:
1. Data never bounces back and forth between the CPU host and the GPU device.
2. The engine does not rely on global type-unstable scratch pads or dictionaries (e.g. `cache.scratch`) to stash buffers.

Instead, every event is strictly responsible for managing and encapsulating its own workspace memory. 

### How Event Buffers are Pre-allocated

When you define an event and pass it to your `PottsSystem`, it does not immediately allocate memory. Instead, memory is allocated right before the simulation begins (during the `SciMLBase.__init` hook). 

The simulator maps the `initialize_workspace` lifecycle hook over every registered event. The events construct their specific buffers (like a `MitosisWorkspace` or spatial neighbor arrays) and return a new instance of themselves containing these initialized buffers. 

## Defining a Custom Event

If you are building an advanced custom event (by subtyping `AbstractEvent`), you must manage your own workspace following this pattern. 

### 1. Define the Workspace Struct
Define a concrete struct to hold the buffers your GPU kernel will need.

```julia
struct MyCustomWorkspace{BufType}
    my_buffer::BufType
end
```

### 2. Define the Event
Your event struct must subtype `AbstractEvent` and it must include a `workspace` field. This field should default to `nothing` upon user construction.

```julia
struct MyCustomEvent{TriggerType, WorkspaceType} <: AbstractEvent
    trigger::TriggerType
    workspace::WorkspaceType
end

# User-facing constructor
function MyCustomEvent(trigger)
    return MyCustomEvent(trigger, nothing)
end
```

### 3. Overload `initialize_workspace`
You must provide a method for `initialize_workspace(evt, u0, topology)` that allocates the buffers based on the size of the state `u0` and returns a newly reconstructed event.

```julia
import CorePotts: initialize_workspace

function initialize_workspace(evt::MyCustomEvent, u0::AbstractPottsState, topology::AbstractTopology)
    # 1. Inspect the state to determine buffer sizes (e.g., number of cells)
    max_cells = length(u0.cell_data.volumes)
    
    # 2. Allocate the buffer on the appropriate device (CPU or GPU)
    # We use similar() or zero() on an existing array to match the backend
    my_buffer = similar(u0.cell_data.volumes, Int32, max_cells)
    fill!(my_buffer, 0)
    
    # 3. Create the workspace
    workspace = MyCustomWorkspace(my_buffer)
    
    # 4. Return a NEW instance of the event containing the workspace
    return MyCustomEvent(evt.trigger, workspace)
end
```

### 4. Overload `required_variables` (Optional)
If your custom event or trigger requires specific fields to exist in the global `cell_data` struct (e.g. tracking a custom property per cell), you should overload the `required_variables` trait.

```julia
import CorePotts: required_variables

# This tells the `build_cell_data` constructor to automatically allocate an array of Float32s 
# called `my_property` if it doesn't already exist.
required_variables(::MyCustomEvent) = (my_property = Float32,)
```

### 5. Use the Workspace in your Dispatcher
When your event's evaluation hook runs, you can safely extract the buffers from the event's `workspace` field and pass them directly to your backend kernel, completely bypassing any global scratch pads.

```julia
function evaluate_event!(evt::MyCustomEvent, integrator)
    # Safely extract the pre-allocated buffers
    buffer = evt.workspace.my_buffer
    
    # ... launch custom kernel using the buffer ...
end
```

By following this pattern, your custom events remain type-stable, isolated, and highly performant on both CPU and GPU backends.
