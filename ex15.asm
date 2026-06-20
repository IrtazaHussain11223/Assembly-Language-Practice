org 0x100
jmp start

clearScreen:
    push ax
    push cx
    push di
    push es

    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000

fill_loop:
    mov al, ' '
    mov ah, 0x07
    stosw
    loop fill_loop

    pop es
    pop di
    pop cx
    pop ax
    ret

start:
    call clearScreen
    mov ax, 0x4C00
    int 0x21
