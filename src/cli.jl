# Command line interface functions

function clihelp()
    # TODO : Print alphalib path
    text = [
            "usage:",
            "   alpha <file>.alpha              Compile <file>.alpha to <file>",
            "   alpha run <file>.alpha          Run <file>.alpha",
            "   alpha generate <file>.alpha     Generate <file>.asm assembly code",
            "   alpha build <file>.alpha        Build <file>.o object file",
        ]

    for t in text
        println(t)
    end
end

# Preprocesses the source code
function preprocess(code)
    code = replace(code, "\t" => "    ")
    code[end] != '\n' && (code *= "\n")

    return code
end

# Alpha to NASM from src (alpha) to out (asm)
function cligenerate(src, out)
    local code
    open(src) do io
        code = read(io, String)
    end

    code = preprocess(code)

    ctx = parse(code)
    ctx.sourcecode = code

    semanticanalysis!(ctx)

    open(out, "w") do io
        println(io, codegen!(ctx))
    end
end

# Replaces the extension by newext
# This function assumes that there is already an extension
function changeext(path, newext)
    period = findlast(path, '.')

    @assert period != nothing "The file $path has no extension"

    return path[begin : period - 1] * "." * newext
end
