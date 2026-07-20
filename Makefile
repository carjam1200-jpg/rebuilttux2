CC=gcc
ASM=nasm
LD=ld

CFLAGS=-m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib

KERNEL=kernel.bin

all: $(KERNEL)

boot.o: kernel/arch/x86/boot.asm
	$(ASM) -f elf32 kernel/arch/x86/boot.asm -o boot.o

kernel.o: kernel/kernel.c
	$(CC) $(CFLAGS) -c kernel/kernel.c -o kernel.o

$(KERNEL): boot.o kernel.o
	$(LD) -m elf_i386 -T kernel/linker.ld -o $(KERNEL) boot.o kernel.o

clean:
	rm -f *.o $(KERNEL)

.PHONY: all clean
