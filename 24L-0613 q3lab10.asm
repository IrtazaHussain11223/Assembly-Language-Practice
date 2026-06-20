org 100h

OldOff  dw 0
OldSeg  dw 0
TickCount dw 0

start:
    xor ax, ax
    mov ds, ax

    mov bx, 0x08
    shl bx, 2

    mov ax, [bx]
    mov [OldOff], ax

    mov ax, [bx+2]
    mov [OldSeg], ax

    cli
    mov word [bx], NewISR
    mov word [bx+2], cs
    sti

    mov dx, msg
    mov ah, 0x09
    int 0x21

wait:
    jmp wait

NewISR:
    push ax
    inc word [cs:TickCount]
    pop ax
    jmp far [cs:OldOff]

msg db "Custom INT 08h Installed$"
