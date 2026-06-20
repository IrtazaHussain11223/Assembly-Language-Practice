[org 0x100]        ; COM program start
jmp start           ; jump to main code

msg1: db 'You pressed: $'  ; message for service 9

start:
    mov ah, 01h       ; DOS function: Read character
    int 21h           ; AL = character read

    mov bl, al       

    mov ah, 09h       ; DOS function: Display string
    lea dx, msg1      ; DX = offset of message
    int 21h
    mov ah, 02h      
    mov dl, bl        
    int 21h
    mov ah, 4Ch       ; DOS terminate program
    mov al, 00        ; return code 0
    int 21h
