# --- Scopes ---
function ctx_pushscope!(ctx, decl = nothing)
    push!(ctx.scopes, symtable_new(decl))
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
function ctx_newsymlocal!(ctx::Ctx, decl::Decl)
    type = decl.type
    id = decl.id

    # TODO : Record number of locals in decl
    @assert length(ctx.scopes) >= 2 "Cannot declare local symbols outside of a function"

    func_scope = ctx.scopes[2]
    func_scope.decl.nlocals += 1
    position = func_scope.decl.nlocals

    scope = last(ctx.scopes)
    sym = sym_new(k_sym_local, type, id, position)

    # TODO : Error
    @assert !haskey(scope.syms, id) "Variable named '$id' already declared"

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

# --- Registers ---
scratchregs_new() = [
        r8,
        r9,
        r10,
        r11
    ]

# Allocates a new scratch register
function ctx_newscratch!(ctx::Ctx)
    # TODO : Throw error / return nothing
    @assert length(ctx.scratch_regs) != 0 "Not enough scratch registers"

    reg = pop!(ctx.scratch_regs)
    push!(ctx.used_scratch_regs, reg)

    return reg
end

function ctx_freescratch!(ctx::Ctx, reg)
    push!(ctx.scratch_regs, reg)
end

function pushinstr!(section::Array{String}, data::String; indent = true)
    if indent
        data = "    " * data
    end

    push!(section, data)
end

# Pushes code either in data section or current function's text section
function ctx_push!(ctx::Ctx, data::String; code = true, indent = true)
    section = if code ctx.code else ctx.data end

    pushinstr!(section, data, indent = indent)
end

function regstr(reg::Reg)
    global reg2str

    return reg2str[reg]
end

# --- Labels ---
function labelstr(ctx, label::Int)
    return ".L$label"
end

function ctx_newlabel!(ctx)
    ctx.n_label += 1

    return ctx.label
end
