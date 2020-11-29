# The lexer included within the parser
# Every public variable starts with l

# --- Def ---
mutable struct LCtx
    state_id
    states
end

mutable struct LState
    id
    # Associates a token or epsilon to a state
    # Note that before determinizing ctx, it gathers states, not ints
    transitions
    # Whether we can accept the input in this state
    terminal
end

mutable struct LTable
    actions
    terminal_states
    tok2index
end

lctx_new() = LCtx(0, [])

function lstate_new!(ctx; transitions = [], terminal = false)
    s = lstate_create(ctx.state_id += 1, transitions, terminal)
    push!(ctx.states, s)

    return s
end

lstate_create(id = 0, transitions = [], terminal = false) = LState(id, transitions, terminal)

# Links a to b by the token tok (can be empty)
function lstate_link!(a, tok, b)
    push!(a.transitions, (tok, b))
end

Base.isequal(a::LState, b::LState) = a.id == b.id
Base.hash(a::LState) = hash(a.id)

function Base.print(io::IO, s::LState)
    println(io, "LState(")
    println(io, "    id = $(s.id)")
    println(io, "    terminal = $(s.terminal)")
    for (tok, state) in s.transitions
        println(io, "    '$tok' -> $(isa(state, LState) ? state.id : state)")
    end

    print(io, ")")
end

ltable_new(action, terminal_states, tok2index) = LTable(action, terminal_states, tok2index)

# --- Functions ---
lend!(ctx) = lstate_new!(ctx, terminal=true)

# One token
function ltok!(ctx, tok)
    start = lstate_new!(ctx)
    stop = lstate_new!(ctx)

    lstate_link!(start, tok, stop)

    return start
end

# Links all states with an epsilon transition
function llink!(states...)
    for i in 1:length(states) - 1
        lstate_link!(states[i], "", states[i + 1])
    end
end

# Solves all epsilon closures for all states
# reachable from this state
# function epsclosure!(ctx, state, closures)
#     if closures[state.id] != nothing
#         return closures[state.id]
#     end

#     clos = Set()
#     for (tok, next_state) in state.transitions
#         if next_state != state
#             union!(clos, epsclosure!(ctx, next_state, closures))
#         end
#     end
# end

# !!! The initial state must be the first created (with id 1)
function determinize!(ctx)
    # Epsilon closures
    closures = [Set() for _ in 1:length(ctx.states)]

    # eps-NFA to NFA
    for (i, s) in enumerate(ctx.states)
        # Bfs
        visited = Set([s])
        q = [s]
        while length(q) > 0
            state = popfirst!(q)
            push!(closures[i], state.id)

            for (tok, next_state) in state.transitions
                # Epsilon
                if next_state ∉ visited && tok == ""
                    push!(q, next_state)
                    push!(visited, next_state)
                end
            end
        end
    end

    # NFA to DFA
    new_states = [Set([1])]
    visited_states = Set()
    states = Set([])
    init_state = nothing
    while length(new_states) != 0
        # Now an id is a set of int ids
        state_ids = pop!(new_states)
        push!(visited_states, state_ids)

        transitions = Dict()
        terminal = false

        for state_id in state_ids
            state = ctx.states[state_id]

            # This state contains a terminal state
            if state.terminal
                terminal = true
            end

            for (tok, next_state) in state.transitions
                # Ignore epsilons
                if tok == ""
                    continue
                end

                next_state_closure = closures[next_state.id]

                if !haskey(transitions, tok)
                    transitions[tok] = next_state_closure
                else
                    union!(transitions[tok], next_state_closure)
                end
            end
        end

        # Parse new states
        for (tok, next_state_ids) in transitions
            # If not parsed, add it to the stack
            if next_state_ids ∉ visited_states
                push!(new_states, next_state_ids)
            end
        end

        state = lstate_create(state_ids, transitions, terminal)

        if length(visited_states) != 1
            push!(states, state)
        else
            init_state = state
        end
    end

    # Convert states to linear and put init_state at the first position
    states = [init_state, states...]

    # Change states ids
    stateids2stateid = Dict()
    for (i, s) in enumerate(states)
        stateids2stateid[s.id] = i
    end

    for s in states
        s.id = stateids2stateid[s.id]
        for (tok, nstate) in s.transitions
            s.transitions[tok] = stateids2stateid[nstate]
        end
    end

    ctx.states = states
end

# tok2index maps a token (character) to an index, returns nothing if invalid token
function maketable(ctx, tok2index, ntoks)
    actions = Matrix{Any}(nothing, length(ctx.states), ntoks)

    for state in ctx.states
        for (tok, nstate) in state.transitions
            @assert isa(tok, String) && length(tok) == 1 "Tokens must be strings containing 1 character"

            t = tok2index(tok[1])

            # TODO : Debug position
            @assert t != nothing "Invalid character '$tok'"

            actions[state.id, t] = nstate
        end
    end

    terminal_states = [s.terminal for s in ctx.states]

    return ltable_new(actions, terminal_states, tok2index)
end

# Parses str with table from index i
# Returns (accepted, end_index)
function parse(table, str, i)
    state = 1
    while i <= length(str)
        tok = tok2index(str[i])

        nstate = table.actions[state, tok]
        if nstate == nothing
            break
        end

        state = nstate
        i += 1
    end

    return (table.terminal_states[state] , i)
end

# --- Main ---
ctx = lctx_new()

# https://www.youtube.com/watch?v=dlH2pIndNrU
s1 = lstate_new!(ctx)
s2 = lstate_new!(ctx)
s3 = lstate_new!(ctx)
s4 = lstate_new!(ctx)
s5 = lstate_new!(ctx, terminal=true)

lstate_link!(s1, "x", s2)
lstate_link!(s1, "z", s5)
lstate_link!(s3, "x", s4)
lstate_link!(s3, "y", s4)
llink!(s2, s3)
llink!(s2, s5)
llink!(s4, s5)
llink!(s4, s3)

determinize!(ctx)

tok2indexmap = Dict(
    'x' => 1,
    'y' => 2,
    'z' => 3,
)
tok2index = (tok) -> haskey(tok2indexmap, tok) ? tok2indexmap[tok] : nothing

table = maketable(ctx, tok2index, length(tok2indexmap))

# regex = x(x|y)*|z
strs = [
        # true
        "x",
        "z",
        "xxxxx",
        "xyyy",
        "xyxyxy",
        # false
        "",
        "zx",
        "zz",
        "xyz",
    ]

# println(table)

for s in strs
    acc, i = parse(table, s, 1)
    println("s = '$s' => acc = $acc, i = $i")
end

# sinit = lstate_new!(ctx)
# # sa = ltok!(ctx, "a")
# # sb = ltok!(ctx, "b")
# # sc = ltok!(ctx, "c")
# sa = lstate_new!(ctx)
# sb = lstate_new!(ctx)
# # sc = lstate_new!(ctx)
# lstate_link!(sa, "A", sb)
# send = lend!(ctx)

# llink!(sinit, sa)
# llink!(sb, send)
# llink!(send, sa)
# llink!(sa, send)

# determinize!(ctx)

# for s in ctx.states
#     println(s)
# end
