function MOI.get(optimizer::Optimizer, ::MOI.ObjectiveSense)
    if optimizer.sense === SAIM.Minimization
        return MOI.MIN_SENSE
    else # optimizer.sense === SAIM.Maximization
        return MOI.MAX_SENSE
    end
end

function MOI.set(optimizer::Optimizer, ::MOI.ObjectiveSense, value::MOI.OptimizationSense)
    @assert value in (MOI.MAX_SENSE, MOI.MIN_SENSE)

    if value === MOI.MIN_SENSE
        optimizer.sense = SAIM.Minimization
    else # value === MOI.MAX_SENSE
        optimizer.sense = SAIM.Maximization
    end

    return nothing
end

function MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{VI})
    return true
end

function MOI.supports(::Optimizer, ::MOI.ObjectiveFunction{F}) where {T,F<:Union{SAF{T},SQF{T}}}
    return true
end
