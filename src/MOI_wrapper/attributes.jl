function MOI.get(::Optimizer, ::MOI.SolverName)
    return "SAIM"
end


function MOI.get(::Optimizer, ::MOI.SolverVersion)
    return SAIMOpt.__VERSION__ # This should be SAIM's version instead!
end


function MOI.get(optimizer::Optimizer, ::MOI.RawSolver)
    return optimizer
end


function MOI.get(optimizer::Optimizer, ::MOI.Name)
    return get(optimizer.moi_attributes, :name, "")
end

function MOI.set(optimizer::Optimizer, ::MOI.Name, value::AbstractString)
    optimizer.moi_attributes[:name] = String(value)

    return nothing
end

function MOI.supports(::Optimizer, ::MOI.Name)
    return true
end


function MOI.get(optimizer::Optimizer, ::MOI.Silent)
    return get(optimizer.moi_attributes, :silent, false)
end

function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    optimizer.moi_attributes[:silent] = value

    return nothing
end

function MOI.supports(::Optimizer, ::MOI.Silent)
    return true
end


function MOI.get(optimizer::Optimizer, ::MOI.TimeLimitSec)
    return get(optimizer.moi_attributes, :time_limit_sec, nothing)
end

function MOI.set(optimizer::Optimizer, ::MOI.TimeLimitSec, value::Real)
    @assert value >= 0

    optimizer.moi_attributes[:time_limit_sec] = Float64(value)

    return nothing
end

function MOI.set(optimizer::Optimizer, ::MOI.TimeLimitSec, ::Nothing)
    delete!(optimizer.moi_attributes, :time_limit_sec)

    return nothing
end

function MOI.supports(::Optimizer, ::MOI.TimeLimitSec)
    return true
end


# function MOI.get(optimizer::Optimizer, ::MOI.ObjectiveLimit)
#     return
# end

# function MOI.set(optimizer::Optimizer, ::MOI.ObjectiveLimit)
#     return
# end

function MOI.supports(::Optimizer, ::MOI.ObjectiveLimit)
    return false
end


# function MOI.get(optimizer::Optimizer, ::MOI.SolutionLimit)
#     return
# end

# function MOI.set(optimizer::Optimizer, ::MOI.SolutionLimit)
#     return
# end

function MOI.supports(::Optimizer, ::MOI.SolutionLimit)
    return false
end

function MOI.get(optimizer::Optimizer, attr::MOI.RawOptimizerAttribute)
    if haskey(SAIM_RAW_ATTRIBUTES, attr.name)
        return MOI.get(optimizer, SAIM_RAW_ATTRIBUTES[attr.name])
    else
        return optimizer.raw_attributes[attr.name]
    end
end

function MOI.set(optimizer::Optimizer, attr::MOI.RawOptimizerAttribute, value::Any)
    if haskey(SAIM_RAW_ATTRIBUTES, attr.name)
        return MOI.set(optimizer, SAIM_RAW_ATTRIBUTES[attr.name], value)
    else
        optimizer.raw_attributes[attr.name] = value
    end

    return nothing
end

function MOI.supports(::Optimizer, attr::MOI.RawOptimizerAttribute)
    return true # haskey(SAIM_RAW_ATTRIBUTES, attr.name)
end


function MOI.get(optimizer::Optimizer, ::MOI.NumberOfThreads)
    return get(optimizer.moi_attributes, :number_of_threads, 1)
end

function MOI.set(optimizer::Optimizer, ::MOI.NumberOfThreads, value::Integer)
    @assert value >= 1

    optimizer.moi_attributes[:number_of_threads] = value

    return nothing
end

function MOI.supports(::Optimizer, ::MOI.NumberOfThreads)
    return true
end


# function MOI.get(optimizer::Optimizer, ::MOI.AbsoluteGapTolerance)
#     return
# end

