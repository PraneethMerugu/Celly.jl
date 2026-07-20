"""A semantic finite-cell raster used only to construct a problem's initial state."""
struct CellLayout{M <: AbstractArray{Bool}, P <: NamedTuple}
    cell_type::CellType
    provisional_id::UInt64
    mask::M
    priority::Int32
    properties::P
end

function CellLayout(cell_type::CellType, provisional_id::Integer,
        mask::AbstractArray{Bool}; priority::Integer = 0, properties::NamedTuple = NamedTuple())
    0 < provisional_id <= typemax(UInt64) || throw(ArgumentError(
        "provisional cell identity must be positive and fit UInt64"))
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "initial claim priority must fit Int32"))
    return CellLayout(cell_type, UInt64(provisional_id), mask, Int32(priority), properties)
end

"""A semantic medium raster used only to construct a problem's initial state."""
struct MediumLayout{M <: AbstractArray{Bool}}
    medium::Medium
    mask::M
    priority::Int32
end

function MediumLayout(medium::Medium, mask::AbstractArray{Bool}; priority::Integer = 0)
    typemin(Int32) <= priority <= typemax(Int32) || throw(ArgumentError(
        "initial claim priority must fit Int32"))
    return MediumLayout(medium, mask, Int32(priority))
end

"""One cell-type-indexed property column produced by Level 2 lowering."""
struct CellPropertyBinding{T}
    key::Symbol
    values::BindingTable{CellType, T}
end

"""Inspectable, host-only result of lowering one normalized Level 2 model."""
struct LoweredModel{N, C, S, B, CT, MD}
    normalized::N
    core_model::C
    property_schema::S
    property_bindings::B
    biological_types::Tuple
    cell_type_ids::CT
    medium_ids::MD
end

function Base.show(io::IO, lowered::LoweredModel)
    print(io, "LoweredModel(", length(lowered.normalized.cell_types), " cell types, ",
        length(lowered.normalized.media), " media, ",
        length(lowered.normalized.components), " components)")
end

struct _LoweringContext{T, C, M, D, R}
    cell_types::C
    media::M
    declarations::D
    contact_relation::R
end

struct _LoweredComponents{E <: Tuple, D <: Tuple, C <: Tuple, K <: Tuple, M <: Tuple,
        L <: Tuple, S <: Tuple, P <: Tuple}
    energies::E
    drives::D
    constraints::C
    modifiers::K
    mechanics::M
    lifecycle::L
    schemas::S
    properties::P
end

_LoweredComponents() = _LoweredComponents((), (), (), (), (), (), (), ())

function _merge_lowered(left::_LoweredComponents, right::_LoweredComponents)
    return _LoweredComponents(
        (left.energies..., right.energies...),
        (left.drives..., right.drives...),
        (left.constraints..., right.constraints...),
        (left.modifiers..., right.modifiers...),
        (left.mechanics..., right.mechanics...),
        (left.lifecycle..., right.lifecycle...),
        (left.schemas..., right.schemas...),
        (left.properties..., right.properties...))
end

function _property_prefix(identity::SemanticName)
    parts = (identity.namespace.parts..., identity.name)
    return join(String.(parts), "__")
end

function _property_bindings(component, target_key::Symbol, strength_key::Symbol)
    T = typeof(first(component.bindings).value.target)
    targets = Tuple(Binding{CellType, T}(
        entry.key, entry.value.target) for entry in component.bindings)
    strengths = Tuple(Binding{CellType, T}(
        entry.key, entry.value.strength) for entry in component.bindings)
    return (
        CellPropertyBinding(target_key, BindingTable{CellType, T}(targets)),
        CellPropertyBinding(strength_key, BindingTable{CellType, T}(strengths)))
end

function _lower_component(property::CellProperty, context::_LoweringContext)
    key = Symbol(_property_prefix(property.name))
    requester = CorePotts.ComponentIdentity(key, v"1.0.0", :property)
    descriptor = CorePotts.PropertyDescriptor(key, typeof(property.initial),
        CorePotts.ConstantInitializer(property.initial);
        mutability = property.mutability, division = property.division,
        transition = property.transition, retirement = property.retirement,
        kind = CorePotts.BiologicalProperty, requester)
    entries = Tuple(Binding{CellType, typeof(property.initial)}(
        cell_type, property.initial) for cell_type in property.cell_types)
    values = BindingTable{CellType, typeof(property.initial)}(entries)
    binding = CellPropertyBinding(key, values)
    return _LoweredComponents((), (), (), (), (), (),
        (CorePotts.PropertySchema(descriptor),), (binding,))
