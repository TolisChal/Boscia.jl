using Boscia
using FrankWolfe
using Random
using HiGHS
using LinearAlgebra
import MathOptInterface

const MOI = MathOptInterface

n = 6

Q = rand(n,n)
Q = Q'*Q
u = rand(n)

x = solve_quadratic_convex(Q, u)

println("sol: ", x)
pritln("value: ", x'*Q*x)

