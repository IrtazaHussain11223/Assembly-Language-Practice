org 0x100
jmp start

num dw 0A425h
start:
    mov ax, [num]
    mov bx, ax
    mov cx, 16
    mov dx, 1
checkbits:
    mov si, ax
    and si, 1          ; LSB
    mov di, bx
    mov cl, 15
    shr di, cl         ; MSB
    cmp si, di
    jne notpalin
    shl ax, 1
    shr bx, 1
    sub cx, 2
    jg checkbits
    jmp done
notpalin:
    mov dx, 0
done:
    mov ax, 0x4C00
    int 0x21
