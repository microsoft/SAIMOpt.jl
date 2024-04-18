struct Variable{T}
    type::Symbol
    lower::Union{T,Nothing}
    upper::Union{T,Nothing}

    function Variable{T}(type::Symbol; lower::Union{T,Nothing} = nothing, upper::Union{T,Nothing} = nothing) where T
        @assert type ∈ (:continuous, :binary)

        if type === :binary
            @assert isnothing(lower) && isnothing(upper)

            lower = zero(T)
            upper = one(T)
        else # type === :continuous
            if !isnothing(lower) && !isnothing(upper)
                @assert lower <= upper
            end
        end

        return new{T}(type, lower, upper)
    end
end

function is_bounded(v::Variable)
    return !isnothing(v.lower) && !isnothing(v.upper)
end