end

function _lower_component(component::VolumeConstraint, context::_LoweringContext{T}) where {T}
    prefix = _property_prefix(component.name)
    target_key = Symbol(prefix, "__target")
    strength_key = Symbol(prefix, "__strength")
    core = CorePotts.QuadraticVolumeHamiltonian(
        target = target_key, strength = strength_key, number_type = T)
    return _LoweredComponents((core,), (), (), (), (), (),
        (CorePotts.required_properties(core),),
        _property_bindings(component, target_key, strength_key))
end

function _lower_component(component::FluctuatingVolumeConstraint,
        context::_LoweringContext{T}) where {T}
    prefix = _property_prefix(component.name)
    target_key = Symbol(prefix, "__target")
    strength_key = Symbol(prefix, "__strength")
    state_key = Symbol(prefix, "__pressure")
    core = CorePotts.FluctuatingVolumePressure(
        target = target_key, strength = strength_key, state = state_key,
        eta = component.eta, noise = component.noise,
        initialization = component.initialization, division = component.division,
        number_type = T)
    return _LoweredComponents((), (), (), (), (core,), (),
        (CorePotts.required_properties(core),),
        _property_bindings(component, target_key, strength_key))
end

function _biological_index(context::_LoweringContext, value::AbstractBiologicalType)
    index = findfirst(==(value), (context.cell_types..., context.media...))
    index === nothing && throw(ArgumentError("undeclared biological identity $value"))
    return index
end

function _pairwise_value(law::PairwiseLaw{T}, left, right) where {T}
    key = PairIdentity(left, right; symmetric = law.symmetric)
    value = get(law.values, key, law.default)
    value === nothing && throw(ArgumentError("missing pairwise value for $key"))
    return value::T
end

function _lower_component(component::Adhesion{T}, context::_LoweringContext{T}) where {T}
    biological_types = (context.cell_types..., context.media...)
    count = length(biological_types)
    interactions = Matrix{T}(undef, count, count)
    for row in 1:count, column in 1:count
        interactions[row, column] = _pairwise_value(
            component.law, biological_types[row], biological_types[column])
    end
    medium_types = CorePotts.MediumTypeTable(Tuple(
        CorePotts.MediumID(index) => CorePotts.CellTypeID(length(context.cell_types) + index)
        for index in eachindex(context.media)))
    core = CorePotts.UnorderedContactHamiltonian(
        interactions, medium_types, context.contact_relation)
    return _LoweredComponents((core,), (), (), (), (), (),
        (CorePotts.required_properties(core),), ())
end

_lower_component(::PrescribedField, context::_LoweringContext) = _LoweredComponents()

function _prescribed_field(context::_LoweringContext, identity::SemanticName)
    index = findfirst(value -> value isa PrescribedField &&
        semantic_identity(value) == identity, context.declarations)
    index === nothing && throw(ArgumentError("missing prescribed field $identity"))
    return context.declarations[index]
end

function _lower_component(component::Chemotaxis{T},
        context::_LoweringContext{T}) where {T}
    field = _field_as_core(_prescribed_field(context, component.field))
    key = Symbol(_property_prefix(component.name), "__sensitivity")
    core_medium_values = Tuple(CorePotts.MediumID(index) => zero(T)
        for index in eachindex(context.media))
    coupling = CorePotts.OwnerScalarCoupling(key, core_medium_values...;
        number_type = T)
    drive = CorePotts.ChemotaxisDrive(
        field, coupling, component.response, component.mode)
    requester = CorePotts.component_identity(drive)
    descriptor = CorePotts.PropertyDescriptor(key, T,
        CorePotts.ConstantInitializer(zero(T));
        mutability = CorePotts.MutableProperty,
        division = CorePotts.CloneOnDivision(),
        transition = CorePotts.PreserveOnTransition(),
        retirement = CorePotts.ResetOnRetirement(),
        kind = CorePotts.BiologicalProperty, requester)
    values = CellPropertyBinding(key, component.sensitivity)
    return _LoweredComponents((), (drive,), (), (), (), (),
        (CorePotts.PropertySchema(descriptor),), (values,))
