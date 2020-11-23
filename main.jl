include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
include("ctx.jl")
include("semantics.jl")
include("codegen.jl")

"""
TODO : Booleans (either create new expression / modify AST within exp_resolve!)
"""

# --- Main ---
# # Test #1 : Declarations, args, return
# """
# main(a, x) {
#     let a = 42
#     let b = 2
#     let c = a + b + x

#     return c
# }
# """
# main_body = stmt_newblock()

# let_a = decl_newint("a", exp_newint(42))
# push!(main_body.stmts, stmt_newdecl(let_a))

# let_b = decl_newint("b", exp_newint(2))
# push!(main_body.stmts, stmt_newdecl(let_b))

# sum_ab = exp_newadd(exp_newid("a"), exp_newid("b"))
# let_c = decl_newint("c", exp_newadd(sum_ab, exp_newid("x")))
# push!(main_body.stmts, stmt_newdecl(let_c))

# ret_c = stmt_newreturn(exp_newid("c"))
# push!(main_body.stmts, ret_c)

# main_args = [arg_new("a"), arg_new("x")]
# main_fn = decl_new(type_newfn(main_args), "main", body=main_body)

# # Test #2 : Declarations, args, return, control flow
# """
# main(a) {
#     # if a != 0
#     test a > 2
#         | true -> a = 0
#         | false -> a = 42

#     return a
# }
# """
# main_body = stmt_newblock()

# set_a_0 = exp_newset(exp_newid("a"), exp_newint(0))
# set_a_42 = exp_newset(exp_newid("a"), exp_newint(42))
# test_a = exp_newtest(exp_newid("a"), ">", exp_newint(2))
# control = stmt_newifelse(test_a,
#                         stmt_newexp(set_a_0),
#                         stmt_newexp(set_a_42))
# push!(main_body.stmts, control)

# ret = stmt_newreturn(exp_newid("a"))
# push!(main_body.stmts, ret)

# main_args = [arg_new("a")]
# main_fn = decl_new(type_newfn(main_args), "main", body=main_body)

# Test #3 : Loop
"""
main()
    -> for (let i = 1; i <= 42; i = i + 2)
        let a = 2;
"""
# TODO : mul
init = stmt_newdecl(decl_newint("i", exp_newint(1)))
condition = exp_newtest(exp_newid("i"), "<=", exp_newint(42))
iter = stmt_newexp(exp_newset(exp_newid("i"), exp_newadd(exp_newid("i"), exp_newint(2))))
let_a = stmt_newdecl(decl_newint("a", exp_newint(2)))

main_body = stmt_newloop(init, condition, iter, let_a)

main_args = []
main_fn = decl_new(type_newfn(main_args), "main", body=main_body)

# --- Entry ---
ctx = ctx_new()

# Parsing
push!(ctx.decls, main_fn)

semanticanalysis!(ctx)

# println(let_c.type)
# println(let_c.value.right)
# println(main_fn.nlocals)
# println(main_fn.type.args)

println(codegen!(ctx))
