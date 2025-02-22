using LinearAlgebra
using Distributions
import Random
using SCIP
import MathOptInterface
const MOI = MathOptInterface
import Boscia
import FrankWolfe

# Testing of the interface function solve

n = 20
diffi = Random.rand(Bool, n) * 0.6 .+ 0.3

@testset "Interface - norm hyperbox" begin
    o = SCIP.Optimizer()
    MOI.set(o, MOI.Silent(), true)
    MOI.empty!(o)
    x = MOI.add_variables(o, n)
    for xi in x
        MOI.add_constraint(o, xi, MOI.GreaterThan(0.0))
        MOI.add_constraint(o, xi, MOI.LessThan(1.0))
        MOI.add_constraint(o, xi, MOI.ZeroOne()) # or MOI.Integer()
    end
    lmo = FrankWolfe.MathOptLMO(o)

    function f(x)
        return sum(0.5 * (x .- diffi) .^ 2)
    end
    function grad!(storage, x)
        @. storage = x - diffi
    end

    x, _, result = Boscia.solve(f, grad!, lmo, verbose=false)

    @test x == round.(diffi)
    @test f(x) == f(result[:raw_solution])
end


# min h(sqrt(y' * M * y)) - r' * y
# s.t. a' * y <= b 
#           y >= 0
#           y_i in Z for i in I

n = 10
const ri = rand(n)
const ai = rand(n)
const Ωi = rand(Float64)
const bi = sum(ai)
Ai = randn(n, n)
Ai = Ai' * Ai
const Mi = (Ai + Ai') / 2
@assert isposdef(Mi)
#=
@testset "Interface - Buchheim et. al." begin
    o = SCIP.Optimizer()
    MOI.set(o, MOI.Silent(), true)
    MOI.empty!(o)
    x = MOI.add_variables(o,n)
    I =  rand(1:n, Int64(floor(n/2)))  #collect(1:n)
    for i in 1:n
        MOI.add_constraint(o, x[i], MOI.GreaterThan(0.0))
        if i in I
            MOI.add_constraint(o, x[i], MOI.Integer())
        end
    end 
    MOI.add_constraint(o, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(ai,x), 0.0), MOI.LessThan(bi))
    #MOI.add_constraint(o, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(ai,x), 0.0), MOI.GreaterThan(minimum(ai)))
    MOI.add_constraint(o, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(ones(n),x), 0.0), MOI.GreaterThan(1.0))
    lmo = FrankWolfe.MathOptLMO(o)

    function h(x)
        return Ωi
    end
    function f(x)
        return h(x) * (x' * Mi * x) - ri' * x
    end
    function grad!(storage, x)
        storage.= 2 * Mi * x - ri
        return storage
    end

    x, _,result = Boscia.solve(f, grad!, lmo, verbose = true)

    @test sum(ai'* x) <= bi + 1e-3
    @test f(x) <= f(result[:raw_solution])
end
=#

# Sparse Poisson regression
# min_{w, b, z} ∑_i exp(w x_i + b) - y_i (w x_i + b) + α norm(w)^2
# s.t. -N z_i <= w_i <= N z_i
# b ∈ [-N, N]
# ∑ z_i <= k 
# z_i ∈ {0,1} for i = 1,..,p

n = 30
p = n

# underlying true weights
const ws = rand(Float64, p)
# set 50 entries to 0
for _ in 1:20
    ws[rand(1:p)] = 0
end
const bs = rand(Float64)
const Xs = randn(Float64, n, p)
const ys = map(1:n) do idx
    a = dot(Xs[idx, :], ws) + bs
    return rand(Distributions.Poisson(exp(a)))
end
Ns = 0.1

@testset "Interface - sparse poisson regression" begin
    k = 10
    o = SCIP.Optimizer()
    MOI.set(o, MOI.Silent(), true)
    w = MOI.add_variables(o, p)
    z = MOI.add_variables(o, p)
    b = MOI.add_variable(o)
    for i in 1:p
        MOI.add_constraint(o, z[i], MOI.GreaterThan(0.0))
        MOI.add_constraint(o, z[i], MOI.LessThan(1.0))
        MOI.add_constraint(o, z[i], MOI.ZeroOne())
    end
    for i in 1:p
        MOI.add_constraint(o, -Ns * z[i] - w[i], MOI.LessThan(0.0))
        MOI.add_constraint(o, Ns * z[i] - w[i], MOI.GreaterThan(0.0))
        # Indicator: z[i] = 1 => -N <= w[i] <= N
        gl = MOI.VectorAffineFunction(
            [
                MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, z[i])),
                MOI.VectorAffineTerm(2, MOI.ScalarAffineTerm(1.0, w[i])),
            ],
            [0.0, 0.0],
        )
        gg = MOI.VectorAffineFunction(
            [
                MOI.VectorAffineTerm(1, MOI.ScalarAffineTerm(1.0, z[i])),
                MOI.VectorAffineTerm(2, MOI.ScalarAffineTerm(-1.0, w[i])),
            ],
            [0.0, 0.0],
        )
        MOI.add_constraint(o, gl, MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.LessThan(Ns)))
        MOI.add_constraint(o, gg, MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.LessThan(-Ns)))
    end
    MOI.add_constraint(o, sum(z, init=0.0), MOI.LessThan(1.0 * k))
    MOI.add_constraint(o, sum(z, init=0.0), MOI.GreaterThan(1.0))
    MOI.add_constraint(o, b, MOI.LessThan(Ns))
    MOI.add_constraint(o, b, MOI.GreaterThan(-Ns))
    lmo = FrankWolfe.MathOptLMO(o)

    α = 1.3
    function f(θ)
        w = @view(θ[1:p])
        b = θ[end]
        s = sum(1:n) do i
            a = dot(w, Xs[:, i]) + b
            return 1 / n * (exp(a) - ys[i] * a)
        end
        return s + α * norm(w)^2
    end
    function grad!(storage, θ)
        w = @view(θ[1:p])
        b = θ[end]
        storage[1:p] .= 2α .* w
        storage[p+1:2p] .= 0
        storage[end] = 0
        for i in 1:n
            xi = @view(Xs[:, i])
            a = dot(w, xi) + b
            storage[1:p] .+= 1 / n * xi * exp(a)
            storage[1:p] .-= 1 / n * ys[i] * xi
            storage[end] += 1 / n * (exp(a) - ys[i])
        end
        storage ./= norm(storage)
        return storage
    end

    x, _, result = Boscia.solve(f, grad!, lmo, verbose=true)

    @test sum(x[p+1:2p]) <= k
    @test f(x) <= f(result[:raw_solution])
end
