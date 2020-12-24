# Template providing lexer runtime functions

# Parses str with table from index i
# Returns (accepted, end_pos, next_pos)
function _lparse(table, str, pos)
    state = 1
    last_pos = deepcopy(pos)
    while pos.index <= length(str)
        char = str[pos.index]
        tok = table.tok2index(char)

        nstate = table.actions[state, tok]
        if nstate == nothing
            break
        end

        state = nstate
        last_pos = deepcopy(pos)

        # Change pos
        pos.index += 1
        if char == '\n'
            pos.line += 1
            pos.column = 1
        else
            pos.column += 1
        end
    end

    return (table.terminal_states[state], last_pos, pos)
end

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
            acc, endpos, newpos = _lparse(reg, src, deepcopy(pos))

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

            line_start == nothing && (line_start = 0)
            line_end == nothing && (line_end = length(src) + 1)

            println("--- Error Info ---")
            if line_start < line_end
                println(src[line_start + 1:line_end - 1])
                println(repeat(' ', pos.column - 1) * "^")
            end

            error("Invalid syntax at position $pos, no token matched")
        end

        pos = newpos
    end

    # End token
    push!(tokens, tok_end(start_pos=pos, end_pos=pos))

    return tokens
end
