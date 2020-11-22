include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
include("ctx.jl")
include("semantics.jl")
include("codegen.jl")

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

# Test #2 : Declarations, args, return, control flow
"""
main(a) {
    # if a != 0
    test a
        | true -> a = 0
        | false -> a = 42

    return a
}
"""
main_body = stmt_newblock()

# let_a = decl_newint("a", exp_newint(42))
# push!(main_body.stmts, stmt_newdecl(let_a))

# let_b = decl_newint("b", exp_newint(2))
# push!(main_body.stmts, stmt_newdecl(let_b))

# sum_ab = exp_newadd(exp_newid("a"), exp_newid("b"))
# let_c = decl_newint("c", exp_newadd(sum_ab, exp_newid("x")))
# push!(main_body.stmts, stmt_newdecl(let_c))

set_a_0 = exp_newset(exp_newid("a"), exp_newint(0))
set_a_42 = exp_newset(exp_newid("a"), exp_newint(42))
control = stmt_newifelse(exp_newid("a"),
                        stmt_newexp(set_a_0),
                        stmt_newexp(set_a_42))
push!(main_body.stmts, control)

ret = stmt_newreturn(exp_newid("a"))
push!(main_body.stmts, ret)

main_args = [arg_new("a")]
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
