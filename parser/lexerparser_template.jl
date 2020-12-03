# Main parser function
# Constructs an AST from the code
function parse(src)
    toks = lparse(src, regs)
    ast = pparse(toks)

    return ast
end