# function MOI.set(optimizer::Optimizer, ::MOI.AbsoluteGapTolerance)
#     return
# end

function MOI.supports(::Optimizer, ::MOI.AbsoluteGapTolerance)
    return false
end


# function MOI.get(optimizer::Optimizer, ::MOI.RelativeGapTolerance)
#     return
# end

# function MOI.set(optimizer::Optimizer, ::MOI.RelativeGapTolerance)
#     return
# end

function MOI.supports(::Optimizer, ::MOI.RelativeGapTolerance)
    return false
end

function MOI.supports(::Optimizer, ::MOI.AbstractModelAttribute)
    return false
end

function MOI.supports(::Optimizer, ::MOI.AbstractOptimizerAttribute)
    return false
end

abstract type SAIMAttribute <: MOI.AbstractOptimizerAttribute end

function MOI.supports(::Optimizer, ::SAIMAttribute)
    return true
end

struct Seed <: SAIMAttribute end

function MOI.get(optimizer::Optimizer, ::Seed)
    return get(optimizer.aim_attributes, :seed, nothing)
end

function MOI.set(optimizer::Optimizer, ::Seed, value::Integer)
    optimizer.aim_attributes[:seed] = value

    return nothing
end

function MOI.set(optimizer::Optimizer, ::Seed, ::Nothing)
    delete!(optimizer.aim_attributes, :seed)

    return nothing
end

struct WorkDir <: SAIMAttribute end

function MOI.get(optimizer::Optimizer, ::WorkDir)
    return get(optimizer.aim_attributes, :work_dir, nothing)
end

function MOI.set(optimizer::Optimizer, ::WorkDir, value::AbstractString)
    optimizer.aim_attributes[:work_dir] = String(value)

    return nothing
end

function MOI.set(optimizer::Optimizer, ::WorkDir, ::Nothing)
    delete!(optimizer.aim_attributes, :work_dir)

    return nothing
end

struct UseGPU <: SAIMAttribute end

_default_use_gpu(::SAIMBackend) = false

function MOI.get(optimizer::Optimizer, ::UseGPU)
    backend = MOI.get(optimizer, Backend())

    return get(optimizer.aim_attributes, :use_gpu, _default_use_gpu(backend))
end

function MOI.set(optimizer::Optimizer, ::UseGPU, value::Bool)
    optimizer.aim_attributes[:use_gpu] = value

    return nothing
end

struct NumericType <: SAIMAttribute end

function MOI.get(optimizer::Optimizer{T}, ::NumericType) where {T<:Real}
    return get(optimizer.aim_attributes, :numeric_type, T)
end

function MOI.set(optimizer::Optimizer, ::NumericType, ::Type{T}) where {T<:Real}
    optimizer.aim_attributes[:numeric_type] = T

    return nothing
end

struct Precision <: SAIMAttribute end

function MOI.get(optimizer::Optimizer, ::Precision)
    return get(optimizer.aim_attributes, :precision, "Float32")
end

function MOI.set(optimizer::Optimizer, ::Precision, value::String)
    @assert value ∈ ("BFloat16", "Float16", "Float32", "Float64")

    optimizer.aim_attributes[:precision] = value

    return nothing
end

struct Backend <: SAIMAttribute end

function MOI.get(optimizer::Optimizer, ::Backend)
    return get(optimizer.aim_attributes, :backend, SAIMOpt.Service())
end

function MOI.set(optimizer::Optimizer, ::Backend, value::B) where {B<:SAIMBackend}
    optimizer.aim_attributes[:backend] = value

    return nothing
end

const SAIM_RAW_ATTRIBUTES = Dict{String,Any}(
    "seed"         => SAIMOpt.Seed(),
    "work_dir"     => SAIMOpt.WorkDir(),
    "use_gpu"      => SAIMOpt.UseGPU(),
    "numeric_type" => SAIMOpt.NumericType(),
    "backend"      => SAIMOpt.Backend(),
)
