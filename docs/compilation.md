# Compilation
The compilation is made in 3 steps.

## Syntax Analysis
An AST is created by lexing and then parsing the source code.
To do so, we use the [Lexer-Parser](parser.md) to generate the parser.

### AST
The AST is made basically of three kinds of node :
- Declarations : Functions or variables.
- Statements : Instructions.
- Expressions : Gather a value or a symbol.

## Semantics Analysis
After building the AST, the AST is parsed in two passes.

The first pass looks for global functions or procedures.
Doing this allows the user to call functions before having declared it's body.

The second one resolves each node of the tree. Most of errors are solved there.

## Code Generation
To generate the assembly code, scratch registers are used to handle expressions.
By doing a prefix traversal of the AST (which is a DAG), we can easily generate
each expression, then each statements, then each declarations.

Furthermore, the format is NASM elf64, which is Linux x86\_64 compatible.

## Notes about linking
The goal is to generate an assembly file, linking is done in the CLI section with NASM and GCC.
