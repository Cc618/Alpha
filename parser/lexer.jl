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
    transitions
    # Whether we can accept the input in this state
    terminal
end

lctx_new() = LCtx(0, [])

function lstate_new!(ctx; transitions = [], terminal = false)
    s = LState(ctx.state_id += 1, transitions, terminal)
    push!(ctx.states, s)

    return s
end

# Links a to b by the token tok (can be empty)
function lstate_link!(a, tok, b)
    push!(a.transitions, (tok, b))
end

Base.isequal(a::LState, b::LState) = a.id == b.id
Base.hash(a::LState) = hash(a.id)

function Base.print(io::IO, s::LState)
    println(io, "LState(")
    println(io, "    id = $(s.id)")
    for (tok, state) in s.transitions
        println(io, "    '$tok' -> $(state.id)")
    end

    print(io, ")")
end

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

function determinize!(ctx)
    # Epsilon closures
    closures = [[] for _ in 1:length(ctx.states)]

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

        println(closures[i])
    end
end

# --- Main ---
ctx = lctx_new()
sinit = lstate_new!(ctx)
# sa = ltok!(ctx, "a")
# sb = ltok!(ctx, "b")
# sc = ltok!(ctx, "c")
sa = lstate_new!(ctx)
sb = lstate_new!(ctx)
# sc = lstate_new!(ctx)
lstate_link!(sa, "A", sb)
send = lend!(ctx)

llink!(sinit, sa)
llink!(sb, send)
llink!(send, sa)
llink!(sa, send)

determinize!(ctx)

for s in ctx.states
    println(s)
end
