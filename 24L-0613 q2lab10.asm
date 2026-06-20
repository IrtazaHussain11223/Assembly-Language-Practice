[org 0x100]

jmp start

oldInt60 dw 0,0

msg db 'Custom Interrupt Triggered$'

isr60:
push ax
push dx
mov dx, offset msg
mov ah, 9
int 21h
pop dx
pop ax
iret

start:
cli
mov ax, 0
mov es, ax
mov bx, [0x0060*4]   ; save old INT 60h vector
mov [oldInt60], bx
mov bx, [0x0060*4+2]
mov [oldInt60+2], bx
mov dx, offset isr60
mov ax, seg isr60
mov ds, ax
mov ax, 0
mov bx, dx
mov word [0x0060*4], bx
mov word [0x0060*4+2], ax
sti

int 60h

mov ax, 4C00h
int 21h
