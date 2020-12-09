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
    new_states = [closures[1]]
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
            @assert isa(tok, Char) "Tokens must be chars (got $tok)"

            t = tok2index(tok)

            @assert t != nothing "Invalid character '$tok'"

            actions[state.id, t] = nstate
        end
    end

    terminal_states = [s.terminal for s in ctx.states]

    return ltable_new(actions, terminal_states, tok2index)
end

# --- Parsing ---
# Intermediate automaton representation
function parsereg(reg)
    states = []

    i = 1
    while i <= length(reg)
        char = reg[i]
        if char in "*?"
            @assert length(states) != 0 "Invalid $char at column $i for regex $reg"

            last_state = pop!(states)
            new_state = ("$char", last_state)
            push!(states, new_state)
        elseif char == '['
            start = i
            while i <= length(reg) && reg[i] != ']'
                i += 1
            end

            @assert i <= length(reg) "Unmatched '[' at column $start for regex $reg"

            push!(states, ("group", reg[start + 1 : i - 1]))
        else
            push!(states, ("char", reg[i]))
        end

        i += 1
    end

    return states
end

reggroups = Dict(
                 "num" => Set(String('0':'9')),
                 "alpha" => Set("_" * String('a':'z') * String('A':'Z')),
                 "\\n" => Set("\n"),
                 "\\t" => Set("\t"),
                 "\\s" => Set("\t "),
                 "\\b" => Set("\t \n"),
                 "\\:" => Set(":"),
                 "\\\"" => Set("\""),
                 "\\*" => Set("*"),
                 "\\[" => Set("["),
                 "\\\\" => Set("\\"),
                 "." => Set([Char(code) for code in 1:128]),
        )
pop!(reggroups["."], '\n')
reggroups["alnum"] = union(reggroups["num"], reggroups["alpha"])

# Returns start automaton state and last one
# Thompson's construction basicaly
function state2nfa!(ctx, state)
    global reggroups

    (class, data) = state

    if class == "char"
        start = lstate_new!(ctx)
        stop = lstate_new!(ctx)

        lstate_link!(start, data, stop)

        return start, stop
    elseif class == "group"
        @assert haskey(reggroups, data) "No group named '$data'"

        start = lstate_new!(ctx)
        stop = lstate_new!(ctx)

        for char in reggroups[data]
            lstate_link!(start, char, stop)
        end

        return start, stop
    elseif class == "*"
        start = lstate_new!(ctx)
        mid_start, mid_stop = state2nfa!(ctx, data)
        suff = lstate_new!(ctx)
        stop = lstate_new!(ctx)

        # start ---------------------------------> stop
        #   +-> mid_start -> mid_stop -> suff +^
        #          ^----------------------+
        llink!(start, stop)
        llink!(start, mid_start)
        llink!(mid_stop, suff, stop)
        llink!(suff, mid_start)

        return start, stop
    elseif class == "?"
        start = lstate_new!(ctx)
        mid_start, mid_stop = state2nfa!(ctx, data)
        stop = lstate_new!(ctx)

        # start -------------------> stop
        #   +-> mid_start -> mid_stop ^
        llink!(start, stop)
        llink!(start, mid_start)
        llink!(mid_stop, stop)

        return start, stop
    else
        error("Invalid state '$class'")
    end
end

# Intermediate to epsilon NFA
function states2nfa(states)
    ctx = lctx_new()
    init_state = lstate_new!(ctx)
    last_state = init_state

    for state in states
        start, stop = state2nfa!(ctx, state)

        transition = lstate_new!(ctx)
        llink!(last_state, start)
        llink!(stop, transition)
        last_state = transition
    end

    terminal_state = lstate_new!(ctx, terminal=true)
    llink!(last_state, terminal_state)

    return ctx
end

# Regex to table
function compilereg(reg)
    # Compile
    states = parsereg(reg)

    # Create automaton
    ctx = states2nfa(states)
    determinize!(ctx)

    # Create table (default char to index mapping)
    table = maketable(ctx, ldefault_chartok2index, ldefault_chartok2index_length)

    return table
end

function generate_lexer(io, regs)
    parserdir = dirname(@__FILE__)

    # Compile regexes
    for (i, (name, reg, rule)) in enumerate(regs)
        regs[i] = (name, compilereg(reg), rule)
    end

    # Regs
    println(io, "regs = [")
    for (name, reg, rule) in regs
        println(io, "    ($(repr(name)), ltable_new($(reg.actions), $(reg.terminal_states), ldefault_chartok2index), $rule),")
    end
    println(io, "]")

    # Template
    println(io, read("$parserdir/lexer_template.jl", String))
end
