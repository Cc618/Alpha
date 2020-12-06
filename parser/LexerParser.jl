module LexerParser

# Gathers all includes
include("syntax.jl")

# Parse syntax file, returns arguments for the generate function
export parsesyntax

# Generate to io stream a parser
export generate

end

# Main
if abspath(PROGRAM_FILE) == @__FILE__
    @assert length(ARGS) == 1 "usage: julia Parser.jl <syntax_file>"

    using .LexerParser

    file = ARGS[begin]
    open(file) do io
        global lines = readlines(io)
    end

    # Parse file
    regs, tokens, prods, produce_rules = parsesyntax(lines)

    extpos = findlast('.', file)
    outfile = extpos == nothing ? "$file.yy.jl" : "$(file[begin:extpos - 1]).yy.jl"

    # Generate lexer-parser
    open(outfile, "w") do io
        generate(io, regs, tokens, prods, produce_rules)
    end

    println("Generated parser $outfile")
end
