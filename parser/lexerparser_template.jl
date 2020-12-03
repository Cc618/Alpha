# Main parser function
# Constructs an AST from the code
function parse(src)
    tokens = lparse(src)
    ast = pparse(tokens)

    return ast
end
