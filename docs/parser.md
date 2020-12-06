# Parser
The lexer-parser generator is a tool like flex and bison.
Located at parser/, it generates a bottom up parser using the SLR(1) automaton.
The lexer is described in this (file)[lexer.md].

## How it works ?
The file ParserLexer.jl is used to generate the parser.

With your syntax file named lang.syntax for example,
compile it to lang.yy.jl with this command (from the root of the repo) :

```sh
julia parser/LexerParser.jl lang.syntax
```

lang.yy.jl is the file to include to call the parse function
that generates the AST.

## Syntax
To see an improved example, look at the [calculator example](../examples/parser/calculator.syntax).

This syntax parses additions :
```julia
@lexer:
    # Return the data
    PLUS    -> "+" : (s) -> nothing
    N       -> "-?[num][num]*" : (s) -> Base.parse(Int, s)
    # Ignore it without a function
    BLANK   -> "[\s][\s]*" : nothing

@parser:
    # Root of the AST
    a -> e : (val) -> val

    # Expression
    e -> e PLUS e : (a, _, b) -> a + b
    e -> N : (val) -> val
```

## Structure
- lexer.jl : Generates all automatons and functions to tokenize the text.
- lexer_\_template.jl : Included in the generated file for runtime (lexical analysis only).
- lexerparser.inc.jl : A file containing definitions for the runtime.
- LexerParser.jl : Main module, exports parsesyntax and generate and has a main function.
- lexerparser.jl : Main file to generate the lexer-parser (parser.yy.jl).
- lexerparser\_template.jl : Contains functions to interact between lexing and parsing modules.
- slr.jl : Generates the SLR(1) automaton and other functions usefull for syntax analysis.
- slr.parse\_template.jl : Included in the generated file for runtime (SLR(1) only).
- syntax.jl : Parses syntax files
