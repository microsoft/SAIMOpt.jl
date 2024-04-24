using Test
using SAIMOpt

# using JET

# @testset "static analysis with JET.jl" begin
#     @test isempty(
#         JET.report_package(SAIMOpt; target_modules=(SAIMOpt,)) |> JET.get_reports
#     )
# end

# using Aqua

# @testset "QA with Aqua.jl" begin
#     Aqua.test_all(SAIMOpt; ambiguities = false)
#     # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
#     Aqua.test_ambiguities(SAIMOpt)
# end

# include("MOI_wrapper.jl")

using JuMP

@testset "JuMP Example" begin
    model = Model(SAIMOpt.Optimizer)

    set_attribute(model, "use_gpu", false)

    @variable(model, x[1:2], Bin)
    @variable(model, 2 <= y[1:2] <= 3)

    @objective(model, Max, x'y + sum(x) - sum(y))

    optimize!(model)

    @test termination_status(model) == MOI.LOCALLY_SOLVED
    @test all(xi -> xi ≈ 0 || xi ≈ 1, value.(x))
    @test all(yi -> yi ≈ 2 || yi ≈ 3, value.(y))

    let inner_model = unsafe_backend(model)
        @test inner_model.sense === SAIMOpt.SAIM.Maximization
    end
end

@testset "Coefficient Types" begin
    model = Model(SAIMOpt.Optimizer)

    set_attribute(model, "numeric_type", Float32)
    
    @variable(model, x[1:2], Bin)
    @variable(model, 2 <= y[1:2] <= 3)

    @objective(model, Max, x'y + sum(x) - sum(y))

    optimize!(model)

    @test termination_status(model) == MOI.LOCALLY_SOLVED
    @test all(xi -> xi ≈ 0 || xi ≈ 1, value.(x))
    @test all(yi -> yi ≈ 2 || yi ≈ 3, value.(y))

    let inner_model = unsafe_backend(model)
        @test inner_model.sense === SAIMOpt.SAIM.Maximization
    end
end