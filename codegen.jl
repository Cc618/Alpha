function codegen!(ctx::Ctx)
    for decl in ctx.decls
        decl_codegen!(ctx, decl)
    end
end

function decl_codegen!(ctx::Ctx, decl::Decl)
    if decl.type.kind ∈ (k_proc_t, k_fn_t)
        ctx.scratch_regs = scratchregs_new()
        ctx.used_scratch_regs = Set()
        ctx.code = []

        # TODO : Gen body code

        fun_name = decl.id
        # TODO : Number of locals
        frame_size = 42 * 8

        # Prologue generation
        prologue = []
        pushinstr!(prologue, "global $fun_name", indent=false)
        pushinstr!(prologue, "$fun_name:", indent=false)
        pushinstr!(prologue, "push rbp")
        pushinstr!(prologue, "mov rbp, rsp")
        pushinstr!(prologue, "sub rsp, $(frame_size)")

        # Epilogue generation
        epilogue = []
        pushinstr!(epilogue, ".$fun_name.epilogue:", indent=false)
        # TODO : Pop scratch
        pushinstr!(epilogue, "leave")
        pushinstr!(epilogue, "ret")

        merge!(ctx.text, prologue)
        merge!(ctx.text, ctx.code)
        merge!(ctx.text, epilogue)
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
