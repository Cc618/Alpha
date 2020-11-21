# --- Decl ---
decl_newint(id::String, value::Exp) = decl_new(t_int, id, value=value)

# --- Stmt ---
stmt_newblock() = stmt_new(k_stmt_block, stmts=[])
stmt_newdecl(decl::Decl) = stmt_new(k_stmt_decl, decl=decl)

# --- Exp ---
exp_newint(value::Int) = exp_new(k_exp_int, t_int, value=value)

# --- SymTable ---
# TODO : mv to ctx
function ctx_newsymlocal!(ctx::Ctx, type::DeclType, id::String, position::Int)
    sym = sym_new(k_sym_local, type, id, position)
    scope = last(ctx.scopes)

    # TODO : Error
    @assert !haskey(scope.syms, id) "Declaration named '$id' already declared"

    scope.syms[id] = sym
end

function ctx_newsymarg!(ctx::Ctx, type::DeclType, id::String, position::Int)
    sym = sym_new(k_sym_arg, type, id, position)
    scope = last(ctx.scopes)

    # TODO : Error
    @assert !haskey(scope.syms, id) "Declaration named '$id' already declared"

    scope.syms[id] = sym
end

function ctx_newsymglobal!(ctx::Ctx, type::DeclType, id::String)
    sym = sym_new(k_sym_global, type, id)
    scope = first(ctx.scopes)

    # TODO : Error
    @assert !haskey(scope.syms, id) "Declaration named '$id' already declared"

    scope.syms[id] = sym
end
