# Phase 5 D2 RNG Evaluation

Status: Active — CPU and Metal candidate qualified; ROCm and CUDA pending

## Candidate

The production candidate is Random123-compatible Philox4x32-10. CorePotts owns the semantic address,
packing, named streams, distribution transforms, and contract version. External implementations are
oracles rather than public API dependencies.

The initial implementation is a small pure, inlineable CorePotts primitive checked against the three
Philox4x32-10 vectors in Random123 1.14.0. PhiloxRNG.jl is the immediate independent Julia oracle;
its implementation uses the same Random123 constants and `widemul(UInt32, UInt32)` round structure.

## V1 address packing

For one fixed master seed and cell generation, every valid `RNGAddress` packs injectively into two
`UInt64` counter words:

- `counter0`: 48-bit MCS, 8-bit semantic subround, 8-bit invocation/retry;
- `counter1`: 32-bit entity, 12-bit operation, 8-bit named stream, 2-bit entity kind, 10-bit draw;
- `key`: master seed XOR a bijective generation-domain transform.

Generation is zero outside the cell entity domain. This makes reuse of one visible cell ID select a
different Philox key while preserving a pure addressed interface. Address-domain overflow is an
explicit model/compilation error rather than silent truncation.

## Implemented transforms

- Raw four-word Philox output
- One selected raw `UInt32`
- `Float32` and `Float64` uniform values strictly inside `(0, 1)`
- Unbiased bounded `UInt32` with locally addressed rejection
- Bernoulli with exact probability-zero and probability-one behavior
- Box–Muller normal with statistical portability
- Exact Poisson inversion on the explicit rate domain `[0, 64]`
- Separately named rounded-normal Poisson approximation
- Immutable categorical tables and exact categorical selection
- Exact small Fisher–Yates permutation for scientific schedules

No default RNG claim is accepted until these transforms pass CPU, Metal, ROCm, and CUDA qualification
under their declared bitwise or statistical portability profiles. Large-layout permutation and an
exact efficient large-rate Poisson family remain separate implementation requirements if demanded
by the final paper workload inventory.

## Current evidence

- Julia 1.12.6 CPU passes all three Random123 1.14.0 Philox4x32-10 known-answer vectors.
- Frozen v1 counter/key packing and semantic-address output vectors pass.
- A KernelAbstractions CPU kernel produces the same raw words as scalar evaluation.
- A local Apple GPU running Metal.jl produces identical raw words, bounded integers, categorical
  choices, and Poisson inversion outputs. Its Float32 uniform and normal transforms meet the
  declared `8eps(Float32)` comparison tolerance.
- The backend benchmark matrix now runs a 257-address, 1,028-word identity probe before existing
  smoke/performance workloads on CPU, Metal, ROCm, and CUDA jobs.
- Warm scalar Philox and categorical calls allocate zero bytes on Julia 1.12.6.
