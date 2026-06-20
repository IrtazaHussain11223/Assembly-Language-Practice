[org 0x100]
mov ax,0xb800
mov es,ax
mov di,0
mov al, 'A'
mov ah, 1
mov cx,26
next:
mov [es:di],ax
add di,162
inc al
inc ah
dec cx
jnz next
mov ax, 0x4C00
    int 21