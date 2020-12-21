function codegen!(ctx::Ctx)
    # Generate instructions for each function
    for decl in ctx.decls
        ctx.current_func = decl
        decl_codegen!(ctx, decl)
    end

    # Combine instructions
    asm = "; Auto generated file\n\n"

    asm *= alphalib_head()

    asm *= "\nsection .data\n"
    for inst in ctx.data
        asm *= inst * "\n"
    end

    asm *= "\nsection .text\n"
    for inst in ctx.text
        asm *= inst * "\n"
    end

    return asm
end

function decl_codegen!(ctx::Ctx, decl::Decl)
    if decl.type.kind ∈ (k_proc_t, k_fn_t)
        ctx.scratch_regs = scratchregs_new()
        ctx.torestore_regs = Set()
        ctx.code = []

        stmt_codegen!(ctx, decl.body)

        fun_name = decl.id
        # TODO : Number of locals
        frame_size = decl.nlocals * 8

        # Prologue generation
        prologue = []
        pushinstr!(prologue, "global $fun_name", indent=false)
        pushinstr!(prologue, "$fun_name:", indent=false)
        pushinstr!(prologue, "push rbp")
        pushinstr!(prologue, "mov rbp, rsp")
        pushinstr!(prologue, "sub rsp, $(frame_size)")
        # TODO preserved : Push preserved

        # Epilogue generation
        epilogue = []
        pushinstr!(epilogue, ".$fun_name.epilogue:", indent=false)
        # TODO preserved : Pop preserved
        pushinstr!(epilogue, "leave")
        pushinstr!(epilogue, "ret")

        ctx.text = vcat(ctx.text, prologue, ctx.code, epilogue)
    elseif decl.type.kind == k_int_t
        # Local variable
        exp_codegen!(ctx, decl.value)

        @assert decl.sym != nothing "The variable $(decl.id) has no symbol resolved"

        sym = sym_codegen(decl.sym)
        ctx_push!(ctx, "mov $(sym), $(regstr(decl.value.reg))")

        ctx_freescratch!(ctx, decl.value.reg)
    else
        error("Not implemented decl type $(decl.type)")
    end
end

function stmt_codegen!(ctx, stmt)
    if stmt == nothing
        return
    end

    # TODO : Loop
    if stmt.kind == k_stmt_exp
        exp_codegen!(ctx, stmt.exp)

        # TODO : Can be nothing ?
        ctx_freescratch!(ctx, stmt.exp.reg)
    elseif stmt.kind == k_stmt_decl
        decl_codegen!(ctx, stmt.decl)
    elseif stmt.kind == k_stmt_return
        exp = stmt.exp
        exp_codegen!(ctx, exp)

        # Move the result into rax
        ctx_push!(ctx, "mov rax, $(regstr(exp.reg))")
        ctx_push!(ctx, "jmp .$(ctx.current_func.id).epilogue")

        ctx_freescratch!(ctx, exp.reg)
    elseif stmt.kind == k_stmt_printint
        exp = stmt.exp
        exp_codegen!(ctx, exp)

        # TODO : Push arg regs (same for printstr and exp_call)
        ctx_push!(ctx, "push rdi")
        ctx_push!(ctx, "push rsi")
        ctx_push!(ctx, "mov rdi, $(regstr(exp.reg))")
        ctx_push!(ctx, "call alphaprintint")
        ctx_push!(ctx, "pop rsi")
        ctx_push!(ctx, "pop rdi")

        ctx_freescratch!(ctx, exp.reg)
    elseif stmt.kind == k_stmt_printstr
        # Generate data
        str = str_escape(stmt.exp)
        data = ctx_newdata!(ctx, "db $str")

        ctx_push!(ctx, "push rdi")
        ctx_push!(ctx, "push rsi")
        ctx_push!(ctx, "mov rdi, $data")
        ctx_push!(ctx, "call alphaprintstr")
        ctx_push!(ctx, "pop rsi")
        ctx_push!(ctx, "pop rdi")
    elseif stmt.kind == k_stmt_block
        for st in stmt.stmts
            stmt_codegen!(ctx, st)
        end
    elseif stmt.kind == k_stmt_ifelse
        labelfalse = ctx_newlabel!(ctx)
        labelend = ctx_newlabel!(ctx)

        # stmt.exp.reg is 0 if false
        exp_codegen!(ctx, stmt.exp)
        ctx_push!(ctx, "cmp $(regstr(stmt.exp.reg)), 0")
        ctx_freescratch!(ctx, stmt.exp.reg)
        ctx_push!(ctx, "je $(labelstr(labelfalse))")

        # True
        stmt_codegen!(ctx, stmt.ifbody)
        ctx_push!(ctx, "jmp $(labelstr(labelend))")

        # False
        label_codegen!(ctx, labelfalse)
        stmt_codegen!(ctx, stmt.elsebody)

        # Done
        label_codegen!(ctx, labelend)
    elseif stmt.kind == k_stmt_loop
        label_start = ctx_newlabel!(ctx)
        label_end = ctx_newlabel!(ctx)

        init, condition, iter, body = stmt.initbody, stmt.exp, stmt.iterbody, stmt.loopbody

        # Init
        stmt_codegen!(ctx, init)
        label_codegen!(ctx, label_start)

        # Test condition
        exp_codegen!(ctx, condition)
        ctx_push!(ctx, "cmp $(regstr(condition.reg)), 0")
        ctx_freescratch!(ctx, condition.reg)
        ctx_push!(ctx, "je $(labelstr(label_end))")

        # Body
        stmt_codegen!(ctx, body)

        # Iter
        stmt_codegen!(ctx, iter)
        ctx_push!(ctx, "jmp $(labelstr(label_start))")

        label_codegen!(ctx, label_end)
    else
        error("Invalid statement kind $(stmt.kind)")
    end
