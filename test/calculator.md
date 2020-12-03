# Calculator
A simple calculator that supports basic algebraic expressions such as 3 + (2 + 2) x 3 + 2 x 2.

This test is made to test the parser generator.

Until now, the parser is generated purely by julia code.

## Build and run
To generate the parser :
```sh
julia calculator.jl
```

Note that this will generate the file parser.yy.jl.

To run :
```sh
julia calculator_runtime.jl
```
