DIR = bin
OBJ = $(DIR)/alpha.o
SRC = $(wildcard src/*)

all: $(OBJ)

$(OBJ): $(SRC) $(wildcard include/*)
	mkdir -p $(DIR)
	gcc -c -o $(OBJ) -Iinclude $(SRC)

.PHONY: clean
clean:
	rm -rf bin
