# --- Decl ---
decl_newint(id::String, value::Exp) = decl_new(t_int, id, value=value)

# --- Stmt ---
stmt_newblock() = stmt_new(k_stmt_block, stmts=[])
stmt_newdecl(decl::Decl) = stmt_new(k_stmt_decl, decl=decl)
stmt_newexp(exp::Exp) = stmt_new(k_stmt_exp, exp=exp)
stmt_newreturn(exp::Exp) = stmt_new(k_stmt_return, exp=exp)
stmt_newifelse(condition::Exp, iftrue, iffalse = nothing) =
        stmt_new(k_stmt_ifelse, exp=condition, ifbody=iftrue, elsebody=iffalse)
stmt_newloop(init::Stmt, condition::Exp, iter::Stmt, body::Stmt) =
        stmt_new(k_stmt_loop, exp=condition, initbody=init, iterbody=iter, loopbody=body)

# --- Exp ---
exp_newint(value::Int) = exp_new(k_exp_int, type=t_int, value=value)
exp_newid(id::String) = exp_new(k_exp_id, id=id)
exp_newadd(left, right) = exp_new(k_exp_add, left=left, right=right)
exp_newmul(left, right) = exp_new(k_exp_mul, left=left, right=right)
exp_newset(left, right) = exp_new(k_exp_set, left=left, right=right)
exp_newtest(left, operator, right) = exp_new(k_exp_test, left=left, right=right, operator=operator)
exp_newcall(fun_id, args::Array{Exp}) = exp_new(k_exp_call, id=fun_id, args=args)

# --- DeclType ---
# proc doesn't return
type_newproc(args) = DeclType(k_proc_t, args)
# fn returns an int
type_newfn(args) = DeclType(k_fn_t, args)

t_int = decltype_new(k_int_t)
t_void = decltype_new(k_void_t)

# --- Arg ---
arg_new(id::String) = Arg(id)
