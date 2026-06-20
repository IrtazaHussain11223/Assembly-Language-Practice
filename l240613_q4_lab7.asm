[org 0x100]
mes db 'irtaza'
start:
mov ax,0xb800
mov es,ax
mov cx,6
mov di,1994
mov si,mes
mov ah,0x00
next:
mov al,[si]
mov [es:di],ax
inc si
inc ah
add di,2
dec cx 
jnz next
mov ax, 0x4C00
int 0x21

