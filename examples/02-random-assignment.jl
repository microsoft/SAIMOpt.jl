#=
02-random-assignment.jl

=#

using Revise
using JuMP
using MathOptInterface
using LinearAlgebra
using SAIMOpt

model = Model(SAIMOpt.Optimizer)
@variable(model, x, Bin)
@variable(model, y, Bin)
@variable(model, -1 <= z <= 5)
@objective(model, Min, x + y * z)

# TODO: is there a better way to access `backend(model).optimizer.model.optimizer`?
MOI.set(backend(model).optimizer.model.optimizer, SAIMOpt.Backend(), SAIMOpt.RandomAssignment())
optimize!(model)

value.([x, y, z])

# BUG: The objective value should return the value of the original objective, and not of the transformed problem.
@assert objective_value(model) == value(x) + value(y) * value(z)
