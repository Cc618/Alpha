# Semantics Analysis

function semanticanalysis!(ctx)
    # 1st pass : Register global scope functions
    for decl in ctx.decls
        # TODO : Error
        @assert decl.type.kind == k_proc_t || decl.type.kind == k_fn_t
                "Unsupported global declaration type $(decl.type)"

        ctx_newsymglobal!(ctx, decl.type, decl.id)
    end

    # 2nd pass : Verify types and push symbols to scopes
    for decl in ctx.decls
        decl_resolve!(ctx, decl, false)
    end
end

# Semantic analysis for a declaration
function decl_resolve!(ctx, decl, pushsym=true)
    # Declare this symbol to the inner scope
    if pushsym
        decl.sym = ctx_newsymlocal!(ctx, decl)
    end

    if decl.type.kind == k_proc_t || decl.type.kind == k_fn_t
        # TODO : Error
        @assert length(ctx.scopes) == 1 "Can't declare functions in a local scope"

        ctx_pushscope!(ctx, decl)

        args_resolve!(ctx, decl.type.args)
        stmt_resolve!(ctx, decl.body)

        # TODO : Type check return if decl.type.kind is k_fn_t
        # TODO : Check no return if decl.type.kind is k_proc_t
        ctx_popscope!(ctx)
    elseif decl.type.kind == k_int_t
        exp_resolve!(ctx, decl.value)

        # TODO : Error
        @assert decl.type == decl.value.type "Invalid type of expression"
    else
        # TODO : Custom error
        error("Unsupported type '$(decl.type)' for declaration")
    end
end

function args_resolve!(ctx, args)
    for (i, arg) in enumerate(args)
        ctx_newsymarg!(ctx, t_int, arg.id, i)
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

        # TODO : Empty return

        # TODO : Check function not proc
        # TODO : Error
        @assert stmt.exp.type.kind == k_int_t "Functions must return ints"
    elseif stmt.kind == k_stmt_ifelse
        exp_resolve!(ctx, stmt.exp)
        stmt_resolve!(ctx, stmt.ifbody)
        stmt_resolve!(ctx, stmt.elsebody)

        # TODO : Error
        @assert stmt.exp.type.kind == k_int_t "Invalid condition expression"
    elseif stmt.kind == k_stmt_block
        ctx_pushscope!(ctx)

        for child in stmt.stmts
            stmt_resolve!(ctx, child)
        end

        ctx_popscope!(ctx)
    else
        error("Unsupported statement kind $(stmt.kind)")
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
            # TODO : Error
            error("Invalid type for this expression")
        end

        exp.type = exp.left.type
    end

    if exp.kind == k_exp_id
        exp.sym = ctx_fetchscope(ctx, exp.id)

        # TODO : Error
        @assert exp.sym != nothing "Not found variable named '$(exp.id)'"

        exp.type = exp.sym.type
    elseif exp.kind == k_exp_int
        exp.type = t_int
    elseif exp.kind == k_exp_set
        # TODO : Error
        @assert exp.left.sym != nothing "Can't assign an rvalue"
    end
end
