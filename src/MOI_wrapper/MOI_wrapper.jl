include("variables.jl")

"""
    Optimizer{T} <: MOI.AbstractOptimizer

This struct is responsible for integrating SAIM with MathOptInterface, which
is how we can build a solver that can be used by JuMP models.

```julia
using JuMP
using SAIMOpt

model = Model(SAIM.Optimizer)

@variable(model, x[1:5], Bin)
@variable(model, -2 <= y[1:5] <= 2)

@objective(model, Max, sum(x) - sum(y) + 2 * x'y)

optimize!(model)
```
"""
mutable struct Optimizer{T} <: MOI.AbstractOptimizer
    sense::SAIM.Direction

    quadratic::Matrix{T}
    linear::Union{Vector{T},Nothing}
    offset::T
    continuous::Union{Vector{Bool},Nothing}

    moi_attributes::Dict{Symbol,Any}
    raw_attributes::Dict{String,Any}
    aim_attributes::Dict{Symbol,Any}

    variable_map::Dict{VI,Int}
    variable_info::Dict{VI,Variable{T}}

    output::Union{Dict{String,Any},Nothing}

    function Optimizer{T}() where {T}
        return new{T}(
            SAIM.Minimization,      # sense
            Matrix{T}(undef, 0, 0), # quadratic
            nothing,                # linear
            zero(T),                # offset
            nothing,                # continuous
            Dict{Symbol,Any}( # moi - default
                :name           => "",
                :silent         => false,
                :time_limit_sec => nothing,
            ),
            Dict{String,Any}(),
            Dict{Symbol,Any}( # aim - default
                :seed => 0,
            ),
            Dict{VI,Int}(),         # variable_map
            Dict{VI,Variable{T}}(), # variable_info
            nothing,
        )
    end

    Optimizer() = Optimizer{Float64}()
end

function MOI.empty!(optimizer::Optimizer{T}) where {T}
    optimizer.quadratic  = Matrix{T}(undef, 0, 0)
    optimizer.linear     = nothing
    optimizer.offset     = zero(T)
    optimizer.continuous = nothing
    optimizer.output     = nothing

    Base.empty!(optimizer.variable_map)

    return optimizer
end

function MOI.is_empty(optimizer::Optimizer{T}) where {T}
    return isempty(optimizer.quadratic) &&
           isnothing(optimizer.linear) &&
           isnothing(optimizer.continuous) &&
           iszero(optimizer.offset) &&
           isempty(optimizer.variable_map)
end

function Base.show(io::IO, ::Optimizer)
    return print(io, "SAIM Optimizer")
end

include("attributes.jl")
include("objective.jl")
include("constraints.jl")
include("solutions.jl")

