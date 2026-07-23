# [PottsToolkit API Reference](@id pottstoolkit-api)

PottsToolkit exports the curated Level 2 modeling and inspection surface. Execution algorithms,
backend types, low-level components, and solution operations remain explicitly owned by
[`CorePotts`](@ref corepotts-api).

`scientific_contract_versions()` exposes the same Phase 13 candidate version report as CorePotts.
`SemanticManifest` records distinct `authoring_dsl_version` and `normalized_ir_version` fields, and
semantic fingerprints carry their independent fingerprint-contract version. These identities do
not claim final paper API freeze approval; see
[Scientific contract identities and algorithm guarantees](@ref scientific-contract-identities)
for the evidence boundary.

## Authoring

```@autodocs
Modules = [PottsToolkit.Authoring]
Order = [:type, :function]
```

## Reference models

```@autodocs
Modules = [PottsToolkit.ReferenceModels]
Order = [:type, :function]
```
