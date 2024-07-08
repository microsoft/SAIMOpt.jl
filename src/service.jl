module SAIMOptService

import PythonCall
import JSON
import MathOptInterface as MOI

import ..SAIMOpt

const __IS_AUTH__ = Ref{Union{Bool,Nothing}}(nothing)

function __auth__()::Bool
    if isnothing(__IS_AUTH__[])
        try
            let workspace = pyaimopt.create_azure_workspace()
                __IS_AUTH__[] = PythonCall.pytruth(workspace.test_connection())::Bool
            end
        catch exc
            @error(
                """
                Automatic authentication failed with error:
                $(sprint(showerror, exc))
                """
            )

            __IS_AUTH__[] = false
        end
    end

    return __IS_AUTH__[]
end

const np                 = PythonCall.pynew()
const json               = PythonCall.pynew()
const pyaimopt           = PythonCall.pynew()
const pyaimopt_workspace = PythonCall.pynew()

function __init__()
    PythonCall.pycopy!(np, PythonCall.pyimport("numpy"))
    PythonCall.pycopy!(json, PythonCall.pyimport("json"))

    PythonCall.pycopy!(pyaimopt, PythonCall.pyimport("pyaimopt"))
    PythonCall.pycopy!(pyaimopt_workspace, PythonCall.pyimport("pyaimopt.workspace"))

    # Authenticate here, at load time, to avoid having to do it at run time.
    # This improves the user experience by prompting the user when the package
    # is loaded, rather than when the model is sent to the solver.
    if !__auth__()
        @warn """
        Automatic authentication failed.
        You might be prompted to authenticate in your next call to the solver.
        """
    end

    return nothing
end

function SAIMOpt.solve!(::SAIMOpt.Service, optimizer::SAIMOpt.Optimizer{T}) where {T}
    # Retrieve parameters
    _precision = MOI.get(optimizer, SAIMOpt.Precision())
    _timeout   = MOI.get(optimizer, MOI.TimeLimitSec())
    # _silent    = MOI.get(optimizer, MOI.Silent())

    @assert _precision ∈ ("BFloat16", "Float16", "Float32", "Float64")

    # Instantiate solver
    workspace = pyaimopt.create_azure_workspace()
    solver    = pyaimopt.Solver(workspace)
    precision = PythonCall.pygetattr(pyaimopt.Precision, PythonCall.pystr(_precision))
    timeout   = PythonCall.pyint(ceil(Int, something(_timeout, 5)))

    solver.set_precision(precision)

    # Retrieve Problem
    Q = optimizer.quadratic
    ℓ = optimizer.linear
    c = optimizer.offset
    y = optimizer.continuous

    # The convention used by the AIM Optimizer is to minimize the energy of
    #   H(s) = - (x'Q x + ℓ'x + c)
    # thus, we need to negate the coefficients.
    problem = pyaimopt.QUMO(-np.array(Symmetric(Q)), -np.array(ℓ))
    results = @timed solver.solve(problem, timeout)

    job_status = results.value

    if !is_job_ok(job_status)
        error("Job failed: $(PythonCall.pystr(job_status))")
    end

    job_result = job_status.result

    x = PythonCall.pyconvert.(T, job_result.output)
    λ = x'Q * x + ℓ'x + c

    output = Dict(
        "Objective"  => λ,
        "Assignment" => x,
        "Info"       => jl_object(job_result.information),
        "Time"       => results.time,
    )

    optimizer.output = output

    return nothing
end

function is_job_ok(job_status)::Bool
    return PythonCall.pyisinstance(job_status, pyaimopt_workspace.Ok) |> PythonCall.pytruth
end

function jl_object(py_obj)
    # Convert Python object to JSON string, then parse it into a Julia object
    return PythonCall.pyconvert(String, json.dumps(py_obj)) |> JSON.parse
end

end
