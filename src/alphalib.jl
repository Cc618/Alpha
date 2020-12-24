# Returns the header containing all instructions
# to use alphalib
alphalib_funcs = [
        "alphaprintint",
        "alphaprintstr",
        "alphascan",
    ]

function alphalib_head()
    s = ""
    for f in alphalib_funcs
        s *= "extern $f\n"
    end

    return s
end
