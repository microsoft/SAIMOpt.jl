#=
attributes.jl

Specifies the attributes supported by the optimizer.
Handles, setting and retrieving those attributes.
=#

#=
Custom attributes specific to the optimizer
=#

"""Root type for all SAIM attributes"""
abstract type SAIMAttribute <: MOI.AbstractOptimizerAttribute end

"""Specifies the random seed to use"""
struct Seed <: SAIMAttribute end

"""Specifies the working directory where
the optimizer should store temporary files and updates (where applicable)"""
struct WorkDir <: SAIMAttribute end

"""Attribute to discourage the use of the GPU"""
struct UseGPU <: SAIMAttribute end

"""Specifies the numeric type to use (Float64, Float32, Float16, BFloat16),
when running locally (if applicable);
Float64 may not be available when running on the GPU"""
struct NumericType <: SAIMAttribute end

"""Specifies the numeric type to use (Float64, Float32, Float16, BFloat16),
when running remotely;
Float64 may not be available when running on the GPU"""
struct Precision <: SAIMAttribute end

"""Specifies the backend to use.
By default it is the online service (Service);
other backends are available (e.g., [`RandomAssignment`](@ref) for quick testing)"""
struct Backend <: SAIMAttribute end


const SAIM_RAW_ATTRIBUTES = Dict{String,Any}(
    "seed"         => SAIMOpt.Seed(),
    "work_dir"     => SAIMOpt.WorkDir(),
    "use_gpu"      => SAIMOpt.UseGPU(),
    "numeric_type" => SAIMOpt.NumericType(),
    "backend"      => SAIMOpt.Backend(),
)

_default_use_gpu(::SAIMBackend) = false

MOI.supports(::Optimizer, ::SAIMAttribute) = true

MOI.get(optimizer::Optimizer, ::Seed) = get(optimizer.aim_attributes, :seed, nothing)
function MOI.set(optimizer::Optimizer, ::Seed, value::Integer)
    optimizer.aim_attributes[:seed] = value
    return nothing
end
function MOI.set(optimizer::Optimizer, ::Seed, ::Nothing)
    delete!(optimizer.aim_attributes, :seed)
    return nothing
end

MOI.get(optimizer::Optimizer, ::WorkDir) = get(optimizer.aim_attributes, :work_dir, nothing)
function MOI.set(optimizer::Optimizer, ::WorkDir, value::AbstractString)
    optimizer.aim_attributes[:work_dir] = String(value)
    return nothing
end
function MOI.set(optimizer::Optimizer, ::WorkDir, ::Nothing)
    delete!(optimizer.aim_attributes, :work_dir)
    return nothing
end


function MOI.get(optimizer::Optimizer, ::UseGPU)
    backend = MOI.get(optimizer, Backend())
    return get(optimizer.aim_attributes, :use_gpu, _default_use_gpu(backend))
end
function MOI.set(optimizer::Optimizer, ::UseGPU, value::Bool)
    optimizer.aim_attributes[:use_gpu] = value
    return nothing
end

MOI.get(optimizer::Optimizer{T}, ::NumericType) where {T<:Real} =
    get(optimizer.aim_attributes, :numeric_type, T)

function MOI.set(optimizer::Optimizer, ::NumericType, ::Type{T}) where {T<:Real}
    optimizer.aim_attributes[:numeric_type] = T
    return nothing
end

MOI.get(optimizer::Optimizer, ::Precision) = get(optimizer.aim_attributes, :precision, "Float32")
function MOI.set(optimizer::Optimizer, ::Precision, value::String)
    @assert value ∈ ("BFloat16", "Float16", "Float32", "Float64")
    optimizer.aim_attributes[:precision] = value
    return nothing
end

MOI.get(optimizer::Optimizer, ::Backend) = get(optimizer.aim_attributes, :backend, SAIMOpt.Service())
function MOI.set(optimizer::Optimizer, ::Backend, value::B) where {B<:SAIMBackend}
    optimizer.aim_attributes[:backend] = value
    return nothing
end


#=
Attributes to interface with the MOI backend
=#

MOI.get(::Optimizer, ::MOI.SolverName) = "SAIM"

# TODO: This should be SAIM's version instead!
MOI.get(::Optimizer, ::MOI.SolverVersion) = SAIMOpt.__VERSION__

MOI.get(optimizer::Optimizer, ::MOI.RawSolver) = optimizer

MOI.supports(::Optimizer, attr::MOI.RawOptimizerAttribute) = true # haskey(SAIM_RAW_ATTRIBUTES, attr.name)
function MOI.get(optimizer::Optimizer, attr::MOI.RawOptimizerAttribute)
    if haskey(SAIM_RAW_ATTRIBUTES, attr.name)
        return MOI.get(optimizer, SAIM_RAW_ATTRIBUTES[attr.name])
    else
        return optimizer.raw_attributes[attr.name]
    end
end
function MOI.set(optimizer::Optimizer, attr::MOI.RawOptimizerAttribute, value::Any)
    if haskey(SAIM_RAW_ATTRIBUTES, attr.name)
        MOI.set(optimizer, SAIM_RAW_ATTRIBUTES[attr.name], value)
    else
        optimizer.raw_attributes[attr.name] = value
    end

    return nothing
end

MOI.supports(::Optimizer, ::MOI.Name) = true
MOI.get(optimizer::Optimizer, ::MOI.Name) = get(optimizer.moi_attributes, :name, "")
function MOI.set(optimizer::Optimizer, ::MOI.Name, value::AbstractString)
    optimizer.moi_attributes[:name] = String(value)
    return nothing
end

MOI.supports(::Optimizer, ::MOI.Silent) = true
MOI.get(optimizer::Optimizer, ::MOI.Silent) = get(optimizer.moi_attributes, :silent, false)
function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    optimizer.moi_attributes[:silent] = value
    return nothing
end

MOI.supports(::Optimizer, ::MOI.TimeLimitSec) = true
MOI.get(optimizer::Optimizer, ::MOI.TimeLimitSec) = get(optimizer.moi_attributes, :time_limit_sec, nothing)
function MOI.set(optimizer::Optimizer, ::MOI.TimeLimitSec, value::Real)
    @assert value >= 0
    optimizer.moi_attributes[:time_limit_sec] = Float64(value)
    return nothing
end
function MOI.set(optimizer::Optimizer, ::MOI.TimeLimitSec, ::Nothing)
    delete!(optimizer.moi_attributes, :time_limit_sec)
    return nothing
end

MOI.supports(::Optimizer, ::MOI.NumberOfThreads) = true
MOI.get(optimizer::Optimizer, ::MOI.NumberOfThreads) = get(optimizer.moi_attributes, :number_of_threads, 1)

function MOI.set(optimizer::Optimizer, ::MOI.NumberOfThreads, value::Integer)
    @assert value >= 1

    optimizer.moi_attributes[:number_of_threads] = value
    return nothing
end


#=
Unsupported attributes
=#

MOI.supports(::Optimizer, ::MOI.ObjectiveLimit) = false
MOI.supports(::Optimizer, ::MOI.SolutionLimit) = false
MOI.supports(::Optimizer, ::MOI.AbsoluteGapTolerance) = false
MOI.supports(::Optimizer, ::MOI.RelativeGapTolerance) = false
MOI.supports(::Optimizer, ::MOI.AbstractModelAttribute) = false
MOI.supports(::Optimizer, ::MOI.AbstractOptimizerAttribute) = false
