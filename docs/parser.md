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

As you can see, two sections are required :

- lexer : Describes which tokens we tokenize.
- parser : Describes how we produce the AST from these tokens.

### Lexer
The syntax is
```
<TOKEN_NAME> -> <REGEX> : <DATA_RULE>
```

Where :
- TOKEN\_NAME : Name of the (terminal) token we match.
- REGEX : A regular expression describing how to match the token.
        The syntax is simplified and non standard See [lexer.md](lexer.md) for the regex syntax.
- DATA\_RULE : If the token is ignored (i.e. a space), put nothing. Otherwise, put a function
        that returns the (possibly null) data of the token, like in this example :
        (s) -> Base.parse(Int, s) to parse an integer value.

Note that the priority is defined from top (most priority) to bottom (least priority).

### Parser
Like in the previous section, the syntax is almost the same :
```
<TOKEN_NAME> -> <PRODUCTION> : <DATA_RULE>
```

Where :
- TOKEN\_NAME : Name of the (non terminal) token we produce.
- PRODUCTION : One or multiple tokens to produce this token (i.e. e PLUS e).
- DATA\_RULE : A function that takes data from each token within PRODUCTION
        and which returns the data for this token.

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
