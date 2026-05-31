bits 16

global _start
global _putInMemory
global _getChar
extern _main

_start:

    cli

    mov ax, cs
    mov ds, ax
    mov es, ax

    sti

    call _main

.hang:
    jmp .hang


_putInMemory:
    push bp
    mov bp, sp

    push ds

    mov ax, [bp+4]
    mov si, [bp+6]
    mov cl, [bp+8]

    mov ds, ax
    mov [si], cl

    pop ds

    pop bp
    ret

; implement this
_getChar:
    push bp
    mov bp, sp

    xor ah, ah      ; BIOS INT 16h function 00h = wait for keypress
    int 0x16        ; AL = ASCII character

    xor ah, ah      ; zero out AH, return ASCII code in AX
    pop bp
    ret
