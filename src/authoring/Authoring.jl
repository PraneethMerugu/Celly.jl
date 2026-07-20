module Authoring

import CorePotts
import SciMLBase
import SHA
import Base: isvalid

include("identities.jl")
include("bindings.jl")
include("properties.jl")
include("components.jl")
include("fields.jl")
include("reports.jl")
include("models.jl")
include("normalization.jl")
include("lowering.jl")

export Namespace, SemanticName, AbstractBiologicalType, CellType, Medium
export Binding, BindingTable, PairIdentity, PairwiseLaw
export AbstractPropertyInvariant, UnboundedProperty, ClosedPropertyInterval
export PropertyVisibility, PublicProperty, PrivateProperty
export PropertyPersistence, CheckpointedProperty, EphemeralProperty
export PropertyOptionality, RequiredProperty, OptionalProperty
export CellProperty
export VolumeParameters, VolumeConstraint, FluctuatingVolumeConstraint, Adhesion
export PrescribedField, Chemotaxis
export PropertyUpdate, StochasticPropertyUpdate
export NamedCoreComponent
export ModelFragment, PottsModel, NormalizedModel
export add, remove, replace, compose, normalize, validate, explain, provenance
export dependencies
export CellLayout, MediumLayout, LoweredModel, lower, problem, validate_problem
export backend_report
export semantic_identity, semantic_fingerprint, isvalid
export execution_fingerprint, semantic_manifest
export SourceLocation, Diagnostic, ValidationReport, ModelValidationError
export ProblemValidationError, ModelReport
export DeclarationReport, DependencyEdge, DependencyReport, ProvenanceEntry
export SemanticFingerprint, ExecutionFingerprint
export SemanticManifest

end
