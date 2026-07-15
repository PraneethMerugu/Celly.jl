import Atomix
import AcceleratedKernels
import KernelAbstractions
using KernelAbstractions: @kernel, @index, @localmem, @synchronize
using LinearAlgebra
using StaticArrays

abstract type AbstractRule end
abstract type InheritanceRule <: AbstractRule end
abstract type UpdateRule <: AbstractRule end
