org 100h

OldOff  dw 0
OldSeg  dw 0

start:

    xor ax, ax
    mov ds, ax

    mov bx, 0x08
    shl bx, 2

    mov ax, [bx]
    mov [OldOff], ax

    mov ax, [bx+2]
    mov [OldSeg], ax

    mov dx, msg
    mov ah, 0x09
    int 0x21

    mov ax, [OldOff]
    call PrintHex

    mov dx, msg2
    mov ah, 0x09
    int 0x21

    mov ax, [OldSeg]
    call PrintHex

    mov ah, 0x4C
    int 0x21


PrintHex:
    pusha
    mov cx, 4

next_digit:
    rol ax, 4
    mov bl, al
    and bl, 0x0F
    add bl, 0x30
    cmp bl, 0x39
    jle print_it
    add bl, 0x07

print_it:
    mov dl, bl
    mov ah, 0x02
    int 0x21
    loop next_digit

    popa
    ret

msg  db "Old INT 08h Offset: $"
msg2 db 0x0D,0x0A,"Old INT 08h Segment: $"
