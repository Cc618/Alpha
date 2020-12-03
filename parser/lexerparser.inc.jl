# Parser-lexer definitions

mutable struct Pos
    column
    line
    index
end

mutable struct LTable
    actions
    terminal_states
    tok2index
end

mutable struct Tok
    id
    terminal
    data
    start_pos
    end_pos
end

mutable struct Prod
    left
    right
    pos
    init
end

ltable_new(actions, terminal_states, tok2index) = LTable(actions, terminal_states, tok2index)

pos_new(; column = 1, line = 1, index = 1) = Pos(column, line, index)

Base.isequal(a::Pos, b::Pos) = a.column == b.column && a.line == b.line
Base.print(io::IO, p::Pos) = print(io, "(line: $(p.line), column: $(p.column))")

function tok_new(id; terminal = false, data = nothing, start_pos = nothing, end_pos = nothing)
    return Tok(id, terminal, data, start_pos, end_pos)
end

tok_eq(a, b) = a.id == b.id

# Special tokens
tok_eps() = tok_new("eps", terminal=true)

function tok_end(; start_pos = nothing, end_pos = nothing)
    return tok_new("\$", terminal=true, start_pos=start_pos, end_pos=end_pos)
end

# Only id matters for sets / dicts
Base.hash(a::Tok) = hash(a.id)
Base.isequal(a::Tok, b::Tok) = a.id == b.id
Base.print(io::IO, t::Tok) = print(io, t.id)

prod_new(left::Tok, right::Array{Tok}; pos = 1, init = false) = Prod(left, right, pos, init)

function Base.hash(a::Prod)
    h = hash(a.left)
    h ⊻= hash(a.pos)
    for (i, r) in enumerate(a.right)
        h ⊻= hash(r) + i
    end

    return h
end

Base.isequal(a::Prod, b::Prod) =
    isequal(a.left, b.left) &&
    all([isequal(u, v) for (u, v) in zip(a.right, b.right)]) &&
    isequal(a.pos, b.pos)

function Base.print(io::IO, p::Prod)
    r = [t.id for t in p.right]
    insert!(r, p.pos, ".")
    str = "$(p.left.id) ->" * reduce((a, b) -> "$a $b", r, init="")

    Base.print(io, str)
end

# Default character to table index mapping
ldefault_chartok2index = (tok) -> codepoint(tok)
ldefault_chartok2index_length = 128
