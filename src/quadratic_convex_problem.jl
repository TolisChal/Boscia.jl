function solve_quadratic_convex(Q::Matrix{Float64}, u::Vector{Float64})

    function f(x::Vector{Float64})
        return dot(x, Q, x) + dot(u, x)
    end
    function grad!(storage, x::Vector{Float64})
        @. storage = Q*x .+ u
    end

    n = length(u)

    o = HiGHS.Optimizer()
    MOI.set(o, MOI.Silent(), true)

    x = MOI.add_variables(o, n)

    for xi in x
        MOI.add_constraint(o, xi, MOI.GreaterThan(0.0))
        MOI.add_constraint(o, xi, MOI.LessThan(1.0))
        MOI.add_constraint(o, xi, MOI.ZeroOne())
    end
    lmo = FrankWolfe.MathOptLMO(o)

    y, _, result = solve(f, grad!, lmo, verbose=true)

    return y
end