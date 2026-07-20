module PottsToolkit

import CorePotts

include("authoring/Authoring.jl")
include("reference_models.jl")

using .Authoring: Namespace, SemanticName, AbstractBiologicalType, CellType, Medium,
                  Binding, BindingTable, PairIdentity, PairwiseLaw,
                  AbstractPropertyInvariant, UnboundedProperty, ClosedPropertyInterval,
                  PropertyVisibility, PublicProperty, PrivateProperty,
                  PropertyPersistence, CheckpointedProperty, EphemeralProperty,
                  PropertyOptionality, RequiredProperty, OptionalProperty, CellProperty,
                  VolumeParameters, VolumeConstraint, FluctuatingVolumeConstraint,
                  ElongationParameters, Elongation,
                  BoundaryParameters, BoundaryConstraint, FluctuatingBoundaryConstraint,
                  Adhesion, PreserveConnectivity, PrescribedField, Chemotaxis,
                  PropertyUpdate, StochasticPropertyUpdate, Growth, Transition,
                  Division, ShrinkDeath, ImmediateDeath, NamedCoreComponent,
                  ModelFragment, PottsModel, NormalizedModel, add, remove, replace,
                  compose, normalize, validate, explain, provenance, dependencies,
                  CellLayout, CellLabelLayout, MediumLayout, LoweredModel, lower, problem,
                  validate_problem, backend_report, semantic_identity,
                  semantic_fingerprint, execution_fingerprint, semantic_manifest,
                  SourceLocation, Diagnostic, ValidationReport, ModelValidationError,
                  ProblemValidationError, ModelReport, DeclarationReport, DependencyEdge,
                  DependencyReport, ProvenanceEntry, SemanticFingerprint,
                  ExecutionFingerprint, SemanticManifest

export Authoring, ReferenceModels
export Namespace, SemanticName, AbstractBiologicalType, CellType, Medium
export Binding, BindingTable, PairIdentity, PairwiseLaw
export AbstractPropertyInvariant, UnboundedProperty, ClosedPropertyInterval
export PropertyVisibility, PublicProperty, PrivateProperty
export PropertyPersistence, CheckpointedProperty, EphemeralProperty
export PropertyOptionality, RequiredProperty, OptionalProperty, CellProperty
export VolumeParameters, VolumeConstraint, FluctuatingVolumeConstraint
export ElongationParameters, Elongation
export BoundaryParameters, BoundaryConstraint, FluctuatingBoundaryConstraint
export Adhesion, PreserveConnectivity, PrescribedField, Chemotaxis
export PropertyUpdate, StochasticPropertyUpdate, Growth, Transition
export Division, ShrinkDeath, ImmediateDeath, NamedCoreComponent
export ModelFragment, PottsModel, NormalizedModel
export add, remove, replace, compose, normalize, validate, explain, provenance, dependencies
export CellLayout, CellLabelLayout, MediumLayout, LoweredModel
export lower, problem, validate_problem, backend_report
export semantic_identity, semantic_fingerprint, execution_fingerprint, semantic_manifest
export SourceLocation, Diagnostic, ValidationReport, ModelValidationError, ProblemValidationError
export ModelReport, DeclarationReport, DependencyEdge, DependencyReport, ProvenanceEntry
export SemanticFingerprint, ExecutionFingerprint, SemanticManifest

end
