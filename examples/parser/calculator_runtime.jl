# include("parser.yy.jl")
include("calculator.yy.jl")

src = "2 x (5 + 3) + 2 x 2"

println("---")
result = parse(src)
println("Result : $result")
