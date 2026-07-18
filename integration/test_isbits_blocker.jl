using Test
using CorePotts
using PottsToolkit

@testset "Isbits Blocker Isolation" begin
    A = CellType(:A, is_background = true)
    B = CellType(:B)

    # Mitosis event that always triggers
    trigger = CustomTrigger((i, cd) -> true)
    mitosis = MitosisEvent(B, trigger = trigger)

    sys = PottsSystem([A, B], [VolumeComponent(B => (target = 10, λ = 1.0))], events = (mitosis,), check_interval = 1)
    prob = PottsProblem(sys, Dict(B => 1), (10, 10))

    alg = SequentialMetropolis(sweeps_per_step = 1)
    integrator = CorePotts.SciMLBase.init(prob, alg)

    # This should now succeed
    CorePotts.SciMLBase.step!(integrator)
    @test integrator.t == 1
end
