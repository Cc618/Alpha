include("ast_def.jl")
include("ctx_def.jl")
include("ast.jl")
include("ctx.jl")
include("semantics.jl")
include("codegen.jl")

# Generated by parser.syntax
include("parser.yy.jl")

#=
# TODO Zone
# # Syntax
# - / % - (negate + sub)
# - true / false
# - not and or (+ in code gen)
# - += -= *= (+ in code gen)
#
# # Codegen
# - Handle iter = init = nothing in loops (see ast.jl:11)
=#

#=
TODO : In documentation
# Operator Precedance
| Precedance | Operators |
| ---------- | --------- |
| 1 | call() |
| 2 | not |
| 3 | * / |
| 4 | + - |
| 5 | <= >= < > |
| 6 | is != |
| 7 | and |
| 8 | or |
| 9 | := += -= *= |
=#


code = """
fun hello
take a, b, c
begin
    # let x be 2 + 2
    # x = x : 2
end
"""

# TODO : Multiple LF
code = """
fun fac
take n
begin
    if n < 0
        return -1
    else
    begin
        let result be 1

        # loop with i from 1 to n
        #     result := result * n

        return result
    end
end
"""

# TODO : Add on the parser if no \n at the end
code[end] != '\n' && (code *= "\n")

ctx = parse(code)
# println(ast)

semanticanalysis!(ctx)
open("tests/source.asm", "w") do io
    println(io, codegen!(ctx))
end

println("Done")

exit()

# TODO : Verify test instruction (use cmp)
# TODO : Improve error for parser (location)

# --- Code Gen tests ---
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

# # Test #3 : Loop
# """
# main()
#     -> for (let i = 1; i <= 42; i = i * 2)
#         let a = 2;
# """
# init = stmt_newdecl(decl_newint("i", exp_newint(1)))
# condition = exp_newtest(exp_newid("i"), "<=", exp_newint(42))
# iter = stmt_newexp(exp_newset(exp_newid("i"), exp_newmul(exp_newid("i"), exp_newint(2))))
# let_a = stmt_newdecl(decl_newint("a", exp_newint(2)))

# main_body = stmt_newloop(init, condition, iter, let_a)

# main_args = []
# main_fn = decl_new(type_newfn(main_args), "main", body=main_body)

# Test #4 : Call
# Note that fun is declared after main
"""
main():
    let a = 2 + fun(4)

fun(x):
    return 42 * x
"""
let_a_rhs = exp_newadd(exp_newint(2), exp_newcall("fun", [exp_newint(4)]))
let_a = stmt_newdecl(decl_newint("a", let_a_rhs))

main_args = []
main_fn = decl_new(type_newfn(main_args), "main", body=let_a)

fun_ret = stmt_newreturn(exp_newmul(exp_newint(42), exp_newid("x")))

fun_args = [arg_new("x")]
fun_fn = decl_new(type_newfn(fun_args), "fun", body=fun_ret)

# --- Entry ---
ctx = ctx_new()

# Parsing
push!(ctx.decls, main_fn)
push!(ctx.decls, fun_fn)

semanticanalysis!(ctx)

# println(let_c.type)
# println(let_c.value.right)
# println(main_fn.nlocals)
# println(main_fn.type.args)

println(codegen!(ctx))
