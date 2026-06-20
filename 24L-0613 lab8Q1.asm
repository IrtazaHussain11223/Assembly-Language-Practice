org 100h

start:
    original db 'AssemblyLab', '$'
    reversed db '           $'

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov si, offset original
    add si, 10
    mov di, offset reversed

    std
    mov cx, 11
reverse_loop:
    lodsb
    stosb
    loop reverse_loop

    cld

    mov ah, 09h
    mov dx, offset original
    int 21h

    mov ah, 02h
    mov dl, 0Dh
    int 21h
    mov dl, 0Ah
    int 21h

    mov ah, 09h
    mov dx, offset reversed
    int 21h

    mov ah, 4Ch
    int 21h
