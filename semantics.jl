# Semantics Analysis

function semanticanalysis!(ctx)
    # 1st pass : Register global scope functions
    for decl in ctx.decls
        # TODO : Error
        @assert decl.type == t_proc "Unsupported global declaration type $(decl.type)"

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
        println("New variable $(decl.id), scope #$(length(ctx.scopes)) = $(last(ctx.scopes))")
        ctx_newsymlocal!(ctx, decl.type, decl.id)
    end

    # TODO : Or function
    if decl.type == t_proc
        # TODO : Error
        @assert length(ctx.scopes) == 1 "Can't declare functions in a local scope"

        ctx_pushscope!(ctx)

        # TODO : Resolve args
        stmt_resolve!(ctx, decl.body)

        # TODO : Type check return
        ctx_popscope!(ctx)
    elseif decl.type == t_int
        exp_resolve!(ctx, decl.value)

        # TODO : Error
        @assert decl.type == decl.value.type "Invalid type of expression"
    else
        # TODO : Custom error
        error("Unsupported type '$(decl.type)' for declaration")
    end
end

function stmt_resolve!(ctx, stmt)
    if stmt == nothing
        return
    end

    # TODO : Return
    if stmt.kind == k_stmt_decl
        decl_resolve!(ctx, stmt.decl)
    elseif stmt.kind == k_stmt_exp
        exp_resolve!(ctx, stmt.exp)
    elseif stmt.kind == k_stmt_ifelse
        exp_resolve!(ctx, stmt.exp)
        stmt_resolve!(ctx, stmt.ifbody)
        stmt_resolve!(ctx, stmt.elsebody)

        # TODO : Error
        @assert stmt.exp.type == t_int "Invalid condition expression"
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

    # TODO : k_exp_set k_exp_int...
    if exp.kind == k_exp_id
        exp.sym = ctx_fetchscope(ctx, exp.id)

        # TODO : Error
        @assert exp.sym != nothing "Not found variable named '$(exp.id)'"

        exp.type = exp.sym.type
    elseif exp.kind == k_exp_int
        exp.type = t_int
    elseif exp.kind == k_exp_set
        # TODO : Error
        @assert exp.sym != nothing "Can't assign an rvalue"
    end
end
