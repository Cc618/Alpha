# Semantics Analysis

# undef = No return or partial return
@enum ReturnKind k_ret_undef k_ret_void k_ret_t

function semanticanalysis!(ctx)
    # 1st pass : Register global scope functions
    for decl in ctx.decls
        @alphaassert decl.type.kind == k_proc_t || decl.type.kind == k_fn_t decl.location "Unsupported global declaration type $(decl.type)"

        ctx_newsymglobal!(ctx, decl.type, decl.id, decl.location)
    end

    # 2nd pass : Verify types and push symbols to scopes
    for decl in ctx.decls
        ctx.current_func = decl
        decl_resolve!(ctx, decl, false)
    end
end

# Semantic analysis for a declaration
function decl_resolve!(ctx, decl, pushsym=true)
    if decl.type.kind == k_proc_t || decl.type.kind == k_fn_t
        @alphaassert length(ctx.scopes) == 1 decl.location "Can't declare functions in a local scope"

        ctx_pushscope!(ctx, decl)

        args_resolve!(ctx, decl.type.args, decl.location)
        stmt_resolve!(ctx, decl.body)

        # TODO : Type check return if decl.type.kind is k_fn_t
        ctx_popscope!(ctx)
    elseif decl.type.kind == k_int_t
        exp_resolve!(ctx, decl.value)

        @alphaassert decl.type == decl.value.type decl.location "Invalid type of expression, must be int"
    else
        alphaerror("Unsupported type '$(decl.type)' for declaration", ctx, decl.location)
    end

    # Declare this symbol to the inner scope
    if pushsym
        decl.sym = ctx_newsymlocal!(ctx, decl, decl.location)
    end
end

function args_resolve!(ctx, args, location)
    for (i, arg) in enumerate(args)
        ctx_newsymarg!(ctx, t_int, arg.id, i, location)
    end
end

function stmt_resolve!(ctx, stmt)
    if stmt == nothing
        return
    end

    if stmt.kind == k_stmt_decl
        decl_resolve!(ctx, stmt.decl)
    elseif stmt.kind == k_stmt_exp
        exp_resolve!(ctx, stmt.exp)
    elseif stmt.kind == k_stmt_return
        exp_resolve!(ctx, stmt.exp)

        # Returns have only ints (empty return not allowed)
        @alphaassert stmt.exp.type.kind == k_int_t stmt.exp.location "Functions must return ints"

        # Check this is not a procedure
        @alphaassert ctx.current_func.type.kind == k_fn_t stmt.location "Cannot return within procedures"
    elseif stmt.kind == k_stmt_ifelse
        exp_resolve!(ctx, stmt.exp)
        stmt_resolve!(ctx, stmt.ifbody)
        stmt_resolve!(ctx, stmt.elsebody)

        @alphaassert stmt.exp.type.kind == k_int_t stmt.location "Invalid condition expression"
    elseif stmt.kind == k_stmt_loop
        ctx_pushscope!(ctx)

        stmt_resolve!(ctx, stmt.initbody)
        exp_resolve!(ctx, stmt.exp)
        stmt_resolve!(ctx, stmt.iterbody)
        stmt_resolve!(ctx, stmt.loopbody)

        ctx_popscope!(ctx)

        @alphaassert stmt.exp.type.kind == k_int_t stmt.location "Invalid condition expression"
    elseif stmt.kind == k_stmt_block
        ctx_pushscope!(ctx)

        for child in stmt.stmts
            stmt_resolve!(ctx, child)
        end

        ctx_popscope!(ctx)
    elseif stmt.kind == k_stmt_chain
        for child in stmt.stmts
            stmt_resolve!(ctx, child)
        end

        # Generate this statement as a block
        stmt.kind = k_stmt_block
    elseif stmt.kind == k_stmt_printint
        exp_resolve!(ctx, stmt.exp)

        @alphaassert stmt.exp.type.kind == k_int_t stmt.exp.location "Cannot display this value"
    elseif stmt.kind == k_stmt_scan
        exp_resolve!(ctx, stmt.exp)

        @alphaassert stmt.exp.type.kind == k_int_t stmt.exp.location "Invalid type for scan"
    elseif stmt.kind ∈ (k_stmt_printstr,)
        # Ignored
    else
        alphaerror("Unsupported statement kind $(stmt.kind)", ctx, stmt.location)
    end
end

function exp_resolve!(ctx, exp)
    if exp == nothing
        return
    end

    # Resolve left and right
    if exp.left != nothing
        exp_resolve!(ctx, exp.left)
        exp_resolve!(ctx, exp.right)

        if exp.right != nothing && exp.right.type != exp.left.type
            alphaerror("Invalid type for this expression", ctx, stmt.location)
        end

        exp.type = exp.left.type
    end

    if exp.kind == k_exp_id
        exp.sym = ctx_fetchscope(ctx, exp.id)

        @alphaassert exp.sym != nothing exp.location "Not found variable named '$(exp.id)'"

        exp.type = exp.sym.type
    elseif exp.kind == k_exp_int
        exp.type = t_int
    elseif exp.kind == k_exp_set
        @alphaassert exp.left.sym != nothing exp.location "Can't assign an rvalue"
    elseif exp.kind == k_exp_call
        # Check args
        for (i, arg) in enumerate(exp.args)
            exp_resolve!(ctx, arg)

            @alphaassert arg.type.kind == k_int_t exp.location "Invalid arg #$(i + 1) type, must be int"
        end

        fun = ctx_fetchglobal(ctx, exp.id)
        exp.type = fun.type.kind == k_fn_t ? t_int : t_void

        @alphaassert fun != nothing exp.location "Function $(exp.id) not declared"
        @alphaassert length(fun.type.args) == length(exp.args) exp.location "Invalid number of arguments to call $(fun.id), $(length(fun.type.args)) args required"
    elseif exp.kind == k_exp_test
        @alphaassert haskey(test_operators, exp.operator) exp.location "Invalid conditional operator $(exp.operator)"
    end
end
