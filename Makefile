# TODO : build objects / compile binary
# TODO : clean

all: src

.PHONY: src
src: src/*.jl
	julia src/main.jl

src/parser.yy.jl: src/parser.syntax
	julia parser/LexerParser.jl src/parser.syntax
