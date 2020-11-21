include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
# include("codegen.jl")

ctx = ctx_new()
ctx_newsymglobal!(ctx, t_int, "a")

println(ctx.scopes[1])
