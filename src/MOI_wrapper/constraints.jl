function MOI.supports_constraint(
    ::Optimizer,
    ::Type{VI},
    ::Type{MOI.ZeroOne},
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer{T},
    ::Type{VI},
    ::Type{F},
) where {T,F<:Union{EQ{T},LT{T},GT{T},MOI.Interval{T}}}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{S},
    ::Type{F},
) where {S<:MOI.AbstractSet,F<:MOI.AbstractFunction}
    return false
end
