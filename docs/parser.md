# Parser
The lexer-parser generator is a tool like flex and bison.
Located at parser/, it generates a bottom up parser using the SLR(1) automaton.
The lexer is described in this (file)[lexer.md].

## How it works ?
<!-- TODO : Main file syntax -->
The file parserlexer.jl is used to generate the parser.
The output file is by default parser.yy.jl. This is the file to
include to call the parse function that generates the AST.

## Structure
- lexer.jl : Generates all automatons and functions to tokenize the text.
- lexer_\_template.jl : Included in the generated file for runtime (lexical analysis only).
- lexerparser.jl : Main module to generate the lexer-parser (parser.yy.jl).
- parser.yy.jl : Generated lexer-parser file, will be included in your code.
- parserlexer.inc.jl : A file containing definitions for the runtime.
- parserlexer\_template.jl : Contains functions to interact between lexing and parsing modules.
- slr.jl : Generates the SLR(1) automaton and other functions usefull for syntax analysis.
- slr.parse\_template.jl : Included in the generated file for runtime (SLR(1) only).