end

_lower_component(component::NamedCoreComponent, context::_LoweringContext) =
    _lower_component(component.component, context)

function _prepare_direct_component(component)
    _validate_direct_component(component)
    CorePotts.validate_proposal_component(component)
    return CorePotts.required_properties(component)
end


_validate_direct_component(component::CorePotts.AbstractEnergy) =
    CorePotts.validate_energy_component(component)
_validate_direct_component(component::CorePotts.AbstractDrive) =
    CorePotts.validate_drive_component(component)
_validate_direct_component(component::CorePotts.AbstractHardConstraint) =
    CorePotts.validate_constraint_component(component)
_validate_direct_component(component::CorePotts.AbstractMechanicalComponent) =
    CorePotts.validate_mechanical_component(component)
_validate_direct_component(component::CorePotts.AbstractKineticModifier) = component

function _lower_component(component::CorePotts.AbstractEnergy, context::_LoweringContext)
    schema = _prepare_direct_component(component)
    return _LoweredComponents((component,), (), (), (), (), (), (schema,), ())
end
function _lower_component(component::CorePotts.AbstractDrive, context::_LoweringContext)
    schema = _prepare_direct_component(component)
    return _LoweredComponents((), (component,), (), (), (), (), (schema,), ())
end
function _lower_component(component::CorePotts.AbstractHardConstraint,
        context::_LoweringContext)
    schema = _prepare_direct_component(component)
    return _LoweredComponents((), (), (component,), (), (), (), (schema,), ())
end
function _lower_component(component::CorePotts.AbstractKineticModifier,
        context::_LoweringContext)
    schema = _prepare_direct_component(component)
    return _LoweredComponents((), (), (), (component,), (), (), (schema,), ())
end
function _lower_component(component::CorePotts.AbstractMechanicalComponent,
        context::_LoweringContext)
    schema = _prepare_direct_component(component)
    return _LoweredComponents((), (), (), (), (component,), (), (schema,), ())
end

function _lower_component(rule::PropertyUpdate, context::_LoweringContext{T}) where {T}
    type_ids = Tuple(CorePotts.CellTypeID(
        _biological_index(context, cell_type)) for cell_type in rule.cell_types)
    trigger = CorePotts.AllLifecycleTriggers(
        CorePotts.CellTypeIn(type_ids...), rule.trigger)
    event_id = 1 + _semantic_rng_code(rule.name, :event, UInt16(0x0ffe))
    key = rule.role === :value ? Symbol(_property_prefix(rule.source)) :
        Symbol(_property_prefix(rule.source), "__", rule.role)
    event = CorePotts.LifecycleEvent(
        CorePotts.ActiveCellsTarget(), rule.schedule, trigger,
        CorePotts.AddCellProperty(key, T(rule.amount)); semantic_id = event_id)
    return _LoweredComponents((), (), (), (), (), (event,), (), ())
end

function _lower_components(components::Tuple, context::_LoweringContext)
    isempty(components) && return _LoweredComponents()
    return _merge_lowered(_lower_component(first(components), context),
        _lower_components(Base.tail(components), context))
end

function _id_table(values::Tuple, constructor)
    entries = Tuple(Binding(value, constructor(index)) for (index, value) in enumerate(values))
    K = eltype(values)
    V = typeof(constructor(1))
    return BindingTable{K, V}(entries)
end

function _component_dimension_diagnostics(normalized::NormalizedModel,
        dimensions::Integer)
    diagnostics = ()
    for component in normalized.components
        report = _declaration_report(component)
        dimensions in report.capabilities.dimensions && continue
        diagnostics = (diagnostics..., Diagnostic(
            :error, :unsupported_component_dimension,
            "a model component does not support the selected lattice dimensionality";
            stage = :problem, identity = report.identity,
            related = (dimensions, report.capabilities.dimensions),
            correction = "select a supported dimension or replace the component"),)
    end
    return diagnostics
end

function _check_component_dimensions(normalized::NormalizedModel,
        dimensions::Integer)
    diagnostics = _component_dimension_diagnostics(normalized, dimensions)
    isempty(diagnostics) || throw(ArgumentError(
        first(diagnostics).message * ": " * string(first(diagnostics).identity)))
    return normalized
