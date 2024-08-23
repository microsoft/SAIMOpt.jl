#=
02-random-assignment.jl

Simple example of changing the backend solver to use a basic solver
that assigns random values from the domain of each variable.
(Maybe useful for debugging and testing.)

=#

using Revise
using JuMP
using MathOptInterface
using LinearAlgebra
# ENV["JULIA_DEBUG"] = "SAIMOpt"
using SAIMOpt

model = Model(SAIMOpt.Optimizer)
@variable(model, x, Bin)
@variable(model, y, Bin)
@variable(model, -1 <= z <= 5)
@objective(model, Min, x + y * z)


MOI.set(unsafe_backend(model), SAIMOpt.Backend(), SAIMOpt.RandomAssignment())
optimize!(model)

@show value.([x, y, z]);
@show objective_value(model);
@show value(x) + value(y) * value(z);
