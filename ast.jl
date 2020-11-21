# --- Sym ---
sym_local(type::DeclType, id::String, position::Int) = sym_new(k_sym_local, type, id, position)
sym_arg(type::DeclType, id::String, position::Int) = sym_new(k_sym_arg, type, id, position)
sym_global(type::DeclType, id::String, position::Int) = sym_new(k_sym_arg, type, id, position)

# --- SymTable ---

# TODO : mv to ctx
function ctx_newsymlocal!(ctx::Ctx, type::DeclType, id::String, position::Int)
    sym = sym_new(k_sym_local, type, id, position)
    # TODO : Verify no name conflict
    push!(last(ctx.scopes), [id, sym])
end

function ctx_newsymglobal!(ctx::Ctx, type::DeclType, id::String)
    sym = sym_new(k_sym_global, type, id)
    # TODO : Verify no name conflict
    ctx.scopes[1].syms[id] = sym
    # push!(ctx.scopes[1], [id, sym])
end
