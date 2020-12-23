# Command line interface functions

tored = "\x1b[1;31m"
toblue = "\x1b[1;34m"
tonormal = "\x1b[1;0m"

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

function clierr(msg)

    println(stderr, "$(tored)Error$tonormal : $msg")
    exit(-1)
end

# Runs the function fun on path
# which outputs path with the new extension ext
function climake(fun, path, newext)
    err = false

    slash = findlast('/', path)
    period = findlast('.', path)

    slash == nothing && (slash = -1)
    if period == nothing || slash > period
        err = true
    else
        ext = path[period + 1:end]
        ext != "alpha" && (err = true)
    end

    if err
        clierr("Invalid file $toblue$path$tonormal, must have a .alpha extension")
    end

    out = path[begin : period - 1] * "." * newext
    println(out)
    fun(path, out)
end
