; RebuiltTux2 BIOS bootloader prototype
; 16-bit x86 boot sector
; Loads in real mode at 0x7C00

BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov si, message

print_loop:
    lodsb
    cmp al, 0
    je hang
    mov ah, 0x0E
    int 0x10
    jmp print_loop

hang:
    cli
    hlt
    jmp hang

message db 'RebuiltTux2 bootloader started!', 0

times 510-($-$$) db 0
dw 0xAA55
