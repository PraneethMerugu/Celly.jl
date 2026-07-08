using Test
using CorePotts, SciMLBase

@testset "HSTLengthPenalty Initial State and SDE" begin
    # 100x100 grid, cell size 20x40
    W, H = 100, 100
    grid = zeros(UInt32, W, H)

    # Create a 20x40 rectangle cell in the middle
    grid[41:60, 31:70] .= 1

    # Inertia tensor for continuous 20x40 rectangle centered at 0:
    # Ixx = integral x^2 dxdy / V = w^2 / 12 = 20^2 / 12 = 33.33
    # Iyy = integral y^2 dxdy / V = h^2 / 12 = 40^2 / 12 = 133.33
    # lambda_max = 133.33. L = sqrt(133.33) = 11.547
    expected_L = sqrt((40^2 - 1) / 12) # For discrete, Var(1..40) = (40^2 - 1)/12 = 133.25
    expected_L_approx = sqrt(133.25) # ~ 11.543

    N_cells = 1
    custom_fields = ()

    cell_data = CorePotts.build_cell_data(grid, 1)
    cell_data.volumes[1] = 20 * 40
    cell_data.cell_types[1] = 1

    # Target length much larger than current
    cell_data.target_lengths[1] = 30.0f0

    lambdas = Float32[0.0f0, 50.0f0]
    eta = 0.1f0

    penalty = HSTLengthPenalty{Rigid}(lambdas, eta)

    u0 = PottsState(grid, cell_data)
    p_sys = PottsParameters(MooreTopology{2}(), (penalty,), (VolumeTracker(),))
    cache = PottsCache(u0, p_sys.topology)
    CorePotts.sync_cell_data!(u0, p_sys, cache, 1)

    # Run auxiliary field update (this should populate current_lengths, major_axis, length_pressures)
    CorePotts.update_step_auxiliary!(penalty, u0, p_sys, cache, 1.0f0, 0.01f0)

    # Check that lengths were calculated correctly
    L_calc = cell_data.current_lengths[1]
    @test isapprox(L_calc, expected_L_approx, atol = 0.1)

    # Major axis should be along Y (0, 1) or (0, -1)
    vx = cell_data.major_axis_x[1]
    vy = cell_data.major_axis_y[1]
    @test abs(vx) < 0.01
    @test abs(vy) > 0.99

    # Target is 30, current is ~11.5. L < Target.
    # length_pressure should be driven negatively because we want L to increase.
    # mean_lp = 2.0 * lam * (L - target) = 2.0 * 50.0 * (11.5 - 30.0) < 0
    lp = cell_data.length_pressures[1]
    @test lp < 0.0f0

    # Test evaluate_penalty. Adding a pixel at (20, 71) increases length.
    ctx = (; grid = grid, grid_dims = (W, H), topology = MooreTopology{2}(),
        cell_data = cell_data, trackers = (), idx = UInt32(1),
        src = UInt32(0), tgt = UInt32(1), T = 1.0f0, spatial_coords = (20, 71),
        neighbors = ntuple(i->0, 8), n_src = Int32(0), n_tgt = Int32(0))
    dH_add = evaluate_penalty(penalty, ctx)

    # Since lp < 0 and dL > 0, dH = lp * dL should be < 0
    @test dH_add < 0.0f0
end

@testset "HSTLengthPenalty Periodic Boundary Wrap" begin
    W, H = 100, 100
    grid = zeros(UInt32, W, H)

    # 20x40 rectangle exactly centered on the x boundary
    for x in 91:100
        grid[x, 31:70] .= 1
    end
    for x in 1:10
        grid[x, 31:70] .= 1
    end

    cell_data = CorePotts.build_cell_data(grid, 1)
    cell_data.volumes[1] = 20 * 40
    cell_data.cell_types[1] = 1
    cell_data.target_lengths[1] = 30.0f0

    penalty = HSTLengthPenalty{Rigid}(Float32[0.0f0, 50.0f0], 0.1f0)
    u0 = PottsState(grid, cell_data)
    p_sys = PottsParameters(MooreTopology{2}(), (penalty,), (VolumeTracker(),))
    cache = PottsCache(u0, p_sys.topology)
    CorePotts.sync_cell_data!(u0, p_sys, cache, 1)
    CorePotts.update_step_auxiliary!(penalty, u0, p_sys, cache, 1.0f0, 0.01f0)

    expected_L_approx = sqrt((40^2 - 1) / 12)
    @test isapprox(cell_data.current_lengths[1], expected_L_approx, atol = 0.1)

    # The circular COM should wrap perfectly to x=0.5. Depending on atan2 logic,
    # it might be 0.5 or 100.5
    ax = cell_data.anchor_x[1]
    @test isapprox(ax, 0.5f0, atol = 1.0) || isapprox(ax, 100.5f0, atol = 1.0)
end

@testset "HSTLengthPenalty Thermodynamic Elongation" begin
    W, H = 100, 100
    grid = zeros(UInt32, W, H)

    # Start with a 28x32 rectangle
    grid[37:64, 35:66] .= 1

    cell_data = CorePotts.build_cell_data(grid, 1)
    cell_data.volumes[1] = 896
    cell_data.target_volumes[1] = 896
    cell_data.cell_types[1] = 1

    # Initial length is sqrt(30^2/12) = 8.66. We target a much longer length
    cell_data.target_lengths[1] = 18.0f0

    vol_tracker = VolumeTracker()
    vol_pen = HSTVolumePenalty{Rigid}(Float32[0.0f0, 50.0f0])
    len_pen = HSTLengthPenalty{Rigid}(Float32[0.0f0, 40.0f0], 0.1f0)

    u0 = PottsState(grid, cell_data)
    p_sys = PottsParameters(MooreTopology{2}(), (vol_pen, len_pen), (VolumeTracker(),))
    problem = PottsProblem(u0, (0, 500), p_sys)
    integrator = init(problem, ParallelMetropolis(; T = 1.0f0, active_fraction = 0.1f0, sweeps_per_step = 1))

    CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 1)

    solve!(integrator)
    CorePotts.sync_cell_data!(integrator.u, integrator.p, integrator.cache, 1)

    CorePotts.update_step_auxiliary!(
        len_pen, integrator.u, integrator.p, integrator.cache, 10.0f0, 0.1f0)
    final_L = cell_data.current_lengths[1]

    initial_L = sqrt((32^2 - 1) / 12)
    @test final_L > initial_L + 1.0f0
    # Volume should remain mostly conserved
    @test abs(cell_data.volumes[1] - 896) < 150
end
