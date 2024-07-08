function MOI.get(optimizer::Optimizer, ::MOI.ObjectiveSense)
    return optimizer.sense
end

function MOI.set(optimizer::Optimizer, ::MOI.ObjectiveSense, value::MOI.OptimizationSense)
    @assert value in (MOI.MAX_SENSE, MOI.MIN_SENSE)

    optimizer.sense = value

    return nothing
end

function MOI.supports(::Optimizer, ::MOI.ObjectiveSense)
    return true
end

function MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{VI})
    return true
end

function MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{F}) where {T,F<:Union{SAF{T},SQF{T}}}
    return true
end
