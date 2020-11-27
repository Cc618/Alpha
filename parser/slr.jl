#!/usr/bin/env julia

using Printf

# --- Def ---
mutable struct Tok
    id
    terminal
    data
end

mutable struct Prod
    left
    right
    produce
    pos
    init
end

mutable struct State
    prods
    transitions
    id
end

state_id = 0

tok_new(id; terminal = false, data = nothing) = Tok(id, terminal, data)
tok_eq(a, b) = a.id == b.id

# Special tokens
tok_eps() = tok_new("eps", terminal=true)
tok_end() = tok_new("\$", terminal=true)

# Only id matters for sets / dicts
Base.hash(a::Tok) = hash(a.id)
Base.isequal(a::Tok, b::Tok) = a.id == b.id
Base.show(io::IO, t::Tok) = print(io, t.id)

# produce is a lambda : produce(right...) -> left
prod_new(left::Tok, right::Array{Tok}, produce; pos = 1, init = false) = Prod(left, right, produce, pos, init)

function Base.hash(a::Prod)
    h = hash(a.left)
    h ⊻= hash(a.pos)
    for r in a.right
        h ⊻= hash(r)
    end

    return h
end

Base.isequal(a::Prod, b::Prod) =
    isequal(a.left, b.left) &&
    all([isequal(u, v) for (u, v) in zip(a.right, b.right)]) &&
    isequal(a.pos, b.pos)

function state_new(prods)
    global state_id

    return State(prods, Dict(), state_id += 1)
end

# Same prods
state_eq_shallow(a, b) = issetequal(a.prods, b.prods)

function Base.show(io::IO, s::State)
    for p in s.prods
        r = [t.id for t in p.right]
        insert!(r, p.pos, ".")
        str = "$(p.left.id) ->" * reduce((a, b) -> "$a $b", r, init="")
        Base.println(io, str)
    end

    for (k, v) in s.transitions
        Base.println("$(k.id) ---> $(v.id)")
    end
end

# --- Algo ---
# Updates the state set (states) by solving state
function slr_graph_solve!(state, states, prods)
    # Get each transition token
    # transitions[tok] = all prods with tok after the dot (aka pos)
    transitions = Dict()

    for p in state.prods
        # Reduce case
        if p.pos == length(p.right) + 1
            continue
        end

        next_tok = p.right[p.pos]
        if !haskey(transitions, next_tok)
            transitions[next_tok] = [p]
        else
            push!(transitions[next_tok], p)
        end
    end

    # For each new state
    for (transition_tok, old_prods) in transitions
        new_prods = Set()

        # Move the dot / remove reduce
        for p in old_prods
            # Reduce
            if p.pos == length(p.right) + 1
                continue
            end

            p = deepcopy(p)
            p.pos += 1
            push!(new_prods, p)
        end

        # Add non terminal prods recursively
        while true
            # All prods that have a non terminal token at pos
            nt_prods = Set([p for p in new_prods
                            if p.pos <= length(p.right) && !p.right[p.pos].terminal])
            # println(nt_prods)
            update = false
            for p in nt_prods
                # Token we create
                tok = p.right[p.pos]

                # Get all prods that make this token
                productions = Set([deepcopy(prod)
                                   for prod in prods if tok_eq(prod.left, tok)])
                # Add them
                old_size = length(new_prods)
                union!(new_prods, productions)

                if length(new_prods) != old_size
                    update = true
                end
            end

            if !update
                break
            end
        end

        # Either new or already present state
        next_state = state_new(new_prods)
        found = false
        for s in states
            # Found same state
            if state_eq_shallow(s, next_state)
                next_state = s
                found = true
                break
            end
        end

        # Link this state
        state.transitions[transition_tok] = next_state
        if !found
            push!(states, next_state)
            slr_graph_solve!(next_state, states, prods)
        end
    end
end

# !!! kernel is not removed from states
function slr_graph(prods)
    kernel = state_new(prods)
    states = [kernel]

    slr_graph_solve!(kernel, states, prods)

    for (i, s) in enumerate(states)
        s.id = i
    end

    return states
end

