# [Backends](@id corepotts-backends)

CorePotts separates the *simulation* from *output storage*.
After each saved time step (`saveat` interval) the current lattice state is written to a
**backend**.
Three backends are provided out of the box.

---

## MemoryBackend *(default)*

```julia
sol = solve(prob, alg; saveat = 10)
# equivalent to:
sol = solve(prob, alg; saveat = 10, backend = MemoryBackend())
```

The `MemoryBackend` stores every saved frame in Julia's heap (RAM).
It requires no additional packages and gives instant random access to any frame via
`sol[t]` or iteration.

**Pros:**
- Zero-dependency, works everywhere.
- Immediate in-memory access — ideal for post-processing in the same Julia session.
- Compatible with all MakiePotts functions (`pottsplot`, `record_potts`, `explore_potts`).

**Cons:**
- Memory usage grows linearly with the number of saved frames and grid size.
  For a 500×500 grid saved every 10 MCS over 5000 steps that is 500 frames × 250 000
  Int32 sites ≈ 500 MB.
- Not suitable for very long simulations or memory-constrained environments.

**When to use:** Short to medium simulations, interactive exploration, tutorials.

---

## ZarrBackend

```julia
using Zarr   # must be loaded before calling solve

sol = solve(prob, alg;
    saveat  = 10,
    backend = ZarrBackend("simulation_output.zarr"),
)
```

The `ZarrBackend` streams each frame to a [Zarr](https://zarr.dev) v2 store on disk
(or any Zarr-compatible storage) in chunked, compressed format.
Zarr is a cloud-native format: the store can point to a local directory, an S3 bucket,
or any AbstractStore-compatible backend.

**Pros:**
- Out-of-core: the simulation can run for millions of MCS without filling RAM.
- Chunked storage enables efficient random access to arbitrary frames.
- Compatible with Python (zarr-python), Dask, and Xarray for downstream analysis.
- Supports compression (default: Blosc LZ4).

**Cons:**
- Requires `using Zarr` before `solve`.
- Slightly higher per-frame write latency than `MemoryBackend`.
- Reading frames back into Julia requires an explicit `sol[t]` call that triggers disk I/O.

**When to use:** Long simulations, batch cluster jobs, any case where the output exceeds
available RAM, or when you need to share output with Python workflows.

```julia
# Reading frames back after the fact
using Zarr, PottsToolkit
sol = load_zarr("simulation_output.zarr")   # returns a lazy solution object
state_at_100 = sol[100]                      # loads only that frame from disk
```

---

## HDF5Backend

```julia
using HDF5   # must be loaded before calling solve

sol = solve(prob, alg;
    saveat  = 10,
    backend = HDF5Backend("simulation_output.h5"),
)
```

The `HDF5Backend` writes each frame as a dataset inside an HDF5 file.
HDF5 is a mature, widely supported scientific data format available in virtually every
language and analysis environment.

**Pros:**
- Out-of-core storage like ZarrBackend.
- Excellent tooling: h5py (Python), MATLAB, R, VisIt, ParaView all support HDF5 natively.
- Single file output is convenient for archiving.
- Supports compression and chunking via the HDF5.jl interface.

**Cons:**
- Requires `using HDF5` before `solve`.
- Less cloud-native than Zarr — not suited for streaming to S3 without extra tooling.
- Large HDF5 files can have slow random-access if chunking is not configured carefully.

**When to use:** When downstream analysis will happen in MATLAB, Python (h5py), or
another HDF5-aware environment; or when archiving simulation output for long-term storage.

---

## Comparison Summary

| | `MemoryBackend` | `ZarrBackend` | `HDF5Backend` |
|---|---|---|---|
| Extra package | none | `Zarr` | `HDF5` |
| Storage location | RAM | Disk / Cloud | Disk |
| Max simulation size | Limited by RAM | Unlimited | Unlimited |
| Random frame access | O(1) | O(1) chunks | O(1) chunks |
| Python-compatible | — | ✅ zarr-python | ✅ h5py |
| Cloud-native | — | ✅ S3, GCS, etc. | ❌ |
| Best for | Short sims / interactive | Long sims / cluster | Archival / MATLAB |

---

## Custom Backends

You can implement a custom backend by subtyping
`CorePotts.CorePottsBase.AbstractBackend` and implementing the `write_frame!` method:

```julia
import CorePotts.CorePottsBase: AbstractBackend, write_frame!

struct MyBackend <: AbstractBackend
    # ... your fields
end

function write_frame!(backend::MyBackend, state, t::Int)
    # serialize `state` to your storage system at time index `t`
end
```

Pass an instance of your backend as the `backend` keyword to `solve`.
