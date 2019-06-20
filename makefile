clean: 
	rm src/*.o
	rm interpreter

all:
	nasm -g -F dwarf -f elf64 src/inter_forth.asm
	nasm -g -F dwarf -f elf64 src/dict.asm
	ld -o interpreter src/*.o
	rm src/*.o
