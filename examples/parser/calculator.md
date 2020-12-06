# Calculator
A simple calculator that supports basic algebraic expressions such as 3 + (2 + 2) x 3 + 2 x 2.

This test is made to test the parser generator.

The file [calculator.syntax](calculator.syntax) contains all rules necessary to build the parser.

## Build and run
To generate the parser :
```sh
julia ../../parser/LexerParser.jl calculator.syntax
```

Note that this will generate the file calculator.yy.jl.

To run :
```sh
julia calculator.jl
```
