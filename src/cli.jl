# Command line interface functions

using Base.Filesystem

tored = "\x1b[1;31m"
toblue = "\x1b[1;34m"
tonormal = "\x1b[1;0m"

function climain(args)
    local out
    local outdir

    if length(args) == 0
        clihelp()
    elseif length(args) == 1
        if args[begin] ∈ ("help", "-h", "--help")
            clihelp()
        else
            out = clicompileall(args[begin])
            outdir = dirname(args[begin])
        end
    elseif length(args) == 2
        args[begin] ∉ ("run", "build", "generate") && clihelp()

        method = args[begin]
        src = args[end]
        out = clicompileall(src, method)
        outdir = dirname(src)

        # Run tmp program
        if method == "run"
            cmd = `$out`
            run(cmd)

            out = nothing
        end
    else
        clihelp()
    end

    if isa(out, String) && isa(outdir, String)
        cmd = `cp $out $outdir`
        run(cmd)
    end
end

function clihelp()
    # TODO : Print alphalib path
    # TODO : -o option
    # TODO : run
    text = [
            "usage:",
            "   alpha <file>.alpha              Compile <file>.alpha to <file>",
            "   alpha run <file>.alpha          Run <file>.alpha",
            "   alpha build <file>.alpha        Build <file>.o object file",
            "   alpha generate <file>.alpha     Generate <file>.asm assembly code",
            "   alpha help                      Show help",
            "   alpha -h                        Show help",
            "   alpha --help                    Show help",
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

# Build asm to object
function clibuild(src, out)
    cmd = `nasm -o $out -f elf64 $src`

    try
        run(cmd)
    catch e
        clierr("Failed to build using NASM, fix errors above to build")
    end
end

# Links th alpha source object file
# with the alphalib to out
function clicompile(src, out)
    libdir = alphalibdir()
    alphalibbin = "$libdir/bin/alpha.o"

    # Build alphalib
    cmd = Cmd(`make`, dir=libdir)
    cmdout = IOBuffer()

    try
        run(pipeline(cmd, stdout=cmdout))
    catch e
        # Show stdout if needed
        cmdoutstr = read(cmdout, String)
        if cmdoutstr != ""
            println("$toblue* Command output:$tonormal")
            println(cmdoutstr)
        end

        clierr("Failed to build alphalib, fix errors above to compile")
    end

    cmd = `gcc -static -o $out $src $alphalibbin`
    try
        run(cmd)
    catch e
        clierr("Failed to link, fix errors above to compile")
    end
end

# Wrapper that compiles everything up to the stop step
# Returns the path of the output
function clicompileall(src, stop="compile")
    src = abspath(src)

    # Auto deleted
    tmp = mktempdir()
    asmout = "$tmp/source.asm"
    objout = "$tmp/source.o"
    exeout = "$tmp/source"

    # Generate
    climake(cligenerate, src, out=asmout)

    if stop == "generate"
        return asmout
    end

    # Build
    clibuild(asmout, objout)

    if stop == "build"
        return objout
    end

    # Compile
    clicompile(objout, exeout)

    return exeout
end

function clierr(msg)
    println(stderr, "$(tored)Error$tonormal : $msg")
    exit(-1)
end

# Runs the function fun on path
# which outputs path with the new extension ext
function climake(fun, path; newext = nothing, verifext = "alpha", out = nothing)
    err = false

    slash = findlast('/', path)
    period = findlast('.', path)

    slash == nothing && (slash = -1)
    if period == nothing || slash > period
        err = true
    else
        ext = path[period + 1:end]
        ext != verifext && (err = true)
    end

    if err
        clierr("Invalid file $toblue$path$tonormal, must have a .$verifext extension")
    end

    # Generate out
    newext != nothing && out != nothing && (out = path[begin : period - 1] * "." * newext)
    fun(path, out)
end

# Returns the root dir of alpha
alphadir() = dirname(@__DIR__)
alphalibdir() = "$(alphadir())/alphalib"
