# The Alpha Compiler
Source for the Alpha language.

## Features
Written in Julia, Alpha is a compiled, statically typed procedural language.
Furthermore, this language supports recursion and the compiler is multipass
(functions can be called before being declared).

In addition to the compiler, a lexer-parser generator which works like flex / bison is included.

Alpha is inspired by Julia and Python for the syntax, though it supports only integers for variables.

See a [brief syntax overview](docs/syntax.md).

## Installation & Usage
### Installation
To install Alpha, first install dependencies and follow these instructions :
```
julia
]
add https://github.com/Cc618/Alpha
```

After this, you can test whether the package is installed with this command :
```
julia -e "import Alpha; Alpha.alphamain()" help
```

Note that this step can take few seconds the first time the module is imported due to precompilation.

### Usage
To use Alpha, import it and run alphamain that interpretes program arguments.
```sh
julia -e "import Alpha; Alpha.alphamain()" <ARGS>
```

You might want to create an alias and add it to your bashrc :
```sh
alias alpha='julia -e "import Alpha; Alpha.alphamain()"'
```

Here is the list of all commands :

| Command | Result |
| ------- | ------ |
| alpha `<file>.alpha`          | Compile `<file>.alpha` to `<file>`    |
| alpha run `<file>.alpha`      | Run `<file>.alpha`                    |
| alpha build `<file>.alpha`    | Build `<file>.o` object file          |
| alpha generate `<file>.alpha` | Generate `<file>.asm` assembly code   |
| alpha [help\|-h\|--help]      | Show help                             |

### Dependencies
Alpha targets Linux machines.
Moreover, it relies on some binaries :

- make
- gcc
- nasm
- julia

Alpha has been tested on Manjaro and Arch Linux (december 2020) with Julia 1.5.3.

## Components
- alphalib : The Alpha standard library
- docs : Project's documentation
- examples : Some Alpha programs
- parser : The lexer and parser generator
- src : The Alpha Compiler
- vim : Plugin for syntax highlighting

## Lexer-Parser
A lexer and parser generator has been created.
The lexer supports custom regexes, the syntax is simple because Alpha's syntax is pretty easy.
The parser is an SLR(1) parser, it handles location detection to display meaningful errors.

### Links
- [Calculator example](examples/parser/calculator.syntax).
- [Parser documentation](docs/parser.md).
- [Lexer documentation](docs/lexer.md).

## Vim
<!-- TODO : Check Vplug install with github subdir -->
The vim folder contains a plugin for Vim syntax highlighting, the script install.sh can be used to install it
or any Vim plugin manager can be used.

## Documentation
You can see all documentation pages [here](docs/README.md).

<!-- TODO : Examples -->
