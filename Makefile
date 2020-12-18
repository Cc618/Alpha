# TODO : build objects / compile binary
# TODO : clean

all: src

.PHONY: src
src: src/*.jl src/parser.yy.jl
	julia src/main.jl

src/parser.yy.jl: src/parser.syntax
	julia parser/LexerParser.jl src/parser.syntax

.PHONY: clean
clean:
	rm -rf src/parser.yy.jl
