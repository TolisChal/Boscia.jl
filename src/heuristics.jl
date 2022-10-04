
"""
Finds the best solution in the SCIP solution storage, based on the objective function `f`.
Returns the solution vector and the corresponding best value.
"""
#import HiGHS

function find_best_solution(f::Function, o::SCIP.Optimizer, vars::Vector{MOI.VariableIndex})
    #println("vars: ")
    #for var in vars
    #    #println(var)
    #end
    sols_vec =
        unsafe_wrap(Vector{Ptr{Cvoid}}, SCIP.LibSCIP.SCIPgetSols(o), SCIP.LibSCIP.SCIPgetNSols(o))
    #println(sols_vec)
    best_val = Inf
    best_v = nothing
    #println("sols: ")
    for sol in sols_vec
        #println(sol)
        v = SCIP.sol_values(o, vars, sol)
        #println(v)
        val = f(v)
        #println(val)
        if val < best_val
            best_val = val
            best_v = v
        end
    end
    println(best_v)
    println(best_val)
    println("-------------SCIP--------------\n")
    @assert isfinite(best_val)
    return (best_v, best_val)
end

function find_best_solution(f::Function, o::HiGHS.Optimizer, vars::Vector{MOI.VariableIndex})
    println(Highs_getNumCol(o))
    col_value = Vector{Float64}(undef, 6)
    col_dual = Vector{Float64}(undef, 6)
    row_value = Vector{Float64}(undef, 6)
    row_dual = Vector{Float64}(undef, 6)
    HiGHS.Highs_getSolution(o, col_value, Vector{Ptr{Cvoid}}, Vector{Ptr{Cvoid}}, Vector{Ptr{Cvoid}})
    println(col_value)
    #println(col_dual)
    #println(row_value)
    #println(row_dual)
    best_val = f(col_value)
    best_v = col_value
    println(best_val)
    #sols_vec =
    #    unsafe_wrap(Vector{Ptr{Cvoid}}, SCIP.LibSCIP.SCIPgetSols(o), SCIP.LibSCIP.SCIPgetNSols(o))
    #println(sols_vec)
    #best_val = 7.5
    #best_v = nothing
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
    println("------------HiGHS---------------\n")
    #@assert isfinite(best_val)
    return (best_v, best_val)
end