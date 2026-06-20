[org 0x100]
jmp start

array db 0xA7, 0xA3, 0x94, 0xFF, 0x00
count db 5
start:
    mov si, array
    mov di, array
    mov cl, [count]
loop1:
    mov al, [si]
    mov bl, al
    mov dl, 0
    mov dh, 8
bit_loop:
    test bl, 1
    jz skip
    inc dl
skip:
    shr bl, 1
    dec dh
    jnz bit_loop
    test dl, 1
    jnz odd_bits
    mov [di], al
    inc di     
odd_bits:
    inc si
    dec cl
    jnz loop1
fill:
    cmp di, array+5; to check if we reached end
    jae end
    mov byte [di], 0
    inc di
    jmp fill
end:
    mov ax, 0x4C00
    int 0x21