end

"""
    lower(model; dimensions, spacing)

Normalize and lower a Level 2 model into public CorePotts scientific values. This operation is
host-only and performs no backend allocation or kernel compilation.
"""
function lower(model::PottsModel; dimensions::Integer,
        spacing = ntuple(_ -> one(CorePotts.real_type(model.numerics)), dimensions))
    dimensions in (2, 3) || throw(ArgumentError("CPM models support two or three dimensions"))
    length(spacing) == dimensions || throw(ArgumentError(
        "spacing must have one value per lattice dimension"))
    normalized = _check_component_dimensions(normalize(model), dimensions)
    T = CorePotts.real_type(normalized.numerics)
    typed_spacing = ntuple(index -> T(spacing[index]), dimensions)
    proposal_relation = CorePotts.first_shell_relation(
        CorePotts.ProposalRole(), Val(dimensions); spacing = typed_spacing)
    contact_relation = CorePotts.first_shell_relation(
        CorePotts.ContactRole(), Val(dimensions); spacing = typed_spacing)
    surface_relation = CorePotts.first_shell_relation(
        CorePotts.SurfaceRole(), Val(dimensions); spacing = typed_spacing)
    context = _LoweringContext{T, typeof(normalized.cell_types),
        typeof(normalized.media), typeof(normalized.components), typeof(contact_relation)}(
        normalized.cell_types, normalized.media, normalized.components, contact_relation)
    lowered = _lower_components(normalized.components, context)
    components = CorePotts.ScientificComponentSet(
        energies = lowered.energies, drives = lowered.drives,
        constraints = lowered.constraints, kinetic_modifiers = lowered.modifiers,
        mechanics = lowered.mechanics)
    tracker = CorePotts.BoundaryMeasureTracker(
        CorePotts.BoundaryEdgeCount(), surface_relation)
    core_model = CorePotts.PottsModel(proposal_relation, tracker; components,
        lifecycle_events = lowered.lifecycle)
    schema = CorePotts.merge_property_schemas(lowered.schemas...)
    cell_type_ids = _id_table(normalized.cell_types, CorePotts.CellTypeID)
    medium_ids = _id_table(normalized.media, CorePotts.MediumID)
    return LoweredModel(normalized, core_model, schema, lowered.properties,
        (normalized.cell_types..., normalized.media...), cell_type_ids, medium_ids)
end

function _property_overrides(lowered::LoweredModel, cell_type::CellType,
        explicit::NamedTuple)
    keys = ()
    values = ()
    for binding in lowered.property_bindings
        haskey(binding.values, cell_type) || continue
        keys = (keys..., binding.key)
        values = (values..., binding.values[cell_type])
    end
    explicit_keys = Tuple(propertynames(explicit))
    overlap = Tuple(key for key in keys if key in explicit_keys)
    isempty(overlap) || throw(ArgumentError(
        "initial properties conflict with model bindings for $(join(overlap, ", "))"))
    all_keys = (keys..., explicit_keys...)
    all_values = (values..., Tuple(explicit)...)
    return NamedTuple{all_keys}(all_values)
end

function _lower_layout(lowered::LoweredModel, layout::CellLayout, dimensions::Integer)
    haskey(lowered.cell_type_ids, layout.cell_type) || throw(ArgumentError(
        "initial layout references undeclared cell type $(layout.cell_type)"))
    ndims(layout.mask) == dimensions || throw(ArgumentError(
        "initial cell layout dimensionality does not match the problem"))
    type_id = lowered.cell_type_ids[layout.cell_type]
    geometry = CorePotts.InitialCellLayout(layout.provisional_id, type_id,
        layout.mask; priority = layout.priority)
    properties = CorePotts.InitialCellProperties(layout.provisional_id, type_id,
        _property_overrides(lowered, layout.cell_type, layout.properties);
        dimensions)
    return (geometry, properties)
end

