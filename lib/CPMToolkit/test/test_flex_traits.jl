using Test
using CoreCPM
using CPMToolkit

@testset "Flex Traits Tests" begin
    # 1. Define a system with Flex traits
    sys = CPMSystem(
        cell_types = [CellType(:Medium), CellType(:A)],
        penalties = [
            VolumeComponent(CellType(:A) => (target=100.0, λ=5.0), flex=true),
            AdhesionComponent((CellType(:A), CellType(:A)) => 10.0,
                              (CellType(:A), CellType(:Medium)) => 5.0,
                              flex=true)
        ]
    )

    # 2. Build the problem
    u0_counts = Dict(CellType(:A) => 2)
    prob = CPMProblem(sys, u0_counts, (20, 20); tspan=(0, 10))

    # 3. Check that Flex properties are initialized
    @test prob.u0.cell_data.volume_lambdas[2] == 5.0f0
    @test prob.u0.cell_data.volume_lambdas[3] == 5.0f0
    
    # 4. Check adhesion modifiers initialized to 1.0
    @test prob.u0.cell_data.adhesion_modifiers[2] == 1.0f0
    @test prob.u0.cell_data.adhesion_modifiers[3] == 1.0f0

    # 5. Modify one cell's lambda and verify independent behavior
    prob.u0.cell_data.volume_lambdas[2] = 10.0f0
    prob.u0.cell_data.adhesion_modifiers[3] = 2.0f0

    @test prob.u0.cell_data.volume_lambdas[2] == 10.0f0
    @test prob.u0.cell_data.volume_lambdas[3] == 5.0f0

    # Check penalty types
    @test prob.p.penalties[1] isa CoreCPM.VolumePenalty{CoreCPM.Flex}
    @test prob.p.penalties[2] isa CoreCPM.AdhesionPenalty{CoreCPM.Flex}

    # Evaluate a flex penalty
    vol_pen = prob.p.penalties[1]
    
    # Fake context
    ctx = (src = UInt32(2), tgt = UInt32(3), cell_data = prob.u0.cell_data)
    
    lam_src = CoreCPM.get_lambda(vol_pen, ctx, ctx.src)
    lam_tgt = CoreCPM.get_lambda(vol_pen, ctx, ctx.tgt)
    
    @test lam_src == 10.0f0
    @test lam_tgt == 5.0f0
    
    adh_pen = prob.p.penalties[2]
    mod_src = CoreCPM.get_adhesion_modifier(adh_pen, ctx, ctx.src)
    mod_tgt = CoreCPM.get_adhesion_modifier(adh_pen, ctx, ctx.tgt)
    
    @test mod_src == 1.0f0
    @test mod_tgt == 2.0f0
end
