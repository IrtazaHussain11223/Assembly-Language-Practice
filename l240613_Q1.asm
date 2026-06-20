[org 0x0100]

jmp start
array db 15, -25, 34, -120, 0, 67, -50, 100, -1, 45  ; 10 elements

UL db 0
US db 0
SL db 0
SS db 0
start:
    mov si, array          ; get 1st elem of arr
    mov al, [si]           
    mov [UL], al
    mov [US], al
    mov [SL], al
    mov [SS], al

    mov cx, 9          ;cx loop to check all elemensts   
   inc si

next_element:
    mov al, [si]           
    mov bl, [UL]
    cmp al, bl    ; to check unsin larg
    jbe skip_UL
    mov [UL], al
skip_UL:
    mov bl, [US]
    cmp al, bl     ; to check unsin small
    jae skip_US
    mov [US], al
skip_US:
    mov bl, [SL]
    cmp al, bl    ; to check sin large
    jle skip_SL
    mov [SL], al
skip_SL:
    mov bl, [SS]
    cmp al, bl   ; to check sin small
    jge skip_SS
    mov [SS], al
skip_SS:

    inc si
    loop next_element

mov ax, 0x4c00
int 0x21