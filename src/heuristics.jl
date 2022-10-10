
"""
Finds the best solution in the SCIP solution storage, based on the objective function `f`.
Returns the solution vector and the corresponding best value.
"""
function find_best_solution(f::Function, o::SCIP.Optimizer, vars::Vector{MOI.VariableIndex})
    sols_vec =
        unsafe_wrap(Vector{Ptr{Cvoid}}, SCIP.LibSCIP.SCIPgetSols(o), SCIP.LibSCIP.SCIPgetNSols(o))
    best_val = Inf
    best_v = nothing
    for sol in sols_vec
        println(sol)
        println(vars)
        v = SCIP.sol_values(o, vars, sol)
        print(v)
        val = f(v)
        if val < best_val
            best_val = val
            best_v = v
        end
    end
    @assert isfinite(best_val)
    return (best_v, best_val)
end

"""
Finds the best solution in the HiGHS solution storage, based on the objective function `f`.
Returns the solution vector and the corresponding best value.
"""
function find_best_solution(f::Function, o::HiGHS.Optimizer, vars::Vector{MOI.VariableIndex})
    println("-------------------")
    for var in vars
        println(var)
    end
    println(vars)
    ncol = Highs_getNumCol(o)
    nrow = Highs_getNumRow(o)
    println("ncol = ", ncol)
    
    col_value = Vector{Float64}(undef, ncol)
    col_dual = Vector{Float64}(undef, ncol)
    row_value = Vector{Float64}(undef, nrow)
    row_dual = Vector{Float64}(undef, nrow)

    println(vars)
    println("\n")
    ordered_indices = [MathOptInterface.VariableIndex(j) for j in 1:ncol]
    println(ordered_indices)
    println("\n")
    indices = [i[1][2] for i in [findall( x -> x == ordered_indices[j], vars) for j in 1:ncol]]
    println(indices)
    col_value = col_value[indices]
    println("-------------------")

    HiGHS.Highs_getSolution(o, col_value, col_dual, row_value, row_dual)
    val = f(col_value)
    best_v = col_value
    
    @assert isfinite(val)
    return (col_value, val)
end
