# Used to parse syntax files

include("lexerparser.jl")

# Parses all lines of the syntax file
# Returns all tokens, prods, etc...
# necessary for lexing and parsing
function parsesyntax(lines)
    # lexer or parser
    section = nothing

    # Parse only strings now
    lexer_items = []
    parser_items = []

    # Fetch names of tokens
    terminals = []
    nonterminals = []

    # Parse all lines
    for (lno, l) in enumerate(lines)
        l = strip(l)
        if length(l) == 0
            continue
        end

        # Comment
        if l[begin] == '#'
            continue
        end

        # Section
        if l[begin] == '@'
            @assert l[end] == ':' "Invalid section declaration at line $lno, a section is ':' terminated"

            section = l[2:end - 1]
            @assert section ∈ ("lexer", "parser") "Invalid section '$section', must be either lexer or parser at line $lno"
        else
            @assert section != nothing "Code outside of section at line $lno"

            if section == "lexer"
                arrow = findfirst("->", l)
                colon = findfirst(r"[^\\]:", l)
                colon = colon.stop

                name, rule = strip(l[begin:arrow.start - 1]), strip(l[colon + 1:end])
                reg = strip(l[arrow.stop + 1:colon - 1])[2:end - 1]

                @assert name ∉ nonterminals "Can't produce non terminal $name from lexer (line $lno)"
                push!(terminals, name)

                # println("Lexer |$name| |$reg| |$rule|")
                push!(lexer_items, (name, reg, rule))
            else
                arrow = findfirst("->", l)
                colon = findfirst(r"[^\\]:", l)
                colon = colon.stop

                name = strip(l[begin:arrow.start - 1])
                prod = [strip(x) for x in split(strip(l[arrow.stop + 1:colon - 1]), ' ')]
                rule = strip(l[colon + 1:end])

                @assert name ∉ terminals "Can't produce terminal $name from parser (line $lno)"

                name ∉ nonterminals && push!(nonterminals, name)


                # println("Parser |$name| |$prod| |$rule|")
                push!(parser_items, (lno, name, prod, rule))
            end
        end
    end

    # Lexer
    regs = lexer_items

    # Create tokens
    terminals = [tok_new(name, terminal=true) for name in terminals]
    nonterminals = [tok_new(name, terminal=false) for name in nonterminals]
    tokens = vcat(terminals, nonterminals)
    id2tok = Dict([t.id => t for t in tokens])

    # Create prods and its rules
    prods = []
    produce_rules = []
    for (lno, left_name, prod, produce_rule) in parser_items
        local left_tok, prod

        try
            left_tok = id2tok[left_name]
            prod = [id2tok[t] for t in prod]
        catch e
            error("Invalid rule at line $lno, unknown token ($e)")
        end

        push!(prods, prod_new(left_tok, prod))
        push!(produce_rules, produce_rule)
    end

    return (regs, tokens, prods, produce_rules)
end
