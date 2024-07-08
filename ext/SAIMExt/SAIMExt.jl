module SAIMExt

import SAIMOpt
import SAIM
import MathOptInterface as MOI

SAIMOpt._default_use_gpu(::SAIMOpt.Local) = SAIM.is_gpu_functional()

function SAIMOpt.solve!(::SAIMOpt.Local, optimizer::SAIMOpt.Optimizer{T}) where {T}
    seed       = something(MOI.get(optimizer, SAIMOpt.Seed()), trunc(Int, time()))
    time_limit = trunc(Int, something(MOI.get(optimizer, MOI.TimeLimitSec()), 10.0))
    work_dir   = MOI.get(optimizer, SAIMOpt.WorkDir())
    use_gpu    = MOI.get(optimizer, SAIMOpt.UseGPU())
    num_type   = MOI.get(optimizer, SAIMOpt.NumericType())

    if use_gpu
        if SAIM.is_gpu_functional()
            if num_type === Float64
                @warn "Changing 'numeric_type' to Float32 to run on the GPU"
                num_type = Float32
            end

            SAIM.Solver.SetDefaultBackEndToGpu()
        else
            error("GPU is not functional")
        end
    else # !use_gpu
        SAIM.Solver.SetDefaultBackEndToCpu()
    end

    quadratic = convert.(num_type, -optimizer.quadratic)
    linear    = convert.(num_type, -optimizer.linear)

    output = SAIM.API.SolverAPI.compute_qumo(
        optimizer.sense,
        quadratic,
        linear,
        optimizer.continuous,
        seed,
        time_limit;
        work_dir,
    )

    if !(T === num_type)
        output = Dict(
            "Objective"  => convert(T, output["Objective"]),
            "Assignment" => convert.(T, output["Assignment"]),
        )
    end

    optimizer.output = output

    return nothing
end

end # module SAIMExt