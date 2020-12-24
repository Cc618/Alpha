using Base.Filesystem

run(Cmd(`make`, dir=dirname(@__DIR__)))
println("Done")
