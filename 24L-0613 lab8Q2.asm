org 100h

start:
    mainstr db 'FASTNUCEFASTNU', '$'
    substr  db 'NU', '$'
    Index   db ? 
    foundMsg db 'FOUND$'
    notfoundMsg db 'NOT FOUND$'

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov si, offset mainstr
    mov di, offset substr
    mov bl, 0
    mov cx, 14

search_loop:
    push si
    push di
    push cx

    mov cx, 2
    repe cmpsb
    je found

    pop cx
    pop di
    pop si

    inc si
    inc bl
    loop search_loop

    jmp not_found

found:
    mov Index, bl
    mov ah, 02h
    mov bh, 0
    mov dh, 5
    mov dl, 24
    int 10h
    mov ah, 09h
    mov dx, offset foundMsg
    int 21h
    jmp exit

not_found:
    mov ah, 02h
    mov bh, 0
    mov dh, 5
    mov dl, 24
    int 10h
    mov ah, 09h
    mov dx, offset notfoundMsg
    int 21h

exit:
    mov ah, 4Ch
    int 21h