end

function exp_codegen!(ctx, exp)
    if exp == nothing
        return
    end

    if exp.kind == k_exp_id
        exp.reg = ctx_newscratch!(ctx)

        sym = exp.sym

        @assert sym != nothing "No symbol resolved after semantic analysis"

        ctx_push!(ctx, "mov $(regstr(exp.reg)), $(sym_codegen(sym))")
    elseif exp.kind == k_exp_int
        exp.reg = ctx_newscratch!(ctx)

        ctx_push!(ctx, "mov $(regstr(exp.reg)), $(exp.value)")
    elseif exp.kind == k_exp_neg
        l = exp.left

        exp_codegen!(ctx, l)

        # l = -l
        ctx_push!(ctx, "neg $(regstr(l.reg))")

        exp.reg = l.reg
    elseif exp.kind == k_exp_add
        l, r = exp.left, exp.right

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        # l += r
        ctx_push!(ctx, "add $(regstr(l.reg)), $(regstr(r.reg))")

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_bool
        l, r = exp.left, exp.right

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        @assert exp.operator ∈ ("and", "or", "xor", "nand", "nor") "Invalid booleand operator $(exp.operator)"

        # l op r
        ctx_push!(ctx, "$(exp.operator) $(regstr(l.reg)), $(regstr(r.reg))")

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_mul
        l, r = exp.left, exp.right

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        # l *= r
        ctx_push!(ctx, "mov rax, $(regstr(l.reg))")
        ctx_push!(ctx, "imul $(regstr(r.reg))")
        ctx_push!(ctx, "mov $(regstr(l.reg)), rax")

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_div
        l, r = exp.left, exp.right

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        ctx_push!(ctx, "push rdx")

        # l /= r
        ctx_push!(ctx, "mov rax, $(regstr(l.reg))")
        ctx_push!(ctx, "idiv $(regstr(r.reg))")
        ctx_push!(ctx, "mov $(regstr(l.reg)), rax")

        ctx_push!(ctx, "pop rdx")

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_mod
        l, r = exp.left, exp.right

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        ctx_push!(ctx, "push rdx")

        # l /= r
        ctx_push!(ctx, "mov rax, $(regstr(l.reg))")
        ctx_push!(ctx, "idiv $(regstr(r.reg))")
        ctx_push!(ctx, "mov $(regstr(l.reg)), rdx")

        ctx_push!(ctx, "pop rdx")

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_set
        l, r = exp.left, exp.right

        @assert l.sym != nothing "Can't assign an rvalue"

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        lsym = sym_codegen(l.sym)

        # l = r
        ctx_push!(ctx, "mov $lsym, $(regstr(r.reg))")

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_test
        l, r = exp.left, exp.right

        exp_codegen!(ctx, l)
        exp_codegen!(ctx, r)

        jmp_condition = test_operators[exp.operator]
        label_true = ctx_newlabel!(ctx)
        label_done = ctx_newlabel!(ctx)

        # If true, jmp to label_true
        ctx_push!(ctx, "cmp $(regstr(l.reg)), $(regstr(r.reg))")
        ctx_push!(ctx, "$(jmp_condition) $(labelstr(label_true))")

        # False
        ctx_push!(ctx, "mov $(l.reg), 0")
        ctx_push!(ctx, "jmp $(labelstr(label_done))")

        # True
        label_codegen!(ctx, label_true)
        ctx_push!(ctx, "mov $(l.reg), 1")

        # End
        label_codegen!(ctx, label_done)

        ctx_freescratch!(ctx, r.reg)
        exp.reg = l.reg
    elseif exp.kind == k_exp_call
        # Push all scratch regs
        push_scratch = scratchregs_new()
        push_scratch = [r for r in push_scratch if r ∉ ctx.scratch_regs]
        for r in push_scratch
            ctx_push!(ctx, "push $(regstr(r))")
        end

        for (i, arg) in enumerate(exp.args)
            exp_codegen!(ctx, arg)

            # Push the arg reg and mov the result in it
            argreg = arg_regs[i]
            ctx_push!(ctx, "push $(regstr(argreg))")
            ctx_push!(ctx, "mov $(regstr(argreg)), $(regstr(arg.reg))")

            ctx_freescratch!(ctx, arg.reg)
        end

        # Call
        ctx_push!(ctx, "call $(exp.id)")

        # Pop arg regs
        for i in length(exp.args):-1:1
            ctx_push!(ctx, "pop $(regstr(arg_regs[i]))")
        end

        # Pop scratch regs
        for r in reverse(push_scratch)
            ctx_push!(ctx, "pop $(regstr(r))")
        end

        # Save return
        exp.reg = ctx_newscratch!(ctx)
        ctx_push!(ctx, "mov $(exp.reg), rax")
    else
        error("Invalid expession kind $(exp.kind)")
    end
end

function label_codegen!(ctx, label::String)
    ctx_push!(ctx, "$(label):", indent = false)
end

function label_codegen!(ctx, label::Int)
    ctx_push!(ctx, "$(labelstr(label)):", indent = false)
end

function sym_codegen(sym::Sym)
    if sym.kind == k_sym_global
        return sym.name
    elseif sym.kind == k_sym_arg
        @assert sym.position <= 5 "5 or more args are not yet supported"

        return regstr(arg_regs[sym.position])
    else
        # Local symbol
        negoffset = sym.position * 8

        return "[rbp - $negoffset]"
    end
end

# Returns the NASM compatible string
function str_escape(s::String)
    return "`$s`, 0"
end
