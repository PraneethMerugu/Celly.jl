# JuliaGPU and Open-Protocol Community Validation

Date: 2026-07-19

Status: Completed research supporting the accepted open-protocol standard and Phase 8 interview

## Question

Do the proposed Phase 8 schedule, trigger, effect, conflict-resolution, and division-geometry
protocols follow current Julia, SciML, and JuliaGPU practice without weakening Potts.jl's scientific,
GPU-residency, performance, reproducibility, or hardware-agnostic goals?

## Conclusion

Yes. All five recommendations follow the strongest recurring Julia design pattern:

1. expose a small semantic interface;
2. let outside packages add owned types and methods;
3. validate and lower flexible host descriptions at an explicit compilation boundary;
4. execute concrete, statically resolvable device code; and
5. verify extensions with reusable conformance tests across backends.

No recommendation needs to be weakened. Three refinements make the design more Julian and more
GPU-correct:

- The public scientific object does not itself have to be a bitstype. A GPU-qualified extension
  must lower to an immutable bitstype-compatible compiled descriptor.
- Lifecycle trigger and effect semantics should explicitly distinguish the common pre-event
  snapshot from post-transaction values.
- Conflict resolvers must be invariant under declaration, tuple, compilation-batch, and launch
  order; conformance should test permutations, not merely repeated execution.

Potts.jl should intentionally be stricter than general callback libraries. Arbitrary imperative
callbacks, silent CPU fallback, hidden synchronization, undeclared mutation, and scheduler-defined
conflict priority are incompatible with the project's goals.

## Primary Evidence

### Julia Base interfaces

Julia's interface model uses a small required method set to unlock generic derived behavior, with
optional specialization for more efficient implementations. Multiple dispatch makes those
specializations open to new owned types. This supports small lifecycle methods plus generic
validation and planning rather than central implementation switches.

Sources:

