# Returns the header containing all instructions
# to use alphalib
function alphalib_head()
    funcs = [
             "alphaprint",
        ]

    s = ""
    for f in funcs
        s *= "extern $f\n"
    end

    return s
end
