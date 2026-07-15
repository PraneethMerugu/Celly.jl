using PottsToolkit
using CorePotts
using Test
using CommonSolve
using SciMLBase

@testset "PottsToolkit Test Suite" begin
    Medium = CellType(:Medium, is_background = true)
    Epithelial = CellType(:Epithelial)
    Mesenchymal = CellType(:Mesenchymal)

    @testset "Dynamic Tracker Injection & Deduplication" begin
        # Test that required trackers are inferred correctly
        sys1 = PottsSystem(
            cell_types = [Medium, Epithelial],
            penalties = [
                VolumeComponent(Epithelial => (target = 500.0, λ = 5.0)),
                SurfaceAreaComponent(Epithelial => (target = 200.0, λ = 2.0))
            ]
        )
        u0_counts1 = Dict(Epithelial => 1)
        prob1 = PottsProblem(sys1, u0_counts1, (20, 20); tspan = (0, 1))

        # Trackers should include VolumeTracker and SurfaceAreaTracker
        @test any(t -> t isa CorePotts.VolumeTracker, prob1.p.trackers)
        @test any(t -> t isa CorePotts.SurfaceAreaTracker, prob1.p.trackers)
        @test length(prob1.p.trackers) == 2

        # Test deduplication
        # If we explicitly provide a VolumeTracker, it should not be duplicated
        prob2 = PottsProblem(sys1, u0_counts1, (20, 20); tspan = (0, 1),
            trackers = (CorePotts.VolumeTracker(),))
        vol_trackers = filter(t -> t isa CorePotts.VolumeTracker, prob2.p.trackers)
        @test length(vol_trackers) == 1
        @test length(prob2.p.trackers) == 2 # One Vol, One Surf
    end

    @testset "Advanced Physics Components Compilation" begin
        chem_field = zeros(Float32, 20, 20)
        chem_field[10, 10] = 1.0f0

        sys = PottsSystem(
            cell_types = [Medium, Epithelial, Mesenchymal],
            penalties = [
                HSTVolumeComponent(Epithelial => (target = 50.0, λ = 5.0), eta = 0.1),
                SurfaceAreaComponent(Mesenchymal => (target = 200.0, λ = 2.0), eta = 0.2),
                LengthComponent(Epithelial => (target = 15.0, λ = 3.0), eta = 0.3),
                ChemotaxisComponent(Mesenchymal => 10.0; chemical_field = chem_field),
                AdhesionComponent((Medium, Epithelial) => 5.0)
            ]
        )
        u0_counts = Dict(Epithelial => 1, Mesenchymal => 1)
        prob = PottsProblem(sys, u0_counts, (20, 20); tspan = (0, 1))

        # Check penalties length
        @test length(prob.p.penalties) == 5

        # 1. HSTVolumePenalty
        hvp = prob.p.penalties[1]
        @test hvp isa CorePotts.HSTVolumePenalty
        @test hvp.eta == 0.1f0
        @test hvp.lambdas[2] == 5.0f0 # Epithelial
        @test hvp.lambdas[3] == 0.0f0 # Mesenchymal

        # 2. HSTSurfaceAreaPenalty
        sap = prob.p.penalties[2]
        @test sap isa CorePotts.HSTSurfaceAreaPenalty
        @test sap.eta == 0.2f0
        @test sap.lambdas[2] == 0.0f0
        @test sap.lambdas[3] == 2.0f0

        # 3. HSTLengthPenalty
        lp = prob.p.penalties[3]
        @test lp isa CorePotts.HSTLengthPenalty
        @test lp.eta == 0.3f0
        @test lp.lambdas[2] == 3.0f0

        # 4. ChemotaxisPenalty
        cp = prob.p.penalties[4]
        @test cp isa CorePotts.ChemotaxisPenalty
        @test cp.lambdas[3] == 10.0f0
        @test cp.chem_field === chem_field

        # 5. AdhesionPenalty
        ap = prob.p.penalties[5]
        @test ap isa CorePotts.AdhesionPenalty

        # Check Cell Data Properties Injection
        cd = prob.u0.cell_data

        # Find cell IDs dynamically since Dict iteration order is non-deterministic
        epi_idx = findfirst(==(1), cd.cell_types)
        mes_idx = findfirst(==(2), cd.cell_types)

        @test cd.target_volumes[epi_idx] == 50
        @test cd.target_surface_areas[mes_idx] == 200
        @test cd.target_lengths[epi_idx] == 15.0f0
    end

    @testset "Simulation Viability" begin
        sys = PottsSystem(
            cell_types = [Medium, Epithelial],
            penalties = [
                VolumeComponent(Epithelial => (target = 50.0, λ = 5.0)),
                AdhesionComponent((Medium, Epithelial) => 20.0, (Epithelial, Epithelial) =>
                    5.0)
            ]
        )
        u0_counts = Dict(Epithelial => 2)
        prob = PottsProblem(sys, u0_counts, (20, 20); tspan = (1, 5))
        alg = ParallelMetropolis(; T = 20.0f0, sweeps_per_step = 10)

        sol = CommonSolve.solve(prob, alg)

        # Check that it solved successfully and generated the requested steps
        @test length(sol.t) == 5
        @test sol.retcode == SciMLBase.ReturnCode.Success
    end

    include("test_flex_traits.jl")
    include("test_layouts.jl")
    include("test_events.jl")
    include("test_rule_macro.jl")
    include("test_gpu_closures.jl")
end
