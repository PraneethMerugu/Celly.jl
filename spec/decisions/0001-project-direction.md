# Decision 0001: Project Direction and Primary Interface

Status: Accepted

Date: 2026-07-17

## Context

Potts.jl currently combines an engine, a high-level toolkit, visualization, and neural-model
experiments. Its intended identity and primary user surface needed to be explicit before APIs and
package boundaries could be redesigned.

## Decision

Potts.jl will equally prioritize scientific trustworthiness, world-leading hardware-agnostic
performance, and ease of biological modeling.

PottsToolkit is the primary public interface and high-level declarative compiler for CorePotts.
CorePotts is the scientific engine and advanced extension interface. The current first-class
backend set is governed by Decision 0013; two- and three-dimensional models are first-class
targets. Genuine SciML semantic integration is a project requirement.

NeuralPotts remains experimental. HST penalties are a defining capability implemented through the
same general extension architecture as other penalties.

Breaking changes are permitted before the paper-quality research release.

## Consequences

- Public modeling examples lead with PottsToolkit.
- Optimized algorithms require explicit scientific guarantee profiles.
- Backend portability requires conformance and benchmarks, not compilation alone.
- Package boundaries and existing APIs may be redesigned.
- Implementation cleverness is subordinate to semantics, generated-code quality, and maintainability.

## Required Evidence

- A complete semantic specification
- Reference-engine conformance
- Backend capability and conformance matrices
- Reproducible scientific and performance benchmarks
