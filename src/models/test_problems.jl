module TestProblems

using ..PottsToolkit
using CorePotts
using Random

export cell_sorting_problem, young_laplace_droplet, young_laplace_droplet_3d, ising_model, single_cell_fluctuation

"""
    cell_sorting_problem(; kwargs...)

Returns a canonical PottsProblem for Steinberg differential adhesion hypothesis cell sorting.
"""
function cell_sorting_problem(;
        grid_size = (50, 50),
        cells_per_type = 25,
        target_volume = 25,
        volume_lambda = 5.0f0,
        J_AA = 2.0f0,
        J_BB = 2.0f0,
        J_AB = 15.0f0,
        J_Medium = 10.0f0,
        tspan = (0, 20),
        topology = MooreTopology{2}()
)
    A = CellType(:A)
    B = CellType(:B)
    Medium = CellType(:Medium, is_background = true)

    sys = PottsSystem([A, B, Medium],
        [
            HSTVolumeComponent(A => (λ = volume_lambda, target = target_volume),
                B => (λ = volume_lambda, target = target_volume)),
            AdhesionComponent(
                (A, A) => J_AA, (B, B) => J_BB, (A, B) => J_AB,
                (A, Medium) => J_Medium, (B, Medium) => J_Medium
            )
        ])
    layout = RandomLayout(Dict(A => cells_per_type, B => cells_per_type))
    return PottsProblem(sys, layout, grid_size; tspan = tspan, topology = topology)
end

"""
    young_laplace_droplet(; kwargs...)

Returns a canonical PottsProblem for verifying the Young-Laplace equation for a single droplet.
"""
function young_laplace_droplet(;
        grid_size = (256, 256),
        target_volume = 5026, # R ≈ 40
        volume_lambda = 1.0f0,
        volume_eta = 0.1f0,
        gamma = 10.0f0,
        tspan = (0, 70),
        topology = MooreTopology{2}(),
        isotropic = false
)
    Cell = CellType(:Cell)
    Medium = CellType(:Medium, is_background = true)

    sys = PottsSystem([Cell, Medium],
        [
            HSTVolumeComponent(Cell => (λ = volume_lambda, target = target_volume); eta = volume_eta),
            AdhesionComponent(
                (Cell, Cell) => 0.0f0,
                (Cell, Medium) => gamma,
                (Medium, Medium) => 0.0f0;
                isotropic = isotropic
            )
        ])

    center = (grid_size[1] ÷ 2, grid_size[2] ÷ 2)
    radius = round(Int, sqrt(target_volume / pi))
    layout = HypersphereLayout(Cell, center, radius)

    return PottsProblem(sys, layout, grid_size; tspan = tspan, topology = topology)
end

"""
    young_laplace_droplet_3d(; kwargs...)

Returns a canonical PottsProblem for verifying the Young-Laplace equation for a single 3D droplet.
"""
function young_laplace_droplet_3d(;
        grid_size = (64, 64, 64),
        target_volume = 33510, # R ≈ 20
        volume_lambda = 1.0f0,
        volume_eta = 0.1f0,
        gamma = 10.0f0,
        tspan = (0, 70),
        topology = MooreTopology{3}(),
        isotropic = false
)
    Cell = CellType(:Cell)
    Medium = CellType(:Medium, is_background = true)

    sys = PottsSystem([Cell, Medium],
        [
            HSTVolumeComponent(Cell => (λ = volume_lambda, target = target_volume); eta = volume_eta),
            AdhesionComponent(
                (Cell, Cell) => 0.0f0,
                (Cell, Medium) => gamma,
                (Medium, Medium) => 0.0f0;
                isotropic = isotropic
            )
        ])

    center = (grid_size[1] ÷ 2, grid_size[2] ÷ 2, grid_size[3] ÷ 2)
    radius = round(Int, cbrt(target_volume / (4/3 * pi)))
    layout = HypersphereLayout(Cell, center, radius)

    return PottsProblem(sys, layout, grid_size; tspan = tspan, topology = topology)
end

"""
    single_cell_fluctuation(; kwargs...)

Returns a canonical PottsProblem for measuring thermodynamic volume fluctuations.
"""
function single_cell_fluctuation(;
        grid_size = (50, 50),
        target_volume = 100,
        volume_lambda = 5.0f0,
        volume_eta = 1.0f0,
        tspan = (0, 11_000),
        topology = MooreTopology{2}()
)
    Cell = CellType(:Cell)
    Medium = CellType(:Medium, is_background = true)

    sys = PottsSystem([Cell, Medium],
        [
            HSTVolumeComponent(Cell => (λ = volume_lambda, target = target_volume); eta = volume_eta)
        ])

    center = (grid_size[1] ÷ 2, grid_size[2] ÷ 2)
    radius = round(Int, sqrt(target_volume / pi))
    layout = HypersphereLayout(Cell, center, radius)

    return PottsProblem(sys, layout, grid_size; tspan = tspan, topology = topology)
end

"""
    ising_model(; kwargs...)

Returns a canonical PottsProblem for testing 2D Ising Model critical phase transitions.
"""
function ising_model(;
        grid_size = (50, 50),
        J = 1.0f0,
        tspan = (0, 6000),
        topology = VonNeumannTopology{2}()
)
    Up = CellType(:Up)
    Down = CellType(:Down)
    Medium = CellType(:Medium, is_background = true) # We won't use Medium, but it's required

    sys = PottsSystem([Up, Down, Medium],
        [
            AdhesionComponent(
            (Up, Down) => J,
            (Up, Up) => 0.0f0,
            (Down, Down) => 0.0f0,
            (Up, Medium) => 0.0f0,
            (Down, Medium) => 0.0f0
        )
        ])

    # We want a fully occupied grid (no Medium) with 2 cells taking up all space.
    layout = RandomLayout(Dict(Up => 1, Down => 1))
    prob = PottsProblem(sys, layout, grid_size;
        tspan = tspan, topology = topology, max_cells = 3)

    # The grid will be populated by the test script.

    return prob
end

end
