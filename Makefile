MAIN = main.asm
BIN  = sokoban.com

build: $(MAIN)
	nasm -f bin $(MAIN) -o $(BIN)

run: main.com
	dosbox $(BIN)
