[org 0x100]
jmp start
mes db 'Fast NU'
start:
mov ax,0xb800
mov es,ax
mov cx,7
mov di,168
mov si,mes
mov ah,0x00
next:
mov al,[si]
mov [es:di],ax
inc si
add di,2
dec cx 
jnz next
mov ax, 0x4C00
int 0x21
