NAME=mario
nasm -f elf -d ELF_TYPE $NASM/asm_io.asm
nasm -f elf $NAME.asm
nasm -f elf io.asm
gcc -m32 -o $NAME.out io.o $NAME.o $NASM/driver.c $NASM/asm_io.o
