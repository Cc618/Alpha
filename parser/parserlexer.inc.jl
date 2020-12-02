mutable struct Pos
    column
    line
end

mutable struct Tok
    id
    terminal
    data
end

mutable struct Prod
    left
    right
    pos
    init
end

tok_new(id; terminal = false, data = nothing) = Tok(id, terminal, data)
tok_eq(a, b) = a.id == b.id

# Special tokens
tok_eps() = tok_new("eps", terminal=true)
tok_end() = tok_new("\$", terminal=true)

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
