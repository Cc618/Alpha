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

function ctx_push!(ctx::Ctx, data::String; code = true, indent = true)
    section = if code ctx.code else ctx.data end

    if indent
        data = "    " * data
    end

    push!(section, data)
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

# TODO : Mv to codegen and update
# function labelcodegen!(ctx, label::String)
#     push!(prog.text, "$(label):")
# end

# function labelcodegen!(ctx, label::Int)
#     push!(prog.text, "$(labelstr(label)):")
# end
