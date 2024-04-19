module SAIMOpt_MOITests

using Test
import SAIMOpt
import MathOptInterface as MOI

const OPTIMIZER = MOI.instantiate(
    MOI.OptimizerWithAttributes(
        SAIMOpt.Optimizer,
        MOI.Silent()       => true,
        MOI.TimeLimitSec() => 1.0,
    ),
)

const BRIDGED = MOI.instantiate(
    MOI.OptimizerWithAttributes(
        SAIMOpt.Optimizer,
        MOI.Silent()       => true,
        MOI.TimeLimitSec() => 1.0,
    ),
    with_bridge_type = Float64,
)

const CONFIG = MOI.Test.Config(
    # Modify tolerances as necessary.
    atol = 1e-6,
    rtol = 1e-6,
    # Use MOI.LOCALLY_SOLVED for local solvers.
    optimal_status = MOI.LOCALLY_SOLVED,
    # Pass attributes or MOI functions to `exclude` to skip tests that
    # rely on this functionality.
    exclude = Any[MOI.VariableName, MOI.delete],
)

"""
    runtests()

This function runs all the tests in MathOptInterface.Test.

Pass arguments to `exclude` to skip tests for functionality that is not
implemented or that your solver doesn't support.
"""
function runtests()
    MOI.Test.runtests(
        BRIDGED,
        CONFIG,
        exclude = [
            "test_attribute_RawStatusString",
            "test_attribute_SolveTimeSec",
            
            "test_HermitianPSDCone_",
            "test_NormNuclearCone_",
            "test_NormSpectralCone_",
            "test_basic_ScalarAffineFunction_",
            "test_basic_ScalarQuadraticFunction_",
            "test_basic_ScalarNonlinearFunction_",
            "test_basic_Vector",

            "test_linear_",
            "test_nonlinear_",
            "test_conic_",
            "test_quadratic_",
            "test_constraint_",
            "test_objective_",
            "test_multiobjective_",
            "test_cpsat_",
            "test_infeasible_",
            "test_modification_",
            "test_solve_",

            r"test_variable_solve.*bound",
        ],
        # This argument is useful to prevent tests from failing on future
        # releases of MOI that add new tests. Don't let this number get too far
        # behind the current MOI release though. You should periodically check
        # for new tests to fix bugs and implement new features.
        exclude_tests_after = v"1.28.1",
    )

    return nothing
end

end

@testset "MathOptInterface Test Suite" begin
    SAIMOpt_MOITests.runtests()
end
