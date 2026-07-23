"""Optional source position captured by a future Level 1 spelling; never fingerprinted."""
struct SourceLocation
    file::String
    line::Int
    column::Int

    function SourceLocation(file::AbstractString, line::Integer, column::Integer = 0)
        line > 0 || throw(ArgumentError("source line must be positive"))
        column >= 0 || throw(ArgumentError("source column must be non-negative"))
        return new(String(file), Int(line), Int(column))
    end
end

"""One structured diagnostic emitted at a named validation stage."""
struct Diagnostic
    severity::Symbol
    stage::Symbol
    code::Symbol
    message::String
    identity::Union{Nothing, SemanticName}
    related::Tuple
    fragment::Union{Nothing, SemanticName}
    source::Union{Nothing, SourceLocation}
    correction::String
end

function Diagnostic(severity::Symbol, code::Symbol, message::AbstractString;
        stage::Symbol = :normalization,
        identity::Union{Nothing, SemanticName} = nothing, related::Tuple = (),
        fragment::Union{Nothing, SemanticName} = nothing,
        source::Union{Nothing, SourceLocation} = nothing,
        correction::AbstractString = "")
    severity in (:error, :warning, :info) || throw(ArgumentError(
        "diagnostic severity must be :error, :warning, or :info"))
    stage in (:construction, :normalization, :problem, :backend) || throw(ArgumentError(
        "diagnostic stage must be :construction, :normalization, :problem, or :backend"))
    return Diagnostic(severity, stage, code, String(message), identity, related,
        fragment, source, String(correction))
end

"""Immutable collection of all independent diagnostics found in one validation pass."""
struct ValidationReport
    diagnostics::Tuple
end

ValidationReport() = ValidationReport(())
Base.isempty(report::ValidationReport) = isempty(report.diagnostics)
Base.length(report::ValidationReport) = length(report.diagnostics)
Base.iterate(report::ValidationReport, state...) = iterate(report.diagnostics, state...)
isvalid(report::ValidationReport) = !any(item -> item.severity === :error, report.diagnostics)

struct ModelValidationError <: Exception
    report::ValidationReport
end

struct ProblemValidationError <: Exception
    report::ValidationReport
end

function Base.showerror(io::IO, error::ModelValidationError)
    failures = filter(item -> item.severity === :error, error.report.diagnostics)
    print(io, "invalid PottsToolkit.PottsModel")
    for failure in failures
        print(io, "\n  - [", failure.code, "] ", failure.message)
        failure.identity === nothing || print(io, " (", failure.identity, ")")
        isempty(failure.correction) || print(io, "; ", failure.correction)
    end
end

function Base.showerror(io::IO, error::ProblemValidationError)
    print(io, "invalid PottsToolkit problem declaration")
    for failure in error.report
        failure.severity === :error || continue
        print(io, "\n  - [", failure.code, "] ", failure.message)
        failure.identity === nothing || print(io, " (", failure.identity, ")")
        isempty(failure.correction) || print(io, "; ", failure.correction)
    end
end

"""Canonical semantic digest independent of source paths and declaration order."""
struct SemanticFingerprint
    version::VersionNumber
    digest::String
end

"""Digest of semantic meaning plus the selected execution contract."""
struct ExecutionFingerprint
    version::VersionNumber
    digest::String
end

"""One inspectable normalized declaration and its lowering-relevant contract."""
struct DeclarationReport
    identity::SemanticName
    kind::Symbol
    requires::Tuple
    provides::Tuple
    effects::Tuple
    rng_streams::Tuple
    lowering::Tuple
    semantic_data::NamedTuple
    capabilities::CorePotts.ScientificCapabilities
end

"""One explicit semantic dependency from a consumer to a provider."""
struct DependencyEdge
    consumer::SemanticName
    provider::SemanticName
    relation::Symbol
end

struct DependencyReport
    edges::Tuple
    unresolved::Tuple
end

"""Immutable aggregate of model-wide and per-declaration execution capabilities."""
struct ModelCapabilityReport
    overall::CorePotts.ScientificCapabilities
    declarations::Tuple
    diagnostics::ValidationReport
end

Base.isvalid(report::ModelCapabilityReport) = isvalid(report.diagnostics)

function Base.show(io::IO, report::ModelCapabilityReport)
    dimensions = isempty(report.overall.dimensions) ? "none" :
        join(report.overall.dimensions, '/')
    print(io, "ModelCapabilityReport(", dimensions, "D, ",
        report.overall.portable ? "portable" : "not portable", ", ",
        length(report.declarations), " declarations, ",
        isvalid(report) ? "valid" : "invalid", ')')
end