# Action is one of Sn, Rn, acc, nothing
function slr_table(states, tokens, prods)
    # table[state][tok] = action
    table = Matrix{Any}(nothing, length(states), length(tokens))

    tok2index = Dict()
    for (i, t) in enumerate(tokens)
        tok2index[t] = i
    end

    prod2index = Dict()
    for (i, p) in enumerate(prods)
        prod2index[p] = i
    end

    for s in states
        # Shifts / gotos
        for (tok, next_state) in s.transitions
            table[s.id, tok2index[tok]] = "S$(next_state.id)"
        end

        # TODO : Reduce conflict
        # TODO : First / follow
        # Reduce
        for p in s.prods
            if p.pos == length(p.right) + 1
                for toki in 1:length(tokens)
                    if table[s.id, toki] != nothing && length(table[s.id, toki]) > 0 && table[s.id, toki][1] == 'R'
                        println("--- Error Info ---")
                        println(s)
                        error("Reduce-reduce conflict for state $(s.id), token $(tokens[toki])")
                    end

                    if table[s.id, toki] == nothing
                        # Reduce using the prod when pos = 1
                        start_prod = deepcopy(p)
                        start_prod.pos = 1
                        rule = prod2index[start_prod]
                        table[s.id, toki] = "R$(rule)"
                    end
                end

                # Set init prod (root of the AST)
                if p.init
                    table[s.id, length(tokens)] = "acc"
                end
            end
        end
    end

    return table
end

# --- Parser Runtime ---
function parse(table, tokens, prods, tok2index)
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
            # TODO : Last rule not executed
            # Return the root of the ast
            return stack[2]
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
            # println("$(rule.left) -> $(right) : $(right[begin].data) => $(rule.produce(right...))")
            new_tok.data = rule.produce(right...)

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

function printtable(table, tokens)
    for row in 0:size(table, 1)
        for col in 0:size(table, 2)
            if col == 0
                @printf("%3d |", row)
            elseif row == 0
                @printf("%3s |", tokens[col])
            else
                val = table[row, col]
                if val == nothing
                    print("    |")
                else
                    @printf("%3s |", val)
                end
            end
        end
        println()
    end
end

function _first!(token, prods, first)
    if haskey(first, token)
        return first[token]
    end

    if token.terminal
        first[token] = Set([token])
        return first[token]
    else
        set = Set()
        for p in prods
            if p.left == token
                # TODO : Epsilon
                # TODO : Verify
                tok = p.right[begin]
                if tok != token
                    union!(set, _first!(tok, prods, first))
                end
            end
        end

        first[token] = set

        return set
    end
end

function first_sets(tokens, prods)
    # first[token] = First set for this token
    first = Dict()

    for tok in tokens
        _first!(tok, prods, first)
    end

    return first
end

# --- Main ---
t_a = tok_new("A")
t_e = tok_new("E")
t_f = tok_new("F")
t_p = tok_new("P")
t_t = tok_new("T")
t_n = tok_new("n", terminal=true)
t_lp = tok_new("(", terminal=true)
t_rp = tok_new(")", terminal=true)
t_i = tok_new("i", terminal=true)
t_plus = tok_new("+", terminal=true)
t_times = tok_new("*", terminal=true)
t_end = tok_new("\$", terminal=true)

tokens = [
    t_a,
    t_e,
    t_t,
    t_f,
    # t_p,
    t_n,
    t_lp,
    t_rp,
    # t_i,
    t_plus,
    t_times,
    t_end,
   ]

# TODO : Set ?
prods = [
        # prod_new(t_a, [t_e]),
        # prod_new(t_e, [t_n]),
        # prod_new(t_e, [t_e, t_plus, t_e]),

        # prod_new(t_p, [t_e], init=true),
        # prod_new(t_e, [t_e, t_plus, t_t]),
        # prod_new(t_e, [t_t]),
        # prod_new(t_t, [t_i, t_lp, t_e, t_rp]),
        # prod_new(t_t, [t_i]),

        # Algebra
        prod_new(t_a, [t_e], (val) -> val.data),
        prod_new(t_e, [t_e, t_plus, t_t], (a, _, b) -> a.data + b.data),
        prod_new(t_e, [t_t], (val) -> val.data),
        prod_new(t_t, [t_t, t_times, t_f], (a, _, b) -> a.data * b.data),
        prod_new(t_t, [t_f], (val) -> val.data),
        prod_new(t_f, [t_lp, t_e, t_rp], (_, val, _) -> val.data),
        prod_new(t_f, [t_n], (val) -> val.data),
    ]

prods[1].init = true


# col = Dict()
# col[t_a] = 1
# col[deepcopy(t_a)] = 2
# println(haskey(col, deepcopy(t_a)), col)
# exit()

first = first_sets(tokens, prods)
for (k, v) in first
    println("$k => $v")
end
exit()



states = slr_graph(prods)

table = slr_table(states, tokens, prods)

# Print states
println("# $(length(states)) states")
println(states[1])
# for s in states
#     println("* State #$(s.id)")
#     println(s)
# end

# Print table
printtable(table, tokens)

tok2index = Dict()
for (i, t) in enumerate(tokens)
    tok2index[t] = i
end

function nb(val)
    t = tok_new("n", terminal=true)
    t.data = val

    return t
end

source = [nb(6), t_plus, nb(3)]
push!(source, t_end)
root = parse(table, source, prods, tok2index)

println()
println("Result : $(root.data)")
