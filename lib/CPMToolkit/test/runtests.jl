using CPMToolkit
using CoreCPM
using Test
using CommonSolve
using SciMLBase

@testset "CPMToolkit Test Suite" begin

    Medium = CellType(:Medium)
    Epithelial = CellType(:Epithelial)
    Mesenchymal = CellType(:Mesenchymal)

    @testset "Dynamic Tracker Injection & Deduplication" begin
        # Test that required trackers are inferred correctly
        sys1 = CPMSystem(
            cell_types = [Medium, Epithelial],
            penalties = [
                VolumeComponent(Epithelial => (target=500.0, λ=5.0)),
                SurfaceAreaComponent(Epithelial => (target=200.0, λ=2.0))
            ]
        )
        u0_counts1 = Dict(Epithelial => 1)
        prob1 = CPMProblem(sys1, u0_counts1, (20, 20); tspan=(0, 1))
        
        # Trackers should include VolumeTracker and SurfaceAreaTracker
        @test any(t -> t isa CoreCPM.VolumeTracker, prob1.p.trackers)
        @test any(t -> t isa CoreCPM.SurfaceAreaTracker, prob1.p.trackers)
        @test length(prob1.p.trackers) == 2

        # Test deduplication
        # If we explicitly provide a VolumeTracker, it should not be duplicated
        prob2 = CPMProblem(sys1, u0_counts1, (20, 20); tspan=(0, 1), trackers=(CoreCPM.VolumeTracker(),))
        vol_trackers = filter(t -> t isa CoreCPM.VolumeTracker, prob2.p.trackers)
        @test length(vol_trackers) == 1
        @test length(prob2.p.trackers) == 2 # One Vol, One Surf
    end

    @testset "Advanced Physics Components Compilation" begin
        chem_field = zeros(Float32, 20, 20)
        chem_field[10, 10] = 1.0f0

        sys = CPMSystem(
            cell_types = [Medium, Epithelial, Mesenchymal],
            penalties = [
                HSTVolumeComponent(Epithelial => (target=50.0, λ=5.0), eta=0.1),
                SurfaceAreaComponent(Mesenchymal => (target=200.0, λ=2.0), eta=0.2),
                LengthComponent(Epithelial => (target=15.0, λ=3.0), eta=0.3),
                ChemotaxisComponent(Mesenchymal => 10.0; chemical_field=chem_field),
                AdhesionComponent((Medium, Epithelial) => 5.0)
            ]
        )
        u0_counts = Dict(Epithelial => 1, Mesenchymal => 1)
        prob = CPMProblem(sys, u0_counts, (20, 20); tspan=(0, 1))

        # Check penalties length
        @test length(prob.p.penalties) == 5

        # 1. HSTVolumePenalty
        hvp = prob.p.penalties[1]
        @test hvp isa CoreCPM.HSTVolumePenalty
        @test hvp.eta == 0.1f0
        @test hvp.lambdas[2] == 5.0f0 # Epithelial
        @test hvp.lambdas[3] == 0.0f0 # Mesenchymal

        # 2. HSTSurfaceAreaPenalty
        sap = prob.p.penalties[2]
        @test sap isa CoreCPM.HSTSurfaceAreaPenalty
        @test sap.eta == 0.2f0
        @test sap.lambdas[2] == 0.0f0
        @test sap.lambdas[3] == 2.0f0

        # 3. HSTLengthPenalty
        lp = prob.p.penalties[3]
        @test lp isa CoreCPM.HSTLengthPenalty
        @test lp.eta == 0.3f0
        @test lp.lambdas[2] == 3.0f0

        # 4. ChemotaxisPenalty
        cp = prob.p.penalties[4]
        @test cp isa CoreCPM.ChemotaxisPenalty
        @test cp.lambdas[3] == 10.0f0
        @test cp.chem_field === chem_field

        # 5. AdhesionPenalty
        ap = prob.p.penalties[5]
        @test ap isa CoreCPM.AdhesionPenalty

        # Check Cell Data Properties Injection
        # Epithelial is ID 2, Mesenchymal is ID 3 (Medium is 1)
        cd = prob.u0.cell_data
        @test cd.target_volumes[2] == 50
        @test cd.target_surface_areas[3] == 200
        @test cd.target_lengths[2] == 15.0f0
    end

    @testset "Simulation Viability" begin
        sys = CPMSystem(
            cell_types = [Medium, Epithelial],
            penalties = [
                VolumeComponent(Epithelial => (target=50.0, λ=5.0)),
                AdhesionComponent((Medium, Epithelial) => 20.0, (Epithelial, Epithelial) => 5.0)
            ]
        )
        u0_counts = Dict(Epithelial => 2)
        prob = CPMProblem(sys, u0_counts, (20, 20); tspan=(1, 5))
        alg = ParallelMetropolis(; T=20.0f0, sweeps_per_step=10)
        
        sol = CommonSolve.solve(prob, alg)
        
        # Check that it solved successfully and generated the requested steps
        @test length(sol.t) == 5
        @test sol.retcode == SciMLBase.ReturnCode.Success
    end

end
