module Alpha

include("main.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    alphamain()
end

end
