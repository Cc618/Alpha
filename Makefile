# TODO : build objects / compile binary
# TODO : clean

all: src

.PHONY: src
src:
	julia parser/LexerParser.jl src/parser.syntax
	julia src/main.jl
