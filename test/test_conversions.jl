#=
test_conversions.jl

Tests of problem conversions.
=#

function test_conversions()

    @testset "Compute objective function correctly" begin
        model = Model(SAIMOpt.Optimizer)
        @variable(model, x, Bin)
        @variable(model, y, Bin)
        @variable(model, -1 <= z <= 5)
        @objective(model, Min, x + y * z)

        MOI.set(unsafe_backend(model), SAIMOpt.Backend(), SAIMOpt.RandomAssignment())
        optimize!(model)

        @test value(x) ∈ [0, 1]
        @test value(y) ∈ [0, 1]
        @test -1 ≤ value(z) ≤ 5
        @test objective_value(model) ≈ value(x) + value(y) * value(z)
    end

    return nothing
end