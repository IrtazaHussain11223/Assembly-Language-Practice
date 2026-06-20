[org 0x100]
jmp start

clearArea:
    push bp
    mov bp, sp
    mov ax, 0xB800
    mov es, ax
    mov ah, 0x07

    mov dx, [bp+4]   
    mov cx, [bp+6]   
    mov bx, [bp+8]   
    mov si, [bp+10]  
row_loop:
    mov ax, si
    mov di, ax
    shl di, 6
    shl ax, 5
    add di, ax
    shl di, 1
    mov ax, bx
    shl ax, 1
    add di, ax
    mov bp, bx

col_loop:
    mov byte [es:di], ' '
    mov byte [es:di+1], ah
    add di, 2
    inc bp
    cmp bp, dx
    jle col_loop
    inc si
    cmp si, cx
    jle row_loop
    pop bp
    ret 8
start:
    push 5     ; top 
    push 10    ; left
    push 15    ; buttom
    push 60    ; right
    call clearArea

    mov ax, 0x4C00
    int 0x21