function MOI.copy_to(optimizer::Optimizer{T}, model::MOI.ModelLike) where {T}
    index_map = MOIU.IndexMap()
    variables = Dict{VI,Variable{T}}()

    # Parse model
    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if !MOI.supports_constraint(optimizer, F, S)
            error("Unsupported constraint type: $F ∈ $S")
        end
    end

    # Binary Variables
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.ZeroOne}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI

        variables[vi] = Variable{T}(:binary)

        index_map[ci] = ci
    end

    # Intervals
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.Interval{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::MOI.Interval{T}

        @assert !haskey(variables, vi) || variables[vi].type === :continuous

        variables[vi] = Variable{T}(:continuous; lower = si.lower, upper = si.upper)
        index_map[ci] = ci
    end

    # Lower Bounds
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,GT{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::GT{T}

        @assert !haskey(variables, vi) || variables[vi].type === :continuous

        variables[vi] = if haskey(variables, vi)
            Variable{T}(:continuous; lower = si.lower, upper = variables[vi].upper)
        else
            Variable{T}(:continuous; lower = si.lower)
        end

        index_map[ci] = ci
    end

    # Upper Bounds
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,LT{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::LT{T}

        @assert !haskey(variables, vi) || variables[vi].type === :continuous

        variables[vi] = if haskey(variables, vi)
            Variable{T}(:continuous; lower = variables[vi].lower, upper = si.upper)
        else
            Variable{T}(:continuous; upper = si.upper)
        end

        index_map[ci] = ci
    end

    for vi in MOI.get(model, MOI.ListOfVariableIndices())
        @assert haskey(variables, vi) && is_bounded(variables[vi]) "Unbounded variable $(vi)"

        index_map[vi] = vi
    end

    variable_inv = sort!(collect(keys(variables)); by = (v -> v.value))         # Int -> VI
    variable_map = Dict{VI,Int}(vi => i for (i, vi) in enumerate(variable_inv)) # VI  -> Int

    optimizer.variable_map = variable_map

    n = length(variable_inv)

    optimizer.continuous = Vector{Bool}(undef, n)

    for (i, vi) in enumerate(variable_inv)
        optimizer.continuous[i] = variables[vi].type === :continuous
    end

    # Parse objective
    let F = MOI.get(model, MOI.ObjectiveFunctionType())
        f = MOI.get(model, MOI.ObjectiveFunction{F}())

        quadratic, linear, offset = _parse_objective(f, variable_map, variables)

        optimizer.quadratic = quadratic
        optimizer.linear    = linear
        optimizer.offset    = offset
    end

    return index_map
end

function _parse_objective(vi::VI, vmap::Dict{VI,Int}, info::Dict{VI,Variable{T}}) where {T}
    n = length(vmap)

    quadratic = zeros(T, n, n)
    linear    = zeros(T, n)
    offset    = zero(T)

    linear[vmap[vi]] = 1.0

    return (quadratic, linear, offset)
end

function _add_scaled_variable!(
    ℓ::Vector{T},
    c::Ref{T},
    i::Integer,
    l::T,
    u::T,
    a::T,
) where {T}
    α = u + l
    β = u - l

    ℓ[i] += 2 * a / β
    c[]  -= α * a / β

    return nothing
end

function _add_scaled_variable!(
    Q::Matrix{T},
    ℓ::Vector{T},
    c::Ref{T},
    i::Integer,
    li::T,
    ui::T,
    j::Integer,
    lj::T,
    uj::T,
    aij::T,
) where {T}
    αi = ui + li
    αj = uj + lj

    βij = (ui - li) * (uj - lj)

    if i == j
        Q[i, j] += 2 * aij / βij
    else
        Q[i, j] += 4 * aij / βij
    end

    ℓ[i] -= 2 * aij * αj / βij
    ℓ[j] -= 2 * aij * αi / βij

    c[] += aij * αi * αj / βij

    return nothing

end

function _parse_objective(
    f::SAF{T},
    vmap::Dict{VI,Int},
    info::Dict{VI,Variable{T}},
) where {T}
    n = length(vmap)

    quadratic = zeros(T, n, n)
    linear    = zeros(T, n)
    offset    = Ref{T}(f.constant)

    for term in f.terms
        vi = term.variable

        _add_scaled_variable!(
            linear,
            offset,
            vmap[vi],
            info[vi].lower,
            info[vi].upper,
            term.coefficient,
        )
    end

    return (quadratic, linear, offset)
end

function _parse_objective(
    f::SQF{T},
    vmap::Dict{VI,Int},
    info::Dict{VI,Variable{T}},
) where {T}
    n = length(vmap)

    quadratic = zeros(T, n, n)
    linear    = zeros(T, n)
    offset    = f.constant

    for term in f.affine_terms
        vi = term.variable

        _add_scaled_variable!(
            linear,
            offset,
            vmap[vi],
            info[vi].lower,
            info[vi].upper,
            term.coefficient,
        )
    end

    for term in f.quadratic_terms
        vi = term.variable_1
        vj = term.variable_2

        _add_scaled_variable!(
            quadratic,
            linear,
            offset,
            vmap[vi],
            info[vi].lower,
            info[vi].upper,
            vmap[vj],
            info[vj].lower,
            info[vj].upper,
            term.coefficient,
        )
    end

    return (quadratic, linear, offset)
end

function MOI.optimize!(optimizer::Optimizer{T}) where {T}
    seed       = something(MOI.get(optimizer, SAIMOpt.Seed()), trunc(Int, time()))
    time_limit = trunc(Int, something(MOI.get(optimizer, MOI.TimeLimitSec()), 10.0))
    work_dir   = MOI.get(optimizer, SAIMOpt.WorkDir())

    optimizer.output = SAIM.API.SolverAPI.compute_qumo(
        optimizer.sense,
        optimizer.quadratic,
        optimizer.linear,
        optimizer.continuous,
        seed,
        time_limit;
        work_dir,
    )

    return nothing
end
