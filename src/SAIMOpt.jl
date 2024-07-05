module SAIMOpt

import TOML
import SAIM
import MathOptInterface as MOI
import MathOptInterface: is_empty, empty!, optimize!
import PythonCall

# const azure_identity = PythonCall.pynew()
const pyaimopt = PythonCall.pynew()

function __init__()
    # PythonCall.pycopy!(azure_identity, PythonCall.pyimport("azure.identity"))
    PythonCall.pycopy!(pyaimopt, PythonCall.pyimport("pyaimopt"))

    return nothing
end

using LinearAlgebra

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

include("variables/variables.jl")
include("MOI_wrapper/MOI_wrapper.jl")

end # module SAIMOpt
