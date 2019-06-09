clean: 
	rm src/*.o
	rm interpreter

all:
	nasm -f elf64 -g src/inter_forth.asm
	nasm -f elf64 -g src/dict.asm
	ld -o interpreter src/*.o
	rm src/*.o
