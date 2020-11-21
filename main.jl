include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
# include("codegen.jl")

# --- Main ---
"""
main() {
    let a = 42
}
"""
main_body = stmt_newblock()

# let a = 42
let_a_be_42 = decl_newint("a", exp_newint(42))
push!(main_body.stmts, stmt_newdecl(let_a_be_42))

main_fn = decl_new(t_proc, "main", body=main_body)

# --- Entry ---
ctx = ctx_new()
ctx_newsymglobal!(ctx, t_proc, "main")

semanticanalysis!(ctx)

println(ctx.scopes[1])
# println(main_fn)
