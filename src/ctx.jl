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

# Fetches a global symbol
# Might return nothing
function ctx_fetchglobal(ctx, id)
    if haskey(ctx.scopes[1].syms, id)
        return ctx.scopes[1].syms[id]
    end

    return nothing
end

# --- Symbols ---
function ctx_newsymlocal!(ctx::Ctx, decl::Decl, location)
    type = decl.type
    id = decl.id

    @alphaassert length(ctx.scopes) >= 2 decl.location "Cannot declare local symbols outside of a function"

    func_scope = ctx.scopes[2]
    func_scope.decl.nlocals += 1
    position = func_scope.decl.nlocals

    scope = last(ctx.scopes)
    sym = sym_new(k_sym_local, type, id, position)

    @alphaassert !haskey(scope.syms, id) decl.location "Variable named '$id' already declared"

    scope.syms[id] = sym

    return sym
end

function ctx_newsymarg!(ctx::Ctx, type::DeclType, id::String, position::Int, location)
    scope = last(ctx.scopes)
    scope.nargs += 1
    position = scope.nargs
    sym = sym_new(k_sym_arg, type, id, position)

    @alphaassert !haskey(scope.syms, id) location "Argument named '$id' already declared"

    scope.syms[id] = sym
end

function ctx_newsymglobal!(ctx::Ctx, type::DeclType, id::String, location)
    global alphalib_funcs

    sym = sym_new(k_sym_global, type, id)
    scope = first(ctx.scopes)

    @alphaassert !haskey(scope.syms, id) location "Declaration named '$id' already declared"
    @alphaassert id ∉ alphalib_funcs location "Declaration named '$id' reserved for alpha interns, use another name"

    scope.syms[id] = sym
end

# --- Registers ---
scratchregs_new() = [
        r8,
        r9,
        r10,
        r11
    ]

arg_regs = [
        di,
        si,
        dx,
        cx,
        r8,
        r9
    ]

# Allocates a new scratch register
function ctx_newscratch!(ctx::Ctx)
    @assert length(ctx.scratch_regs) != 0 "Not enough scratch registers"

    reg = pop!(ctx.scratch_regs)

    return reg
end

function ctx_freescratch!(ctx::Ctx, reg)
    @assert reg ∉ ctx.scratch_regs "Cannot push reg $(regstr(reg)) to $(ctx.scratch_regs)"

    push!(ctx.scratch_regs, reg)
end

function pushinstr!(section, data::String; indent = true)
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
function labelstr(label::Int)
    return ".L$label"
end

function ctx_newlabel!(ctx)
    ctx.n_labels += 1

    return ctx.n_labels
end

# --- Data ---
# Returns the name of the label
function ctx_newdata!(ctx, data)
    ctx.n_data += 1

    name = "D$(ctx.n_data)"

    instruction = "$name:\n$data"
    ctx_push!(ctx, instruction, code=false, indent=false)

    return name
end
