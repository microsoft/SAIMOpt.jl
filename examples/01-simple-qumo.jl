#=
01-simple-qumo.jl

A simple example of a Quadratically Unconstrained Quadratic Optimization (QUMO) problem
being solved by the AIM service.
=#

using Revise
using JuMP
# On first invocation the following takes a while to complete as it initializes
# a python environment to talk to the service. After that, it takes a few seconds.
using SAIMOpt

model = Model(SAIMOpt.Optimizer)
@variable(model, x, Bin)
@variable(model, y, Bin)
@variable(model, -1 <= z <= 1)
@objective(model, Min, x + y * z)

# The following will solve with default settings,
# using 60sec as timeout value.
optimize!(model)

@show termination_status(model)
@show value(x)
@show value(y)
@show value(z)

@show objective_value(model)

let inner_model = unsafe_backend(model)
    @show inner_model.sense
    @show inner_model.quadratic
    @show inner_model.linear
    @show inner_model.offset
    @show inner_model.aim_attributes
    @show inner_model.output
end






#=

model = Model(SAIMOpt.Optimizer)

@variable(model, x[1:2], Bin)
@variable(model, 2 <= y[1:2] <= 3)

@objective(model, Max, x'y + sum(x) - y[1] - 2*y[2])

optimize!(model)

@show termination_status(model)
@show value.(x)
@show value.(y)

let inner_model = unsafe_backend(model)
    @show inner_model.sense
    @show inner_model.quadratic
    @show inner_model.linear
    @show inner_model.offset
    @show inner_model.aim_attributes
    @show inner_model.output
end
=#