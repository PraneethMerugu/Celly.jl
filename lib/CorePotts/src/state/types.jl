"""Open family for logical and compiled Cellular Potts state representations."""
abstract type AbstractPottsState end

"""Return the ownership lattice at an explicit logical or execution boundary."""
function lattice_storage end

"""Open SciML problem family implemented by the scientific Potts interface."""
abstract type AbstractPottsProblem <: SciMLBase.AbstractSciMLProblem end

"""Open SciML algorithm family implemented by scientific schedulers."""
abstract type AbstractPottsAlgorithm <: SciMLBase.AbstractSciMLAlgorithm end

"""Open tracker component family for derived scientific state."""
abstract type AbstractTracker end

"""Open event component family validated by the scientific lifecycle protocol."""
abstract type AbstractEvent end
