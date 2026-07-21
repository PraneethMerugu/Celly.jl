# Potts.jl Benchmark Project

This project captures correctness-qualified pre-refactor baselines and will become the permanent
JuliaGPU benchmark suite. Results use the versioned schema in `schema.md` and are generated under
the ignored `results/` directory.

Set up the base environment:

```sh
julia --project=benchmark benchmark/setup.jl
```

The environment pins the Apple-Silicon-compatible KernelIntrinsics fork to commit
`b3a02b6e80f0839082a02f1838af7e10e992062c`. It does not follow the branch head, so a future force
push or additional branch commit cannot silently change a paper baseline.

Run one CPU case:

```sh
julia --project=benchmark benchmark/run.jl \
  --backend=cpu --workload=volume_2d_small --algorithm=checkerboard
```

The workload names are:

- `volume_2d_small`
- `adhesion_2d_medium`
- `volume_3d_small`
- `adhesion_2d_publication`

The legacy algorithm names accepted by the runner are `sequential`, `lottery`, `checkerboard`, and
`intrinsic`. These labels describe the pre-refactor implementation; they are not final API names or
scientific guarantee claims.

GPU packages live in separate environments under `backends/`. Stack the selected backend environment
ahead of the base benchmark project so only one GPU stack is loaded:

```sh
JULIA_LOAD_PATH="benchmark/backends/metal:benchmark:@stdlib" \
  julia benchmark/run.jl --backend=metal \
  --workload=volume_2d_small --algorithm=checkerboard
```

GPU samples synchronize the active KernelAbstractions backend inside the timed region. A GPU timing
without this synchronization is invalid.

Run a repeatable smoke or full matrix locally with `benchmark/matrix.jl`, or dispatch the
`Benchmarks` GitHub workflow and download its machine-readable artifact. GPU jobs run only on
explicitly enabled, trusted, backend-labeled self-hosted runners.

Launch independent fresh Julia processes with `benchmark/repeat.jl`. One process is diagnostic,
three full processes are the minimum regression evidence, and five full processes qualify a paper
candidate:

```sh
julia --project=benchmark benchmark/repeat.jl \
  --backend=cpu --profile=full --repetitions=3
```

Phase 12 comparisons consume repeated fresh-process schema `3.0.0` records. The comparator refuses
different hardware, precision, algorithm, model fingerprint, workload shape, or measurement-contract
versions before calculating a performance ratio:

```sh
julia --project=benchmark benchmark/compare.jl \
  --baseline=baseline-run-1.toml --baseline=baseline-run-2.toml \
  --baseline=baseline-run-3.toml \
  --candidate=candidate-run-1.toml --candidate=candidate-run-2.toml \
  --candidate=candidate-run-3.toml --output=comparison.toml
```

Smoke diagnostics may explicitly pass `--minimum-processes=1`; such output is not regression or
paper evidence.

Every matrix now writes a versioned `phase10-reference-suite` TOML record in addition to the
historical baselines. That record covers all five mandatory reference families, separates Level 2
host stages from initialization and warm execution, and retains actual proposal accounting,
residency, observation, checkpoint, and direct-CorePotts evidence. `smoke` is the CI gate; `full`
uses paper-scalable problem sizes and longer synchronized samples.

Phase 1 and the refactor target Julia 1.12.6 exclusively. Older-version compatibility is deferred
until dedicated compatibility CI lanes are established during final release qualification.
