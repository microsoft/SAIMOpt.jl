module SAIMOpt

import TOML
import SAIM
import MathOptInterface as MOI
import MathOptInterface: is_empty, empty!, optimize!

const __PROJECT__ = abspath(@__DIR__, "..")
const __VERSION__ = get(TOML.parsefile(joinpath(__PROJECT__, "Project.toml")), "version", nothing)

const MOIU    = MOI.Utilities
const VI      = MOI.VariableIndex
const CI{S,F} = MOI.ConstraintIndex{S,F}
const EQ{T}   = MOI.EqualTo{T}
const LT{T}   = MOI.LessThan{T}
const GT{T}   = MOI.GreaterThan{T}
const SAT{T}  = MOI.ScalarAffineTerm{T}
const SAF{T}  = MOI.ScalarAffineFunction{T}
const SQT{T}  = MOI.ScalarQuadraticTerm{T}
const SQF{T}  = MOI.ScalarQuadraticFunction{T}

include("MOI_wrapper/MOI_wrapper.jl")

end # module SAIMOpt
