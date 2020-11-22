# --- Decl ---
decl_newint(id::String, value::Exp) = decl_new(t_int, id, value=value)

# --- Stmt ---
stmt_newblock() = stmt_new(k_stmt_block, stmts=[])
stmt_newdecl(decl::Decl) = stmt_new(k_stmt_decl, decl=decl)
stmt_newreturn(exp::Exp) = stmt_new(k_stmt_return, exp=exp)

# --- Exp ---
exp_newint(value::Int) = exp_new(k_exp_int, type=t_int, value=value)
exp_newid(id::String) = exp_new(k_exp_id, id=id)
exp_newadd(left, right) = exp_new(k_exp_add, left=left, right=right)

# --- DeclType ---
# proc doesn't return
type_newproc(args) = DeclType(k_proc_t, args)
# fn returns an int
type_newfn(args) = DeclType(k_fn_t, args)

t_int = decltype_new(k_int_t)
t_void = decltype_new(k_void_t)

# --- Arg ---
arg_new(id::String) = Arg(id)
