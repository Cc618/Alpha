function codegen!(ctx::Ctx)
    # Generate instructions
    for decl in ctx.decls
        decl_codegen!(ctx, decl)
    end

    # Combine instructions
    asm = "; Auto generated file\n"

    # TODO : Declare sections
    asm *= "\n; --- Data section ---\n"
    for inst in ctx.data
        asm *= inst * "\n"
    end

    asm *= "\n; --- Text section ---\n"
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

        # TODO : Gen body code

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
    else
        # TODO : Implement int...
        error("Not implemented decl type $(decl.type)")
    end
end

function label_codegen!(ctx, label::String)
    ctx_push!(ctx, "$(label):", indent = false)
end

function label_codegen!(ctx, label::Int)
    ctx_push!(ctx, "$(labelstr(label)):", indent = false)
end
