# ADR 0009: Versioned Compatibility and Explicit Parameter Semantics

- Status: Accepted
- Date: 2026-07-17

## Context

CPM simulators differ in proposal neighborhoods, surface neighborhoods,
interface counting, parameter normalization, acceptance modifiers, cell
lifecycle, and clock definitions. A parameter file copied verbatim between two
programs therefore need not describe the same model. Calling an implementation
"compatible" without specifying the feature and degree of agreement would be
misleading.

Neighborhood-dependent surface definitions are especially important: changing
the counting convention can require coordinated conversion of contact energies,
target surface, surface penalty strength, temperature, yield barriers, and other
energy-like quantities.

## Decision

Raw lattice parameters and normalized or physical parameters are different,
explicit representations. PottsToolkit may accept unitful host-side values, but
it lowers them to a documented device-compatible numeric representation before
execution.

Compatibility is expressed through versioned targets such as
`CC3DCompatibility`, `MorpheusCompatibility`, and `ArtistooCompatibility`.
Compatibility claims are feature-specific and use one of these levels:

1. exact
2. converted
3. statistically equivalent
4. approximate
5. syntax-only
6. unsupported

There is no blanket simulator-compatibility claim. Importers preserve source
version, source semantics, conversions, assumptions, warnings, and unsupported
features as provenance. Unsupported features raise an error by default. A model
combining semantics from multiple targets is labeled hybrid.

Every conversion is registered, versioned, directional, and auditable. If a
conversion scales Hamiltonian energy by a factor `c`, every quantity compared on
that energy scale—including temperature, yield, acceptance offsets, and
energy-dimensional drive parameters—must be scaled consistently.

Exact random trajectories are not expected across independent simulators unless
an individual feature contract explicitly promises them. Compatibility may
instead be established through exact local fixtures, converted observables, or
statistical ensembles as appropriate.

Every compiled model emits a model report containing its semantic choices:
neighborhoods, boundary rules, proposal and acceptance algorithms, clock,
parameter representations, compatibility target, conversions, approximations,
and provenance.

## Consequences

- Compatibility presets are semantic adapters, not bags of default numbers.
- Parameter import cannot silently rescale or reinterpret values.
- Documentation and papers must state feature-level compatibility and the
  evidence supporting it.
- A maintained conversion registry and cross-simulator fixture corpus become
  release requirements.
- Reproducing another simulator may select conventional nonequilibrium behavior
  even when an equilibrium-corrected alternative exists; the distinction must
  remain visible.

## Evidence required

- Golden fixtures generated with pinned versions of each external simulator.
- Round-trip and dimensional-consistency tests for every registered conversion.
- Reports showing every transformation from imported parameters to executable
  device values.
- Exact, conversion-based, or statistical tests matching each advertised claim
  level on CPU and supported GPU backends.
- A paper appendix or companion artifact containing the compatibility matrix,
  fixture versions, tolerances, and known deviations.

## Specification

See [Energy, Proposal, Acceptance, and Tracker Semantics](../energy-proposals-and-trackers.md).

