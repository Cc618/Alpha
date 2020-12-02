# Template providing lexer runtime functions

# Lexer parse
# regs : Tuple(id, table, rule)
# Returns all tokens
function lparse(src, regs)
    tokens = []
    pos = pos_new()
    while pos.index <= length(src)
        # Test each reg
        err = true
        newpos = nothing
        for (id, reg, rule) in regs
            # endpos is just before newpos
            acc, endpos, newpos = parse(reg, src, deepcopy(pos))

            # Match
            if acc && newpos != pos
                err = false

                # Send token if not ignored
                if rule != nothing
                    data = rule(src[pos.index:newpos.index - 1])
                    tok = tok_new(id, terminal=true, data=data, start_pos=pos, end_pos=endpos)

                    push!(tokens, tok)
                end
                break
            end
        end

        # Error case (no match)
        if err
            line_start = findprev('\n', src, pos.index)
            line_end = findnext('\n', src, pos.index + 1)

            println("--- Error Info ---")
            if line_start < line_end
                println(src[line_start + 1:line_end - 1])
                println(repeat(' ', pos.column - 1) * "^")
            end

            # TODO : File
            error("Invalid syntax at position $pos, no token matched")
        end

        pos = newpos
    end

    # End token
    push!(tokens, tok_end(start_pos=pos, end_pos=pos))

    return tokens
end
