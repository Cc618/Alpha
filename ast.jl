# --- Decl ---
decl_newint(id::String, value::Exp) = decl_new(t_int, id, value=value)

# --- Stmt ---
stmt_newblock() = stmt_new(k_stmt_block, stmts=[])
stmt_newdecl(decl::Decl) = stmt_new(k_stmt_decl, decl=decl)

# --- Exp ---
exp_newint(value::Int) = exp_new(k_exp_int, type=t_int, value=value)
exp_newid(id::String) = exp_new(k_exp_id, id=id)
exp_newadd(left, right) = exp_new(k_exp_add, left=left, right=right)
