include("error.jl")
include("ast_def.jl")
include("ctx_def.jl")
include("alphalib.jl")
include("ast.jl")
include("ctx.jl")
include("semantics.jl")
include("codegen.jl")
include("cli.jl")

# Generated by parser.syntax
include("parser.yy.jl")

#=
# TODO Zone
# # alphalib
# - Check main defined
# - Can't define alphalib functions in alpha
=#

alphamain() = climain(ARGS)
