using PrecompileTools: @compile_workload
import SciMLBase

# This workload deliberately remains CPU-only. GPU packages and device initialization do not belong
# in package precompilation; backend-native kernels are compiled on the selected device at first use.
@compile_workload begin
    model = ReferenceModels.differential_adhesion_model(target_volume = 8)
    normalize(model)
    lower(model; dimensions = 2)
    problem = ReferenceModels.differential_adhesion_problem(
        (16, 16); cells_per_population = 2, target_volume = 8, capacity = 8,
        tspan = (0, 1), seed = 0x707265636f6d7001)
    algorithms = (
        SequentialCPM(temperature = 2.0f0),
        SequentialEquilibrium(temperature = 2.0f0),
        CheckerboardSweepCPM(temperature = 2.0f0),
        LotteryCPM(temperature = 2.0f0),
    )
    for algorithm in algorithms
        integrator = SciMLBase.init(problem, algorithm;
            verbose = false, save_start = false, save_end = false)
        SciMLBase.step!(integrator, 1)
    end
end
