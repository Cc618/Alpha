all: src alphalib

src: src/*.jl src/parser.yy.jl

src/parser.yy.jl: src/parser.syntax
	@echo '>' Generating parser
	julia parser/LexerParser.jl src/parser.syntax

.PHONY: alphalib
alphalib:
	@echo '>' Building AlphaLib
	cd alphalib && make

.PHONY: run
run: src
	julia src/main.jl

.PHONY: clean
clean:
	rm -rf src/parser.yy.jl
	cd alphalib && make clean
