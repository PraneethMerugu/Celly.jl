using Test
using CoreCPM
using SciMLBase
using CairoMakie # For plot testing

@testset "SciML Saving and Makie Recipes" begin
    W, H = 20, 20
    N_cells = 5
    grid = rand(UInt32(1):UInt32(N_cells), W, H)
    cell_data = build_cell_data(grid, N_cells)
    
    for i in 1:N_cells
        cell_data.cell_types[i] = 1
    end
    
    penalties = (HSTVolumePenalty{Rigid}(zeros(Float32, 256)),)
    trackers = (VolumeTracker(), SurfaceAreaTracker())
    
    u0 = CPMState(grid, cell_data)
    p_sys = CPMParameters(VonNeumannTopology{2}(), penalties, trackers)
    prob = CPMProblem(u0, (0, 10), p_sys)
    alg = ParallelMetropolis(; T=1.0f0) 
    
    @testset "Default Saving" begin
        # By default, solve should return only start and end? Actually, our logic:
        # save_everystep default is `isempty(saveat)` so if saveat is empty, it saves everystep!
        sol = solve(prob, alg; save_start=true, save_end=true)
        # 11 states: t=0,1,2,3,4,5,6,7,8,9,10
        @test length(sol.t) == 11
        @test length(sol.u) == 11
        @test sol.t[1] == 0
        @test sol.t[end] == 10
        
        # The recipes are exported and defined correctly
        @test isdefined(CoreCPM, :cpmplot)
        @test isdefined(CoreCPM, :cpmsolutionplot)
    end
    
    @testset "Specific saveat" begin
        sol2 = solve(prob, alg; saveat=[2, 5, 8], save_start=false, save_end=false)
        @test sol2.t == [2, 5, 8]
        @test length(sol2.u) == 3
        
        sol3 = solve(prob, alg; saveat=3, save_start=true, save_end=true)
        # saves start (0), and saveat points (3, 6, 9), and end (10)
        @test sol3.t == [0, 3, 6, 9, 10]
        @test length(sol3.u) == 5
    end
end
