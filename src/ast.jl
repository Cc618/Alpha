# --- Decl ---
decl_newint(id::String, value::Exp; location = nothing) = decl_new(t_int, id, value=value, location=location)

# --- Stmt ---
stmt_newblock(stmts = []; location = nothing) = stmt_new(k_stmt_block, stmts=stmts, location=location)
stmt_newchain(stmts = []; location = nothing) = stmt_new(k_stmt_chain, stmts=stmts, location=location)
stmt_newdecl(decl::Decl; location = nothing) = stmt_new(k_stmt_decl, decl=decl, location=location)
stmt_newexp(exp::Exp; location = nothing) = stmt_new(k_stmt_exp, exp=exp, location=location)
stmt_newreturn(exp::Exp; location = nothing) = stmt_new(k_stmt_return, exp=exp, location=location)
stmt_newifelse(condition::Exp, iftrue, iffalse = nothing; location = nothing) =
        stmt_new(k_stmt_ifelse, exp=condition, ifbody=iftrue, elsebody=iffalse, location=location)
stmt_newloop(init::Union{Stmt, Nothing}, condition::Exp,
             iter::Union{Stmt, Nothing}, body::Stmt; location = nothing) =
        stmt_new(k_stmt_loop, exp=condition, initbody=init, iterbody=iter, loopbody=body, location=location)

# IO
stmt_newprintint(exp; location = nothing) = stmt_new(k_stmt_printint, exp=exp, location=location)
stmt_newprintstr(s; location = nothing) = stmt_new(k_stmt_printstr, exp=s, location=location)
stmt_newprintline(; location = nothing) = stmt_new(k_stmt_printstr, exp="\\n", location=location)
stmt_newprintspace(; location = nothing) = stmt_new(k_stmt_printstr, exp=" ", location=location)
stmt_newscan(exp; location = nothing) = stmt_new(k_stmt_scan, exp=exp, location=location)

# Wrappers
# loop with <id> from <from> to <to>
function stmt_newloopwith(id, from, to, body; location = nothing)
    init = stmt_newdecl(decl_newint(id, from))
    condition = exp_newtest(exp_newid(id), "<=", to)
    iter = exp_newset(exp_newid(id), exp_newadd(exp_newid(id), exp_newint(1)))

    return stmt_newloop(init, condition, stmt_newexp(iter), body, location=location)
end

# Items is an array of Exp / String
function stmt_newprint(items; location = nothing)
    stmts = []
    for (i, item) in enumerate(items)
        push!(stmts, (isa(item, String) ? stmt_newprintstr : stmt_newprintint)(item))
        push!(stmts, (i == length(items) ? stmt_newprintline : stmt_newprintspace)())
    end

    return stmt_newchain(stmts, location=location)
end

function stmt_newletscan(id; location = nothing)
    stmtlet = stmt_newdecl(decl_newint(id, exp_newint(0), location=location), location=location)
    stmtscan = stmt_newscan(exp_newid(id, location=location), location=location)

    return stmt_newchain([stmtlet, stmtscan], location=location)
end

# --- Exp ---
exp_newint(value::Int; location = nothing) = exp_new(k_exp_int, type=t_int, value=value, location=location)
exp_newid(id::String; location = nothing) = exp_new(k_exp_id, id=id, location=location)
exp_newadd(left, right; location = nothing) = exp_new(k_exp_add, left=left, right=right, location=location)
exp_newdiv(left, right; location = nothing) = exp_new(k_exp_div, left=left, right=right, location=location)
exp_newmod(left, right; location = nothing) = exp_new(k_exp_mod, left=left, right=right, location=location)
exp_newneg(val; location = nothing) = exp_new(k_exp_neg, left=val, location=location)
exp_newmul(left, right; location = nothing) = exp_new(k_exp_mul, left=left, right=right, location=location)
exp_newset(left, right; location = nothing) = exp_new(k_exp_set, left=left, right=right, location=location)
exp_newtest(left, operator, right; location = nothing) = exp_new(k_exp_test, left=left, right=right, operator=operator, location=location)
exp_newbool(left, operator, right; location = nothing) = exp_new(k_exp_bool, left=left, right=right, operator=operator, location=location)
exp_newcall(fun_id, args::Array{Exp}; location = nothing) = exp_new(k_exp_call, id=fun_id, args=args, location=location)

# --- DeclType ---
# proc doesn't return
type_newproc(args) = DeclType(k_proc_t, args)
# fn returns an int
type_newfn(args) = DeclType(k_fn_t, args)

t_int = decltype_new(k_int_t)
t_void = decltype_new(k_void_t)

# --- Arg ---
arg_new(id::String) = Arg(id)
