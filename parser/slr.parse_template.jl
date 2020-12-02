# Parser (SLR(1)) template

tok2index = Dict()
for (i, t) in enumerate(tokens)
    tok2index[t] = i
end

function _parse(table, tokens, prods, tok2index, produce_rules)
    stack = Array{Any}([1])
    while true
        @assert length(stack) > 0 && length(tokens) > 0 "Unexpected end of file"

        state = stack[end]
        token = tokens[1]
        # println(tokens[1].data)
        action = table[state, tok2index[token]]

        if action == nothing
            # TODO : Location
            error("Syntax error")
        elseif action == "acc"
            @assert length(tokens) == 1 "Unexpected end of file"

            # Reduce using the first rule
            right = stack[2:2:end]
            rule = prods[begin]

            new_tok = deepcopy(rule.left)
            right = [r.data for r in right]
            new_tok.data = produce_rules[begin](right...)

            # Return the root of the ast
            return new_tok.data
        elseif action[1] == 'R'
            # Reduce
            i = Base.parse(Int, action[2:end])
            rule = prods[i]

            # Pop right
            right = stack[length(stack) - length(rule.right) * 2 + 1:2:length(stack)]
            splice!(stack, length(stack) - length(rule.right) * 2 + 1:length(stack))

            # State when we start to produce this token
            old_state = stack[end]

            # Push left
            idx = tok2index[rule.left]

            goto = table[old_state, idx]
            @assert goto != nothing && goto[1] == 'S' "Can't go to new state after using rule #$i (producing $(rule.left) with $(rule.right))"

            new_state = Base.parse(Int, goto[2:end])

            # TODO : Location
            new_tok = deepcopy(rule.left)
            right = [r.data for r in right]
            new_tok.data = produce_rules[i](right...)

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

function parse(tokens)
    global tok2index
    global prods
    global table
    global produce_rules

    return _parse(table, tokens, prods, tok2index, produce_rules)
end
