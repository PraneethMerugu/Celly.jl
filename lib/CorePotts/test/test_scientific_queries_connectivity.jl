@testset "explicit spatial query aggregations" begin
    identity = ComponentIdentity(:query_test, v"1.0.0", :test)
    schema = PropertySchema(PropertyDescriptor(:signal, Float32,
        ConstantInitializer(0.0f0); requester = identity))
    owners = fill(MediumOwner(1), 5, 5)
    owners[2, 2] = owners[2, 3] = owners[3, 3] = CellOwner(1)
    owners[3, 2] = owners[4, 2] = CellOwner(2)
    owners[3, 4] = owners[4, 4] = CellOwner(3)
    state = LogicalPottsState(owners, CellCapacity(3);
        cell_types = Dict(CellID(1) => CellTypeID(2), CellID(2) => CellTypeID(2),
            CellID(3) => CellTypeID(3)),
        medium_domains = [MediumID(1)], property_schema = schema)
    property_values(state, :signal) .= Float32[10, 20, 30]
    boundaries = (AxisBoundary(ClosedBoundary()), AxisBoundary(ClosedBoundary()))
    domain = CartesianDomain((5, 5); boundaries)
    relation = first_shell_relation(SpatialQueryRole(), Val(2))
    types = MediumTypeTable(MediumID(1) => CellTypeID(1))

    @test contact_edge_count(state, domain, relation, CellOwner(1),
        CellIdentityFilter(CellID(2)), types) == 2
    @test contact_edge_count(state, domain, relation, CellOwner(1),
        MediumDomainFilter(MediumID(1)), types) == 5
    @test contact_measure(state, domain, relation, CellOwner(1),
        CellIdentityFilter(CellID(2)), types) == 2.0
    @test boundary_site_count(state, domain, relation, CellOwner(1),
        CellIdentityFilter(CellID(2)), types) == 2
    args = (domain, relation, CellOwner(1), AnyFiniteCell(), types)
    @test neighbor_cells(state, args...) == CellID[CellID(2), CellID(3)]
    @test neighbor_cell_count(state, args...) == 2
    @test neighbor_property_sum(state, CellPropertyRef(:signal), args...) == 50.0f0
    @test neighbor_property_mean(state, CellPropertyRef(:signal), args...) == 25.0f0
    @test neighbor_property_mean(state, CellPropertyRef(:signal), domain, relation,
        CellOwner(1), CellTypeFilter(CellTypeID(99)), types) === missing

    @test global_interface_measure(state, domain, relation,
        CellIdentityFilter(CellID(1)), CellIdentityFilter(CellID(2)), types) == 2
    @test global_interface_measure(state, domain, relation,
        CellIdentityFilter(CellID(1)), MediumDomainFilter(MediumID(1)), types) == 5
    @test global_interface_measure(state, domain, relation,
        CellIdentityFilter(CellID(1)), CellIdentityFilter(CellID(2)), types,
        WeightedBoundaryCount()) == 2.0

    compiled_state = compile_state(state)
    compiled_domain = compile_domain(domain)
    @test contact_edge_count(compiled_state, compiled_domain, relation, CellOwner(1),
        CellIdentityFilter(CellID(2)), types) == 2

    surface_relation = first_shell_relation(SurfaceRole(), Val(2))
    scientific = compile_scientific_state(
        state, domain, BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation))
    runtime = scientific_execution(scientific)
    workspace = DistinctNeighborWorkspace(3)
    @test workspace_bytes(workspace) == 28
    @test validate_workspace(workspace, runtime) === workspace
    @test_throws ArgumentError validate_workspace(DistinctNeighborWorkspace(2), runtime)
    @test_throws ArgumentError neighbor_cells!(
        workspace, runtime, runtime.domain, relation,
        CellOwner(1), AnyFiniteCell(), types, UInt32(0))
    count = neighbor_cells!(workspace, runtime, runtime.domain, relation,
        CellOwner(1), AnyFiniteCell(), types, UInt32(1))
    @test count == 2
    @test workspace.ids[1:count] == UInt32[2, 3]
    @test neighbor_property_sum(runtime, CellPropertyRef(:signal), workspace,
        runtime.domain, relation, CellOwner(1), AnyFiniteCell(), types, UInt32(2)) == 50.0f0
    @test neighbor_property_mean(runtime, CellPropertyRef(:signal), workspace,
        runtime.domain, relation, CellOwner(1), AnyFiniteCell(), types, UInt32(3);
        empty = -1.0f0) == 25.0f0
end

@testset "exact optional connectivity constraint" begin
    for dims in ((5, 5), (5, 5, 5))
        N = length(dims)
        owners = fill(MediumOwner(1), dims)
        center = ntuple(_ -> 3, N)
        left = Base.setindex(center, 2, 1)
        right = Base.setindex(center, 4, 1)
        owners[left...] = owners[center...] = owners[right...] = CellOwner(1)
        state = LogicalPottsState(owners, CellCapacity(1);
            cell_types = Dict(CellID(1) => CellTypeID(1)),
            medium_domains = [MediumID(1)])
        boundaries = ntuple(_ -> AxisBoundary(ClosedBoundary()), N)
        domain = CartesianDomain(dims; boundaries)
        relation = first_shell_relation(ConnectivityRole(), Val(N))
        constraint = PreserveConnectedCells(relation)
        linear = LinearIndices(dims)
        bridge = CopyProposal(linear[center...], linear[Base.setindex(center, 4, 2)...],
            CellOwner(1), MediumOwner(1))
        endpoint = CopyProposal(linear[left...], linear[Base.setindex(left, 1, 1)...],
            CellOwner(1), MediumOwner(1))
        @test !is_allowed(constraint, bridge, state, domain)
        @test is_allowed(constraint, endpoint, state, domain)
        @test !is_allowed(constraint, bridge, compile_state(state), compile_domain(domain))

        surface_relation = first_shell_relation(SurfaceRole(), Val(N))
        scientific = compile_scientific_state(
            state, domain, BoundaryMeasureTracker(BoundaryEdgeCount(), surface_relation))
        runtime = scientific_execution(scientific)
        workspace = ConnectivityWorkspace(prod(dims))
        @test workspace_bytes(workspace) == 8 * prod(dims)
        @test validate_workspace(workspace, runtime) === workspace
        @test_throws ArgumentError validate_workspace(
            ConnectivityWorkspace(prod(dims) - 1), runtime)
        @test !is_allowed(constraint, bridge, runtime, workspace, UInt32(1))
        @test is_allowed(constraint, endpoint, runtime, workspace, UInt32(2))
    end
end
