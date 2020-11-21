include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
include("ctx.jl")
include("semantics.jl")
# include("codegen.jl")

# --- Main ---
"""
main() {
    let a = 42
    let b = 2
    let c = a + b
}
"""
main_body = stmt_newblock()

let_a = decl_newint("a", exp_newint(42))
push!(main_body.stmts, stmt_newdecl(let_a))

let_b = decl_newint("b", exp_newint(2))
push!(main_body.stmts, stmt_newdecl(let_b))

let_c = decl_newint("c", exp_newadd(exp_newid("a"), exp_newid("b")))
push!(main_body.stmts, stmt_newdecl(let_c))

main_fn = decl_new(t_proc, "main", body=main_body)

# --- Entry ---
ctx = ctx_new()

# Parsing
push!(ctx.decls, main_fn)

# ctx_newsymglobal!(ctx, t_proc, "main")

semanticanalysis!(ctx)

println(let_c.type)

# println(ctx.scopes)
# println(main_fn)
