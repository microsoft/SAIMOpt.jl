using Test
using SAIMOpt
using JuMP
using JET
using Aqua

function test_jet()
    @testset "static analysis with JET.jl" begin
        @test isempty(
            JET.report_package(SAIMOpt; target_modules=(SAIMOpt,)) |> JET.get_reports
        )
    end

    return nothing
end

function test_aqua()
    @testset "QA with Aqua.jl" begin
        Aqua.test_all(SAIMOpt; ambiguities = false)
        # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
        Aqua.test_ambiguities(SAIMOpt)
    end

    return nothing
end

include("MOI_wrapper.jl")

function test_qumo_example(config!::Function)
    model = Model(SAIMOpt.Optimizer)

    config!(model)

    @variable(model, x[1:2], Bin)
    @variable(model, 2 <= y[1:2] <= 3)

    @objective(model, Max, x'y + sum(x) - sum(y))

    optimize!(model)

    @test termination_status(model) == MOI.LOCALLY_SOLVED
    @test all(xi -> xi ≈ 0 || xi ≈ 1, value.(x))
    @test all(yi -> yi ≈ 2 || yi ≈ 3, value.(y))

    let inner_model = unsafe_backend(model)
        @test inner_model.sense === MOI.MAX_SENSE
    end

    return nothing
end

function test_examples()
    @testset "JuMP Example" verbose = true begin
        @testset "GPU (If Available) - 64 Bits" begin
            test_qumo_example() do model
                # set_attribute(model, "use_gpu", true) # automatically defined if GPU is functional
                set_attribute(model, "numeric_type", Float64)
            end
        end

        @testset "GPU (If Available) - 32 Bits" begin
            test_qumo_example() do model
                # set_attribute(model, "use_gpu", true) # automatically defined if GPU is functional
                set_attribute(model, "numeric_type", Float32)
            end
        end

        @testset "CPU - 64 Bits" begin
            test_qumo_example() do model
                set_attribute(model, "use_gpu", false)
                set_attribute(model, "numeric_type", Float64)
            end
        end

        @testset "CPU - 32 Bits" begin
            test_qumo_example() do model
                set_attribute(model, "use_gpu", false)
                set_attribute(model, "numeric_type", Float32)
            end
        end
    end

    return nothing
end

function main()
    @testset "♠ SAIMOpt v$(SAIMOpt.__VERSION__) Test Suite ♠" verbose = true begin
        if !isnothing(get(ENV, "SAIMOPT_COMPLETE_TEST", nothing))
            test_jet()
            test_aqua()
            test_moi()
        end

        test_examples()
    end

    return nothing
end

main() # Here we go!
