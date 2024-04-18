using SAIMOpt
using Test

## NOTE add JET to the test environment, then uncomment
using JET

@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(SAIMOpt, target_modules=(SAIMOpt,))))
end

## NOTE add Aqua to the test environment, then uncomment
import Aqua

@testset "QA with Aqua" begin
    Aqua.test_all(SAIMOpt; ambiguities = false)
    # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
    Aqua.test_ambiguities(SAIMOpt)
end

include("MOI_wrapper.jl")
