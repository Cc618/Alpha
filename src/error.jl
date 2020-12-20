function alphaerror(msg, ctx, loc)
    tored = "\x1b[1;31m"
    toblue = "\x1b[1;34m"
    tonormal = "\x1b[1;0m"

    pos = loc[begin]

    line_start = findprev('\n', ctx.sourcecode, pos.index)
    line_end = findnext('\n', ctx.sourcecode, pos.index + 1)

    line_start == nothing && (line_start = 0)
    line_end == nothing && (line_end = length(ctx.sourcecode) + 1)

    println(stderr, "$tored+-> Error$tonormal")
    println(stderr, "From $toblue$(loc[begin])$tonormal to $toblue$(loc[end])$tonormal:")
    if line_start < line_end
        println(stderr, ctx.sourcecode[line_start + 1:line_end - 1])
        println(stderr, repeat(' ', pos.column - 1) * "$toblue^$tonormal")
    end

    println(stderr, "> $tored$msg$tonormal")

    exit(-1)
end

macro alphaassert(condition, location, msg)
    return :( $(esc(condition)) ? nothing : alphaerror($(esc(msg)), ctx, $(esc(location))) )
end
