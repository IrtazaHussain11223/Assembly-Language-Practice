org 0x100
jmp start

num dw 0A425h     
dx  dw 0           

start:
    mov ax, [num]     
    mov bx, ax        
    mov cx, 16        
    mov dx, 1   ; assume its palindrome      

loop:
    mov si, ax        
    and si, 1         ;to get lsb
    mov di, bx
    shr di, 15        ; get  msb
    cmp si, di
    jne not_palin

    shl ax, 1         
    shr bx, 1         
    sub cx, 2
    jg loop
    jmp done

not_palin:
    mov dx, 0         ; not palindrome

done:
    mov ax, 0x4C00
    int 0x21
