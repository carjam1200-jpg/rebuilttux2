# RebuiltTux2 Build System

ASM=nasm
ISO_DIR=iso
BOOT_DIR=bootloader

all: $(ISO_DIR)/rebuilttux2.iso

boot.bin: $(BOOT_DIR)/boot.asm
	$(ASM) -f bin $(BOOT_DIR)/boot.asm -o boot.bin

$(ISO_DIR)/rebuilttux2.iso: boot.bin
	@echo "ISO generation placeholder"
	@echo "Add ISO tools (xorriso/grub-mkrescue) when kernel is ready"

clean:
	rm -f boot.bin $(ISO_DIR)/*.iso

.PHONY: all clean
