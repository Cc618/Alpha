# The lexer included within the parser
# Every public variable starts with l

# --- Def ---
mutable struct LState
    id
    # Associates a token or epsilon to a state
    transitions
    # Whether we can accept the input in this state
    terminal
end

lstate_id = 0

function lstate_new(; transitions = [], terminal = false)
    global lstate_id

    LState(lstate_id += 1, transitions, terminal)
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
lend() = lstate_new(terminal=true)

# One token
function ltok(tok)
    start = lstate_new()
    stop = lstate_new()

    lstate_link!(start, tok, stop)

    return start
end

# Links all states with an epsilon transition
function llink!(states...)
    for i in 1:length(states) - 1
        lstate_link!(states[i], "", states[i + 1])
    end
end

# --- Main ---
sinit = lstate_new()
sa = ltok("a")
sb = ltok("b")
sc = ltok("c")
send = lend()

llink!(sinit, sa, sb, sc, send)

println(sinit)
println(sa)
println(sb)
println(sc)
println(send)
