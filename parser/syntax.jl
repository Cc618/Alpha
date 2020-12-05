# Parses all lines of the syntax file
# Returns all tokens, prods, etc...
# necessary for lexing and parsing
function parsesyntax(lines)
    # lexer or parser
    section = nothing
    lexer_items = []
    parser_items = []
    terminals = []
    nonterminals = []

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

            # TODO : Parse terminals...
            if section == "lexer"
                arrow = findfirst("->", l)
                colon = findfirst(r"[^\\]:", l)
                colon = colon.stop
                name, reg, rule = strip(l[begin:arrow.start - 1]), strip(l[arrow.stop + 1:colon - 1]), strip(l[colon + 1:end])

                println("Lexer |$name| |$reg| |$rule|")
                push!(lexer_items, (name, reg, rule))
            else
                # arrow = findfirst("->", l)
                # colon = findfirst(':', l)
                # name, reg, rule = strip(l[begin:arrow - 1]), strip(l[arrow + 2:colon - 1]), strip(l[colon + 1:end])

                # println("Parser |{name}| |{reg}| |{rule}|")
                # push!(parser_items, (name, reg, rule))
            end
        end
    end

    prods = []
    produce_rules = []

    # # TODO : Construct
    # tokens = vcat(terminals, nonterminals)

    # return (regs, tokens, prods, produce_rules)
end

file = "calculator.syntax"
open(file) do io
    lines = readlines(io)
    parsesyntax(lines)
end
