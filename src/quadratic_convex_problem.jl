Base.@ccallable function solve_quadratic_convex2(Qp::Ptr{Cdouble}, up::Ptr{Cdouble}, len::Csize_t)::Ptr{Cdouble}

    Q = unsafe_wrap(Matrix{Float64}, Qp, (len,len))
    u = unsafe_wrap(Vector{Float64}, up, (len,))

    function f(x::Vector{Float64})
        return dot(x, Q, x) + dot(u, x)
    end
    function grad!(storage, x::Vector{Float64})
        storage = Q*x .+ u
        return storage
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
    
    y, _, result = Boscia.solve(f, grad!, lmo, verbose=true)
    
    return pointer(y)
end