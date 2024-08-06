#=
random_assignment.jl

A simple "solver" for a QUMO problem that randomly assigns values to the variables.
It can be used for testing and debugging.
=#

using Random

struct RandomAssignment <: SAIMBackend end

function SAIMOpt.solve!(::RandomAssignment, optimizer::SAIMOpt.Optimizer{T}) where {T}
    seed = optimizer.aim_attributes[:seed]
    if seed === nothing || seed == 0
        seed = rand(1:1000)
        @info "RandomAssignment: No seed provided. Using $seed"
    end

    rng = Random.Xoshiro(seed)

    number_of_variables = length(optimizer.variable_map)
    assignment = zeros(T, number_of_variables)

    for (var, i) in optimizer.variable_map
        var_type = optimizer.variable_info[var]

        if var_type.type == :binary
            assignment[i] = T(rand(rng, 0:1))
        else
            # Observe that the values here are expected to be in the range [-1, 1],
            # and not on the range of the variable itself.
            random_value = 2.0 * rand(rng) - 1
            assignment[i] = T(random_value)
        end
    end

    quadratic = Symmetric(optimizer.quadratic)
    objective = T(0.5) * assignment' * quadratic * assignment + optimizer.linear' * assignment + optimizer.offset

    # @show quadratic

    output = Dict(
            "Objective"  => T(objective),
            "Assignment" => assignment,
        )

    optimizer.output = output

    return nothing
end