function _lower_layout(lowered::LoweredModel, layout::MediumLayout, dimensions::Integer)
    haskey(lowered.medium_ids, layout.medium) || throw(ArgumentError(
        "initial layout references undeclared medium $(layout.medium)"))
    ndims(layout.mask) == dimensions || throw(ArgumentError(
        "initial medium layout dimensionality does not match the problem"))
    return (CorePotts.InitialMediumLayout(lowered.medium_ids[layout.medium],
        layout.mask; priority = layout.priority),)
end

function _lower_layout_tuple(lowered::LoweredModel, layouts::Tuple, dimensions::Integer)
    isempty(layouts) && return ()
    return (_lower_layout(lowered, first(layouts), dimensions)...,
        _lower_layout_tuple(lowered, Base.tail(layouts), dimensions)...)
end

function _layout_diagnostics(layout::CellLayout, shape::Tuple,
        cells::Tuple, media::Tuple)
    diagnostics = ()
    layout.cell_type in cells || (diagnostics = (diagnostics..., Diagnostic(
        :error, :undeclared_layout_cell_type,
        "initial cell layout references an undeclared cell type";
        stage = :problem, identity = semantic_identity(layout.cell_type),
        correction = "declare the cell type or correct the layout"),))
    size(layout.mask) == shape || (diagnostics = (diagnostics..., Diagnostic(
        :error, :layout_shape_mismatch,
        "initial cell layout mask shape does not match the problem lattice";
        stage = :problem, identity = semantic_identity(layout.cell_type),
        related = (size(layout.mask), shape),
        correction = "provide a Boolean mask with exactly the problem shape"),))
    return diagnostics
end

function _layout_diagnostics(layout::MediumLayout, shape::Tuple,
        cells::Tuple, media::Tuple)
    diagnostics = ()
    layout.medium in media || (diagnostics = (diagnostics..., Diagnostic(
        :error, :undeclared_layout_medium,
        "initial medium layout references an undeclared medium";
        stage = :problem, identity = semantic_identity(layout.medium),
        correction = "declare the medium or correct the layout"),))
    size(layout.mask) == shape || (diagnostics = (diagnostics..., Diagnostic(
        :error, :layout_shape_mismatch,
        "initial medium layout mask shape does not match the problem lattice";
        stage = :problem, identity = semantic_identity(layout.medium),
        related = (size(layout.mask), shape),
        correction = "provide a Boolean mask with exactly the problem shape"),))
    return diagnostics
end

_layout_diagnostics(layout, shape::Tuple, cells::Tuple, media::Tuple) = (Diagnostic(
    :error, :unsupported_initial_layout,
    "initial layouts must implement the PottsToolkit CellLayout or MediumLayout protocol";
    stage = :problem,
    correction = "use CellLayout/MediumLayout or add a public lowering method"),)

_cell_layout_id(layout) = nothing
_cell_layout_id(layout::CellLayout) = layout.provisional_id

