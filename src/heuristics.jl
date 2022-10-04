
"""
Finds the best solution in the SCIP solution storage, based on the objective function `f`.
Returns the solution vector and the corresponding best value.
"""
using HiGHS

function find_best_solution2(f::Function, o::SCIP.Optimizer, vars::Vector{MOI.VariableIndex})
    println("vars: ")
    for var in vars
        println(var)
    end
    sols_vec =
        unsafe_wrap(Vector{Ptr{Cvoid}}, SCIP.LibSCIP.SCIPgetSols(o), SCIP.LibSCIP.SCIPgetNSols(o))
    #println(sols_vec)
    best_val = Inf
    best_v = nothing
    println("sols: ")
    for sol in sols_vec
        println(sol)
        v = SCIP.sol_values(o, vars, sol)
        println(v)
        val = f(v)
        println(val)
        if val < best_val
            best_val = val
            best_v = v
        end
    end
    println("---------------------------\n")
    @assert isfinite(best_val)
    return (best_v, best_val)
end

function find_best_solution(f::Function, o, vars::Vector{MOI.VariableIndex})

    col_value = Vector{Float64}(undef, 6)
    col_dual = Vector{Float64}(undef, 6)
    row_value = Vector{Float64}(undef, 6)
    row_dual = Vector{Float64}(undef, 6)
    Highs_getSolution(o, col_value, col_dual, row_value, row_dual)
    println(col_value)
    println(col_dual)
    println(row_value)
    println(row_dual)
    #sols_vec =
    #    unsafe_wrap(Vector{Ptr{Cvoid}}, SCIP.LibSCIP.SCIPgetSols(o), SCIP.LibSCIP.SCIPgetNSols(o))
    #println(sols_vec)
    best_val = Inf
    best_v = nothing
    #println("sols: ")
    #for sol in sols_vec
    #    println(sol)
    #    v = SCIP.sol_values(o, vars, sol)
    #    println(v)
    #    val = f(v)
    #    println(val)
    #    if val < best_val
    #        best_val = val
    #        best_v = v
    #    end
    #end
    println("---------------------------\n")
    #@assert isfinite(best_val)
    return (best_v, best_val)
end