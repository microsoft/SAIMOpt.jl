#=
test_conversions.jl

Tests of problem conversions.
=#

@testset "Compute objective function correctly" begin
    model = Model(SAIMOpt.Optimizer)
    @variable(model, x, Bin)
    @variable(model, y, Bin)
    @variable(model, -1 <= z <= 5)
    @objective(model, Min, x + y * z)

    # TODO: is there a better way to access `backend(model).optimizer.model.optimizer`?
    MOI.set(backend(model).optimizer.model.optimizer, SAIMOpt.Backend(), SAIMOpt.RandomAssignment())
    optimize!(model)

    @assert value(x) ∈ [0, 1]
    @assert value(y) ∈ [0, 1]
    @assert -1 ≤ value(z) ≤ 5
    @assert objective_value(model) ≈ value(x) + value(y) * value(z)
end