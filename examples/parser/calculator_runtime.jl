include("calculator.yy.jl")

src = "2 x (5 + 3) + 2 * 2"

println("---")
result = parse(src)
println("Result : $result")
