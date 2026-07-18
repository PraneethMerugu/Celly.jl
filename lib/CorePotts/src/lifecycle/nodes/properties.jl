"""
    Clone <: InheritanceRule

The child cell receives an exact copy of the parent cell's property (e.g. `target_volume`).
"""
struct Clone <: InheritanceRule end

"""
    Split(fraction=0.5f0) <: InheritanceRule

The parent cell's property is split between the parent and child according to the `fraction`.
"""
struct Split{T} <: InheritanceRule
    fraction::T
end
Split() = Split(0.5f0)

"""
    Reset(value) <: InheritanceRule

Both parent and child have the property set to `value`.
"""
struct Reset{T} <: InheritanceRule
    value::T
end

"""
    AsymmetricReset(parent_value, child_value) <: InheritanceRule

The parent has the property set to `parent_value` and the child has the property set to `child_value`.
"""
struct AsymmetricReset{T} <: InheritanceRule
    parent_value::T
    child_value::T
end

"""
    ResetChild(value) <: InheritanceRule

The parent retains its property, but the child has the property set to `value`.
"""
struct ResetChild{T} <: InheritanceRule
    value::T
end

struct RandomPoisson{T} <: InheritanceRule
    lambda::T
end

"""
    RandomUniform(min, max) <: InheritanceRule

Both parent and child have their property drawn from a uniform distribution [min, max].
"""
struct RandomUniform{T} <: InheritanceRule
    min::T
    max::T
end

"""
    RandomNormal(mean, std) <: InheritanceRule

Both parent and child have their property drawn from a normal distribution.
"""
struct RandomNormal{T} <: InheritanceRule
    mean::T
    std::T
end

"""
    InheritAdd(value) <: InheritanceRule

Both parent and child have `value` added to their property.
"""
struct InheritAdd{T} <: InheritanceRule
    value::T
end

"""
    InheritMultiply(value) <: InheritanceRule

Both parent and child have their property multiplied by `value`.
"""
struct InheritMultiply{T} <: InheritanceRule
    value::T
end