"""Validate model-instance facts without compiling a backend or allocating device storage."""
function validate_problem(model::PottsModel, shape::Tuple, layouts...;
        capacity::Integer, tspan = (0, 1), seed::Integer = 0,
        spacing = ntuple(_ -> one(CorePotts.real_type(model.numerics)), length(shape)))
    model_report = validate(model)
    diagnostics = model_report.diagnostics
    dimensions = length(shape)
    dimensions in (2, 3) || (diagnostics = (diagnostics..., Diagnostic(
        :error, :unsupported_dimension,
        "CPM problems support exactly two or three lattice dimensions";
        stage = :problem, related = (dimensions,),
        correction = "use a 2D or 3D lattice shape"),))
    all(value -> value isa Integer && value > 0, shape) ||
        (diagnostics = (diagnostics..., Diagnostic(:error, :invalid_lattice_shape,
            "every lattice extent must be a positive integer";
            stage = :problem, related = shape,
            correction = "replace zero, negative, or non-integer extents"),))
    capacity > 0 || (diagnostics = (diagnostics..., Diagnostic(
        :error, :invalid_cell_capacity, "cell capacity must be positive";
        stage = :problem, related = (capacity,),
        correction = "choose a positive fixed maximum cell count"),))
    0 <= seed <= typemax(UInt64) || (diagnostics = (diagnostics..., Diagnostic(
        :error, :invalid_seed, "problem seed must fit UInt64";
        stage = :problem, related = (seed,),
        correction = "choose an integer seed between 0 and typemax(UInt64)"),))
    tspan_values = tspan isa Tuple ? tspan : (tspan,)
    valid_tspan = length(tspan_values) == 2 &&
        all(value -> value isa Integer, tspan_values) &&
        0 <= tspan_values[1] <= tspan_values[2] <= typemax(Int)
    valid_tspan || (diagnostics = (diagnostics..., Diagnostic(
        :error, :invalid_mcs_tspan,
        "problem tspan must be two ordered non-negative integer MCS values";
        stage = :problem, related = tspan_values,
        correction = "use `(start_mcs, end_mcs)` with integer `0 ≤ start ≤ end`"),))
    spacing_values = spacing isa Tuple ? spacing : (spacing,)
    length(spacing_values) == dimensions && all(value -> value isa Real &&
        isfinite(value) && value > 0, spacing_values) ||
        (diagnostics = (diagnostics..., Diagnostic(:error, :invalid_spacing,
            "spacing must contain one positive finite value per dimension";
            stage = :problem, related = spacing_values,
            correction = "provide positive finite lattice spacing for every axis"),))

    if isvalid(model_report)
        normalized = normalize(model)
        dimensions in (2, 3) && (diagnostics = (diagnostics...,
            _component_dimension_diagnostics(normalized, dimensions)...))
        for layout in layouts
            diagnostics = (diagnostics..., _layout_diagnostics(
                layout, shape, normalized.cell_types, normalized.media)...)
        end
    end
    provisional_ids = Tuple(filter(value -> !isnothing(value),
        map(_cell_layout_id, layouts)))
    length(unique(provisional_ids)) == length(provisional_ids) ||
        (diagnostics = (diagnostics..., Diagnostic(
            :error, :duplicate_provisional_cell_id,
            "initial cell layouts must use distinct provisional identities";
            stage = :problem, related = provisional_ids,
            correction = "assign one unique positive provisional ID per initial cell"),))
    length(provisional_ids) <= capacity || (diagnostics = (diagnostics..., Diagnostic(
        :error, :initial_capacity_exceeded,
        "the number of initial cells exceeds fixed cell capacity";
        stage = :problem, related = (length(provisional_ids), capacity),
        correction = "increase capacity or reduce the initial cell count"),))
    return ValidationReport(diagnostics)
end

"""
    problem(model, shape, layouts...; capacity, tspan, seed, ...)

Construct the single public CorePotts/SciML `PottsProblem` from a Level 2 model and typed initial
layouts. No PottsToolkit runtime wrapper is introduced.
"""
function problem(model::PottsModel, shape::NTuple{N, <:Integer}, layouts...;
        capacity::Integer, tspan = (0, 1), seed::Integer = 0,
        spacing = ntuple(_ -> one(CorePotts.real_type(model.numerics)), Val(N)),
        boundaries = nothing, obstacles = (),
        overlap_policy::CorePotts.AbstractInitialOverlapPolicy =
            CorePotts.RejectInitialOverlap()) where {N}
    report = validate_problem(model, shape, layouts...;
        capacity, tspan, seed, spacing)
    isvalid(report) || throw(ProblemValidationError(report))
    lowered = lower(model; dimensions = N, spacing)
    realized_layouts = _lower_layout_tuple(lowered, Tuple(layouts), N)
    medium_ids = Tuple(entry.value for entry in lowered.medium_ids)
    initialized = CorePotts.finalize_initial_state(shape, realized_layouts...;
        capacity = CorePotts.CellCapacity(capacity), medium_domains = medium_ids,
        property_schema = lowered.property_schema, overlap_policy, seed)
    geometry = boundaries === nothing ?
        CorePotts.CartesianDomain(shape; spacing, obstacles) :
        CorePotts.CartesianDomain(shape; spacing, boundaries, obstacles)
    return CorePotts.PottsProblem(lowered.core_model, CorePotts.logical_state(initialized),
        geometry, tspan; capacity = CorePotts.CellCapacity(capacity), seed)
end

"""Return CorePotts's public, allocation-free host compatibility preflight report."""
backend_report(problem::CorePotts.PottsProblem, algorithm, backend) =
    CorePotts.compatibility_report(problem, algorithm, backend)

backend_report(problem::CorePotts.PottsProblem, algorithm) =
    CorePotts.compatibility_report(problem, algorithm)
