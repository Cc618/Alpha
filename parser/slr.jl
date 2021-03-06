#!/usr/bin/env julia

using Printf

# --- Def ---
include("lexerparser.inc.jl")

mutable struct State
    prods
    transitions
    id
end

state_id = 0

function state_new(prods)
    global state_id

    return State(prods, Dict(), state_id += 1)
end

# Same prods
state_eq_shallow(a, b) = issetequal(a.prods, b.prods)

function Base.print(io::IO, s::State)
    for p in s.prods
        Base.println(io, p)
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
function slr_table(states, tokens, prods, follow)
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

        # Reduce
        for p in s.prods
            if p.pos == length(p.right) + 1
                # Set reduce action for all tokens in follow(left of production)
                for reduce_tok in follow[p.left]
                    toki = tok2index[reduce_tok]
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
                # No epsilon supported
                tok = p.right[1]
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

# No epsilon supported
function follow_sets(tokens, prods, first)
    follow = Dict()
    end_tok = tok_new("\$", terminal=true)
    follow[prods[begin].left] = Set([end_tok])

    changes = true
    while changes
        changes = false

        for p in prods
            for i in 1:length(p.right)
                tok = p.right[i]
                if !haskey(follow, tok)
                    follow[tok] = Set()
                end

                set = follow[tok]
                old_len = length(set)

                if i == length(p.right)
                    # Merge follow of the left token
                    if haskey(follow, p.left)
                        union!(set, follow[p.left])
                    end
                elseif p.right[i + 1].terminal
                    # Add this terminal to follow
                    push!(set, p.right[i + 1])
                else
                    # Merge first of the next token
                    if haskey(first, p.right[i + 1])
                        union!(set, first[p.right[i + 1]])
                    end
                end

                if old_len != length(set)
                    changes = true
                end
            end
        end
    end

    return follow
end

function setup!(tokens, prods)
    # Tokens
    @assert length(tokens) >= 1 "No tokens"

    end_tok = tok_new("\$", terminal=true)
    push!(tokens, end_tok)

    @assert length(unique(tokens)) == length(tokens) "Duplicate tokens or \$ (end) token declared manually"

    # Productions
    @assert length(prods) >= 1 "No productions"

    root_tok = prods[begin].left

    @assert all(p -> p.left != root_tok, prods[2:end]) "There must be only one rule to produce the root token ($root_tok)"
    prods[begin].init = true

    for (i, p) in enumerate(prods)
        @assert p.left in tokens "Left token ($(p.left)) not declared for production #$i ($p)"

        for (ti, tok) in enumerate(p.right)
            @assert tok in tokens "Right token #$ti ($tok) not declared for production #$i ($p)"
        end
    end
end

# Main function
function generate_parser(io, tokens, prods, produce_rules)
    parserdir = dirname(@__FILE__)

    # Setup and verify everything
    setup!(tokens, prods)

    # First / follow
    first = first_sets(tokens, prods)
    follow = follow_sets(tokens, prods, first)

    # Generate automaton
    states = slr_graph(prods)
    table = slr_table(states, tokens, prods, follow)

    # Def table
    src_table = "table = $table"
    src_tokens = "tokens = $tokens"
    src_prods = "prods = $prods"
    src_produce_rules = "produce_rules = [$(join(produce_rules, ", "))]"

    # Parse functions
    src_parse = read("$parserdir/slr.parse_template.jl", String)

    srcs = [
            src_table,
            src_tokens,
            src_prods,
            src_produce_rules,
            src_parse,
        ]

    src = join(srcs, "\n")
    println(io, src)
end
