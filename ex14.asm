[org 0x100]
jmp start

swapRows:
    push ax
    push bx
    push cx
    push si
    push di
    push es
    push ds
    mov ax, 0xB800
    mov es, ax
    mov ds, ax
    xor bx, bx
    mov cx, 12
next_pair:
    mov si, bx
    mov di, bx
    add di, 160
    mov dx, 80

swap_loop:
    lodsw
    mov bx, [es:di]    
    mov [es:di], ax    
    mov ax, bx     
    stosw
    dec dx
    jnz swap_loop
    add bx, 320
    loop next_pair
    pop ds
    pop es
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

start:
    call swapRows
    mov ax, 0x4C00
    int 0x21

