[org 0x100]
mov ax,0xb800
mov es,ax
mov di,0
mov al,'A'
mov ah,0x0F
mov [es:di],ax
mov ax, 0x4C00
int 0x21