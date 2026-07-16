using Test
using Potts
using Potts.CorePotts
using Potts.PottsToolkit
using MakiePotts

@testset "Ecosystem Fixes" begin
    @testset "Issue 2: PottsCache RefValue elimination" begin
        grid = backend_zeros(UInt32, 10, 10)
        cell_data = CorePotts.build_cell_data(grid, 5)
        u = CorePotts.PottsState(grid, cell_data)
        topology = CorePotts.VonNeumannTopology{2}()

        cache = CorePotts.PottsCache(u, topology)
        @test cache.step_counter isa Vector{UInt64}
        @test cache.noise_counter isa Vector{UInt64}
    end

    @testset "Issue 1: Integrator logic loop (Simulator)" begin
        A = CellType(:A, is_background = true)
        B = CellType(:B)
        sys = PottsSystem([A, B], [VolumeComponent(B => (target = 10, λ = 1.0))])
        prob = PottsProblem(sys, Dict(B => 1), (10, 10); tspan = (0, 2))

        alg = SequentialMetropolis(sweeps_per_step = 5)
        import SciMLBase
        integrator = SciMLBase.init(prob, alg)

        @test integrator.cache.step_counter[1] == 0

        SciMLBase.step!(integrator)

        # execute_step! increments step_counter. With sweeps_per_step=5, it should run 5 times.
        @test integrator.cache.step_counter[1] == 5
    end

    @testset "Issue 3: Hidden Mutability in Events" begin
        Bg = CellType(:Bg, is_background = true)
        Cell = CellType(:Cell)
        sys = PottsSystem([Bg, Cell], [VolumeComponent(Cell => (target = 10, λ = 1.0))],
            events = (MitosisEvent(Cell, trigger = VolumeRatioTrigger(2.0)),))

        prob = PottsProblem(sys, Dict(Cell => 1), (10, 10))

        alg = SequentialMetropolis()
        import SciMLBase
        integrator = SciMLBase.init(prob, alg)
        
        # Test that workspace is attached to the MitosisEvent inside the integrator
        evt = integrator.p.events[1]
        @test evt isa PottsToolkit.Events.ResolvedMitosisEvent
        @test evt.workspace isa CorePotts.MitosisWorkspace
    end

    @testset "Issue 4: MakiePotts UI resets" begin
        Bg = CellType(:Bg, is_background = true)
        Cell = CellType(:Cell)
        sys = PottsSystem([Bg, Cell], [VolumeComponent(Cell => (target = 10, λ = 1.0))])
        prob = PottsProblem(sys, Dict(Cell => 1), (10, 10))
        alg = SequentialMetropolis()

        fig = explore_potts(prob, alg)
        @test typeof(fig).name.name == :Figure
    end
end
