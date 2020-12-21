# Returns the header containing all instructions
# to use alphalib
function alphalib_head()
    funcs = [
             "alphaprintint",
             "alphaprintstr",
             "alphaprintline",
             "alphaprintspace",
        ]

    s = ""
    for f in funcs
        s *= "extern $f\n"
    end

    return s
end
