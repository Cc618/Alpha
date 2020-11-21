# --- Scopes ---
function ctx_pushscope!(ctx)
    push!(ctx.scopes, symtable_new())
end

function ctx_popscope!(ctx)
    pop!(ctx.scopes)
end

# Returns the symbol for this variable id
# Can return nothing if no symbol with this name already declared
function ctx_fetchscope(ctx, id)
    for i in length(ctx.scopes):-1:1
        if haskey(ctx.scopes[i].syms, id)
            return ctx.scopes[i].syms[id]
        end
    end

    return nothing
end

# --- Symbols ---
function ctx_newsymlocal!(ctx::Ctx, type::DeclType, id::String)
    scope = last(ctx.scopes)
    scope.nlocals += 1
    position = scope.nlocals
    sym = sym_new(k_sym_local, type, id, position)

    # TODO : Error
    @assert !haskey(scope.syms, id) "Declaration named '$id' already declared"

    scope.syms[id] = sym
end

function ctx_newsymarg!(ctx::Ctx, type::DeclType, id::String, position::Int)
    scope = last(ctx.scopes)
    scope.nargs += 1
    position = scope.nargs
    sym = sym_new(k_sym_arg, type, id, position)

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
