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
                  CellParameter, ModelParameter,
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
                  ExecutionFingerprint, SemanticManifest,
                  AbstractLevel1Declaration, Volume, Surface,
                  FluctuatingVolumePressure, FluctuatingSurfaceTension,
                  AcceptanceTemperature, IndependentNoise,
                  AbstractMissingPairPolicy, RejectMissingPairs, DefaultPairValue,
                  Layout, Place, LabelledCells, CartesianDomain, PeriodicBoundary,
                  ClosedBoundary, FixedExterior, AxisBoundary, PottsProblem,
                  Phase, AbstractRuleExpression, RuleLiteral, OwnerReference,
                  PropertyRead, CellParameterRead, ModelParameterRead,
                  ScalarCall, ConditionalExpression, NoChange,
                  Rule, RuleGroup, TriggerRule, EveryMCS, AtMCS, BetweenMCS,
                  evaluate, @rule, @rules, @trigger

export Authoring, ReferenceModels
export Namespace, SemanticName, AbstractBiologicalType, CellType, Medium
export Binding, BindingTable, PairIdentity, PairwiseLaw
export AbstractPropertyInvariant, UnboundedProperty, ClosedPropertyInterval
export PropertyVisibility, PublicProperty, PrivateProperty
export PropertyPersistence, CheckpointedProperty, EphemeralProperty
export PropertyOptionality, RequiredProperty, OptionalProperty, CellProperty
export CellParameter, ModelParameter
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
export AbstractLevel1Declaration, Volume, Surface
export FluctuatingVolumePressure, FluctuatingSurfaceTension
export AcceptanceTemperature, IndependentNoise
export AbstractMissingPairPolicy, RejectMissingPairs, DefaultPairValue
export Layout, Place, LabelledCells
export CartesianDomain, PeriodicBoundary, ClosedBoundary, FixedExterior, AxisBoundary
export PottsProblem
export Phase, AbstractRuleExpression, RuleLiteral, OwnerReference, PropertyRead
export CellParameterRead, ModelParameterRead
export ScalarCall, ConditionalExpression, NoChange, Rule, RuleGroup, TriggerRule
export EveryMCS, AtMCS, BetweenMCS, evaluate
export @rule, @rules, @trigger

end
