[org 0x100]
jmp start

msg1 db 'ASCII code: $'
msg2 db 'Scan code: $'

start:
mov ah, 0
int 16h
mov bl, al
mov ah, 0
add bl, '0'
mov dl, bl
mov ah, 2
int 21h
mov dl, ' '
int 21h
mov bl, ah
mov ah, 0
add bl, '0'
mov dl, bl
mov ah, 2
int 21h
mov ax, 4C00h
int 21h
