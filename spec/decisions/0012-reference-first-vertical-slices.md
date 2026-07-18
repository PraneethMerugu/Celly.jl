# 0012: Close architecture phases with reference-first vertical slices

Status: Accepted

Date: 2026-07-17

## Context

Phase 4 established typed state and extension protocols horizontally, but its original exit gate
also required wholesale migration of historical CPU and GPU runtime storage. That delayed executable
scientific feedback and encouraged judging APIs before a complete model used them.

## Decision

New scientific architecture is developed in narrow vertical slices. The first slice is the accepted
sequential reference engine in `reference-engine-semantics.md`, followed by one PottsToolkit
authoring path that compiles to it. Public API shapes may break until executable slices demonstrate
that they compose naturally.

Phase 4 requires the logical reference slice, not migration or qualification of production GPU
engines. Compiled execution state, GPU execution, and performance qualification remain mandatory in
their roadmap phases and must conform to the same reference behavior.

## Consequences

- Scientific semantics receive end-to-end evidence earlier.
- The project may revise recently introduced protocols when actual use exposes friction.
- Accepted semantics, reference implementation, production implementation, and backend
  qualification are reported independently.
- Historical runtime fields may coexist temporarily, but cannot define the new public contract.

## Alternatives considered

- Migrate every existing kernel before running the new state: rejected because it couples API
  discovery to backend machinery and slows scientific validation.
- Freeze protocols from isolated interface fixtures: rejected because shape tests do not prove that
  a model can execute coherently.

## Required conformance evidence

- Complete normalized-MCS reference execution.
- Deterministic replay and canonical-state checks.
- Local-delta versus full-Hamiltonian checks.
- One PottsToolkit-to-CorePotts reference compilation path.
