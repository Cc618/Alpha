# Parser (SLR(1)) template

parser_pos_start = pos_new()
parser_pos_end = pos_new()

tok2index = Dict()
for (i, t) in enumerate(tokens)
    tok2index[t] = i
end

# Returns (start, end) describing the start / end
# location of the current token being produced
function parser_pos()
    global parser_pos_start, parser_pos_end

    return (parser_pos_start, parser_pos_end)
end

function _pparse(table, tokens, prods, tok2index, produce_rules)
    global parser_pos_start, parser_pos_end

    stack = Array{Any}([1])
    while true
        @assert length(stack) > 0 && length(tokens) > 0 "Unexpected end of file"

        state = stack[end]
        token = tokens[1]
        action = table[state, tok2index[token]]

        if action == nothing
            if token.id == "\$"
                error("Syntax error : Unexpected end of file")
            else
                error("Syntax error from $(token.start_pos) to $(token.end_pos) : Invalid token $token (data = $(token.data))")
            end
        elseif action == "acc"
            @assert length(tokens) == 1 "Unexpected end of file"

            # Reduce using the first rule
            right = stack[2:2:end]
            rule = prods[begin]

            new_tok = deepcopy(rule.left)
            new_tok.start_pos = right[begin].start_pos
            new_tok.end_pos = right[end].end_pos

            parser_pos_start = deepcopy(new_tok.start_pos)
            parser_pos_end = deepcopy(new_tok.end_pos)

            right = [r.data for r in right]
            try
                new_tok.data = produce_rules[begin](right...)
            catch e
                error("Can't produce token $new_tok, invalid rule (got $(length(right)) right tokens)")
            end

            # Return the root of the ast
            return new_tok.data
        elseif action[1] == 'R'
            # Reduce
            i = Base.parse(Int, action[2:end])
            rule = prods[i]

            # Pop right
            right_toks = stack[length(stack) - length(rule.right) * 2 + 1:2:length(stack)]
            splice!(stack, length(stack) - length(rule.right) * 2 + 1:length(stack))

            # State when we start to produce this token
            old_state = stack[end]

            # Push left
            idx = tok2index[rule.left]

            goto = table[old_state, idx]
            @assert goto != nothing && goto[1] == 'S' "Can't go to new state after using rule #$i (producing $(rule.left) with $(rule.right))"

            new_state = Base.parse(Int, goto[2:end])

            new_tok = deepcopy(rule.left)

            new_tok.start_pos = right_toks[begin].start_pos
            new_tok.end_pos = right_toks[end].end_pos
            parser_pos_start = deepcopy(new_tok.start_pos)
            parser_pos_end = deepcopy(new_tok.end_pos)

            right = [r.data for r in right_toks]
            try
                new_tok.data = produce_rules[i](right...)
            catch e
                error("Can't produce token $new_tok, invalid rule (got $(length(right)) right tokens)")
            end


            push!(stack, new_tok)
            push!(stack, new_state)
        elseif action[1] == 'S'
            # Shift
            next_state = Base.parse(Int, action[2:end])

            # Accept the token, push it on the stack and the new state
            popfirst!(tokens)
            push!(stack, token)
            push!(stack, next_state)
        end
    end
end

# Parser parse
function pparse(tokens)
    global tok2index
    global prods
    global table
    global produce_rules

    return _pparse(table, tokens, prods, tok2index, produce_rules)
end