- [Julia interfaces](https://docs.julialang.org/en/v1/manual/interfaces/)
- [Julia methods](https://docs.julialang.org/en/v1/manual/methods/)
- [Julia performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/)

### GPUArrays

GPUArrays explicitly separates a host GPU-array representation from a device-instantiable array
representation and obtains backend behavior through interfaces. It provides a CPU reference
implementation and a reusable test suite for new backends. This is direct precedent for
Potts.jl's logical scientific object, compiled device descriptor, and downstream conformance
fixture model.

Source:

- [GPUArrays interface](https://juliagpu.github.io/GPUArrays.jl/dev/interface/)

### KernelAbstractions

KernelAbstractions specializes a kernel constructor on a backend and concrete arguments, supplies a
small backend interface, and launches asynchronously. Its current design removed the old event-token
system in favor of implicitly ordered launches. Potts.jl therefore should use KernelAbstractions as
an execution mechanism, not as the definition of biological event scheduling or dependency
semantics.

Kernel workgroup barriers require convergent execution. Static workgroup or range specialization
can improve performance but can also cause recompilation. These facts support bounded compiled
descriptors, explicit workspaces, measured specialization, and lifecycle planning across multiple
ordered kernels rather than an unconstrained monolithic callback kernel.

Sources:

- [KernelAbstractions overview](https://juliagpu.github.io/KernelAbstractions.jl/)
- [KernelAbstractions API](https://juliagpu.github.io/KernelAbstractions.jl/v0.9/api/)
- [KernelAbstractions quick start and asynchronous launches](https://juliagpu.github.io/KernelAbstractions.jl/stable/quickstart/)

### CUDA and Adapt

CUDA requires GPU memory accessibility and statically resolvable calls. Runtime dispatch,
exceptions, strings, and many runtime-library operations do not compile. CUDA's own documentation
shows that parametric function arguments can force the specialization needed for device execution.
Kernel arguments ultimately need bitstype-compatible representations.

Adapt separates recursive structural adaptation from storage conversion. Wrapper-owning packages
extend `adapt_structure`; backend libraries provide storage adaptation. For Potts.jl this supports
an extension-owned scientific-to-compiled lowering method followed by centralized engine storage
adaptation. It does not support adapting the entire host model indiscriminately.

Sources:

- [CUDA kernel programming requirements](https://cuda.juliagpu.org/stable/development/kernel/)
- [CUDA troubleshooting and unsupported dynamic calls](https://cuda.juliagpu.org/stable/development/troubleshooting/)
- [CUDA custom structs](https://cuda.juliagpu.org/dev/tutorials/custom_structs/)
- [Adapt](https://github.com/JuliaGPU/Adapt.jl)

### AcceleratedKernels

AcceleratedKernels uses unified interfaces across CPU, CUDA, AMDGPU, oneAPI, and Metal, runs the same
randomized tests on those architectures, represents alternative implementations as explicit
algorithm values, and exposes temporary arrays for caller-managed reuse. This validates several
Potts.jl rules:

- one public scientific operation can have portable implementations across backends;
- execution algorithms and performance tuning remain explicit values rather than backend-named
  scientific behavior;
- lifecycle scans, compaction, sorting, and predicates should reuse preallocated workspaces; and
- every adopted primitive needs backend qualification because an algorithm valid on one device may
  require a safer implementation on another.

This is not hypothetical. AcceleratedKernels documents that its decoupled-lookback scan requires
device-level memory consistency unavailable on Metal, while its scan-prefix implementation remains
the portable choice. Potts.jl must therefore qualify the selected primitive algorithm, not merely
the public primitive name.

Sources:

- [AcceleratedKernels overview and cross-backend testing](https://juliagpu.github.io/AcceleratedKernels.jl/stable/)
- [AcceleratedKernels temporary-buffer guidance](https://juliagpu.github.io/AcceleratedKernels.jl/stable/performance/)
- [AcceleratedKernels algorithm policies](https://juliagpu.github.io/AcceleratedKernels.jl/stable/api/predicates/)
- [AcceleratedKernels scan capability differences](https://juliagpu.github.io/AcceleratedKernels.jl/stable/api/accumulate/)

### Kernel intrinsics

KernelAbstractions mainline is developing a nested lower-level `KernelIntrinsics` API for backend
implementers. Potts.jl currently pins the distinct external `KernelIntrinsics.jl` package and the
project's Metal-support fork. This does not create a present namespace conflict, but it confirms
that subgroup operations and memory intrinsics are evolving backend plumbing rather than stable CPM
model semantics.

CorePotts should retain its portable KernelAbstractions implementation, isolate the external
intrinsics dependency behind internal operation methods, and reevaluate overlap with the
KernelAbstractions interface during Phase 12. The current fork remains pinned until an upstream or
replacement version passes the same Metal and ROCm conformance and performance evidence.

Sources:

- [KernelAbstractions mainline intrinsics interface](https://github.com/JuliaGPU/KernelAbstractions.jl/blob/main/src/intrinsics.jl)
- [KernelAbstractions v0.9.41 intrinsics API release entry](https://github.com/JuliaGPU/KernelAbstractions.jl/releases/tag/v0.9.41)

### SciML and ModelingToolkit

SciMLBase uses type dispatch on problems and algorithms through `init`, `solve!`, `__init`, and
`__solve`, rather than a central solver implementation registry. This supports Potts.jl's open
algorithm and lifecycle policy values.

ModelingToolkit separates event conditions from effects and explicitly distinguishes values before
an event with `Pre`. Symbolic effects declare changed values and are checked for post-event
consistency. Its more general imperative affects must declare observed and modified state and remain
less constrained. Potts.jl should adopt the condition/effect and pre/post distinctions while keeping
only typed, transactional effects in the stable device path.

Periodic and preset-time ModelingToolkit events confirm that schedules are reusable semantic
objects rather than fields hidden in every callback. Potts.jl appropriately narrows their time
domain to positive integer MCS boundaries.

Sources:

- [SciMLBase init and solve interface](https://docs.sciml.ai/SciMLBase/dev/interfaces/Init_Solve/)
- [ModelingToolkit event handling](https://docs.sciml.ai/ModelingToolkit/stable/basics/Events/)

### Tables and ChainRules

Tables demonstrates a small required interface, optional optimized methods, interface traits,
external implementation, and reusable implementation tests. It also demonstrates that an abstract
supertype may provide useful defaults without making subtyping the complete conformance test.

ChainRulesCore separates a lightweight protocol from rule collections and provides a companion
testing package. Packages define methods for their own functions without depending on every AD
engine. Potts.jl should similarly keep lightweight runtime validation in CorePotts and eventually
place heavyweight randomized and multi-backend extension tests in a test-only conformance package
or module.

Sources:

- [Tables implementation interface](https://tables.juliadata.org/dev/implementing-the-interface/)
- [ChainRules ecosystem organization](https://juliadiff.org/ChainRulesCore.jl/stable/)

### Julia package extensions

Julia package extensions load optional integration methods only when their weak dependencies are
present. CorePotts already follows this pattern for backend and storage packages. The protocol
provider remains open even when the currently qualified release set is deliberately finite.

Source:

- [Julia package extensions](https://docs.julialang.org/en/v1/manual/code-loading/#Package-Extensions)

## Verification of the Five Recommendations

| Recommendation | Community validation | Potts.jl refinement | Verdict |
| --- | --- | --- | --- |
| Open integer-MCS schedules | ModelingToolkit exposes periodic and preset-time event forms; Julia interfaces favor reusable values and methods. | A host schedule lowers to a compact device schedule descriptor. Stable identity, serialization, positive integer domain, and boundary-zero rejection are explicit. | Confirmed |
| Pure snapshot triggers | ModelingToolkit separates conditions and affects; GPU compilation forbids arbitrary runtime behavior. | Trigger reads use the common `PreLifecycleSnapshot`. Target domain, reads, RNG labels, and capabilities are declared. The device result is a compact decision/mask, not an allocated object. | Confirmed |
| Typed transactional effects | ModelingToolkit symbolic affects declare changes and post-event consistency; Tables/ChainRules show small open interfaces. | Stable effects declare observed and modified state, plan from the common pre-snapshot, validate before mutation, and commit through category-owned transaction machinery. Arbitrary imperative mutation remains host-only and explicitly synchronizing, never a stable GPU effect. | Confirmed and strengthened |
| Explicit conflict resolvers | GPU race documentation shows that concurrent writes need deliberate coordination; atomics solve memory races, not scientific priority. | Resolver output must be permutation-invariant and keyed by semantic identity. Tests permute declarations, tuple layout, batches, and workgroup tuning. Unresolved conflicts abort before mutation. | Confirmed; deliberately stricter than general callbacks |
| Open division geometry | Julia dispatch, GPUArrays host/device separation, Adapt lowering, and CUDA specialization all support open host policies with concrete device forms. | The geometry authoring value lowers to a compiled descriptor. The device partition method returns a compact descendant-region label. Phase 8 qualifies two-region binary division while avoiding a representation that can express only a Boolean forever. | Confirmed |

## Refined Phase 8 Contract

The research supports the following refined architecture:

```text
host event declaration
    schedule + target domain + trigger + effect + resolver
                         |
                         v
host validation and lowering
    identities + requirements + effects + capabilities + workspace bounds
                         |
                         v
concrete compiled lifecycle plan
    device descriptors + canonical ordering + preallocated arrays
                         |
                         v
integer-MCS boundary
    trigger masks -> typed plans -> conflict resolution -> validation -> atomic commit
```

Every arrow is a documented protocol boundary. Only the last stage runs inside the MCS lifecycle
step. Host construction and validation may be expressive; the compiled plan is concrete and the
device path has no runtime dispatch, allocation, exception, host callback, or hidden synchronization.

## Important Non-Copies

Potts.jl should learn from these libraries without copying mechanisms that conflict with its domain:

- Do not use SciML's arbitrary imperative callback model for stable lifecycle mutation.
- Do not use KernelAbstractions launch ordering as biological conflict resolution.
- Do not use device atomics as an implicit event priority rule.
- Do not require every scientific authoring object to be a bitstype; require its compiled device
  form to be valid instead.
- Do not assume a reusable AcceleratedKernels primitive preserves Potts.jl reproducibility or
  transaction semantics until it is qualified with explicit workspace and backend tests.
- Do not force every interface through one inheritance tree; subtyping communicates scientific
  category while methods and conformance establish behavior.
- Do not create a runtime plugin registry where Julia dispatch or package extensions already solve
  the problem.

## Resulting Research Gate

The five recommendations are safe to accept when their normative wording includes the three
refinements in this report. Phase 8 implementation should then proceed with:

1. minimal interface sketches;
2. scalar reference implementations;
3. host-to-compiled lowering;
4. one non-built-in downstream fixture per protocol;
5. CPU device-style execution;
6. Metal and ROCm compile-and-run qualification; and
7. compile-latency, allocation, synchronization, workspace, and steady-state performance checks.

This sequence preserves the existing goals. It does not require implementing arbitrary schedules,
effects, or division mechanics before the paper release; it requires that the required built-ins do
not close the protocol around themselves.