function Base.show(io::IO, ::MIME"text/plain", report::ModelCapabilityReport)
    println(io, "PottsToolkit model capabilities")
    println(io, "  dimensions: ", isempty(report.overall.dimensions) ?
        "none" : join(report.overall.dimensions, ", "))
    println(io, "  portable:   ", report.overall.portable)
    println(io, "  declarations:")
    limit = min(length(report.declarations), 20)
    for index in 1:limit
        entry = report.declarations[index]
        println(io, "    - ", _identity_text(entry.identity), ": ",
            join(entry.capabilities.dimensions, '/'), "D, ",
            entry.capabilities.portable ? "portable" : "backend-specific")
    end
    length(report.declarations) > limit && println(io, "    … ",
        length(report.declarations) - limit, " more")
    if !isvalid(report)
        println(io, "  diagnostics:")
        for item in report.diagnostics
            println(io, "    - [", item.code, "] ", item.message)
        end
    end
end

"""Typed origin record for one normalized declaration."""
struct ProvenanceEntry
    identity::SemanticName
    origin::Symbol
    fragment::Union{Nothing, SemanticName}
    supplied::Bool
    defaulted::Bool
    source::Union{Nothing, SourceLocation}
    lowering_path::Tuple
end

Base.:(==)(left::ExecutionFingerprint, right::ExecutionFingerprint) =
    left.version == right.version && left.digest == right.digest
Base.show(io::IO, fingerprint::ExecutionFingerprint) =
    print(io, "ExecutionFingerprint(v", fingerprint.version, ", ",
        first(fingerprint.digest, 12), "…)")

Base.:(==)(left::SemanticFingerprint, right::SemanticFingerprint) =
    left.version == right.version && left.digest == right.digest
Base.show(io::IO, fingerprint::SemanticFingerprint) =
    print(io, "SemanticFingerprint(v", fingerprint.version, ", ",
        first(fingerprint.digest, 12), "…)")

"""Public inspectable summary of normalized meaning and its complete expansion."""
struct ModelReport
    fingerprint::SemanticFingerprint
    numerical_policy::CorePotts.NumericalPolicy
    cell_types::Tuple
    media::Tuple
    components::Tuple
    declarations::Tuple
    provenance::Tuple
    diagnostics::ValidationReport
end

"""Portable description of normalized meaning; deliberately not executable serialization."""
struct SemanticManifest
    schema_version::VersionNumber
    authoring_dsl_version::VersionNumber
    normalized_ir_version::VersionNumber
    fingerprint::SemanticFingerprint
    numerical_policy::NamedTuple
    declarations::Tuple
    dependencies::DependencyReport
    reconstruction::Symbol
end

function Base.show(io::IO, manifest::SemanticManifest)
    print(io, "SemanticManifest(v", manifest.schema_version, ", ",
        first(manifest.fingerprint.digest, 12), "…, dsl=",
        manifest.authoring_dsl_version, ", ir=", manifest.normalized_ir_version,
        ", ", manifest.reconstruction, ")")
end

function Base.show(io::IO, report::ModelReport)
    print(io, "ModelReport(", length(report.cell_types), " cell types, ",
        length(report.media), " media, ", length(report.components), " components, ",
        isvalid(report.diagnostics) ? "valid" : "invalid", ")")
end

function Base.show(io::IO, ::MIME"text/plain", report::ModelReport)
    println(io, "PottsToolkit normalized model")
    println(io, "  fingerprint: ", report.fingerprint.digest)
    println(io, "  real type:   ", CorePotts.real_type(report.numerical_policy))
    println(io, "  cell types:  ", join((_identity_text(value) for value in report.cell_types), ", "))
    println(io, "  media:       ", join((_identity_text(value) for value in report.media), ", "))
    println(io, "  components:")
    component_limit = min(length(report.components), 20)
    for component in report.components[1:component_limit]
        println(io, "    - ", _identity_text(semantic_identity(component)),
            " :: ", typeof(component))
    end
    length(report.components) > component_limit && println(io, "    … ",
        length(report.components) - component_limit, " more")
    println(io, "  expansion:")
    declaration_limit = min(length(report.declarations), 20)
    for declaration in report.declarations[1:declaration_limit]
        println(io, "    - ", _identity_text(declaration.identity),
            " [", declaration.kind, "] -> ", join(string.(declaration.lowering), ", "),
            " (", join(declaration.capabilities.dimensions, "/"), "D, ",
            declaration.capabilities.portable ? "portable" : "backend-specific", ")")
    end
    length(report.declarations) > declaration_limit && println(io, "    … ",
        length(report.declarations) - declaration_limit, " more")
    if !isempty(report.diagnostics)
        println(io, "  diagnostics:")
        diagnostic_limit = min(length(report.diagnostics), 20)
        for item in report.diagnostics.diagnostics[1:diagnostic_limit]
            println(io, "    - ", item.severity, " ", item.stage,
                " [", item.code, "]: ", item.message)
        end
        length(report.diagnostics) > diagnostic_limit && println(io, "    … ",
            length(report.diagnostics) - diagnostic_limit, " more")
    end
end
