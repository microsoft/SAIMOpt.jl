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

    fixed::Dict{VI,T}

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
            Dict{VI,T}(),           # fixed variables
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
    Base.empty!(optimizer.variable_info)
    Base.empty!(optimizer.fixed)

    return optimizer
end

function MOI.is_empty(optimizer::Optimizer{T}) where {T}
    return isempty(optimizer.quadratic)     &&
           isnothing(optimizer.linear)      &&
           isnothing(optimizer.continuous)  &&
           iszero(optimizer.offset)         &&
           isempty(optimizer.variable_map)  &&
           isempty(optimizer.variable_info) &&
           isempty(optimizer.fixed)
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

    # Copy attributes
    for attr in MOI.get(model, MOI.ListOfModelAttributesSet())
        if MOI.supports(optimizer, attr)
            MOI.set(optimizer, attr, MOI.get(model, attr))
        else
            throw(MOI.UnsupportedAttribute(attr))
        end
    end

    for attr in MOI.get(model, MOI.ListOfOptimizerAttributesSet())
        if MOI.supports(optimizer, attr)
            MOI.set(optimizer, attr, MOI.get(model, attr))
        else
            throw(MOI.UnsupportedAttribute(attr))
        end
    end

    # Copy variable attributes
    for attr in MOI.get(model, MOI.ListOfVariableAttributesSet())
        if MOI.supports(optimizer, attr, VI)
            for vi in MOI.get(model, MOI.ListOfVariablesWithAttributeSet(attr))
                MOI.set(optimizer, attr, vi, MOI.get(model, attr, vi))
            end
        else
            throw(MOI.UnsupportedAttribute(attr))
        end
    end

    # Copy constraint attributes
    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        for attr in MOI.get(model, MOI.ListOfConstraintAttributesSet{F,S}())
            if MOI.supports(optimizer, attr, CI{F,S})
                for ci in MOI.get(model, MOI.ListOfConstraintsWithAttributeSet{F,S}(attr))
                    MOI.set(optimizer, attr, ci, MOI.get(model, attr, ci))
                end
            else
                throw(MOI.UnsupportedAttribute(attr))
            end
        end
    end

    # Parse model
    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if !MOI.supports_constraint(optimizer, F, S)
            error("Unsupported constraint type: $F ∈ $S")
        end
    end

    # Binary Variables
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.ZeroOne}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI

        optimizer.variable_info[vi] = Variable{T}(:binary)

        index_map[ci] = ci
    end

    # Intervals
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.Interval{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::MOI.Interval{T}

        @assert !haskey(optimizer.variable_info, vi) || optimizer.variable_info[vi].type === :continuous

        optimizer.variable_info[vi] = Variable{T}(:continuous; lower = si.lower, upper = si.upper)
        index_map[ci] = ci
    end

    # Lower Bounds
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,GT{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::GT{T}

        @assert !haskey(optimizer.variable_info, vi) || optimizer.variable_info[vi].type === :continuous || si.lower <= zero(T)

        optimizer.variable_info[vi] = if haskey(optimizer.variable_info, vi)
            Variable{T}(:continuous; lower = si.lower, upper = optimizer.variable_info[vi].upper)
        else
            Variable{T}(:continuous; lower = si.lower)
        end

        index_map[ci] = ci
    end

    # Upper Bounds
    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,LT{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::LT{T}

        @assert !haskey(optimizer.variable_info, vi) || optimizer.variable_info[vi].type === :continuous || si.upper >= one(T)

        optimizer.variable_info[vi] = if haskey(optimizer.variable_info, vi)
            Variable{T}(:continuous; lower = optimizer.variable_info[vi].lower, upper = si.upper)
        else
            Variable{T}(:continuous; upper = si.upper)
        end

        index_map[ci] = ci
    end

    for vi in MOI.get(model, MOI.ListOfVariableIndices())
        @assert haskey(optimizer.variable_info, vi) && is_bounded(optimizer.variable_info[vi]) "Unbounded variable $(vi)"

        index_map[vi] = vi
    end

    for ci in MOI.get(model, MOI.ListOfConstraintIndices{VI,EQ{T}}())
        vi = MOI.get(model, MOI.ConstraintFunction(), ci)::VI
        si = MOI.get(model, MOI.ConstraintSet(), ci)::EQ{T}

        if !haskey(optimizer.variable_info, vi)
            optimizer.variable_info[vi] = Variable{T}(:continuous; lower = si.value, upper = si.value)
        end

        optimizer.fixed[vi] = si.value
    end

    # Fixed variables are not included in the variable list, so they won't get an index
    variable_list = sort!(
        filter(vi -> !haskey(optimizer.fixed, vi), collect(keys(optimizer.variable_info)));
        by = (vi -> vi.value)
    )

    optimizer.variable_map  = Dict{VI,Int}(vi => i for (i, vi) in enumerate(variable_list))
    optimizer.continuous    = [optimizer.variable_info[vi].type === :continuous for vi in variable_list]

    # Parse objective
    let F = MOI.get(model, MOI.ObjectiveFunctionType())
        f = MOI.get(model, MOI.ObjectiveFunction{F}())

        quadratic, linear, offset = _parse_objective(
            f,
            optimizer.variable_map,
            optimizer.variable_info,
            optimizer.fixed,
        )

        optimizer.quadratic = quadratic
        optimizer.linear    = linear
        optimizer.offset    = offset[]
    end

    return index_map
end

function _parse_objective(vi::VI, vmap::Dict{VI,Int}, ::Dict{VI,Variable{T}}, fixed::Dict{VI,T}) where {T}
    n = length(vmap)

    quadratic = zeros(T, n, n)
    linear    = zeros(T, n)
    offset    = Ref{T}(zero(T))

    if haskey(fixed, vi)
        offset[] += fixed[vi]
    else
        linear[vmap[vi]] = 1.0
    end

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
    fixed::Dict{VI,T},
) where {T}
    n = length(vmap)

    quadratic = zeros(T, n, n)
    linear    = zeros(T, n)
    offset    = Ref{T}(f.constant)

    for term in f.terms
        vi = term.variable

        if haskey(fixed, vi)
            offset[] += fixed[vi] * term.coefficient
        else
            _add_scaled_variable!(
                linear,
                offset,
                vmap[vi],
                info[vi].lower,
                info[vi].upper,
                term.coefficient,
            )
        end
    end

    return (quadratic, linear, offset)
end

function _parse_objective(
    f::SQF{T},
    vmap::Dict{VI,Int},
    info::Dict{VI,Variable{T}},
    fixed::Dict{VI,T},
) where {T}
    n = length(vmap)

    quadratic = zeros(T, n, n)
    linear    = zeros(T, n)
    offset    = Ref{T}(f.constant)

    for term in f.affine_terms
        vi = term.variable

        if haskey(fixed, vi)
            offset[] += fixed[vi] * term.coefficient
        else
            _add_scaled_variable!(
                linear,
                offset,
                vmap[vi],
                info[vi].lower,
                info[vi].upper,
                term.coefficient,
            )
        end
    end

    for term in f.quadratic_terms
        vi = term.variable_1
        vj = term.variable_2

        if haskey(fixed, vi) && haskey(fixed, vj)
            offset[] += fixed[vi] * fixed[vj] * term.coefficient
        elseif haskey(fixed, vj)
            _add_scaled_variable!(
                linear,
                offset,
                vmap[vi],
                info[vi].lower,
                info[vi].upper,
                term.coefficient * fixed[vj],
            )
        elseif haskey(fixed, vi)
            _add_scaled_variable!(
                linear,
                offset,
                vmap[vj],
                info[vj].lower,
                info[vj].upper,
                term.coefficient * fixed[vi],
            )
        else
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
