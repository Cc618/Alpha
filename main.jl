include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
include("ctx.jl")
include("semantics.jl")
include("codegen.jl")

# --- Main ---
"""
main(a, x) {
    let a = 42
    let b = 2
    let c = a + b

    return c
}
"""
main_body = stmt_newblock()

let_a = decl_newint("a", exp_newint(42))
push!(main_body.stmts, stmt_newdecl(let_a))

let_b = decl_newint("b", exp_newint(2))
push!(main_body.stmts, stmt_newdecl(let_b))

let_c = decl_newint("c", exp_newadd(exp_newid("a"), exp_newid("b")))
push!(main_body.stmts, stmt_newdecl(let_c))

ret_c = stmt_newreturn(exp_newid("c"))
push!(main_body.stmts, ret_c)

main_args = [arg_new("a"), arg_new("x")]
main_fn = decl_new(type_newfn(main_args), "main", body=main_body)

# --- Entry ---
ctx = ctx_new()

# Parsing
push!(ctx.decls, main_fn)

semanticanalysis!(ctx)

println(let_c.type)
