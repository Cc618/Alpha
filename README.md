# The Alpha Compiler
Source for the Alpha language.

## Features
Written in Julia, Alpha is a compiled, statically typed procedural language.
Furthermore, this language supports recursion and the compiler is multipass (functions can be called before being declared).

<!-- TODO : DOC links -->
In addition to the compiler, a lexer-parser generator which works like flex / bison is included.

Alpha is inspired by Julia and Python for the syntax, though it supports only integers for variables.

## Usage
### Building
Interpreting all files within src can be slow, it is preferable to precompile this package.
To do so, follow these instructions :

<!-- TODO -->
<!-- ``` -->
<!-- julia -->

<!-- ``` -->

### Running
```sh
julia -e "import Alpha; Alpha.alphamain()" <ARGS>
```

## Components
- alphalib : The Alpha standard library
- docs : Project's documentation
- examples : Some Alpha programs
- parser : The lexer and parser generator
- src : The Alpha Compiler
<!-- TODO : DOC link -->
- vim : Plugin for syntax highlighting

## Lexer-Parser
<!-- TODO : DOC link -->
A lexer and parser generator has been created.
The lexer supports custom regexes, the syntax is simple because Alpha's syntax is pretty easy.
The parser is an SLR(1) parser, it handles location detection to display meaningful errors.

## Vim
The vim folder contains a plugin for Vim syntax highlighting, the script install.sh can be used to install it
or any Vim plugin manager can be used.

<!-- TODO : Examples -->
